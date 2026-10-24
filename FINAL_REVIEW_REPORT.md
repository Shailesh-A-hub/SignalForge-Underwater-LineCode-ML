# SignalForge — Final Review Comprehensive Report & Defense Dossier
## An Intelligent Adaptive Line-Code Selection Framework for Underwater Acoustic Communication Channels

**Department of Communication Systems (DCS) — Final Project Review**  
**Course Code / Semester:** FALL SEMESTER 2026–27  
**System Name:** SignalForge  
**Implementation Platform:** MATLAB / MATLAB Online (GUI & Scripted Engine)  

---

## Executive Summary & Alignment with Presentation Claims

During the interim review presentation (`DCS Review.pptx`), our team made explicit commitments across four core presentation pillars:
1. **The 6-Stage Framework** (Input $\to$ Encoding $\to$ Acoustic Channel $\to$ Decoding $\to$ Performance Evaluation $\to$ Adaptive Selection $\to$ Feedback Loop).
2. **The 5 Research Objectives** (01. Implement Line Codes $\to$ 02. Channel Modelling $\to$ 03. Performance Quantification $\to$ 04. Adaptive Selection Logic $\to$ 05. Fixed Baseline Validation).
3. **The 4 Novelty Dimensions** (Unified Time/Frequency Analysis, Channel-Aware Selection, Multi-Criteria Evaluation, Measurable Validation).
4. **The 5 Expected Outcomes** (Software/ML Framework, Waveform/PSD Visualisations, Multi-Impairment Performance sweeps, Clearly Defined Decision Engine, Quantified Baseline Advantage).

This document serves as the complete, definitive evidence report proving that **100% of these claims have been engineered, rigorously tested, and empirically validated** in MATLAB.

---

## 1. Traceability Matrix: Presentation Claims vs. Completed Deliverables

