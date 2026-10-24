function SignalForgeGUI()
% SIGNALFORGE GUI — Interactive Dashboard for Underwater Acoustic
% Line-Code Selection Simulation
%
% Launch: >> SignalForgeGUI()
%
% Requires MATLAB R2019b or later (uifigure-based App).
% Adds subfolders to path automatically.

    addpath(genpath(fileparts(mfilename('fullpath'))));
    if ~exist('results','dir'), mkdir('results'); end

    % ---------------------------------------------------------------
    % Colour palette
    % ---------------------------------------------------------------
    CLR.bg       = [0.06  0.06  0.10];
    CLR.panel    = [0.10  0.10  0.15];
    CLR.card     = [0.13  0.13  0.20];
    CLR.accent   = [0.20  0.60  1.00];
    CLR.text     = [0.95  0.95  0.95];
    CLR.subtext  = [0.60  0.60  0.70];
    CLR.good     = [0.30  0.90  0.50];
    CLR.warn     = [1.00  0.75  0.20];
    CLR.bad      = [0.95  0.30  0.30];
    CLR.schemes  = [0.00 0.45 0.74;
                    0.85 0.33 0.10;
                    0.93 0.69 0.13;
                    0.47 0.67 0.19;
                    0.63 0.08 0.18;
                    0.49 0.18 0.56];

    SCHEME_NAMES  = {'nrzl','nrzi','rz','manchester','ami','diff_manchester'};
    SCHEME_LABELS = {'NRZ-L','NRZ-I','RZ','Manchester','AMI','Diff. Man.'};

    % ---------------------------------------------------------------
    % Main figure
    % ---------------------------------------------------------------
    fig = uifigure('Name','SignalForge — Underwater Acoustic Line-Code Simulator', ...
        'Position',[50 30 1600 900], ...
        'Color', CLR.bg, ...
        'Resize','off');

    % ---------------------------------------------------------------
    % LEFT PANEL — Controls
    % ---------------------------------------------------------------
    leftW  = 320;
    pLeft  = uipanel(fig, 'Position',[0 0 leftW 900], ...
        'BackgroundColor', CLR.panel, 'BorderType','none');

    % Title
    uilabel(pLeft,'Position',[10 860 300 35], ...
        'Text','⬡ SignalForge', ...
        'FontSize',22,'FontWeight','bold', ...
        'FontColor',[0.3 0.7 1.0], ...
        'BackgroundColor',CLR.panel);
    uilabel(pLeft,'Position',[10 840 300 20], ...
        'Text','Underwater Acoustic Channel Simulator', ...
        'FontSize',10,'FontColor',CLR.subtext, ...
        'BackgroundColor',CLR.panel);

    % Separator
    uipanel(pLeft,'Position',[10 833 300 2],'BackgroundColor',[0.2 0.4 0.7],'BorderType','none');

    % ---- Channel Parameters ----
    uilabel(pLeft,'Position',[10 810 300 20], ...
        'Text','CHANNEL PARAMETERS','FontSize',9,'FontWeight','bold', ...
        'FontColor',CLR.accent,'BackgroundColor',CLR.panel);

    ctrl = struct();

    % SNR
    [ctrl.snr_lbl, ctrl.snr_sl, ctrl.snr_val] = make_slider(pLeft, CLR, ...
        'SNR (dB)', 785, -5, 30, 20);

    % Distance
    [~, ctrl.dist_sl, ctrl.dist_val] = make_slider(pLeft, CLR, ...
        'Distance (m)', 745, 50, 2000, 300);

    % Multipath severity
    [~, ctrl.mp_sl, ctrl.mp_val] = make_slider(pLeft, CLR, ...
        'Multipath Severity', 705, 0, 1, 0.3);

    % Num multipath
    [~, ctrl.np_sl, ctrl.np_val] = make_slider(pLeft, CLR, ...
        'Num. Paths', 665, 1, 8, 3);

    % Doppler
    [~, ctrl.dop_sl, ctrl.dop_val] = make_slider(pLeft, CLR, ...
        'Doppler Velocity (m/s)', 625, 0, 10, 1);

    % Centre frequency
    [~, ctrl.fc_sl, ctrl.fc_val] = make_slider(pLeft, CLR, ...
        'Centre Freq (Hz)', 585, 1000, 10000, 5000);

    % BW fraction
    [~, ctrl.bw_sl, ctrl.bw_val] = make_slider(pLeft, CLR, ...
        'BW Fraction', 545, 0.1, 0.9, 0.4);

    % ---- Simulation Parameters ----
    uipanel(pLeft,'Position',[10 535 300 2],'BackgroundColor',[0.2 0.3 0.5],'BorderType','none');
    uilabel(pLeft,'Position',[10 518 300 18], ...
        'Text','SIMULATION','FontSize',9,'FontWeight','bold', ...
        'FontColor',CLR.accent,'BackgroundColor',CLR.panel);

    % Num bits
    [~, ctrl.nb_sl, ctrl.nb_val] = make_slider(pLeft, CLR, ...
        'Num Bits', 495, 100, 5000, 1000);

    % Bit rate
    [~, ctrl.br_sl, ctrl.br_val] = make_slider(pLeft, CLR, ...
        'Bit Rate (bps)', 455, 100, 5000, 1000);

    % Priority
    uilabel(pLeft,'Position',[10 430 120 18],'Text','Priority Mode', ...
        'FontSize',10,'FontColor',CLR.text,'BackgroundColor',CLR.panel);
    ctrl.priority = uidropdown(pLeft, 'Position',[10 405 200 28], ...
        'Items',{'balanced','low_ber','low_bandwidth','sync','dc_free'}, ...
        'Value','balanced', ...
        'BackgroundColor',CLR.card, 'FontColor',CLR.text);

    % Scheme checkboxes
    uipanel(pLeft,'Position',[10 393 300 2],'BackgroundColor',[0.2 0.3 0.5],'BorderType','none');
    uilabel(pLeft,'Position',[10 375 300 18],'Text','ACTIVE SCHEMES', ...
        'FontSize',9,'FontWeight','bold','FontColor',CLR.accent, ...
        'BackgroundColor',CLR.panel);

    ctrl.scheme_cb = gobjects(6,1);
    for k = 1:6
        ctrl.scheme_cb(k) = uicheckbox(pLeft, ...
            'Position',[10 360 - (k-1)*26 200 22], ...
            'Text', SCHEME_LABELS{k}, ...
            'Value', 1, ...
            'FontColor', CLR.schemes(k,:), ...
            'BackgroundColor', CLR.panel);
    end

    % Run button
    uipanel(pLeft,'Position',[10 185 300 2],'BackgroundColor',[0.2 0.3 0.5],'BorderType','none');
    btn_run = uibutton(pLeft,'Position',[10 150 300 42], ...
        'Text','▶  RUN SIMULATION', ...
        'BackgroundColor',[0.15 0.50 0.90], ...
        'FontColor','w','FontSize',14,'FontWeight','bold', ...
        'ButtonPushedFcn', @(~,~) run_all());

    btn_exp = uibutton(pLeft,'Position',[10 100 300 35], ...
        'Text','📊  Run All Experiments', ...
        'BackgroundColor',CLR.card,'FontColor',CLR.text,'FontSize',11, ...
        'ButtonPushedFcn', @(~,~) run_experiments());

    btn_save = uibutton(pLeft,'Position',[10 55 145 35], ...
        'Text','💾  Save Results', ...
        'BackgroundColor',CLR.card,'FontColor',CLR.text,'FontSize',11, ...
        'ButtonPushedFcn', @(~,~) save_results());

    btn_help = uibutton(pLeft,'Position',[165 55 145 35], ...
        'Text','ℹ  About', ...
        'BackgroundColor',CLR.card,'FontColor',CLR.text,'FontSize',11, ...
        'ButtonPushedFcn', @(~,~) show_about());

    % Status label
    ctrl.status = uilabel(pLeft,'Position',[10 10 300 40], ...
        'Text','Ready. Configure parameters and click RUN.', ...
        'FontSize',9,'FontColor',CLR.subtext, ...
        'BackgroundColor',CLR.panel, ...
        'WordWrap','on','VerticalAlignment','top');

    % ---------------------------------------------------------------
    % RIGHT AREA — Tab group with plots
    % ---------------------------------------------------------------
    tg = uitabgroup(fig, 'Position',[leftW+8 5 1265 890], ...
        'TabLocation','top');

    tab1 = uitab(tg,'Title','  Waveforms  ');
    tab2 = uitab(tg,'Title','  BER vs SNR  ');
    tab3 = uitab(tg,'Title','  BER vs Multipath  ');
    tab4 = uitab(tg,'Title','  Signal Properties  ');
    tab5 = uitab(tg,'Title','  PSD  ');
    tab6 = uitab(tg,'Title','  Decision Engine  ');

    set([tab1 tab2 tab3 tab4 tab5 tab6], 'BackgroundColor', CLR.bg);

    % ---- Tab 1: Waveform axes (6 rows) ----
    ax_wave = gobjects(6,1);
    h_wave  = 120;
    for k = 1:6
        ax_wave(k) = uiaxes(tab1, 'Position', [10 820-k*h_wave 1240 h_wave-5]);
        style_ax(ax_wave(k), CLR);
        ylabel(ax_wave(k), SCHEME_LABELS{k}, 'Color', CLR.schemes(k,:), ...
            'FontSize',9,'FontWeight','bold');
    end
    xlabel(ax_wave(6),'Time (s)','Color',CLR.text,'FontSize',10);

    % ---- Tab 2: BER vs SNR ----
    ax_ber_snr = uiaxes(tab2,'Position',[10 10 1240 860]);
    style_ax(ax_ber_snr, CLR);
    xlabel(ax_ber_snr,'SNR (dB)','Color',CLR.text,'FontSize',12);
    ylabel(ax_ber_snr,'BER','Color',CLR.text,'FontSize',12);
    title(ax_ber_snr,'BER vs SNR — UWAC Channel','Color',CLR.text, ...
        'FontSize',14,'FontWeight','bold');

    % ---- Tab 3: BER vs Multipath ----
    ax_ber_mp = uiaxes(tab3,'Position',[10 10 1240 860]);
    style_ax(ax_ber_mp, CLR);
    xlabel(ax_ber_mp,'Multipath Severity (0–1)','Color',CLR.text,'FontSize',12);
    ylabel(ax_ber_mp,'BER','Color',CLR.text,'FontSize',12);
    title(ax_ber_mp,'BER vs Multipath Severity','Color',CLR.text, ...
        'FontSize',14,'FontWeight','bold');

    % ---- Tab 4: Signal Properties ----
    ax_bw   = uiaxes(tab4,'Position',[10 480 600 370]);
    ax_dc   = uiaxes(tab4,'Position',[630 480 600 370]);
    ax_sync = uiaxes(tab4,'Position',[10 60 600 370]);
    ax_pwr  = uiaxes(tab4,'Position',[630 60 600 370]);
    for ax = [ax_bw ax_dc ax_sync ax_pwr], style_ax(ax, CLR); end

    % ---- Tab 5: PSD ----
    ax_psd = uiaxes(tab5,'Position',[10 10 1240 860]);
    style_ax(ax_psd, CLR);
    xlabel(ax_psd,'Frequency (Hz)','Color',CLR.text,'FontSize',12);
    ylabel(ax_psd,'PSD (dB)','Color',CLR.text,'FontSize',12);
    title(ax_psd,'Power Spectral Density','Color',CLR.text,'FontSize',14,'FontWeight','bold');

    % ---- Tab 6: Decision Engine ----
    ax_dec = uiaxes(tab6,'Position',[10 300 700 560]);
    style_ax(ax_dec, CLR);

    ctrl.dec_text = uitextarea(tab6,'Position',[720 300 530 560], ...
        'Value','Decision engine output will appear here after simulation.', ...
        'BackgroundColor',CLR.card,'FontColor',CLR.text,'FontSize',11, ...
        'Editable','off');

    ctrl.best_lbl = uilabel(tab6,'Position',[10 220 1240 70], ...
        'Text','Recommended Scheme: — ', ...
        'FontSize',26,'FontWeight','bold','FontColor',CLR.good, ...
        'BackgroundColor',CLR.bg,'HorizontalAlignment','center');

    ctrl.reasoning = uitextarea(tab6,'Position',[10 10 1240 205], ...
        'Value','','BackgroundColor',CLR.card,'FontColor',CLR.text, ...
        'FontSize',10,'Editable','off');

    % ---------------------------------------------------------------
    % Simulation state
    % ---------------------------------------------------------------
    sim_results = [];

    % ---------------------------------------------------------------
    % Callbacks
    % ---------------------------------------------------------------
    function run_all()
        set(ctrl.status,'Text','⏳ Running simulation...');
        drawnow;
        try
            % Collect parameters
            p = collect_params();
            active = arrayfun(@(cb) cb.Value, ctrl.scheme_cb);
            active_schemes = SCHEME_NAMES(logical(active));
            active_labels  = SCHEME_LABELS(logical(active));
            active_colors  = CLR.schemes(logical(active),:);

            if isempty(active_schemes)
                set(ctrl.status,'Text','⚠ Select at least one scheme.');
                return;
            end

            fs   = 48000;
            Tb   = 1 / p.bitrate;
            bits = randi([0 1], 1, p.nbits);

            % Core simulation
            res = run_simulation(bits, active_schemes, p, fs, Tb);
            sim_results = res;

            % Plot waveforms (Tab 1)
            t = (0:length(res(1).tx_signal)-1) / fs;
            t_show = t(1:min(end, round(50*fs*Tb)));  % show first 50 bits
            for k = 1:length(active_schemes)
                cla(ax_wave(k));
                idx_show = 1:length(t_show);
                plot(ax_wave(k), t_show, res(k).tx_signal(idx_show), ...
                    'Color', active_colors(k,:), 'LineWidth', 1.4);
                hold(ax_wave(k),'on');
                plot(ax_wave(k), t_show, res(k).rx_signal(idx_show), ...
                    'Color', [active_colors(k,:)*0.7, 0.5], 'LineWidth', 0.8);
                hold(ax_wave(k),'off');
                ylabel(ax_wave(k), active_labels{k}, ...
                    'Color', active_colors(k,:),'FontSize',9,'FontWeight','bold');
                ax_wave(k).XLim = [t_show(1) t_show(end)];
            end
            % Clear unused axes
            for k = length(active_schemes)+1:6
                cla(ax_wave(k));
            end

            % Plot BER vs SNR (Tab 2)
            plot_ber_vs_snr(p, bits, active_schemes, active_labels, active_colors, fs, Tb);

            % Plot BER vs Multipath (Tab 3)
            plot_ber_vs_mp(p, bits, active_schemes, active_labels, active_colors, fs, Tb);

            % Plot properties (Tab 4)
            plot_properties(res, active_labels, active_colors, CLR);

            % Plot PSD (Tab 5)
            plot_psd(res, active_labels, active_colors, fs);

            % Decision Engine (Tab 6)
            dec = decision_engine([res.metrics], ctrl.priority.Value);
            plot_decision(dec, active_labels, active_colors, active_schemes, p);

            set(ctrl.status,'Text',sprintf('✅ Done. Best: %s', dec.best_scheme));
        catch ME
            set(ctrl.status,'Text',['❌ Error: ' ME.message]);
            rethrow(ME);
        end
    end

    function p = collect_params()
        p.SNR_dB      = ctrl.snr_sl.Value;
        p.distance_m  = ctrl.dist_sl.Value;
        p.multipath_k = ctrl.mp_sl.Value;
        p.num_paths   = round(ctrl.np_sl.Value);
        p.doppler_v   = ctrl.dop_sl.Value;
        p.fc_Hz       = ctrl.fc_sl.Value;
        p.bw_fraction = ctrl.bw_sl.Value;
        p.max_delay_s = 5e-3;
        p.nbits       = round(ctrl.nb_sl.Value);
        p.bitrate     = ctrl.br_sl.Value;
    end

    function plot_ber_vs_snr(base_p, bits, active_sch, act_lbl, act_clr, fs, Tb)
        snr_vec = -5:2:28;
        cla(ax_ber_snr); hold(ax_ber_snr,'on'); grid(ax_ber_snr,'on');
        for s = 1:length(active_sch)
            bers = zeros(1,length(snr_vec));
            for q = 1:length(snr_vec)
                pp = base_p; pp.SNR_dB = snr_vec(q);
                r = run_simulation(bits, active_sch(s), pp, fs, Tb);
                bers(q) = r(1).metrics.BER;
            end
            semilogy(ax_ber_snr, snr_vec, max(bers,1e-5), ...
                'Color', act_clr(s,:), 'LineWidth',2, ...
                'Marker','o','MarkerSize',5,'DisplayName', act_lbl{s});
        end
        legend(ax_ber_snr,'Location','southwest','TextColor','w', ...
            'Color',CLR.card,'EdgeColor',[0.3 0.3 0.4],'FontSize',10);
        ax_ber_snr.YScale = 'log';
        ax_ber_snr.YLim   = [1e-5 1];
    end

    function plot_ber_vs_mp(base_p, bits, active_sch, act_lbl, act_clr, fs, Tb)
        mp_vec = 0:0.1:1;
        cla(ax_ber_mp); hold(ax_ber_mp,'on'); grid(ax_ber_mp,'on');
        for s = 1:length(active_sch)
            bers = zeros(1,length(mp_vec));
            for q = 1:length(mp_vec)
                pp = base_p; pp.multipath_k = mp_vec(q);
                r = run_simulation(bits, active_sch(s), pp, fs, Tb);
                bers(q) = r(1).metrics.BER;
            end
            semilogy(ax_ber_mp, mp_vec, max(bers,1e-5), ...
                'Color', act_clr(s,:), 'LineWidth',2, ...
                'Marker','s','MarkerSize',5,'DisplayName', act_lbl{s});
        end
        legend(ax_ber_mp,'Location','northwest','TextColor','w', ...
            'Color',CLR.card,'EdgeColor',[0.3 0.3 0.4],'FontSize',10);
        ax_ber_mp.YScale = 'log';
        ax_ber_mp.YLim   = [1e-5 1];
    end

    function plot_properties(res, act_lbl, act_clr, C)
        n = length(res);
        bw_v   = arrayfun(@(r) r.metrics.bandwidth_hz, res);
        dc_v   = arrayfun(@(r) abs(r.metrics.dc_offset), res);
        sync_v = arrayfun(@(r) r.metrics.transition_density, res);
        pwr_v  = arrayfun(@(r) r.metrics.power_dBm, res);

        function bar_plot(ax, vals, lbl, ttl, unit)
            cla(ax); hold(ax,'on'); grid(ax,'on');
            for i = 1:length(vals)
                bar(ax, i, vals(i), 'FaceColor', act_clr(i,:), ...
                    'EdgeColor','none','BarWidth',0.6);
            end
            set(ax,'XTick',1:n,'XTickLabel',act_lbl,'XTickLabelRotation',25);
            ylabel(ax, unit, 'Color',C.text,'FontSize',10);
            title(ax, ttl,'Color',C.text,'FontSize',12,'FontWeight','bold');
        end

        bar_plot(ax_bw,   bw_v,   act_lbl, 'Bandwidth', 'Hz');
        bar_plot(ax_dc,   dc_v,   act_lbl, 'DC Component', '|DC|');
        bar_plot(ax_sync, sync_v, act_lbl, 'Sync (Transition Density)', 'Trans/bit');
        bar_plot(ax_pwr,  pwr_v,  act_lbl, 'Signal Power', 'dBm');
    end

    function plot_psd(res, act_lbl, act_clr, fs)
        cla(ax_psd); hold(ax_psd,'on'); grid(ax_psd,'on');
        for s = 1:length(res)
            m = res(s).metrics;
            f  = m.psd_f;
            psd = m.psd_mag;
            % Smooth for display
            if length(psd) > 50
                psd_s = smoothdata(psd,'gaussian',20);
            else
                psd_s = psd;
            end
            plot(ax_psd, f/1e3, psd_s, 'Color', act_clr(s,:), ...
                'LineWidth', 1.8, 'DisplayName', act_lbl{s});
        end
        legend(ax_psd,'TextColor','w','Color',CLR.card, ...
            'EdgeColor',[0.3 0.3 0.4],'FontSize',10);
        xlabel(ax_psd,'Frequency (kHz)','Color',CLR.text,'FontSize',12);
        ax_psd.XLim = [0 min(fs/2000, 20)];
        ax_psd.YLim = [-80 0];
    end

    function plot_decision(dec, act_lbl, act_clr, active_sch, ch_params)
        % Score bar
        scores = dec.score_values;
        cla(ax_dec); hold(ax_dec,'on'); grid(ax_dec,'on');
        n = length(scores);
        for i = 1:n
            c = act_clr(i,:);
            if strcmp(active_sch{i}, dec.best_scheme)
                c = CLR.good;  % highlight winner
            end
            barh(ax_dec, i, scores(i), 'FaceColor', c, 'EdgeColor','none','BarWidth',0.6);
        end
        set(ax_dec,'YTick',1:n,'YTickLabel',act_lbl,'YDir','reverse', ...
            'FontSize',11);
        xlabel(ax_dec,'Composite Score','Color',CLR.text,'FontSize',12);
        title(ax_dec,sprintf('Decision Scores — Priority: %s',dec.priority), ...
            'Color',CLR.text,'FontSize',13,'FontWeight','bold');
        ax_dec.XLim = [0 1];

        % Query ML model
        ml_txt = '';
        if nargin >= 5 && ~isempty(ch_params)
            try
                ml_pred = predict_linecode_ml(ch_params, dec.priority);
                ml_txt = sprintf('\n✦  ML Model Prediction:  %s  (Confidence: %.1f%%)  ✦', ...
                    ml_pred.predicted_label, ml_pred.confidence * 100);
            catch
                ml_txt = '';
            end
        end

        % Best label
        best_str = upper(strrep(dec.best_scheme,'_',' '));
        if isempty(ml_txt)
            set(ctrl.best_lbl,'Text', ...
                sprintf('✦  SAW Selected:  %s  ✦', best_str));
        else
            set(ctrl.best_lbl,'Text', ...
                sprintf('✦  SAW: %s  |  ML: %s (%.0f%%)  ✦', ...
                    best_str, ml_pred.predicted_label, ml_pred.confidence*100));
        end

        % Reasoning text
        set(ctrl.dec_text,'Value', ...
            strsplit(dec.reasoning, '\n'));

        % Full reasoning
        reason_lines = {sprintf('RANKING (best → worst):'), ...
             strjoin(dec.ranking, '  >  '), ...
             '', ...
             'SCORE TABLE:', ...
             sprintf('%-20s  %s','Scheme','Score'), ...
             repmat('-',1,35)};
        for k = 1:n
            reason_lines{end+1} = sprintf('%-20s  %.4f', active_sch{k}, scores(k));
        end
        if ~isempty(ml_txt)
            reason_lines{end+1} = '';
            reason_lines{end+1} = 'MACHINE LEARNING CLASSIFIER INFERENCE:';
            reason_lines{end+1} = sprintf('Predicted Scheme: %s', ml_pred.predicted_label);
            reason_lines{end+1} = sprintf('Confidence:       %.1f%%', ml_pred.confidence * 100);
            reason_lines{end+1} = sprintf('Agreement with SAW Engine: %s', ...
                char(string(strcmpi(ml_pred.predicted_scheme, dec.best_scheme))));
        end
        set(ctrl.reasoning, 'Value', reason_lines);
    end

    function run_experiments()
        choice = uiconfirm(fig, ...
            'This will run all 7 experiments (may take 2–5 minutes). Continue?', ...
            'Run Experiments', 'Options',{'Yes','Cancel'}, ...
            'DefaultOption',1,'CancelOption',2,'Icon','question');
        if strcmp(choice,'Cancel'), return; end
        set(ctrl.status,'Text','⏳ Running experiments...');
        drawnow;
        try
            run('experiments/exp1_ber_vs_snr.m');
            run('experiments/exp2_ber_vs_multipath.m');
            run('experiments/exp3_ber_vs_doppler.m');
            run('experiments/exp456_properties.m');
            run('experiments/exp7_adaptive.m');
            set(ctrl.status,'Text','✅ All experiments complete. See results/ folder.');
        catch ME
            set(ctrl.status,'Text',['❌ Exp error: ' ME.message]);
        end
    end

    function save_results()
        if isempty(sim_results)
            set(ctrl.status,'Text','⚠ Run simulation first.');
            return;
        end
        fname = fullfile('results', sprintf('run_%s.mat', ...
            datestr(now,'yyyymmdd_HHMMSS')));
        save(fname,'sim_results');
        set(ctrl.status,'Text',['💾 Saved: ' fname]);
    end

    function show_about()
        msg = sprintf(['SignalForge v1.0\n\n' ...
            'Software-based simulation and intelligent\n' ...
            'line-code selection framework for underwater\n' ...
            'acoustic communication channels.\n\n' ...
            'Six line codes: NRZ-L, NRZ-I, RZ,\n' ...
            'Manchester, AMI, Differential Manchester\n\n' ...
            'Channel: Thorp attenuation + spreading loss +\n' ...
            'multipath (tap-delay) + Doppler + bandwidth filter\n\n' ...
            'Decision engine: Multi-objective weighted scoring\n\n' ...
            'DCS Group Project — 2026-27']);
        uialert(fig, msg, 'About SignalForge', 'Icon','info');
    end

