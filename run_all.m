function run_all()
% RUN_ALL  One-click master execution and export script for SignalForge.
% =========================================================================
%   Runs all validation scripts and experiments sequentially, generating
%   all plots, data files, and performance tables in the 'results/' folder.
%
%   Usage (in MATLAB Command Window):
%     >> run_all
%
%   To share this project with a classmate or reviewer:
%     1. Zip this entire project folder and send it to them.
%     2. They extract the zip, open MATLAB, and set the Current Folder to
%        this directory.
%     3. They type:  run_all
%     4. All output figures (.png) and data (.mat) will appear in 'results/'!
% =========================================================================

close all; clc;

fprintf('=========================================================================\n');
fprintf('  SignalForge — Complete Master Simulation & Output Generator\n');
fprintf('=========================================================================\n\n');

% Set up paths
proj_dir = fileparts(mfilename('fullpath'));
if isempty(proj_dir), proj_dir = pwd; end
addpath(genpath(proj_dir));

results_dir = fullfile(proj_dir, 'results');
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

t_start = tic;

% -------------------------------------------------------------------------
% Step 1: Stage 2 Verification Suite (Deliverables D1a - D1f)
% -------------------------------------------------------------------------
fprintf('[1/7] Running Stage 2 Verification Suite (validate_all_d1.m)...\n');
try
    validate_all_d1();
    fprintf('      -> Stage 2 verification complete.\n\n');
catch ME
    warning('Error running validate_all_d1: %s', ME.message);
end

% -------------------------------------------------------------------------
% Step 2: Main Demonstration & Waveforms
% -------------------------------------------------------------------------
fprintf('[2/6] Running Core Waveform Demonstration (signalforge_main.m)...\n');
try
    run(fullfile(proj_dir, 'signalforge_main.m'));
    fprintf('      -> Waveforms saved to results/waveforms_tx_rx.png.\n\n');
catch ME
    warning('Error running signalforge_main: %s', ME.message);
end

% -------------------------------------------------------------------------
% Step 3: Experiment 1 — BER vs SNR
% -------------------------------------------------------------------------
fprintf('[3/6] Running Experiment 1: BER vs SNR (exp1_ber_vs_snr.m)...\n');
try
    run(fullfile(proj_dir, 'experiments', 'exp1_ber_vs_snr.m'));
    fprintf('      -> Plot saved to results/exp1_ber_vs_snr.png.\n\n');
catch ME
    warning('Error running exp1_ber_vs_snr: %s', ME.message);
end

% -------------------------------------------------------------------------
% Step 4: Experiment 2 — BER vs Multipath Severity
% -------------------------------------------------------------------------
fprintf('[4/6] Running Experiment 2: BER vs Multipath (exp2_ber_vs_multipath.m)...\n');
try
    run(fullfile(proj_dir, 'experiments', 'exp2_ber_vs_multipath.m'));
    fprintf('      -> Plot saved to results/exp2_ber_vs_multipath.png.\n\n');
catch ME
    warning('Error running exp2_ber_vs_multipath: %s', ME.message);
end

% -------------------------------------------------------------------------
% Step 5: Experiment 3 — BER vs Doppler Shift
% -------------------------------------------------------------------------
fprintf('[5/6] Running Experiment 3: BER vs Doppler (exp3_ber_vs_doppler.m)...\n');
try
    run(fullfile(proj_dir, 'experiments', 'exp3_ber_vs_doppler.m'));
    fprintf('      -> Plot saved to results/exp3_ber_vs_doppler.png.\n\n');
catch ME
    warning('Error running exp3_ber_vs_doppler: %s', ME.message);
end

% -------------------------------------------------------------------------
% Step 6: Experiments 4-6 — Spectral and Signal Properties
% -------------------------------------------------------------------------
fprintf('[6/7] Running Experiments 4-6: Signal Properties (exp456_properties.m)...\n');
try
    run(fullfile(proj_dir, 'experiments', 'exp456_properties.m'));
    fprintf('      -> Plot saved to results/exp456_properties.png.\n\n');
