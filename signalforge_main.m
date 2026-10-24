% SIGNALFORGE_MAIN  Command-line entry point for SignalForge.
%
%   Runs a quick demonstration of all modules without the GUI.
%   Useful for validating each module independently before using the GUI.
%
%   Usage (from project root in MATLAB):
%     >> signalforge_main
%
%   To launch the full interactive GUI:
%     >> SignalForgeGUI()

close all;
fprintf('============================================================\n');
fprintf('  SignalForge — Underwater Acoustic Line-Code Simulator\n');
fprintf('  DCS Group Project 2026-27\n');
fprintf('============================================================\n\n');

% Add all subfolders to MATLAB path
addpath(genpath(fileparts(mfilename('fullpath'))));
if ~exist('results','dir'), mkdir('results'); end

% ---------------------------------------------------------------
% Simulation settings
% ---------------------------------------------------------------
fs     = 48000;      % sampling frequency (Hz)
Tb     = 1e-3;       % bit period (1 ms)
N_bits = 500;        % bits per test
rng(42);
bits   = randi([0 1], 1, N_bits);

SCHEMES = {'nrzl','nrzi','rz','manchester','ami','diff_manchester'};
LABELS  = {'NRZ-L','NRZ-I','RZ','Manchester','AMI','Diff. Manchester'};

% ---------------------------------------------------------------
% Channel scenario: moderate underwater conditions
% ---------------------------------------------------------------
params.SNR_dB      = 15;
params.distance_m  = 300;
params.fc_Hz       = 5000;
params.num_paths   = 3;
params.max_delay_s = 3e-3;
params.multipath_k = 0.3;
params.doppler_v   = 1.0;
params.bw_fraction = 0.4;

fprintf('Channel parameters:\n');
fprintf('  SNR         = %d dB\n',   params.SNR_dB);
fprintf('  Distance    = %d m\n',    params.distance_m);
fprintf('  Multipath k = %.1f\n',    params.multipath_k);
fprintf('  Doppler v   = %.1f m/s\n',params.doppler_v);
fprintf('  Fc          = %d Hz\n\n', params.fc_Hz);

% ---------------------------------------------------------------
% Run simulation for all schemes
% ---------------------------------------------------------------
fprintf('Running simulation for all six schemes...\n\n');
results = run_simulation(bits, SCHEMES, params, fs, Tb);

% ---------------------------------------------------------------
% Print metrics table
% ---------------------------------------------------------------
fprintf('%-22s %8s %12s %10s %10s %10s\n', ...
    'Scheme', 'BER', 'BW (Hz)', 'DC |val|', 'Sync', 'Power(dBm)');
fprintf('%s\n', repmat('-', 1, 76));

for i = 1:length(SCHEMES)
    m = results(i).metrics;
    fprintf('%-22s %8.4f %12.1f %10.4f %10.2f %10.1f\n', ...
        LABELS{i}, m.BER, m.bandwidth_hz, abs(m.dc_offset), ...
        m.transition_density, m.power_dBm);
end
fprintf('%s\n\n', repmat('-', 1, 76));

% ---------------------------------------------------------------
% ---------------------------------------------------------------
% Decision engine (Multi-Criteria SAW)
% ---------------------------------------------------------------
fprintf('Decision Engine (priority: balanced)...\n\n');
dec = decision_engine([results.metrics], 'balanced');
fprintf('%s\n', dec.reasoning);
fprintf('\nFull ranking:\n');
for i = 1:length(dec.ranking)
    marker = '  ';
    if i == 1, marker = '★ '; end
    fname  = matlab.lang.makeValidName(dec.ranking{i});
    fprintf('  %s%d. %-22s  score = %.4f\n', ...
        marker, i, dec.ranking{i}, dec.ranking_scores(i));
end

% ---------------------------------------------------------------
% Machine Learning Model Prediction
% ---------------------------------------------------------------
fprintf('\n------------------------------------------------------------\n');
fprintf('  Machine Learning Classifier Model Prediction\n');
fprintf('------------------------------------------------------------\n');
try
    ml_pred = predict_linecode_ml(params, 'balanced');
    fprintf('  Predicted Scheme:   %s (%s)\n', ml_pred.predicted_label, ml_pred.predicted_scheme);
    fprintf('  Model Confidence:   %.1f%%\n', ml_pred.confidence * 100);
    fprintf('  Agreement with SAW: %s\n', char(string(strcmpi(ml_pred.predicted_scheme, dec.best_scheme))));
catch ME
    fprintf('  ML Prediction Notice: %s\n', ME.message);
end
fprintf('------------------------------------------------------------\n\n');

% ---------------------------------------------------------------
% Plot waveforms (first 30 bits)
% ---------------------------------------------------------------
fig = figure('Name','SignalForge — Waveforms', ...
    'NumberTitle','off','Position',[80 60 1400 800], ...
    'Color',[0.06 0.06 0.10]);

t     = (0:length(results(1).tx_signal)-1) / fs;
Nshow = min(length(t), round(30 * fs * Tb));
t_s   = t(1:Nshow);
colors = [0 114 189; 217 83 25; 237 177 32; 119 172 48; 162 20 47; 126 47 142]/255;

for i = 1:6
    ax = subplot(6,1,i);
    ax.Color        = [0.08 0.08 0.12];
    ax.XColor       = 'w'; ax.YColor  = 'w';
    ax.GridColor    = [0.25 0.25 0.3]; ax.GridAlpha = 0.5;
    hold(ax,'on'); grid(ax,'on');

    tx_s = results(i).tx_signal(1:Nshow);
    rx_s = results(i).rx_signal(1:Nshow);
    plot(ax, t_s*1000, tx_s, 'Color', colors(i,:),    'LineWidth',1.6);
    plot(ax, t_s*1000, rx_s, 'Color', colors(i,:)*0.6,'LineWidth',0.8);
    ylabel(ax, LABELS{i}, 'Color', colors(i,:), 'FontSize',9,'FontWeight','bold');
    ylim(ax, [-1.8 1.8]);
    if i < 6, ax.XTickLabel = {}; end
end
xlabel('Time (ms)', 'Color','w','FontSize',11);
sgtitle('SignalForge — TX (bright) vs RX (dim) — First 30 bits', ...
    'Color','w','FontSize',13,'FontWeight','bold');
res_dir = fullfile(fileparts(mfilename('fullpath')), 'results');
if ~exist(res_dir, 'dir'), mkdir(res_dir); end
saveas(fig, fullfile(res_dir, 'waveforms_tx_rx.png'));
fprintf('\nWaveform figure saved to %s\n', fullfile(res_dir, 'waveforms_tx_rx.png'));

fprintf('\n\nTo launch the full interactive GUI:\n');
fprintf('  >> SignalForgeGUI()\n\n');
fprintf('To run individual experiments:\n');
fprintf('  >> run(''experiments/exp1_ber_vs_snr.m'')\n');
fprintf('  >> run(''experiments/exp2_ber_vs_multipath.m'')\n');
fprintf('  >> run(''experiments/exp3_ber_vs_doppler.m'')\n');
fprintf('  >> run(''experiments/exp456_properties.m'')\n');
fprintf('  >> run(''experiments/exp7_adaptive.m'')\n\n');
