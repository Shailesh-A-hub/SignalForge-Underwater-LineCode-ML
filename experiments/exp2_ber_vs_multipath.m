% EXPERIMENT 2: BER vs Multipath Severity
% =========================================================
% Fix SNR at 15 dB and sweep multipath_k from 0 (no multipath)
% to 1 (severe), showing how each line code degrades.

close all;
addpath(genpath(fileparts(mfilename('fullpath'))));

fprintf('=== Experiment 2: BER vs Multipath Severity ===\n\n');

fs     = 48000;
Tb     = 1e-3;
N_bits = 2000;
rng(2);
bits   = randi([0 1], 1, N_bits);

schemes = {'nrzl','nrzi','rz','manchester','ami','diff_manchester'};
labels  = {'NRZ-L','NRZ-I','RZ','Manchester','AMI','Diff. Manchester'};
colors  = {'#0072BD','#D95319','#EDB120','#77AC30','#A2142F','#7E2F8E'};

mp_range = 0:0.05:1.0;          % multipath severity

base_params.SNR_dB      = 15;
base_params.distance_m  = 300;
base_params.fc_Hz       = 5000;
base_params.num_paths   = 4;
base_params.max_delay_s = 5e-3;
base_params.doppler_v   = 0.0;          % 0 m/s isolates multipath ISI without Doppler drift
base_params.bw_fraction = 0.4;

BER_matrix = zeros(length(schemes), length(mp_range));

for s = 1:length(schemes)
    fprintf('  Scheme: %-18s ', labels{s});
    for q = 1:length(mp_range)
        base_params.multipath_k = mp_range(q);
        res = run_simulation(bits, schemes(s), base_params, fs, Tb);
        BER_matrix(s,q) = res(1).metrics.BER;
        fprintf('.');
    end
    fprintf('  done\n');
end

figure('Name','Exp2: BER vs Multipath','NumberTitle','off', ...
       'Position',[100 100 900 550], 'Color','k');
ax = axes('Color','[0.08 0.08 0.12]', 'XColor','w', 'YColor','w', ...
          'GridColor','[0.3 0.3 0.3]', 'GridAlpha',0.4);
hold(ax,'on'); grid(ax,'on');

for s = 1:length(schemes)
    semilogy(ax, mp_range, max(BER_matrix(s,:), 1e-5), ...
        'Color',colors{s}, 'LineWidth',2.0, 'Marker','s','MarkerSize',5,...
        'DisplayName',labels{s});
end

xlabel(ax,'Multipath Severity (0–1)','Color','w','FontSize',13);
ylabel(ax,'Bit Error Rate (BER)','Color','w','FontSize',13);
title(ax,'SignalForge — BER vs Multipath Severity (SNR=15 dB)', ...
    'Color','w','FontSize',14,'FontWeight','bold');
legend(ax,'Location','northwest','TextColor','w', ...
    'Color','[0.1 0.1 0.15]','EdgeColor','[0.4 0.4 0.4]','FontSize',10);
ylim(ax,[1e-5 1]);

res_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'results');
if ~exist(res_dir, 'dir'), mkdir(res_dir); end
save(fullfile(res_dir, 'exp2_ber_vs_multipath.mat'), 'mp_range', 'BER_matrix', 'labels', 'schemes');
saveas(gcf, fullfile(res_dir, 'exp2_ber_vs_multipath.png'));
fprintf('\nResults saved to %s\n', res_dir);
