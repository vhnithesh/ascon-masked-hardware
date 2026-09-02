import sys
import os
import time
import json
import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
from torch.utils.data import TensorDataset, DataLoader

SEED = 42
np.random.seed(SEED)
torch.manual_seed(SEED)

# ==============================================================================
# 1. ADVANCED LOSS FUNCTIONS FOR METHOD B
# ==============================================================================

class FocalLoss(nn.Module):
    """
    Focal Loss to counter HW class imbalance:
    FL(p_t) = - alpha_t * (1 - p_t)^gamma * log(p_t)
    """
    def __init__(self, weight=None, gamma=2.0, reduction='mean'):
        super().__init__()
        self.weight = weight
        self.gamma = gamma
        self.reduction = reduction

    def forward(self, inputs, targets):
        ce_loss = F.cross_entropy(inputs, targets, weight=self.weight, reduction='none')
        pt = torch.exp(-ce_loss)
        focal_loss = ((1.0 - pt) ** self.gamma) * ce_loss
        if self.reduction == 'mean':
            return focal_loss.mean()
        elif self.reduction == 'sum':
            return focal_loss.sum()
        return focal_loss

def get_class_weights(labels, num_classes=6):
    counts = np.bincount(labels, minlength=num_classes)
    total = len(labels)
    # Avoid zero division
    weights = total / (num_classes * np.maximum(counts, 1).astype(np.float32))
    # Normalize
    weights = weights / weights.sum() * num_classes
    return torch.tensor(weights, dtype=torch.float32)

# ==============================================================================
# 2. NEURAL NETWORK ARCHITECTURES FOR METHOD B
# ==============================================================================

class DilatedConvBlock(nn.Module):
    def __init__(self, in_ch, out_ch, k=5, dilation=1):
        super().__init__()
        padding = ((k - 1) * dilation) // 2
        self.block = nn.Sequential(
            nn.Conv1d(in_ch, out_ch, kernel_size=k, padding=padding, dilation=dilation),
            nn.BatchNorm1d(out_ch),
            nn.ReLU(),
            nn.Conv1d(out_ch, out_ch, kernel_size=k, padding=padding, dilation=dilation),
            nn.BatchNorm1d(out_ch),
            nn.ReLU()
        )
    def forward(self, x):
        return self.block(x)

class ResBlock1D(nn.Module):
    def __init__(self, channels, k=5, dilation=1):
        super().__init__()
        padding = ((k - 1) * dilation) // 2
        self.conv1 = nn.Conv1d(channels, channels, kernel_size=k, padding=padding, dilation=dilation)
        self.bn1 = nn.BatchNorm1d(channels)
        self.conv2 = nn.Conv1d(channels, channels, kernel_size=k, padding=padding, dilation=dilation)
        self.bn2 = nn.BatchNorm1d(channels)
        self.relu = nn.ReLU()
    def forward(self, x):
        res = x
        out = self.relu(self.bn1(self.conv1(x)))
        out = self.bn2(self.conv2(out))
        return self.relu(out + res)

class ResNet1D_SCA(nn.Module):
    """1D Residual Network with multi-scale dilation for SCA"""
    def __init__(self, in_channels=1, num_classes=6):
        super().__init__()
        self.stem = nn.Sequential(
            nn.Conv1d(in_channels, 32, kernel_size=7, padding=3),
            nn.BatchNorm1d(32),
            nn.ReLU()
        )
        self.res1 = ResBlock1D(32, k=5, dilation=1)
        self.down1 = nn.Sequential(
            nn.Conv1d(32, 64, kernel_size=3, stride=2, padding=1),
            nn.BatchNorm1d(64),
            nn.ReLU()
        )
        self.res2 = ResBlock1D(64, k=5, dilation=2)
        self.down2 = nn.Sequential(
            nn.Conv1d(64, 128, kernel_size=3, stride=2, padding=1),
            nn.BatchNorm1d(128),
            nn.ReLU()
        )
        self.res3 = ResBlock1D(128, k=5, dilation=4)
        self.pool = nn.AdaptiveAvgPool1d(4)
        self.head = nn.Sequential(
            nn.Flatten(),
            nn.Linear(128 * 4, 256),
            nn.BatchNorm1d(256),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(256, num_classes)
        )
    def forward(self, x):
        x = self.stem(x)
        x = self.res1(x)
        x = self.down1(x)
        x = self.res2(x)
        x = self.down2(x)
        x = self.res3(x)
        x = self.pool(x)
        return self.head(x)

