# SignalForge — Software Specification

## 1. Objective
Develop a MATLAB-based framework for comparing six digital line codes under configurable, simulated underwater-acoustic-like channel conditions.

## 2. Supported line codes
- NRZ-L
- NRZ-I
- RZ
- Manchester
- AMI
- Differential Manchester

## 3. System inputs
- Binary data sequence
- Bit rate and sampling rate
- SNR
- Attenuation and propagation distance
- Multipath configuration
- Relative Doppler velocity
- Random seed
- Decision-engine weights and priorities

## 4. Processing pipeline
1. Generate or accept input bits.
2. Encode using each supported line code.
3. Apply configured channel impairments.
4. Decode the received waveform.
5. Calculate BER and waveform metrics.
6. Rank line codes using the documented decision algorithm.
7. Compare the selected code with fixed-code baselines.
8. Generate plots and export numerical results.

## 5. Required metrics
- Bit error rate (BER)
- Power spectral density (PSD)
- Occupied bandwidth using a documented definition
- DC component or DC balance
- Transition density
- Relative energy per bit

## 6. Required verification
- Encoder test vectors for every code.
- Zero-error bypass tests for matching encoders and decoders.
- Noise-off and individual-impairment tests.
- Verification of target versus measured SNR.
- Metric calculations checked against independent test cases.
- Repeatability with fixed random seeds.
- Decision-engine comparison against fixed and empirical-best baselines.

## 7. Required outputs
- MATLAB source code
- Automated test scripts
- Raw experiment results in CSV or MAT format
- Publication-quality figures
- Experiment configuration files
- README with setup and execution instructions
- Limitations and assumptions documentation

## 8. Development rules
- Implement one module at a time.
- Do not fabricate experimental results.
- Do not mark tests as passing unless they have actually executed.
- Stop and report failed tests before proceeding to dependent modules.
- Document all modelling assumptions and units.
- Keep the simulated baseband model distinct from a validated physical underwater acoustic modem.
