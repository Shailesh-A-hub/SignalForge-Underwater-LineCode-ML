% EXPERIMENT 4–6: Bandwidth, DC Component & Sync Comparison
% =========================================================
% Static analysis of signal properties independent of the
% channel. Compares the six schemes under identical conditions.

close all;
addpath(genpath(fileparts(mfilename('fullpath'))));

fprintf('=== Experiments 4–6: Bandwidth / DC / Sync Comparison ===\n\n');

fs     = 48000;
Tb     = 1e-3;
N_bits = 500;
rng(10);
bits   = randi([0 1], 1, N_bits);

schemes = {'nrzl','nrzi','rz','manchester','ami','diff_manchester'};
labels  = {'NRZ-L','NRZ-I','RZ','Manchester','AMI','Diff. Man.'};
colors  = [0  114 189;
           217  83  25;
           237 177  32;
           119 172  48;
           162  20  47;
           126  47 142] / 255;

BW_vals    = zeros(1, length(schemes));
DC_vals    = zeros(1, length(schemes));
Sync_vals  = zeros(1, length(schemes));

for s = 1:length(schemes)
    tx = encode_linecode(bits, schemes{s}, Tb, fs, 1.0);
    % Simple decode (not via channel, just for metric completeness)
    rx = decode_linecode(tx, schemes{s}, Tb, fs);
    m  = analyse_linecode(bits, tx, tx, rx, schemes{s}, fs, Tb);
    BW_vals(s)   = m.bandwidth_hz;
    DC_vals(s)   = abs(m.dc_offset);
    Sync_vals(s) = m.transition_density;
end

% ---------------------------------------------------------------
% Plot 4: Bandwidth comparison
% ---------------------------------------------------------------
figure('Name','Exp4-6: Properties','NumberTitle','off', ...
       'Position',[50 50 1200 400],'Color','k');

subplot(1,3,1);
ax1 = gca;
bar(ax1, BW_vals, 'FaceColor','flat', 'CData', colors);
ax1.Color        = [0.08 0.08 0.12];
ax1.XColor       = 'w'; ax1.YColor = 'w';
ax1.GridColor    = [0.3 0.3 0.3]; ax1.GridAlpha = 0.4;
grid(ax1,'on');
set(ax1,'XTickLabel',labels,'XTickLabelRotation',30,'FontSize',10);
ylabel(ax1,'First-null Bandwidth (Hz)','Color','w');
title(ax1,'Exp 4 — Bandwidth','Color','w','FontWeight','bold');

subplot(1,3,2);
ax2 = gca;
bar(ax2, DC_vals, 'FaceColor','flat', 'CData', colors);
ax2.Color        = [0.08 0.08 0.12];
ax2.XColor       = 'w'; ax2.YColor = 'w';
ax2.GridColor    = [0.3 0.3 0.3]; ax2.GridAlpha = 0.4;
grid(ax2,'on');
set(ax2,'XTickLabel',labels,'XTickLabelRotation',30,'FontSize',10);
ylabel(ax2,'|DC Offset|','Color','w');
title(ax2,'Exp 5 — DC Component','Color','w','FontWeight','bold');

subplot(1,3,3);
ax3 = gca;
bar(ax3, Sync_vals, 'FaceColor','flat', 'CData', colors);
ax3.Color        = [0.08 0.08 0.12];
ax3.XColor       = 'w'; ax3.YColor = 'w';
ax3.GridColor    = [0.3 0.3 0.3]; ax3.GridAlpha = 0.4;
grid(ax3,'on');
set(ax3,'XTickLabel',labels,'XTickLabelRotation',30,'FontSize',10);
ylabel(ax3,'Transitions per Bit','Color','w');
title(ax3,'Exp 6 — Sync / Transition Density','Color','w','FontWeight','bold');

sgtitle('SignalForge — Signal Property Comparison', ...
    'Color','w','FontSize',14,'FontWeight','bold');
set(gcf,'Color','k');

% Print summary table
fprintf('\n%-20s %12s %12s %12s\n','Scheme','BW (Hz)','|DC|','Sync/bit');
fprintf('%s\n', repmat('-',1,60));
for s = 1:length(schemes)
    fprintf('%-20s %12.1f %12.4f %12.2f\n', ...
        labels{s}, BW_vals(s), DC_vals(s), Sync_vals(s));
end

res_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'results');
if ~exist(res_dir, 'dir'), mkdir(res_dir); end
save(fullfile(res_dir, 'exp456_properties.mat'), 'labels', 'BW_vals', 'DC_vals', 'Sync_vals');
saveas(gcf, fullfile(res_dir, 'exp456_properties.png'));
fprintf('\nResults saved to %s\n', res_dir);