class WideDilatedCNN(nn.Module):
    """Multi-stage Dilated CNN covering all 50 cycles"""
    def __init__(self, in_channels=1, num_classes=6):
        super().__init__()
        self.features = nn.Sequential(
            DilatedConvBlock(in_channels, 32, k=7, dilation=1),
            nn.MaxPool1d(2),
            DilatedConvBlock(32, 64, k=5, dilation=2),
            nn.MaxPool1d(2),
            DilatedConvBlock(64, 128, k=5, dilation=4),
            nn.AdaptiveAvgPool1d(4),
            nn.Flatten()
        )
        self.classifier = nn.Sequential(
            nn.Linear(128 * 4, 256),
            nn.BatchNorm1d(256),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(256, 128),
            nn.ReLU(),
            nn.Linear(128, num_classes)
        )
    def forward(self, x):
        return self.classifier(self.features(x))

class DeepMLP_SCA(nn.Module):
    """Deep 4-layer MLP connecting all 50 time samples simultaneously"""
    def __init__(self, in_features=50, num_classes=6):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(in_features, 512),
            nn.BatchNorm1d(512),
            nn.ReLU(),
            nn.Dropout(0.2),
            nn.Linear(512, 512),
            nn.BatchNorm1d(512),
            nn.ReLU(),
            nn.Dropout(0.2),
            nn.Linear(512, 256),
            nn.BatchNorm1d(256),
            nn.ReLU(),
            nn.Dropout(0.2),
            nn.Linear(256, 128),
            nn.BatchNorm1d(128),
            nn.ReLU(),
            nn.Linear(128, num_classes)
        )
    def forward(self, x):
        return self.net(x)

# ==============================================================================
# 3. TRAINING & ATTACK EVALUATION (GUESSING ENTROPY / KEY RANK)
# ==============================================================================

def train_model(model, train_loader, val_loader, criterion, epochs=30, lr=1e-3, is_cnn=False):
    optimizer = torch.optim.AdamW(model.parameters(), lr=lr, weight_decay=1e-4)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=epochs)
    
    best_acc = 0.0
    best_weights = None
    
    for ep in range(epochs):
        model.train()
        for bx, by in train_loader:
            if is_cnn and bx.dim() == 2:
                bx = bx.unsqueeze(1)
            optimizer.zero_grad()
            out = model(bx)
            loss = criterion(out, by)
            loss.backward()
            optimizer.step()
        scheduler.step()
        
        # Validation
        model.eval()
        correct, total = 0, 0
        with torch.no_grad():
            for bx, by in val_loader:
                if is_cnn and bx.dim() == 2:
                    bx = bx.unsqueeze(1)
                preds = model(bx).argmax(dim=1)
                correct += (preds == by).sum().item()
                total += len(by)
        val_acc = correct / total
        if val_acc > best_acc:
            best_acc = val_acc
            best_weights = {k: v.cpu().clone() for k, v in model.state_dict().items()}
            
    if best_weights is not None:
        model.load_state_dict(best_weights)
    return model, best_acc