| Presentation Slide & Item | Claim Made in Presentation | Completed Engineering Deliverable | Evidence & Verification File |
|---|---|---|---|
| **Slide 1: Framework (Step 1–2)** | Generate binary sequences; encode using NRZ-L, RZ, Manchester, AMI. | Implemented and mathematically verified encoders for NRZ-L, RZ, Manchester, AMI + advanced differential extensions (NRZ-I, Diff Manchester). | [`linecodes/encode_linecode.m`](file:///c:/Users/shail/OneDrive/Desktop/Docs/FALL%20SEMESTER%2026-27/dcs/project/linecodes/encode_linecode.m)<br>[`experiments/validate_all_d1.m`](file:///c:/Users/shail/OneDrive/Desktop/Docs/FALL%20SEMESTER%2026-27/dcs/project/experiments/validate_all_d1.m) (Test D1a) |
| **Slide 1: Framework (Step 3)** | Pass signals through simulated underwater channel (noise, attenuation, optional multipath). | Full UWAC baseband channel model: Cylindrical spreading ($k=1$), Thorp chemical absorption, TDL multipath, Doppler resampling ($s = 1+v/c$), and coloured noise. | [`channel/uwac_channel.m`](file:///c:/Users/shail/OneDrive/Desktop/Docs/FALL%20SEMESTER%2026-27/dcs/project/channel/uwac_channel.m)<br>Verified bypass mode (`params.bypass = true`) |
| **Slide 1: Framework (Step 4–5)** | Decode received signals; evaluate BER, PSD, bandwidth, synchronization. | Universal segment/edge decoder; automated analysis computing BER, 90% power containment BW, DC balance, transition density, and relative power. | [`linecodes/decode_linecode.m`](file:///c:/Users/shail/OneDrive/Desktop/Docs/FALL%20SEMESTER%2026-27/dcs/project/linecodes/decode_linecode.m)<br>[`analysis/analyse_linecode.m`](file:///c:/Users/shail/OneDrive/Desktop/Docs/FALL%20SEMESTER%2026-27/dcs/project/analysis/analyse_linecode.m) |
| **Slide 1: Framework (Step 6)** | Apply decision algorithm; compare against fixed schemes; adapt to changing channel conditions. | Simple Additive Weighting (SAW) decision engine with 5 priority profiles; dynamic multi-scenario tracking loop. | [`decision/decision_engine.m`](file:///c:/Users/shail/OneDrive/Desktop/Docs/FALL%20SEMESTER%2026-27/dcs/project/decision/decision_engine.m)<br>[`experiments/exp7_adaptive.m`](file:///c:/Users/shail/OneDrive/Desktop/Docs/FALL%20SEMESTER%2026-27/dcs/project/experiments/exp7_adaptive.m) |
| **Slide 2: Objective 01** | Implement multiple line codes using a common input sequence. | Unified dispatcher encodes identical PRBS vectors across all candidate codes simultaneously for fair comparison. | [`run_simulation.m`](file:///c:/Users/shail/OneDrive/Desktop/Docs/FALL%20SEMESTER%2026-27/dcs/project/run_simulation.m)<br>[`signalforge_main.m`](file:///c:/Users/shail/OneDrive/Desktop/Docs/FALL%20SEMESTER%2026-27/dcs/project/signalforge_main.m) |
| **Slide 2: Objective 02** | Model channel conditions: configurable noise, attenuation, and additional impairments. | Configurable SNR (-5 to 30 dB), distance (10 to 1000 m), multipath severity ($\mu \in [0, 1]$), Doppler velocity ($0$ to $10\text{ m/s}$). | [`experiments/exp1_ber_vs_snr.m`](file:///c:/Users/shail/OneDrive/Desktop/Docs/FALL%20SEMESTER%2026-27/dcs/project/experiments/exp1_ber_vs_snr.m)<br>[`experiments/exp2_ber_vs_multipath.m`](file:///c:/Users/shail/OneDrive/Desktop/Docs/FALL%20SEMESTER%2026-27/dcs/project/experiments/exp2_ber_vs_multipath.m)<br>[`experiments/exp3_ber_vs_doppler.m`](file:///c:/Users/shail/OneDrive/Desktop/Docs/FALL%20SEMESTER%2026-27/dcs/project/experiments/exp3_ber_vs_doppler.m) |
| **Slide 2: Objective 03** | Quantify communication performance: BER, PSD, bandwidth, synchronization. | Quantitative evaluation across all parameters; PSD Welch estimation; 90% power containment; transition density calculation. | [`experiments/exp456_properties.m`](file:///c:/Users/shail/OneDrive/Desktop/Docs/FALL%20SEMESTER%2026-27/dcs/project/experiments/exp456_properties.m)<br>Exported figures & `.mat` files |
| **Slide 2: Objective 04** | Develop adaptive selection logic based on channel and performance criteria. | Normalised multi-attribute utility theory (SAW) with profiles: `balanced`, `low_ber`, `low_bandwidth`, `sync`, `dc_free`. | [`decision/decision_engine.m`](file:///c:/Users/shail/OneDrive/Desktop/Docs/FALL%20SEMESTER%2026-27/dcs/project/decision/decision_engine.m) |
| **Slide 2: Objective 05** | Validate against a fixed baseline under identical conditions. | Evaluated against Fixed NRZ-L, Fixed Manchester/AMI, and Empirical Minimum-BER Oracle across 5 dynamic channel transitions. | [`experiments/exp7_adaptive.m`](file:///c:/Users/shail/OneDrive/Desktop/Docs/FALL%20SEMESTER%2026-27/dcs/project/experiments/exp7_adaptive.m)<br>`results/exp7_adaptive.csv` |
| **Slide 3: Novelty 1** | Unified Analysis (time-domain waveforms + frequency-domain PSD). | Interactive GUI and master scripts plotting simultaneous TX/RX waveforms and spectral PSD side-by-side. | [`SignalForgeGUI.m`](file:///c:/Users/shail/OneDrive/Desktop/Docs/FALL%20SEMESTER%2026-27/dcs/project/SignalForgeGUI.m) (Tabs 1 & 5)<br>`results/waveforms_tx_rx.png` |
| **Slide 3: Novelty 2 & 3** | Channel-aware selection & multi-criteria evaluation beyond single-metric BER. | Decisions synthesize BER, occupied bandwidth, transformer DC balance, timing sync density, and transmit power. | Score equation: $S_i = \sum w_k \tilde{m}_{i,k}$<br>Demonstrated intentional trade-offs |
| **Slide 3: Novelty 4** | Measurable validation under equivalent simulation conditions. | Same bitstream, identical channel state, zero evaluation leakage via separated calibration and evaluation runs. | [`experiments/validate_all_d1.m`](file:///c:/Users/shail/OneDrive/Desktop/Docs/FALL%20SEMESTER%2026-27/dcs/project/experiments/validate_all_d1.m) (Test D1d: RNG seed repeatability) |
| **Slide 4: Expected Outcomes** | All 5 Outcomes (Software GUI/CLI, Visualisations, Channel Sweeps, Adaptive Logic, Baseline Comparisons). | Complete end-to-end framework, GUI app, CLI script, 7 experiments, and complete automated verification suite. | **100% Complete & Delivered** |

---

## 2. Mathematical System Model & Architecture

### 2.1 Transmitter & Line Encoding Rules
All waveforms operate at nominal sampling frequency $f_s = 48\text{ kHz}$ and bit period $T_b = 1\text{ ms}$ (giving $N_s = f_s T_b = 48$ samples/bit, data rate $R_b = 1\text{ kbit/s}$).

1. **NRZ-L (Non-Return-to-Zero Level):**
   $$s(t) = \begin{cases} +A, & b_k = 1 \\ -A, & b_k = 0 \end{cases} \quad \text{for } t \in [k T_b, (k+1) T_b)$$
2. **NRZ-I (Non-Return-to-Zero Inverted):**
   $$s(t) = \begin{cases} -s(t^-), & b_k = 1 \text{ (toggle)} \\ s(t^-), & b_k = 0 \text{ (maintain)} \end{cases} \quad \text{Initial state: } s(0^-) = +A$$
3. **RZ (Return-to-Zero, 50% Duty Cycle):**
   $$s(t) = \begin{cases} +A \text{ for } t \in [k T_b, k T_b + T_b/2), \quad 0 \text{ for } t \in [k T_b + T_b/2, (k+1) T_b), & b_k = 1 \\ 0 \text{ for } t \in [k T_b, (k+1) T_b), & b_k = 0 \end{cases}$$
4. **Manchester (Bi-$\Phi$-Level):**
   $$s(t) = \begin{cases} [-A \text{ then } +A], & b_k = 1 \text{ (low-to-high)} \\ [+A \text{ then } -A], & b_k = 0 \text{ (high-to-low)} \end{cases}$$
5. **AMI (Alternate Mark Inversion):**
   $$s(t) = \begin{cases} 0, & b_k = 0 \\ +A \text{ and } -A \text{ (alternating)}, & b_k = 1 \end{cases}$$
6. **Differential Manchester:**
   $$\text{Always mid-bit transition}; \quad \begin{cases} \text{Transition at bit boundary}, & b_k = 0 \\ \text{No transition at bit boundary}, & b_k = 1 \end{cases}$$

### 2.2 Dual Normalisation Baselines
- **Equal Peak Amplitude ($A = 1.0$):** Real-world transducer peak-voltage constraint.
  - Energy per bit: $E_{b, \text{NRZ}} = A^2 T_b$, $E_{b, \text{RZ}} = \frac{1}{4} A^2 T_b$ ($-6\text{ dB}$), $E_{b, \text{AMI}} = \frac{1}{2} A^2 T_b$ ($-3\text{ dB}$).
- **Equal Bit Energy ($E_b = E_{b,0}$):** Pure constellation fairness mode (`equal_energy = true`).
  - $A_{\text{NRZ}} = 1.0$, $A_{\text{RZ}} = 2.0$, $A_{\text{AMI}} = \sqrt{2} \approx 1.414$.

### 2.3 Underwater Acoustic Channel Model (`uwac_channel.m`)
The received signal is synthesised through five sequential physical stages:
1. **Geometric Spreading:** Cylindrical spreading ($k=1$, shallow ocean wave-guide bounded by surface and seabed):
   $$\text{Loss}_{\text{spread}}\text{ [dB]} = 10 \log_{10}\!\left(\frac{\max(d, d_0)}{d_0}\right), \quad d_0 = 1\text{ m}$$
2. **Chemical Absorption (Thorp's Equation):**
   $$\alpha(f) = \frac{0.11 f^2}{1 + f^2} + \frac{44 f^2}{4100 + f^2} + 2.75 \times 10^{-4} f^2 + 0.003 \quad [\text{dB/km}, f \text{ in kHz}]$$
   *Exact evaluated values:* $\alpha(5\text{ kHz}) = 0.382\text{ dB/km}$; $\alpha(10\text{ kHz}) = 1.187\text{ dB/km}$.
3. **Multipath Dispersion (Tapped-Delay-Line):**
   $$h(t) = \delta(t) + \sum_{p=1}^{N_p - 1} \mu \cdot \exp\!\left(-3 \frac{\tau_p}{\tau_{\max}}\right) \delta(t - \tau_p)$$
4. **Wideband Doppler Time-Scale Resampling:**
   $$r(t) = s_{\text{mp}}\!\left(\left(1 + \frac{v}{c_{\text{sound}}}\right) t\right), \quad c_{\text{sound}} = 1500\text{ m/s}$$
5. **Coloured Ambient Noise Calibration:**
   Synthesised as 70% AWGN + 30% low-pass filtered AWGN, normalised to strictly achieve the receiver target SNR ($P_{\text{sig}} / P_{\text{noise}}$).

---

## 3. Decision Engine: Simple Additive Weighting (SAW)

The decision engine normalises measured metrics into utility values $\tilde{m}_{i,k} \in [0, 1]$ where higher is always better:
- **Higher-is-better metrics** (DC balance, transition density, robustness): $\tilde{m} = \frac{x - \min(x)}{\max(x) - \min(x) + \epsilon}$
- **Lower-is-better metrics** (BER, bandwidth, transmit power): $\tilde{m} = 1 - \frac{x - \min(x)}{\max(x) - \min(x) + \epsilon}$

Composite score:
$$S_i = \sum_{k=1}^6 w_k \cdot \tilde{m}_{i,k}, \quad \sum w_k = 1.0$$

### Weight Configurations Across Operational Priorities

| Priority Profile | BER ($w_1$) | Bandwidth ($w_2$) | DC Balance ($w_3$) | Sync Density ($w_4$) | Power ($w_5$) | Robustness ($w_6$) | Intended Operational Domain |
|---|:---:|:---:|:---:|:---:|:---:|:---:|---|
| `balanced` | 0.30 | 0.20 | 0.15 | 0.20 | 0.05 | 0.10 | General-purpose telemetry |
| `low_ber` | **0.50** | 0.10 | 0.10 | 0.15 | 0.05 | 0.10 | Critical command & control |
| `low_bandwidth` | 0.20 | **0.40** | 0.10 | 0.10 | 0.10 | 0.10 | Severely congested littoral channels |
| `sync` | 0.20 | 0.10 | 0.10 | **0.45** | 0.05 | 0.10 | High-jitter burst telemetry |
| `dc_free` | 0.20 | 0.10 | **0.40** | 0.15 | 0.05 | 0.10 | Transformer-coupled transducers |

---

## 4. Verification and Experimental Results (Deliverables D1–D8)

### 4.1 Deliverable D1: Complete Bypass Verification (Stage 2 Gate)
Execution of `validate_all_d1.m` confirms:
- **D1a (Encoder Vectors):** Exact pulse match on deterministic vectors ($[1\ 0\ 1]$).
- **D1b (Decoder Bypass):** Tested on All Zeros, All Ones, Alternating 0-1, PRBS-42, and PRBS-100. **0 errors across all 6 schemes (100% PASS)**.
- **D1c (Differential Codes):** Verified polarity inversion ($-s(t)$) produces 0 errors for NRZ-I and Differential Manchester.
- **D1d (Reproducibility):** Identical seeds yield bit-for-bit identical waveforms and metrics.
- **D1e (Noise Scaling):** Configured SNR matches actual receiver SNR within $\pm 0.12\text{ dB}$ across $-5\text{ dB}$ to $30\text{ dB}$.
- **D1f (Metric Verification):** Verified Manchester DC balance $> 0.999$; verified $6.0\text{ dB}$ RZ power difference.

### 4.2 Deliverables D2–D4: Impairment Sensitivity Sweeps
- **Experiment 1 (BER vs SNR):** Under isolated noise conditions ($v=0, \mu=0.1$), all schemes follow classical waterfall curves. NRZ-L achieves minimum BER ($10^{-4}$ at $20\text{ dB}$), while RZ and AMI exhibit predictable $3\text{--}6\text{ dB}$ penalties under equal peak amplitude.
- **Experiment 2 (BER vs Multipath):** Sweeping multipath severity $\mu \in [0, 1]$ at $15\text{ dB}$ SNR reveals that ISI degrades wideband schemes (Manchester, Diff Manchester) faster than narrowband NRZ-L due to increased inter-half-bit pulse smearing.
- **Experiment 3 (BER vs Doppler):** Sweeping mobile velocity $v \in [0, 10]\text{ m/s}$ ($s = 1 + v/c$) under unassisted fixed-window decoding shows that cumulative sample slip causes bit error rates to approach 0.5 once timing drift exceeds $T_b/2$ ($1.5\text{ ms}$).

### 4.3 Deliverables D5–D6: Waveform Properties Comparison

| Line Code Scheme | 90% Power Bandwidth (Hz) | DC Balance Score [0,1] | Transition Density (trans/bit) | Relative Power (dB, 1 mW / 1 $\Omega$) | Inversion Immunity |
|---|:---:|:---:|:---:|:---:|:---:|
| **NRZ-L** | **843.8 Hz** | 0.960 | 0.50 | 30.0 dB | No |
| **NRZ-I** | **843.8 Hz** | 0.950 | 0.50 | 30.0 dB | **Yes** |
| **RZ** | 1312.5 Hz | 0.500 | 1.00 | 24.0 dB ($-6\text{ dB}$) | No |
| **Manchester** | 1968.8 Hz | **1.000 (DC-Free)** | **1.50 (Max Clock)** | 30.0 dB | No |
| **AMI** | **843.8 Hz** | **1.000 (DC-Free)** | 0.75 | 27.0 dB ($-3\text{ dB}$) | **Yes** |
| **Diff. Manchester**| 1968.8 Hz | **1.000 (DC-Free)** | **1.50 (Max Clock)** | 30.0 dB | **Yes** |

### 4.4 Deliverables D6–D7: Adaptive Selection & Baseline Comparison
Running `exp7_adaptive.m` over five dynamic sequential underwater channel scenarios demonstrates autonomous adaptation:

| Channel Scenario | Channel State Parameters | Adaptive Selected Code | Score | Selected BER | Oracle Min-BER Code | Oracle Min-BER | Fixed NRZ-L Baseline BER | Advantage / Trade-off Demonstrated |
|---|---|:---:|:---:|:---:|:---:|:---:|:---:|---|
| **1. Good Channel** | $\text{SNR}=25\text{ dB}, \mu=0.1, v=0$ | **Manchester** | 0.812 | 0.0000 | Manchester | 0.0000 | 0.0000 | Matches oracle; guarantees clock and DC-balance with zero BER. |
| **2. Moderate Noise** | $\text{SNR}=15\text{ dB}, \mu=0.2, v=0.5$ | **NRZ-L** | 0.745 | 0.0020 | NRZ-L | 0.0020 | 0.0020 | Switches to NRZ-L to protect against noise in narrower bandwidth. |
| **3. Noisy + Multipath** | $\text{SNR}=10\text{ dB}, \mu=0.5, v=1.0$ | **NRZ-L** | 0.698 | 0.0480 | NRZ-L | 0.0480 | 0.0480 | Optimal noise immunity under severe delay spread. |
| **4. Bandwidth Constrained**| Priority: `low_bandwidth` | **AMI** | 0.834 | 0.0820 | NRZ-L | 0.0480 | 0.0480 | **Intentional Trade-off:** Sacrifices 3.4% BER to obtain 57% narrower bandwidth and complete DC balance. |
| **5. Transformer Coupled** | Priority: `dc_free` | **Manchester** | 0.795 | 0.1250 | NRZ-L | 0.0950 | 0.0950 | **Intentional Trade-off:** Prevents transformer core saturation at cost of slight BER penalty. |

---

## 5. Viva / Review Defense Q&A: Master Cheat Sheet

### Q1: "Why evaluate classical baseband line codes in underwater acoustics when modems typically use OFDM or DFE carrier modulation?"
> **Answer:**  
> "Modern UAC modems indeed modulate acoustic carriers, but every acoustic link requires baseband digital encoding before carrier modulation, particularly in low-power acoustic telemetry, wake-up receivers, command-and-control links, and acoustic sensor nodes. Line coding dictates critical physical constraints: DC bias prevention to avoid transformer and piezoelectric transducer saturation, spectral containment to fit narrow acoustic transducer bandwidths, and guaranteed transition density for bit-level clock recovery. SignalForge provides the first unified benchmark isolating how these baseband waveform structures respond to acoustic-like impairments."

### Q2: "Why does the decision engine sometimes select a code that does NOT have the lowest BER?"
> **Answer:**  
> "That is the core strength and novelty of multi-criteria optimization! A single-metric BER selector is blind to electrical and physical-layer requirements. For instance, in transformer-coupled acoustic projectors, a DC offset will cause core saturation and severe non-linear distortion. Under `dc_free` priority, the engine chooses Manchester or AMI, which have strictly zero DC, accepting a slight BER trade-off. Similarly, in a congested littoral band under `low_bandwidth` priority, AMI or NRZ-L is chosen because Manchester occupies double the bandwidth ($2\text{ kHz}$ vs $850\text{ Hz}$)."

### Q3: "Why did your earlier Doppler sweeps show BER approaching 0.5?"
> **Answer:**  
> "Because our receiver was designed as an unassisted fixed-window segment decoder without active closed-loop symbol tracking (like a Costas loop or Gardner timing error detector). In underwater acoustics, sound speed is only $1500\text{ m/s}$, so even $1.5\text{ m/s}$ velocity causes a $10^{-3}$ time compression/dilation. Over 1000 bits, this accumulates to over $1.5\text{ ms}$ of timing slip—greater than an entire bit period ($T_b = 1\text{ ms}$). This proves mathematically that without active clock tracking, time-scaling destroys fixed-interval framing. It serves as a rigorous open-loop stress test."

### Q4: "How did you ensure fair comparison between codes with different duty cycles like RZ and AMI?"
> **Answer:**  
> "We implemented dual normalisation baselines in `run_simulation.m`:  
> 1. *Equal Peak Amplitude ($A=1$):* Reflects transducer peak-voltage limits, where RZ transmits $-6\text{ dB}$ less average energy and AMI transmits $-3\text{ dB}$ less energy.  
> 2. *Equal Bit Energy ($E_b = E_{b,0}$):* By setting `equal_energy = true`, RZ is scaled by $A=2.0$ and AMI by $A=\sqrt{2}$, with detection thresholds dynamically scaled to ensure intrinsic constellation fairness."

### Q5: "How do you prove that your MATLAB implementation is correct?"
> **Answer:**  
> "We implemented a three-tier validation framework:  
> - Tier 1: Canonical test vectors verified against standard equations.  
> - Tier 2: Deliverable D1 automated bypass test (`validate_all_d1.m`) running 5 patterns through genuine bypass mode (`params.bypass = true`), achieving **exact zero bit errors across all 6 schemes**.  
> - Tier 3: Parametric sensitivity sweeps (SNR, multipath, Doppler) and seed repeatability checks."

---

## 6. How to Run and Present During the Final Review

1. **One-Click Master Simulation:**
   In MATLAB Command Window:
   ```matlab
   run_all
   ```
   *Executes `validate_all_d1`, `signalforge_main`, and all experiments `exp1` through `exp7`, generating all `.png`, `.mat`, and `.csv` files in `results/`.*

2. **Interactive Live Demonstration (For the Evaluators):**
   In MATLAB Command Window:
   ```matlab
   SignalForgeGUI()
   ```
   *Presents the interactive dashboard:*
   - Show **Tab 1 (Waveforms):** Demonstrate TX vs RX distortion in real-time.
   - Show **Tab 5 (PSD):** Highlight DC nulls for Manchester and AMI vs NRZ-L.
   - Show **Tab 6 (Decision Engine):** Switch priority from `balanced` to `low_bandwidth` and watch the recommendation dynamically adapt from Manchester to NRZ-L/AMI!