end  % SignalForgeGUI


% ---------------------------------------------------------------
% Helper: create a slider row
% ---------------------------------------------------------------
function [lbl, sl, val_lbl] = make_slider(parent, CLR, name, y, mn, mx, def)
    lbl = uilabel(parent,'Position',[10 y 160 18],'Text',name, ...
        'FontSize',9.5,'FontColor',CLR.text,'BackgroundColor',CLR.panel);
    val_lbl = uilabel(parent,'Position',[240 y 70 18], ...
        'Text',sprintf('%.2g', def),'FontSize',9.5, ...
        'FontColor',CLR.accent,'BackgroundColor',CLR.panel, ...
        'HorizontalAlignment','right');
    sl = uislider(parent,'Position',[10 y-14 300 3], ...
        'Limits',[mn mx],'Value',def, ...
        'MajorTicksMode','none','MinorTicksMode','none', ...
        'FontColor',CLR.text,'BackgroundColor',CLR.panel);
    sl.ValueChangedFcn = @(src,~) set(val_lbl,'Text',sprintf('%.4g',src.Value));
end


% ---------------------------------------------------------------
% Helper: style a uiaxes with dark theme
% ---------------------------------------------------------------
function style_ax(ax, CLR)
    ax.BackgroundColor = CLR.card;
    ax.XColor          = CLR.text;
    ax.YColor          = CLR.text;
    ax.GridColor       = [0.25 0.25 0.32];
    ax.GridAlpha       = 0.5;
    ax.FontSize        = 10;
    grid(ax,'on');
    box(ax,'on');
end