def evaluate_key_rank(model, traces_test, nonces_test, true_keys_test, column=0, is_cnn=False):
    """
    Computes Guessing Entropy and Key Rank across candidate 2-bit key hypotheses:
    Key bits candidate (k0_c, k8_c) in { (0,0), (0,1), (1,0), (1,1) }
    """
    model.eval()
    t_traces = torch.tensor(traces_test, dtype=torch.float32)
    if is_cnn:
        t_traces = t_traces.unsqueeze(1)
        
    with torch.no_grad():
        logits = model(t_traces)
        log_probs = F.log_softmax(logits, dim=1).numpy() # (N_test, 6)
        
    # Ascon S-box column simulation helper
    def sbox_col(v):
        b0, b1, b2, b3, b4 = (v>>0)&1, (v>>1)&1, (v>>2)&1, (v>>3)&1, (v>>4)&1
        b0^=b4; b4^=b3; b2^=b1
        t0, t1, t2, t3, t4 = (~b0)&b1, (~b1)&b2, (~b2)&b3, (~b3)&b4, (~b4)&b0
        b0^=t1; b1^=t2; b2^=t3; b3^=t4; b4^=t0
        b1^=b0; b0^=b4; b3^=b2; b2^=1
        return (b0) | (b1<<1) | (b2<<2) | (b3<<3) | (b4<<4)
        
    popcount = [bin(v).count('1') for v in range(32)]
    
    IV_0 = np.uint64(0x00001000808c0001)
    iv_bit = (IV_0 >> np.uint64(column)) & np.uint64(1)
    n0_bits = (nonces_test[:, 0] >> column) & 1
    n8_bits = (nonces_test[:, 8] >> column) & 1
    rc_bit = 1 if column == 0 else 0
    
    # 4 hypotheses for (k0, k8) bits
    hyps = [(0,0), (0,1), (1,0), (1,1)]
    N_test = len(traces_test)
    
    # Precompute predicted HW class for each trace under each hypothesis
    pred_hw = np.zeros((N_test, 4), dtype=int)
    for h_idx, (kb0, kb1) in enumerate(hyps):
        for i in range(N_test):
            b0 = iv_bit
            b1 = kb0
            b2 = kb1 ^ rc_bit
            b3 = n0_bits[i]
            b4 = n8_bits[i]
            col_in = b0 | (b1<<1) | (b2<<2) | (b3<<3) | (b4<<4)
            col_out = sbox_col(col_in)
            pred_hw[i, h_idx] = popcount[col_out]
            
    # True key bits for each test trace
    true_kb0 = (true_keys_test[:, 0] >> column) & 1
    true_kb1 = (true_keys_test[:, 8] >> column) & 1
    
    # Accumulate log-likelihoods over attack traces
    attack_steps = [10, 20, 50, 100, 200, 500, 1000]
    ranks_at_step = {}
    
    # Compute rank for individual fixed key sub-batches or across test set
    cum_log_p = np.zeros(4)
    # Average rank across random keys
    all_ranks = []
    for i in range(min(N_test, 1000)):
        # True hyp index
        true_h = hyps.index((true_kb0[i], true_kb1[i]))
        # Score each hypothesis for trace i
        scores = np.array([log_probs[i, pred_hw[i, h]] for h in range(4)])
        # Rank of true hypothesis (1 = best, 4 = worst)
        rank = (np.argsort(-scores) == true_h).argmax() + 1
        all_ranks.append(rank)
        
    avg_rank = np.mean(all_ranks)
    top1_rate = np.mean(np.array(all_ranks) == 1) * 100.0
    return avg_rank, top1_rate

# ==============================================================================
# 4. MAIN BENCHMARK & EXECUTION
# ==============================================================================

