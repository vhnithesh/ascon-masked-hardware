import sys
import os
import time
import numpy as np
from itertools import combinations
import torch
import torch.nn as nn
from torch.utils.data import TensorDataset, DataLoader

SEED = 42
np.random.seed(SEED)
torch.manual_seed(SEED)

def load_data(npz_path="Dataset/ascon_30k.npz", num_traces=10000):
    print(f"[*] Loading dataset from {npz_path} (using {num_traces} traces)...")
    d = np.load(npz_path)
    traces_d0 = d['traces_d0'][:num_traces]
    traces_d1 = d['traces_d1'][:num_traces]
    traces_d2 = d['traces_d2'][:num_traces]
    keys = d['keys'][:num_traces]
    nonces = d['nonces'][:num_traces]
    labels_hw = d['labels_sbox_hw'][:num_traces, 0]
    
    IV_0 = np.uint64(0x00001000808c0001)
    k0 = keys[:, 0].astype(np.uint64)
    k8 = keys[:, 8].astype(np.uint64)
    n0 = nonces[:, 0].astype(np.uint64)
    n8 = nonces[:, 8].astype(np.uint64)
    
    b0 = IV_0 & np.uint64(1)
    b1 = k0 & np.uint64(1)
    b2 = ((k8 ^ np.uint64(0xF0)) & np.uint64(1))
    b3 = n0 & np.uint64(1)
    b4 = n8 & np.uint64(1)
    
    x0 = b0 ^ b4
    x4 = b4 ^ b3
    x2 = b2 ^ b1
    x1 = b1
    x3 = b3
    t1 = (~x1) & x2
    bit0 = (x0 ^ t1) & np.uint64(1)
    labels_bit = bit0.astype(np.uint8)

    print(f"    Loaded {num_traces} traces (50 samples/trace).")
    print(f"    HW class distribution: {np.bincount(labels_hw, minlength=6)}")
    print(f"    Bit 0 class distribution: {np.bincount(labels_bit, minlength=2)}")
    return traces_d0, traces_d1, traces_d2, labels_hw, labels_bit, keys, nonces

def run_method_a(traces, labels, order=2, top_pois=20, name="D=1"):
    print(f"\n--- Method A: Higher-Order Product CPA ({name}, order={order}) ---")
    t0 = time.time()
    N, T = traces.shape
    traces_centered = traces - np.mean(traces, axis=0, keepdims=True)
    variances = np.var(traces, axis=0)
    top_poi_idx = np.argsort(variances)[-top_pois:]
    comb_list = list(combinations(top_poi_idx, order))
    print(f"    Evaluating {len(comb_list)} product tuples across top {top_pois} POIs...")
    
    y_centered = labels - np.mean(labels)
    y_std = np.std(labels)
    
    max_corr = 0.0
    best_combo = None
    
    for combo in comb_list:
        prod = np.prod(traces_centered[:, combo], axis=1)
        p_std = np.std(prod)
        if p_std > 1e-9 and y_std > 1e-9:
            corr = np.abs(np.mean((prod - np.mean(prod)) * y_centered) / (p_std * y_std))
            if corr > max_corr:
                max_corr = corr
                best_combo = combo
                
    elapsed = time.time() - t0
    print(f"    Result: Peak |Pearson r| = {max_corr:.5f} at clock cycles {best_combo} ({elapsed:.2f}s)")
    return max_corr, best_combo, elapsed

class StandardCNN(nn.Module):
    def __init__(self, num_classes=6):
        super().__init__()
        self.conv = nn.Sequential(
            nn.Conv1d(1, 16, kernel_size=3, padding=1),
            nn.BatchNorm1d(16),
            nn.ReLU(),
            nn.MaxPool1d(2),
            nn.Conv1d(16, 32, kernel_size=3, padding=1),
            nn.BatchNorm1d(32),
            nn.ReLU(),
            nn.MaxPool1d(2),
            nn.Flatten()
        )
        self.fc = nn.Sequential(
            nn.LazyLinear(128),
            nn.ReLU(),
            nn.Linear(128, num_classes)
        )
    def forward(self, x):
        return self.fc(self.conv(x))

class MLPModel(nn.Module):
    def __init__(self, num_classes=6, binary=False):
        super().__init__()
        self.binary = binary
        out_dim = 1 if binary else num_classes
        self.net = nn.Sequential(
            nn.Linear(50, 512),
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
            nn.Linear(128, out_dim)
        )
    def forward(self, x):
        out = self.net(x)
        return out.squeeze(-1) if self.binary else out

