# SignalForge — Intelligent Adaptive Line-Code Selection Framework
### for Underwater Acoustic Communication (UWAC) Channels

[![MATLAB](https://img.shields.io/badge/MATLAB-R2021b%2B-blue.svg)](https://www.mathworks.com/products/matlab.html)
[![Web Dashboard](https://img.shields.io/badge/Dashboard-HTML5%20%2F%20Vanilla%20JS-brightgreen.svg)](dashboard/index.html)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Architecture](https://img.shields.io/badge/Architecture-Hybrid%20Physics%20%2B%20ML-orange.svg)](#dual-engine-architecture-physics--machine-learning)

> **"SignalForge is a specification-driven, hybrid communication engineering framework designed for underwater acoustic channels. It evaluates six digital line-coding schemes under configurable acoustic impairments (path loss, 3-path multipath, Doppler spread, and AWGN) and combines a ground-truth physical simulation engine with a sub-millisecond 9-dimensional machine learning classifier."**

---

## Dual-Engine Architecture: Physics + Machine Learning

SignalForge is intentionally built around a **Hybrid Dual-Engine** architecture rather than relying solely on black-box machine learning.

```
+-----------------------------------------------------------------------------------------+
|                                    SIGNALFORGE ARCHITECTURE                             |
+-----------------------------------------------------------------------------------------+
|                                                                                         |
|                        [ User Inputs / Modem Sensor Readings ]                          |
|             (SNR: 15 dB, Multipath: 0.25, Doppler: 0.5 m/s, Priority: Sync)             |
|                                       |                                                 |
|                    +------------------+------------------+                              |
|                    |                                     |                              |
|                    v                                     v                              |
|     +-----------------------------+       +-----------------------------+               |
|     |   MACHINE LEARNING ENGINE   |       |   PHYSICAL SIMULATION ENGINE|               |
|     |       (The "Brain")         |       |      (The "Ground Truth")   |               |
|     +-----------------------------+       +-----------------------------+               |
|     • 9-D pattern-matching k-NN           • Exact line encoders (6 types)               |
|     • Replaces slow search                • Real acoustic physics:                      |
|     • Runs in 0.2 to 0.5 ms               • Multipath reflection convolution            |
|     • Outputs:                            • Doppler phase drift                         |
|       - Predicted Code: Manchester        • Thorp acoustic distance loss                |
|       - 6-Class Probability Vector        • AWGN noise generation                       |
|       - Decision Objective                • Physical bit thresholding                   |
|                                           • Empirically measured BER                    |
|                    |                                     |                              |
|                    +------------------+------------------+                              |
|                                       |                                                 |
|                                       v                                                 |
|                   [ Live Waveform Display & Validation ]                                |
|        The ML model chooses the code -> The physics engine proves it works!            |
+-----------------------------------------------------------------------------------------+
```

### Why This Dual-Engine Approach Matters:
1. **The Machine Learning Engine (Decision Speed):**
   In a real-time underwater modem, you cannot afford to encode, transmit, filter, and decode bits across all 6 candidate line codes simultaneously in real hardware just to pick one. That would drain battery power, take 80 to 200 ms, and waste precious acoustic bandwidth. The ML model predicts the optimal code in **less than 0.5 ms** (a ~360x speedup).
2. **The Physical Simulation Engine (Ground Truth Verification):**
   An ML model should never "hallucinate" or fabricate a fake bit error rate (BER) or a fake waveform. SignalForge's physical engine simulates the true square waves, convolves them through 3-path acoustic multipath channel profiles, adds Doppler phase modulation and AWGN, threshold-detects the bits, and measures genuine bit flips.
3. **Scientific Rigor:**
   The ML model makes the fast decision, and the physics engine proves that the decision was correct with real waveforms and measured metrics.

---

## Key Features

- **Six Supported Line Codes:**
  - `NRZ-L` (Non-Return-to-Zero Level)
  - `NRZ-I` (Non-Return-to-Zero Inverted on 1)
  - `RZ` (Unipolar Return-to-Zero)
  - `Manchester` (Biphase-L with guaranteed mid-bit transitions)
  - `AMI` (Alternate Mark Inversion, pseudo-ternary, strictly DC-free)
  - `Differential Manchester` (Transition at bit start for 0, polarity immune)
- **Acoustic Channel Modeling:**
  - Frequency-dependent acoustic attenuation (Thorp's absorption equation).
  - Cylindrical and spherical geometric spreading over 50 m to 1000 m.
  - 3-path surface and bottom bounce multipath reflections.
  - Doppler frequency drift and velocity spread (0.0 to 4.0 m/s).
  - Configurable AWGN noise calibrated across -5.0 dB to +30.0 dB SNR.
- **Two Distinct Machine Learning Objectives:**
  - **Objective A: SAW Multi-Criteria Imitator (`trained_model_saw.mat`):** Mimics the Simple Additive Weighting (SAW) utility function balancing BER, bandwidth, DC balance, and clock synchronization.
  - **Objective B: Oracle Minimum-BER Predictor (`trained_model_oracle.mat`):** Targets the absolute lowest measured bit error rate with deterministic tie-breaking (by bandwidth then DC balance).
- **9-Dimensional Feature Space:**
  - Continuous channel features: `[SNR_dB, multipath_k, doppler_v, distance_m]`
  - One-hot binary priority indicators: `[is_balanced, is_low_ber, is_low_bw, is_sync, is_dc_free]`
- **Interactive Multi-Platform Interfaces:**
  - **Standalone Web Dashboard:** Zero-dependency, pure HTML5/CSS/JS dashboard (`dashboard/index.html`) executable in any browser without MATLAB.
  - **MATLAB App / GUI:** Full 6-tab desktop interface (`SignalForgeGUI.m`).

---

## Project Structure

```
SignalForge/
│
├── dashboard/                      ← Standalone Modern Web Dashboard (Zero MATLAB dependency)
│   ├── index.html                  ← Interactive UI (Sliders, live Canvas waveforms, ML outputs)
│   ├── style.css                   ← Dark Cyber-Sonar & MATLAB Classic themes
│   ├── app.js                      ← In-browser 9-D k-NN inference & acoustic channel simulator
│   └── ml_model_data.js            ← Pre-trained weights, normalization mu/sigma, and training set
│
├── encoding/                       ← Digital Line-Coding Modules
│   ├── encode_linecode.m           ← Unified encoder dispatcher
│   ├── decode_linecode.m           ← Universal threshold decoder
│   ├── encode_nrzl.m
│   ├── encode_nrzi.m
│   ├── encode_rz.m
│   ├── encode_manchester.m
│   ├── encode_ami.m
│   └── encode_diff_manchester.m
│
├── channel/
│   └── uwac_channel.m              ← Underwater acoustic channel model (Thorp, multipath, Doppler)
│
├── analysis/
│   └── analyse_linecode.m          ← BER, 99% bandwidth, DC balance, sync density, power
│
├── decision/
│   └── decision_engine.m           ← Multi-objective adaptive selector (SAW scoring)
│
├── ml/                             ← Machine Learning Subsystem
│   ├── generate_ml_dataset.m       ← Synthesizes labeled 9-D training data across channel sweeps
│   ├── train_ml_model.m            ← Trains multi-class classifier with zero-toolbox fallback
│   ├── predict_linecode_ml.m       ← Real-time inference predicting optimal line code
│   ├── compare_saw_vs_oracle_models.m ← Trains and compares Oracle vs SAW models on held-out test data
│   ├── evaluate_ml_model.m         ← Confusion matrix & fixed-baseline benchmarking
│   └── benchmark_ml_vs_simulation.m← Runtime latency, speedup, and multi-class Brier score
│
├── tests/
│   └── test_ml_module.m            ← 6 automated verification unit tests
│
├── experiments/                    ← Parameter Sweeps & Stage 2 Verification
│   ├── validate_all_d1.m           ← Stage 2 verification suite (D1a–D1f)
│   ├── exp1_ber_vs_snr.m           ← BER vs SNR curves
│   ├── exp2_ber_vs_multipath.m     ← BER vs multipath severity
│   ├── exp3_ber_vs_doppler.m       ← BER vs Doppler velocity
│   ├── exp456_properties.m         ← Bandwidth / DC / Sync property comparison
│   └── exp7_adaptive.m             ← Adaptive decision engine demonstration
│
├── signalforge_main.m              ← Command-line demonstration
├── SignalForgeGUI.m                ← 6-tab MATLAB interactive graphical user interface
├── run_all.m                       ← Master 10-step execution & artifact generator
└── results/                        ← Saved .png figures, .mat workspaces, and .csv logs
```

---

## Quick Start

### Option A: Open the Standalone Web Dashboard (No MATLAB Required)
Simply double-click `dashboard/index.html` in your file manager, or open it in Chrome, Edge, Safari, or Firefox:
- Drag sliders for **SNR**, **Multipath**, **Doppler velocity**, and **Distance**.
- Select a **Transmission Priority** (`Balanced`, `Low BER`, `Low Bandwidth`, `Clock Sync`, `DC-Free`).
- Watch the **ML model predict the winning code in 0.2 ms** and inspect the **live animated square-wave vs acoustic corrupted waveforms**.
- Click **"Export MATLAB Script"** to view and copy the exact, reproducible MATLAB script matching your slider settings.

### Option B: Run in MATLAB / MATLAB Online

Open MATLAB, navigate to this project directory, and run:

```matlab
% 1. Run all 6 automated ML subsystem tests
test_ml_module

% 2. Train both Oracle and SAW models and compare them on held-out data
compare_saw_vs_oracle_models

% 3. Run physical simulation vs ML inference benchmark (speedup & Brier score)
benchmark_ml_vs_simulation

% 4. Launch the desktop MATLAB graphical user interface
SignalForgeGUI

% 5. Run the complete end-to-end master suite (runs all experiments and exports results/)
run_all
```

---

## Input & Output Specification

### Input Vector (9 Dimensions)
The feature vector `x_raw` fed into the ML classifier contains:
```
x_raw = [ SNR_dB, multipath_k, doppler_v, distance_m, is_balanced, is_low_ber, is_low_bw, is_sync, is_dc_free ]
```
- Continuous channel parameters:
  - `SNR_dB`: Signal-to-noise ratio (-5.0 to +30.0 dB)
  - `multipath_k`: Reflection coefficient (0.0 to 1.0)
  - `doppler_v`: Relative platform velocity (0.0 to 4.0 m/s)
  - `distance_m`: Propagation distance (50 to 1000 m)
- Categorical priorities: Represented as a 5-element one-hot vector to prevent artificial ordinal bias.

### Model Outputs
When querying `predict_linecode_ml(ch_params, priority)`:
1. **Predicted Code:** The recommended line code (`'nrzl'`, `'nrzi'`, `'rz'`, `'manchester'`, `'ami'`, or `'diff_manchester'`).
2. **Class Probabilities:** 6-element posterior probability vector `[P(NRZ-L), P(NRZ-I), P(RZ), P(Manchester), P(AMI), P(Diff. Manchester)]` based on nearest-neighbor vote proportions.
3. **Decision Objective:** Explicitly identifies whether inference is running under Objective A (SAW Multi-Criteria) or Objective B (Oracle Minimum-BER).
4. **Expected Performance:** Backed by measured physical simulation (measured BER, 99% occupied bandwidth in kHz, DC balance score, clock transition density).
5. **Inference Latency:** Measured live in the execution environment (sub-millisecond runtime).

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
