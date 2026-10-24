% EXPERIMENT 7: Adaptive Line-Code Selection Under Changing Conditions
% =========================================================
% Demonstrates SignalForge's intelligence by changing channel
% conditions in steps and observing how the decision engine
% adapts its line-code recommendation.

close all;
addpath(genpath(fileparts(mfilename('fullpath'))));

fprintf('=== Experiment 7: Adaptive Line-Code Selection ===\n\n');

fs     = 48000;
Tb     = 1e-3;
N_bits = 1000;
rng(7);
bits   = randi([0 1], 1, N_bits);

schemes = {'nrzl','nrzi','rz','manchester','ami','diff_manchester'};
labels  = {'NRZ-L','NRZ-I','RZ','Manchester','AMI','Diff. Manchester'};

% ---------------------------------------------------------------
% Define five channel scenarios (easy → severe)
% ---------------------------------------------------------------
scenarios(1) = struct('name','Good Channel', ...
    'SNR_dB',25,'multipath_k',0.1,'doppler_v',0,'distance_m',200);
scenarios(2) = struct('name','Moderate Noise', ...
    'SNR_dB',15,'multipath_k',0.2,'doppler_v',0.5,'distance_m',300);
scenarios(3) = struct('name','Noisy + Multipath', ...
    'SNR_dB',10,'multipath_k',0.5,'doppler_v',1.0,'distance_m',500);
scenarios(4) = struct('name','Severe Conditions', ...
    'SNR_dB',5, 'multipath_k',0.8,'doppler_v',3.0,'distance_m',800);
scenarios(5) = struct('name','Extreme Channel', ...
    'SNR_dB',2, 'multipath_k',1.0,'doppler_v',5.0,'distance_m',1000);

priority = 'balanced';

% ---------------------------------------------------------------
% Run all scenarios with empirical benchmarking
% ---------------------------------------------------------------
fprintf('%-20s | %-16s | %-8s | %-8s | %-16s | %-8s | %-8s\n', ...
    'Scenario', 'Selected Scheme', 'Score', 'Sel BER', 'Min-BER Scheme', 'Min BER', 'NRZ-L BER');
fprintf('%s\n', repmat('-', 1, 98));

n_sc  = length(scenarios);
best_schemes   = cell(1, n_sc);
score_matrices = zeros(length(schemes), n_sc);

for sc = 1:n_sc
    p.SNR_dB      = scenarios(sc).SNR_dB;
    p.distance_m  = scenarios(sc).distance_m;
    p.fc_Hz       = 5000;
    p.num_paths   = 4;
    p.max_delay_s = 5e-3;
    p.multipath_k = scenarios(sc).multipath_k;
    p.doppler_v   = scenarios(sc).doppler_v;
    p.bw_fraction = 0.4;

    res = run_simulation(bits, schemes, p, fs, Tb);
    dec = decision_engine([res.metrics], priority);

    best_schemes{sc}      = dec.best_scheme;
    score_matrices(:, sc) = dec.score_values(:);

    % Find index of selected scheme
    sel_idx = find(strcmpi(schemes, dec.best_scheme), 1);
    sel_ber = res(sel_idx).metrics.BER;

    % Find empirical minimum BER scheme
    m_arr    = [res.metrics];
    all_bers = [m_arr.BER];
    [min_ber, min_idx] = min(all_bers);
    min_scheme = schemes{min_idx};

    % NRZ-L baseline BER (scheme index 1)
    nrzl_ber = res(1).metrics.BER;

    fprintf('%-20s | %-16s | %-8.3f | %-8.4f | %-16s | %-8.4f | %-8.4f\n', ...
        scenarios(sc).name, dec.best_scheme, max(dec.score_values), ...
        sel_ber, min_scheme, min_ber, nrzl_ber);
end

% ---------------------------------------------------------------
% Plot: Heatmap of scores across scenarios
% ---------------------------------------------------------------
figure('Name','Exp7: Adaptive Selection','NumberTitle','off', ...
       'Position',[100 80 1000 480],'Color','k');

ax1 = subplot(1,2,1);
imagesc(score_matrices);
colormap(ax1, parula);
cb = colorbar(ax1);
cb.Color = 'w';
set(ax1,'XTickLabel',{scenarios.name},'XTickLabelRotation',30, ...
    'YTickLabel',labels,'TickLabelInterpreter','none', ...
    'Color','[0.08 0.08 0.12]','XColor','w','YColor','w', ...
    'FontSize',10);
xlabel(ax1,'Channel Scenario','Color','w','FontSize',12);
ylabel(ax1,'Line-Coding Scheme','Color','w','FontSize',12);
title(ax1,'Decision Score Heatmap','Color','w','FontSize',13,'FontWeight','bold');

% Mark best scheme per scenario
for sc = 1:n_sc
    [~, best_row] = max(score_matrices(:, sc));
    hold(ax1,'on');
    plot(ax1, sc, best_row, 'w*', 'MarkerSize',14, 'LineWidth',2);
end

% Plot 2: Score bars for final scenario
ax2 = subplot(1,2,2);
sc_last = score_matrices(:, end);
barh(ax2, sc_last, 'FaceColor','#4DBBFF', 'EdgeColor','none');
set(ax2,'YTickLabel',labels,'YDir','reverse', ...
    'Color','[0.08 0.08 0.12]','XColor','w','YColor','w', ...
    'GridColor','[0.3 0.3 0.3]','GridAlpha',0.4);
grid(ax2,'on');
xlabel(ax2,'Composite Score','Color','w','FontSize',12);
title(ax2,sprintf('Extreme Channel\nBest: %s',best_schemes{end}), ...
    'Color','w','FontSize',13,'FontWeight','bold');

sgtitle('SignalForge — Adaptive Selection Intelligence', ...
    'Color','w','FontSize',14,'FontWeight','bold');
set(gcf,'Color','k');

res_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'results');
if ~exist(res_dir, 'dir'), mkdir(res_dir); end
save(fullfile(res_dir, 'exp7_adaptive.mat'), 'scenarios', 'score_matrices', ...
     'best_schemes', 'labels', 'schemes');
saveas(gcf, fullfile(res_dir, 'exp7_adaptive.png'));

% Save tabular comparison CSV
adaptive_tbl = table({scenarios.name}', best_schemes', ...
    'VariableNames', {'Scenario', 'SelectedScheme'});
writetable(adaptive_tbl, fullfile(res_dir, 'exp7_adaptive.csv'));

fprintf('\nResults saved to %s (.mat, .png, and .csv)\n', res_dir);
