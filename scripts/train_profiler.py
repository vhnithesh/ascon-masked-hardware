import os
import time
import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import TensorDataset, DataLoader

# Set seeds for deterministic academic benchmarking
torch.manual_seed(42)
np.random.seed(42)

device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
print(f"Using compute device: {device}")

# -----------------------------------------------------------------------------
# 1. Load 30,000-Trace Dataset
# -----------------------------------------------------------------------------
data_path = r"C:\Users\vhnit\ascon_masked_vivado\Dataset\ascon_30k.npz"
data = np.load(data_path)

traces_d0 = data['traces_d0'] # (30000, 50)
traces_d1 = data['traces_d1'] # (30000, 50)
traces_d2 = data['traces_d2'] # (30000, 50)
labels_all = data['labels_sbox_hw'] # (30000, 64)

# Target Column 0 for evaluation (HW 0..5, 6 classes)
target_col = 0
labels = labels_all[:, target_col].astype(np.int64)

print(f"Dataset Loaded: {traces_d0.shape[0]} traces, {traces_d0.shape[1]} samples/trace")
print(f"Target Label: Round-1 S-box Column {target_col} Hamming Weight (0..5)")
print(f"Class Distribution across 30k traces: {np.bincount(labels, minlength=6)}")

# Standardize traces (Z-score normalization)
def standardize(x):
    mean = np.mean(x, axis=0, keepdims=True)
    std = np.std(x, axis=0, keepdims=True) + 1e-6
    return (x - mean) / std

norm_d0 = standardize(traces_d0)
norm_d1 = standardize(traces_d1)
norm_d2 = standardize(traces_d2)

# Train/Val Split (80% Train = 24,000 / 20% Val = 6,000)
N_TRAIN = 24000
train_idx = np.arange(0, N_TRAIN)
val_idx = np.arange(N_TRAIN, len(labels))

# Compute inverse frequency class weights for loss function
class_counts = np.bincount(labels[train_idx], minlength=6)
class_weights = N_TRAIN / (6.0 * np.maximum(class_counts, 1).astype(np.float32))
weights_tensor = torch.tensor(class_weights, dtype=torch.float32).to(device)

# -----------------------------------------------------------------------------
# 2. Define 1D-CNN Profiling Architecture (Matching DL-SCA Standard)
# -----------------------------------------------------------------------------
class ConvNetSCA(nn.Module):
    def __init__(self, in_channels=1, num_classes=6, num_samples=50):
        super(ConvNetSCA, self).__init__()
        self.features = nn.Sequential(
            # Block 1
            nn.Conv1d(in_channels, 16, kernel_size=11, padding=5),
            nn.BatchNorm1d(16),
            nn.ReLU(),
            nn.AvgPool1d(kernel_size=2),

            # Block 2
            nn.Conv1d(16, 32, kernel_size=11, padding=5),
            nn.BatchNorm1d(32),
            nn.ReLU(),
            nn.AvgPool1d(kernel_size=2),

            # Block 3
            nn.Conv1d(32, 64, kernel_size=11, padding=5),
            nn.BatchNorm1d(64),
            nn.ReLU(),
            nn.AvgPool1d(kernel_size=2),
        )
        
        # Calculate feature map dimension
        with torch.no_grad():
            dummy = torch.zeros(1, in_channels, num_samples)
            feat_size = self.features(dummy).view(1, -1).shape[1]
            
        self.classifier = nn.Sequential(
            nn.Linear(feat_size, 128),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(128, num_classes)
        )

    def forward(self, x):
        feat = self.features(x)
        flat = feat.view(feat.size(0), -1)
        return self.classifier(flat)

