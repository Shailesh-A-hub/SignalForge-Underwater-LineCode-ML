% EXPERIMENT 1: BER vs SNR
% =========================================================
% For all six line-coding schemes, sweep SNR from -5 to 30 dB
% and plot BER curves under realistic UWAC channel conditions.
%
% Member 2 responsibility: Channel & Analysis

close all;
addpath(genpath(fileparts(mfilename('fullpath'))));

fprintf('=== Experiment 1: BER vs SNR ===\n\n');

% ---------------------------------------------------------------
% Configuration
% ---------------------------------------------------------------
fs      = 48000;        % sampling frequency (Hz)
Tb      = 1e-3;         % bit period (1 ms → 1 kbit/s)
N_bits  = 2000;         % number of bits
rng(1);
bits    = randi([0 1], 1, N_bits);

schemes = {'nrzl','nrzi','rz','manchester','ami','diff_manchester'};
labels  = {'NRZ-L','NRZ-I','RZ','Manchester','AMI','Diff. Manchester'};
colors  = {'#0072BD','#D95319','#EDB120','#77AC30','#A2142F','#7E2F8E'};

SNR_range = -5:2:30;

% Fixed channel conditions (isolates SNR/noise without Doppler timing slip)
base_params.distance_m  = 300;
base_params.fc_Hz       = 5000;
base_params.num_paths   = 3;
base_params.max_delay_s = 3e-3;
base_params.multipath_k = 0.1;
base_params.doppler_v   = 0.0;          % 0 m/s isolates noise from timing slip
base_params.bw_fraction = 0.4;

% ---------------------------------------------------------------
% BER sweep
% ---------------------------------------------------------------
BER_matrix = zeros(length(schemes), length(SNR_range));

for s = 1:length(schemes)
    fprintf('  Scheme: %-18s ', labels{s});
    for q = 1:length(SNR_range)
        base_params.SNR_dB = SNR_range(q);
        res = run_simulation(bits, schemes(s), base_params, fs, Tb);
        BER_matrix(s,q) = res(1).metrics.BER;
        fprintf('.');
    end
    fprintf('  done\n');
end

% ---------------------------------------------------------------
% Plot
% ---------------------------------------------------------------
figure('Name','Exp1: BER vs SNR','NumberTitle','off', ...
       'Position',[100 100 900 550], 'Color','k');
ax = axes('Color','[0.08 0.08 0.12]', 'XColor','w', 'YColor','w', ...
          'GridColor','[0.3 0.3 0.3]', 'GridAlpha',0.4);
hold(ax,'on'); grid(ax,'on');

for s = 1:length(schemes)
    semilogy(ax, SNR_range, max(BER_matrix(s,:), 1e-5), ...
        'Color', colors{s}, 'LineWidth', 2.0, 'Marker','o', ...
        'MarkerSize', 5, 'DisplayName', labels{s});
end

xlabel(ax, 'SNR (dB)', 'Color','w', 'FontSize',13);
ylabel(ax, 'Bit Error Rate (BER)', 'Color','w', 'FontSize',13);
title(ax, 'SignalForge — BER vs SNR | UWAC Channel', ...
    'Color','w', 'FontSize',14, 'FontWeight','bold');
legend(ax, 'Location','southwest', 'TextColor','w', ...
    'Color','[0.1 0.1 0.15]', 'EdgeColor','[0.4 0.4 0.4]', 'FontSize',10);
ylim(ax, [1e-5 1]);
ax.YAxis.Color = 'w';

% Save results (.mat and .csv for scientific reproducibility)
res_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'results');
if ~exist(res_dir, 'dir'), mkdir(res_dir); end
save(fullfile(res_dir, 'exp1_ber_vs_snr.mat'), 'SNR_range', 'BER_matrix', 'labels', 'schemes');
saveas(gcf, fullfile(res_dir, 'exp1_ber_vs_snr.png'));

% Write numerical CSV
csv_tbl = array2table([SNR_range', BER_matrix'], ...
    'VariableNames', [{'SNR_dB'}, matlab.lang.makeValidName(labels)]);
writetable(csv_tbl, fullfile(res_dir, 'exp1_ber_vs_snr.csv'));

fprintf('\nResults saved to %s (.mat, .png, and .csv)\n', res_dir);