catch ME
    warning('Error running exp456_properties: %s', ME.message);
end

% -------------------------------------------------------------------------
% Step 7: Experiment 7 — Adaptive Selection Intelligence
% -------------------------------------------------------------------------
fprintf('[7/7] Running Experiment 7: Adaptive Selection (exp7_adaptive.m)...\n');
try
    run(fullfile(proj_dir, 'experiments', 'exp7_adaptive.m'));
    fprintf('      -> Plot saved to results/exp7_adaptive.png.\n\n');
catch ME
    warning('Error running exp7_adaptive: %s', ME.message);
end

% -------------------------------------------------------------------------
% Step 8: Machine Learning Model Evaluation & Benchmarking
% -------------------------------------------------------------------------
fprintf('[8/8] Running Machine Learning Model Evaluation (evaluate_ml_model.m)...\n');
try
    evaluate_ml_model();
    fprintf('      -> Plot saved to results/ml_model_evaluation.png.\n\n');
catch ME
    warning('Error running evaluate_ml_model: %s', ME.message);
end

% Step 9: Quantitative Latency & Trade-Off Benchmarking
fprintf('[9/10] Running Latency & Objective Trade-Off Benchmarking (benchmark_ml_vs_simulation.m)...\n');
try
    benchmark_ml_vs_simulation();
    fprintf('       -> Trade-off plot saved to results/ml_benchmark_tradeoff.png.\n\n');
catch ME
    warning('Error running benchmark_ml_vs_simulation: %s', ME.message);
end

% Step 10: Dual Model Training & Comparison (Oracle Min-BER vs SAW Imitator)
fprintf('[10/10] Running Dual-Model Training & Comparison (compare_saw_vs_oracle_models.m)...\n');
try
    compare_saw_vs_oracle_models();
    fprintf('        -> Model comparison plot saved to results/model_comparison_saw_vs_oracle.png.\n\n');
catch ME
    warning('Error running compare_saw_vs_oracle_models: %s', ME.message);
end

elapsed = toc(t_start);

% -------------------------------------------------------------------------
% Output Summary
% -------------------------------------------------------------------------
fprintf('=========================================================================\n');
fprintf('  ALL EXPERIMENTS & ML SUITE COMPLETED in %.1f seconds!\n', elapsed);
fprintf('=========================================================================\n\n');
fprintf('All output files have been exported to:  %s\n\n', results_dir);
fprintf('Generated Image Files (ready for reports and presentations):\n');
fprintf('  1. results/waveforms_tx_rx.png       — TX vs RX 6-line code waveforms\n');
fprintf('  2. results/exp1_ber_vs_snr.png        — BER vs SNR curve comparison\n');
fprintf('  3. results/exp2_ber_vs_multipath.png  — BER vs multipath severity curve\n');
fprintf('  4. results/exp3_ber_vs_doppler.png    — BER vs Doppler velocity curve\n');
fprintf('  5. results/exp456_properties.png      — Bandwidth, DC balance, and Sync bars\n');
fprintf('  6. results/exp7_adaptive.png          — Adaptive decision engine score heatmap\n');
fprintf('  7. results/ml_model_evaluation.png    — ML Confusion matrix & baseline comparison\n\n');
fprintf('Generated Data Files (.mat and .csv for further MATLAB analysis):\n');
fprintf('  - results/exp1_ber_vs_snr.mat & .csv\n');
fprintf('  - results/exp2_ber_vs_multipath.mat\n');
fprintf('  - results/exp3_ber_vs_doppler.mat\n');
fprintf('  - results/exp456_properties.mat\n');
fprintf('  - results/exp7_adaptive.mat & .csv\n');
fprintf('  - results/ml_model_evaluation.mat\n\n');
fprintf('To interact with the simulation via graphical UI, run:\n');
fprintf('  >> SignalForgeGUI\n');
fprintf('=========================================================================\n');
end