# -----------------------------------------------------------------------------
# 3. Training & Evaluation Engine
# -----------------------------------------------------------------------------
def train_and_evaluate(trace_matrix, name, epochs=15, batch_size=128, lr=1e-3):
    print(f"\n>>> Training Profiler for {name} ({N_TRAIN} train / 6000 val traces) <<<")
    
    # Format tensors
    X_train = torch.tensor(trace_matrix[train_idx, np.newaxis, :], dtype=torch.float32)
    y_train = torch.tensor(labels[train_idx], dtype=torch.long)
    X_val = torch.tensor(trace_matrix[val_idx, np.newaxis, :], dtype=torch.float32)
    y_val = torch.tensor(labels[val_idx], dtype=torch.long)

    train_loader = DataLoader(TensorDataset(X_train, y_train), batch_size=batch_size, shuffle=True)
    val_loader = DataLoader(TensorDataset(X_val, y_val), batch_size=batch_size, shuffle=False)

    model = ConvNetSCA(in_channels=1, num_classes=6, num_samples=50).to(device)
    criterion = nn.CrossEntropyLoss(weight=weights_tensor)
    optimizer = torch.optim.Adam(model.parameters(), lr=lr, weight_decay=1e-4)
    scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(optimizer, mode='min', factor=0.5, patience=2)

    best_val_acc = 0.0
    history = {'train_loss': [], 'val_loss': [], 'val_acc': []}

    for epoch in range(1, epochs + 1):
        model.train()
        running_loss = 0.0
        for bx, by in train_loader:
            bx, by = bx.to(device), by.to(device)
            optimizer.zero_grad()
            out = model(bx)
            loss = criterion(out, by)
            loss.backward()
            optimizer.step()
            running_loss += loss.item() * bx.size(0)

        epoch_train_loss = running_loss / N_TRAIN

        # Validation
        model.eval()
        val_loss = 0.0
        correct = 0
        total = 0
        with torch.no_grad():
            for bx, by in val_loader:
                bx, by = bx.to(device), by.to(device)
                out = model(bx)
                loss = criterion(out, by)
                val_loss += loss.item() * bx.size(0)
                preds = torch.argmax(out, dim=1)
                correct += (preds == by).sum().item()
                total += by.size(0)

        epoch_val_loss = val_loss / total
        epoch_val_acc = (correct / total) * 100.0
        scheduler.step(epoch_val_loss)

        history['train_loss'].append(epoch_train_loss)
        history['val_loss'].append(epoch_val_loss)
        history['val_acc'].append(epoch_val_acc)

        if epoch % 5 == 0 or epoch == 1 or epoch == epochs:
            print(f"  Epoch {epoch:2d}/{epochs:2d} | Train Loss: {epoch_train_loss:.4f} | Val Loss: {epoch_val_loss:.4f} | Val Acc: {epoch_val_acc:.2f}%")

    return history

# Train across all three masking orders
hist_d0 = train_and_evaluate(norm_d0, "ORDER D = 0 (Unmasked)", epochs=15)
hist_d1 = train_and_evaluate(norm_d1, "ORDER D = 1 (1st-Order Masked, 3 Shares)", epochs=15)
hist_d2 = train_and_evaluate(norm_d2, "ORDER D = 2 (2nd-Order Masked, 4 Shares)", epochs=15)

print("\n================================================================================")
print("   EXPERIMENTAL BENCHMARK SUMMARY (RESEARCH PAPER TABLE)")
print("================================================================================")
print(f"  Configuration               | Final Train Loss | Final Val Loss | Final Val Acc")
print(f"  ----------------------------+------------------+----------------+--------------")
print(f"  D = 0 (Unmasked / 1 Share)  |      {hist_d0['train_loss'][-1]:.4f}      |     {hist_d0['val_loss'][-1]:.4f}     |    {hist_d0['val_acc'][-1]:.2f}%")
print(f"  D = 1 (1st-Order / 3 Shares)|      {hist_d1['train_loss'][-1]:.4f}      |     {hist_d1['val_loss'][-1]:.4f}     |    {hist_d1['val_acc'][-1]:.2f}%")
print(f"  D = 2 (2nd-Order / 4 Shares)|      {hist_d2['train_loss'][-1]:.4f}      |     {hist_d2['val_loss'][-1]:.4f}     |    {hist_d2['val_acc'][-1]:.2f}%")
print("================================================================================\n")