class DilatedCNNModel(nn.Module):
    def __init__(self, num_classes=6, binary=False):
        super().__init__()
        self.binary = binary
        out_dim = 1 if binary else num_classes
        self.conv = nn.Sequential(
            nn.Conv1d(1, 32, kernel_size=7, padding=3, dilation=1),
            nn.BatchNorm1d(32),
            nn.ReLU(),
            nn.Conv1d(32, 64, kernel_size=5, padding=4, dilation=2),
            nn.BatchNorm1d(64),
            nn.ReLU(),
            nn.Conv1d(64, 128, kernel_size=5, padding=8, dilation=4),
            nn.BatchNorm1d(128),
            nn.ReLU(),
            nn.AdaptiveAvgPool1d(4),
            nn.Flatten()
        )
        self.fc = nn.Sequential(
            nn.Linear(128 * 4, 128),
            nn.ReLU(),
            nn.Dropout(0.2),
            nn.Linear(128, out_dim)
        )
    def forward(self, x):
        feat = self.conv(x)
        out = self.fc(feat)
        return out.squeeze(-1) if self.binary else out

def train_eval_nn(model, traces, labels, binary=False, epochs=25, batch_size=128, is_cnn=False, desc=""):
    t0 = time.time()
    N = len(traces)
    split = int(0.8 * N)
    
    mean = np.mean(traces[:split], axis=0, keepdims=True)
    std = np.std(traces[:split], axis=0, keepdims=True) + 1e-8
    X_tr = (traces[:split] - mean) / std
    X_va = (traces[split:] - mean) / std
    y_tr = labels[:split]
    y_va = labels[split:]
    
    if is_cnn:
        t_x_tr = torch.tensor(X_tr, dtype=torch.float32).unsqueeze(1)
        t_x_va = torch.tensor(X_va, dtype=torch.float32).unsqueeze(1)
    else:
        t_x_tr = torch.tensor(X_tr, dtype=torch.float32)
        t_x_va = torch.tensor(X_va, dtype=torch.float32)
        
    if binary:
        t_y_tr = torch.tensor(y_tr, dtype=torch.float32)
        t_y_va = torch.tensor(y_va, dtype=torch.float32)
        criterion = nn.BCEWithLogitsLoss()
    else:
        t_y_tr = torch.tensor(y_tr, dtype=torch.long)
        t_y_va = torch.tensor(y_va, dtype=torch.long)
        criterion = nn.CrossEntropyLoss()
        
    loader = DataLoader(TensorDataset(t_x_tr, t_y_tr), batch_size=batch_size, shuffle=True)
    optimizer = torch.optim.AdamW(model.parameters(), lr=1e-3, weight_decay=1e-4)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=epochs)
    
    for ep in range(epochs):
        model.train()
        for bx, by in loader:
            optimizer.zero_grad()
            out = model(bx)
            loss = criterion(out, by)
            loss.backward()
            optimizer.step()
        scheduler.step()
        
    model.eval()
    with torch.no_grad():
        preds_raw = model(t_x_va)
        if binary:
            preds = (torch.sigmoid(preds_raw) > 0.5).long().cpu().numpy()
            acc = np.mean(preds == y_va)
            chance = 0.50
        else:
            preds = torch.argmax(preds_raw, dim=1).cpu().numpy()
            acc = np.mean(preds == y_va)
            chance = 1.0 / 6.0
            
    gain_over_chance = (acc - chance) * 100
    elapsed = time.time() - t0
    print(f"    [{desc}] Val Acc: {acc*100:.2f}% (Chance: {chance*100:.2f}%, Gain: +{gain_over_chance:.2f}%) [{elapsed:.2f}s]")
    return acc, gain_over_chance, elapsed