def main():
    print("=" * 80)
    print("        METHOD B DEEP LEARNING PROFILING & KEY RECOVERY PIPELINE")
    print("=" * 80)
    
    npz_path = "Dataset/ascon_30k.npz"
    print(f"[*] Loading dataset from {npz_path}...")
    d = np.load(npz_path)
    traces_d1 = d['traces_d1'] # 30,000 traces, 50 samples
    traces_d2 = d['traces_d2'] # 30,000 traces, 50 samples
    keys = d['keys']
    nonces = d['nonces']
    labels_hw = d['labels_sbox_hw'][:, 0]
    
    N = len(traces_d1)
    train_n = 24000
    test_n = 6000
    
    print(f"    Total Traces: {N} (Train: {train_n}, Test/Validation: {test_n})")
    print(f"    HW Class counts (Train): {np.bincount(labels_hw[:train_n], minlength=6)}")
    
    # Preprocessing: Z-score normalization per order
    mean_d1, std_d1 = traces_d1[:train_n].mean(axis=0), traces_d1[:train_n].std(axis=0) + 1e-8
    X1_tr = (traces_d1[:train_n] - mean_d1) / std_d1
    X1_te = (traces_d1[train_n:] - mean_d1) / std_d1
    
    mean_d2, std_d2 = traces_d2[:train_n].mean(axis=0), traces_d2[:train_n].std(axis=0) + 1e-8
    X2_tr = (traces_d2[:train_n] - mean_d2) / std_d2
    X2_te = (traces_d2[train_n:] - mean_d2) / std_d2
    
    y_tr = labels_hw[:train_n]
    y_te = labels_hw[train_n:]
    
    class_weights = get_class_weights(y_tr, num_classes=6)
    print(f"    Inverse Frequency Class Weights: {class_weights.numpy().round(3)}")
    
    batch_size = 128
    epochs = 30
    
    # DataLoaders for D=1
    loader_d1_tr = DataLoader(TensorDataset(torch.tensor(X1_tr, dtype=torch.float32), torch.tensor(y_tr, dtype=torch.long)), batch_size=batch_size, shuffle=True)
    loader_d1_te = DataLoader(TensorDataset(torch.tensor(X1_te, dtype=torch.float32), torch.tensor(y_te, dtype=torch.long)), batch_size=batch_size, shuffle=False)
    
    # DataLoaders for D=2
    loader_d2_tr = DataLoader(TensorDataset(torch.tensor(X2_tr, dtype=torch.float32), torch.tensor(y_tr, dtype=torch.long)), batch_size=batch_size, shuffle=True)
    loader_d2_te = DataLoader(TensorDataset(torch.tensor(X2_te, dtype=torch.float32), torch.tensor(y_te, dtype=torch.long)), batch_size=batch_size, shuffle=False)
    
    results = {}
    
    # --------------------------------------------------------------------------
    # ARCHITECTURE EVALUATION ON D=1 (1st-Order Masked, 3 Shares)
    # --------------------------------------------------------------------------
    print("\n" + "="*60)
    print(">>> EVALUATION ON D=1 (Masked Order 1, 3 Shares)")
    print("="*60)
    
    crit_ce = nn.CrossEntropyLoss(weight=class_weights)
    crit_focal = FocalLoss(weight=class_weights, gamma=2.0)
    
    models_d1 = {
        'Deep MLP (50 cycles)': (DeepMLP_SCA(50, 6), False, crit_ce),
        'Wide Dilated CNN (RF=50)': (WideDilatedCNN(1, 6), True, crit_ce),
        'ResNet-1D SCA (Residual Dilated)': (ResNet1D_SCA(1, 6), True, crit_ce),
        'ResNet-1D + Focal Loss': (ResNet1D_SCA(1, 6), True, crit_focal),
    }
    
    for name, (mod, is_cnn, crit) in models_d1.items():
        print(f"[*] Training {name} on D=1...")
        t0 = time.time()
        mod, val_acc = train_model(mod, loader_d1_tr, loader_d1_te, crit, epochs=epochs, lr=1e-3, is_cnn=is_cnn)
        el = time.time() - t0
        avg_rank, top1_rate = evaluate_key_rank(mod, X1_te, nonces[train_n:], keys[train_n:], column=0, is_cnn=is_cnn)
        print(f"    -> Val Acc: {val_acc*100:.2f}% | Avg Key Rank: {avg_rank:.2f}/4 | Top-1 Key Success: {top1_rate:.2f}% ({el:.2f}s)")
        results[f'D=1: {name}'] = {'Accuracy': f'{val_acc*100:.2f}%', 'Key Rank': f'{avg_rank:.2f}', 'Top-1 Success': f'{top1_rate:.2f}%'}

    # --------------------------------------------------------------------------
    # ARCHITECTURE EVALUATION ON D=2 (2nd-Order Masked, 4 Shares)
    # --------------------------------------------------------------------------
    print("\n" + "="*60)
    print(">>> EVALUATION ON D=2 (Masked Order 2, 4 Shares)")
    print("="*60)
    
    models_d2 = {
        'Deep MLP (50 cycles)': (DeepMLP_SCA(50, 6), False, crit_ce),
        'Wide Dilated CNN (RF=50)': (WideDilatedCNN(1, 6), True, crit_ce),
        'ResNet-1D SCA (Residual Dilated)': (ResNet1D_SCA(1, 6), True, crit_ce),
        'ResNet-1D + Focal Loss': (ResNet1D_SCA(1, 6), True, crit_focal),
    }
    
    for name, (mod, is_cnn, crit) in models_d2.items():
        print(f"[*] Training {name} on D=2...")
        t0 = time.time()
        mod, val_acc = train_model(mod, loader_d2_tr, loader_d2_te, crit, epochs=epochs, lr=1e-3, is_cnn=is_cnn)
        el = time.time() - t0
        avg_rank, top1_rate = evaluate_key_rank(mod, X2_te, nonces[train_n:], keys[train_n:], column=0, is_cnn=is_cnn)
        print(f"    -> Val Acc: {val_acc*100:.2f}% | Avg Key Rank: {avg_rank:.2f}/4 | Top-1 Key Success: {top1_rate:.2f}% ({el:.2f}s)")
        results[f'D=2: {name}'] = {'Accuracy': f'{val_acc*100:.2f}%', 'Key Rank': f'{avg_rank:.2f}', 'Top-1 Success': f'{top1_rate:.2f}%'}

    # --------------------------------------------------------------------------
    # SUMMARY TABLE
    # --------------------------------------------------------------------------
    print("\n" + "="*80)
    print("                   METHOD B PERFORMANCE & ATTACK SUMMARY")
    print("="*80)
    print(f"  {'Architecture / Loss':<40} | {'Val Acc':<10} | {'Avg Rank':<10} | {'Top-1 Success':<12}")
    print("-" * 80)
    for k, v in results.items():
        print(f"  {k:<40} | {v['Accuracy']:<10} | {v['Key Rank']:<10} | {v['Top-1 Success']:<12}")
    print("="*80)

if __name__ == '__main__':
    main()
