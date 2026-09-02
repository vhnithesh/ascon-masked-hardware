import os
import numpy as np
import scipy.stats as stats

print("================================================================================")
print("   ASCON-128 HARDWARE LEAKAGE EVALUATION (TVLA & KEY RANK BENCHMARK)")
print("================================================================================")

# Load 30k trace dataset
data_path = r"C:\Users\vhnit\ascon_masked_vivado\Dataset\ascon_30k.npz"
data = np.load(data_path)

traces_d0 = data['traces_d0'] # (30000, 50)
traces_d1 = data['traces_d1'] # (30000, 50)
traces_d2 = data['traces_d2'] # (30000, 50)
keys      = data['keys']      # (30000, 16)
nonces    = data['nonces']    # (30000, 16)
labels_hw = data['labels_sbox_hw'][:, 0] # Column 0 HW (0..5)

# -----------------------------------------------------------------------------
# 1. Test Vector Leakage Assessment (TVLA / Welch's t-test)
# -----------------------------------------------------------------------------
def compute_tvla(traces, group_mask):
    group_a = traces[group_mask]
    group_b = traces[~group_mask]
    
    n_a, n_b = len(group_a), len(group_b)
    mu_a, mu_b = np.mean(group_a, axis=0), np.mean(group_b, axis=0)
    var_a, var_b = np.var(group_a, axis=0, ddof=1), np.var(group_b, axis=0, ddof=1)
    
    denom = np.sqrt((var_a / n_a) + (var_b / n_b) + 1e-12)
    t_stat = (mu_a - mu_b) / denom
    return t_stat

# Group partition based on bit 0 of intermediate state
group_mask = (labels_hw >= 3)

t_d0 = compute_tvla(traces_d0, group_mask)
t_d1 = compute_tvla(traces_d1, group_mask)
t_d2 = compute_tvla(traces_d2, group_mask)

max_t_d0 = np.max(np.abs(t_d0))
max_t_d1 = np.max(np.abs(t_d1))
max_t_d2 = np.max(np.abs(t_d2))

print("\n--- 1. TVLA (Welch's t-test) Results (Threshold: |t| < 4.5) ---")
print(f"  D = 0 (Unmasked / 1 Share)  : Max |t| = {max_t_d0:6.2f}  --> {'FAIL (Leaking)' if max_t_d0 >= 4.5 else 'PASS'}")
print(f"  D = 1 (1st-Order / 3 Shares): Max |t| = {max_t_d1:6.2f}  --> {'FAIL (Leaking)' if max_t_d1 >= 4.5 else 'PASS (Protected)'}")
print(f"  D = 2 (2nd-Order / 4 Shares): Max |t| = {max_t_d2:6.2f}  --> {'FAIL (Leaking)' if max_t_d2 >= 4.5 else 'PASS (Protected)'}")

# -----------------------------------------------------------------------------
# 2. Key Rank / Guessing Entropy (GE) Progression Analysis
# -----------------------------------------------------------------------------
IV = 0x80400c0600000000

def compute_sbox_hw_hypo(nonces_bytes, col=0):
    N = len(nonces_bytes)
    hw_candidates = np.zeros((N, 4), dtype=np.float32)
    
    for h in range(4):
        b_k0 = int((h >> 0) & 1)
        b_k1 = int((h >> 1) & 1)
        b_iv = 1 if (col == 63 or col == 62) else 0
        
        for i in range(N):
            n0_bit = int((nonces_bytes[i, 0] >> (col % 8)) & 1)
            n1_bit = int((nonces_bytes[i, 8] >> (col % 8)) & 1)
            
            x0 = int(b_iv ^ n1_bit)
            x4 = int(n1_bit ^ n0_bit)
            x2 = int(b_k1 ^ b_k0)
            x1 = int(b_k0)
            x3 = int(n0_bit)
            
            t0 = (1 ^ x0) & x1
            t1 = (1 ^ x1) & x2
            t2 = (1 ^ x2) & x3
            t3 = (1 ^ x3) & x4
            t4 = (1 ^ x4) & x0
            
            y0 = x0 ^ t1
            y1 = x1 ^ t2
            y2 = x2 ^ t3
            y3 = x3 ^ t4
            y4 = x4 ^ t0
            y1 ^= y0
            y0 ^= y4
            y3 ^= y2
            y2 ^= 1
            
            hw_candidates[i, h] = float(y0 + y1 + y2 + y3 + y4)
            
    return hw_candidates

N_EVAL = 1000
hw_hypos = compute_sbox_hw_hypo(nonces[:N_EVAL], col=0)
true_k0_bit = int((keys[0, 0] >> 0) & 1)
true_k1_bit = int((keys[0, 8] >> 0) & 1)
true_hypo = int(true_k0_bit | (true_k1_bit << 1))

def evaluate_key_rank_progression(traces, hw_hypos, true_h, num_traces_eval=[10, 50, 100, 250, 500]):
    ranks = []
    T = traces.shape[1]
    
    for n in num_traces_eval:
        sub_traces = traces[:n]
        sub_hypos = hw_hypos[:n]
        
        corr_scores = np.zeros(4)
        for h in range(4):
            h_vals = sub_hypos[:, h]
            if np.std(h_vals) > 0:
                corr_profile = np.zeros(T)
                for t in range(T):
                    t_vals = sub_traces[:, t]
                    if np.std(t_vals) > 0:
                        r, _ = stats.pearsonr(t_vals, h_vals)
                        corr_profile[t] = abs(r) if not np.isnan(r) else 0.0
                corr_scores[h] = np.max(corr_profile)
        
        order = np.argsort(corr_scores)[::-1]
        rank = int(np.where(order == true_h)[0][0]) + 1
        ranks.append(rank)
        
    return ranks

eval_steps = [10, 50, 100, 250, 500]
ranks_d0 = evaluate_key_rank_progression(traces_d0[:N_EVAL], hw_hypos, true_hypo, eval_steps)
ranks_d1 = evaluate_key_rank_progression(traces_d1[:N_EVAL], hw_hypos, true_hypo, eval_steps)
ranks_d2 = evaluate_key_rank_progression(traces_d2[:N_EVAL], hw_hypos, true_hypo, eval_steps)

print("\n--- 2. Guessing Entropy / Key Rank Progression vs. Traces Tested ---")
print(f"{'Trace Count':<12} | {'D=0 (Unmasked)':<16} | {'D=1 (1st-Order)':<16} | {'D=2 (2nd-Order)':<16}")
print("-" * 68)
for i, n in enumerate(eval_steps):
    print(f"{n:<12} | Rank {ranks_d0[i]:<11} | Rank {ranks_d1[i]:<11} | Rank {ranks_d2[i]:<11}")

print("\n================================================================================")
print("   EVALUATION COMPLETE")
print("================================================================================")
