% EXPERIMENT 3: BER vs Doppler Velocity
% =========================================================
% Fix SNR=15 dB, moderate multipath. Sweep relative velocity
% from 0 to 10 m/s to model source/receiver motion.

close all;
addpath(genpath(fileparts(mfilename('fullpath'))));

fprintf('=== Experiment 3: BER vs Doppler Velocity ===\n\n');

fs     = 48000;
Tb     = 1e-3;
N_bits = 2000;
rng(3);
bits   = randi([0 1], 1, N_bits);

schemes = {'nrzl','nrzi','rz','manchester','ami','diff_manchester'};
labels  = {'NRZ-L','NRZ-I','RZ','Manchester','AMI','Diff. Manchester'};
colors  = {'#0072BD','#D95319','#EDB120','#77AC30','#A2142F','#7E2F8E'};

v_range = 0:0.5:10;             % relative velocity (m/s)

base_params.SNR_dB      = 15;
base_params.distance_m  = 300;
base_params.fc_Hz       = 5000;
base_params.num_paths   = 3;
base_params.max_delay_s = 3e-3;
base_params.multipath_k = 0.3;
base_params.bw_fraction = 0.4;

BER_matrix = zeros(length(schemes), length(v_range));

for s = 1:length(schemes)
    fprintf('  Scheme: %-18s ', labels{s});
    for q = 1:length(v_range)
        base_params.doppler_v = v_range(q);
        res = run_simulation(bits, schemes(s), base_params, fs, Tb);
        BER_matrix(s,q) = res(1).metrics.BER;
        fprintf('.');
    end
    fprintf('  done\n');
end

figure('Name','Exp3: BER vs Doppler','NumberTitle','off', ...
       'Position',[100 100 900 550],'Color','k');
ax = axes('Color','[0.08 0.08 0.12]','XColor','w','YColor','w', ...
          'GridColor','[0.3 0.3 0.3]','GridAlpha',0.4);
hold(ax,'on'); grid(ax,'on');

for s = 1:length(schemes)
    semilogy(ax, v_range, max(BER_matrix(s,:), 1e-5), ...
        'Color',colors{s},'LineWidth',2.0,'Marker','^','MarkerSize',5,...
        'DisplayName',labels{s});
end

xlabel(ax,'Relative Velocity (m/s)','Color','w','FontSize',13);
ylabel(ax,'Bit Error Rate (BER)','Color','w','FontSize',13);
title(ax,'SignalForge — BER vs Doppler Shift (SNR=15 dB)', ...
    'Color','w','FontSize',14,'FontWeight','bold');
legend(ax,'Location','northwest','TextColor','w', ...
    'Color','[0.1 0.1 0.15]','EdgeColor','[0.4 0.4 0.4]','FontSize',10);
ylim(ax,[1e-5 1]);

res_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'results');
if ~exist(res_dir, 'dir'), mkdir(res_dir); end
save(fullfile(res_dir, 'exp3_ber_vs_doppler.mat'), 'v_range', 'BER_matrix', 'labels', 'schemes');
saveas(gcf, fullfile(res_dir, 'exp3_ber_vs_doppler.png'));
fprintf('\nResults saved to %s\n', res_dir);