def main():
    print("=" * 80)
    print("      SIDE-CHANNEL PROFILING BENCHMARK: METHODS A vs B vs C")
    print("=" * 80)
    
    traces_d0, traces_d1, traces_d2, labels_hw, labels_bit, keys, nonces = load_data("Dataset/ascon_30k.npz", num_traces=10000)
    
    results = {}
    
    # METHOD A
    print("\n" + "="*50)
    print(">>> 1. METHOD A: Higher-Order Feature Engineering (Product Traces)")
    print("="*50)
    corr_d0, _, _ = run_method_a(traces_d0, labels_hw, order=1, top_pois=20, name="D=0 (1st Order)")
    corr_d1_1st, _, _ = run_method_a(traces_d1, labels_hw, order=1, top_pois=20, name="D=1 with 1st Order")
    corr_d1_2nd, _, _ = run_method_a(traces_d1, labels_hw, order=2, top_pois=20, name="D=1 with 2nd Order Bivariate")
    corr_d2_3rd, _, _ = run_method_a(traces_d2, labels_hw, order=3, top_pois=15, name="D=2 with 3rd Order Trivariate")
    
    results['Method A (D=0 1st-ord CPA)'] = f"|r| = {corr_d0:.4f}"
    results['Method A (D=1 1st-ord CPA - Fails)'] = f"|r| = {corr_d1_1st:.4f}"
    results['Method A (D=1 2nd-ord Bivariate)'] = f"|r| = {corr_d1_2nd:.4f}"
    results['Method A (D=2 3rd-ord Trivariate)'] = f"|r| = {corr_d2_3rd:.4f}"
    
    # METHOD B
    print("\n" + "="*50)
    print(">>> 2. METHOD B: Deep Learning Multi-Point Profiling (HW Target)")
    print("="*50)
    std_cnn = StandardCNN(num_classes=6)
    acc, gain, el = train_eval_nn(std_cnn, traces_d1, labels_hw, binary=False, epochs=25, is_cnn=True, desc="D=1 Narrow CNN (k=3)")
    results['Method B (Narrow CNN k=3 on D=1)'] = f"Acc: {acc*100:.2f}%, Gain: +{gain:.2f}%"
    
    mlp_d1 = MLPModel(num_classes=6, binary=False)
    acc, gain, el = train_eval_nn(mlp_d1, traces_d1, labels_hw, binary=False, epochs=25, is_cnn=False, desc="D=1 MLP (All 50 cycles)")
    results['Method B (MLP 50-cycles on D=1)'] = f"Acc: {acc*100:.2f}%, Gain: +{gain:.2f}%"
    
    dilated_cnn_d1 = DilatedCNNModel(num_classes=6, binary=False)
    acc, gain, el = train_eval_nn(dilated_cnn_d1, traces_d1, labels_hw, binary=False, epochs=25, is_cnn=True, desc="D=1 Dilated CNN (RF=50)")
    results['Method B (Dilated CNN on D=1)'] = f"Acc: {acc*100:.2f}%, Gain: +{gain:.2f}%"
    
    mlp_d2 = MLPModel(num_classes=6, binary=False)
    acc, gain, el = train_eval_nn(mlp_d2, traces_d2, labels_hw, binary=False, epochs=25, is_cnn=False, desc="D=2 MLP (All 50 cycles)")
    results['Method B (MLP 50-cycles on D=2)'] = f"Acc: {acc*100:.2f}%, Gain: +{gain:.2f}%"

    # METHOD C
    print("\n" + "="*50)
    print(">>> 3. METHOD C: Single-Bit Binary (50/50 Balanced BCE) Profiling")
    print("="*50)
    bit_mlp_d0 = MLPModel(binary=True)
    acc, gain, el = train_eval_nn(bit_mlp_d0, traces_d0, labels_bit, binary=True, epochs=25, is_cnn=False, desc="D=0 Single-Bit MLP")
    results['Method C (Single-Bit MLP on D=0)'] = f"Acc: {acc*100:.2f}%, Gain: +{gain:.2f}%"
    
    bit_mlp_d1 = MLPModel(binary=True)
    acc, gain, el = train_eval_nn(bit_mlp_d1, traces_d1, labels_bit, binary=True, epochs=25, is_cnn=False, desc="D=1 Single-Bit MLP")
    results['Method C (Single-Bit MLP on D=1)'] = f"Acc: {acc*100:.2f}%, Gain: +{gain:.2f}%"
    
    bit_dcnn_d1 = DilatedCNNModel(binary=True)
    acc, gain, el = train_eval_nn(bit_dcnn_d1, traces_d1, labels_bit, binary=True, epochs=25, is_cnn=True, desc="D=1 Single-Bit Dilated CNN")
    results['Method C (Single-Bit Dilated CNN on D=1)'] = f"Acc: {acc*100:.2f}%, Gain: +{gain:.2f}%"

    bit_mlp_d2 = MLPModel(binary=True)
    acc, gain, el = train_eval_nn(bit_mlp_d2, traces_d2, labels_bit, binary=True, epochs=25, is_cnn=False, desc="D=2 Single-Bit MLP")
    results['Method C (Single-Bit MLP on D=2)'] = f"Acc: {acc*100:.2f}%, Gain: +{gain:.2f}%"
    
    print("\n" + "="*80)
    print("                    FINAL BENCHMARK COMPARISON TABLE")
    print("="*80)
    for k, v in results.items():
        print(f"  {k:<45} : {v}")
    print("="*80)

if __name__ == '__main__':
    main()
