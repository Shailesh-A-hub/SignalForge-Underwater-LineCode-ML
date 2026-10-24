function benchmark_results = benchmark_ml_vs_simulation(N_test, rng_seed)
% BENCHMARK_ML_VS_SIMULATION
% =========================================================================
% Formal Verification Suite: ML Inference vs. Full Physical Simulation
%
% Empirically evaluates and proves:
%   1. Runtime latency: Physical simulation (Path A) vs. ML inference (Path B)
%   2. Preprocessing latency vs Core inference latency separation
%   3. Speedup factor (T_sim / T_ML)
%   4. Held-out accuracy against Oracle minimum-BER and SAW selectors
%   5. Objective performance penalty (Delta BER = BER_ML - BER_Oracle)
%   6. Nearest-neighbor vote fraction (heuristic posterior) vs empirical correctness
%
% Outputs publication figures and CSV logs to 'results/'.
% =========================================================================

    close all;
    base_dir = fileparts(fileparts(mfilename('fullpath')));
    if isempty(base_dir), base_dir = pwd; end
    addpath(genpath(base_dir));

    if nargin < 1 || isempty(N_test),   N_test   = 50;  end
    if nargin < 2 || isempty(rng_seed), rng_seed = 888; end

    fprintf('=========================================================================\n');
    fprintf('  SignalForge: ML vs. Simulation Rigorous Benchmarking Suite\n');
    fprintf('=========================================================================\n\n');

    % 1. Ensure trained model exists
    model_path = fullfile(base_dir, 'ml', 'trained_linecode_model.mat');
    if ~exist(model_path, 'file')
        fprintf('Training base model first...\n');
        train_ml_model([], [], model_path);
    end
    loaded = load(model_path, 'model');
    model  = loaded.model;

    % 2. Synthesize independent held-out evaluation scenarios
    fprintf('Generating %d independent held-out test scenarios (Seed %d)...\n', N_test, rng_seed);
    [dataset, X_test, y_saw_true, y_oracle_true] = generate_ml_dataset(N_test, rng_seed);

    % 3. Benchmark Path A: Physical Simulation Runtime (with warm-up run)
    fprintf('\nBenchmarking Path A (Full Physical Simulation + Metrics + SAW)...\n');
    fs = 48000; Tb = 1e-3; N_bits = 400;
    bits = randi([0 1], 1, N_bits);
    schemes = model.schemes;

    % Warm-up trial (discards initial JIT compilation overhead)
    dummy_ch = struct('SNR_dB', 15, 'distance_m', 200, 'fc_Hz', 5000, ...
                      'num_paths', 3, 'max_delay_s', 4e-3, 'multipath_k', 0.2, ...
                      'doppler_v', 0.0, 'bw_fraction', 0.4);
    res_dummy = run_simulation(bits, schemes, dummy_ch, fs, Tb);
    dec_dummy = decision_engine([res_dummy.metrics], 'balanced');

    t_sim_vec = zeros(N_test, 1);
    for i = 1:N_test
        ch_p = struct('SNR_dB', X_test(i, 1), ...
                      'distance_m', X_test(i, 4), ...
                      'fc_Hz', 5000, ...
                      'num_paths', 3, ...
                      'max_delay_s', 4e-3, ...
                      'multipath_k', X_test(i, 2), ...
                      'doppler_v', X_test(i, 3), ...
                      'bw_fraction', 0.4);
        prio_str = dataset(i).priority_name;

        tic;
        res = run_simulation(bits, schemes, ch_p, fs, Tb);
        dec = decision_engine([res.metrics], prio_str);
        t_sim_vec(i) = toc * 1000; % ms
    end
    mean_t_sim_ms = mean(t_sim_vec);
    std_t_sim_ms  = std(t_sim_vec);

    % 4. Benchmark Path B: ML Inference Runtime (Warm-up + Preprocessing vs Inference)
    fprintf('Benchmarking Path B (Feature Processing + ML Inference)...\n');
    % Warm-up ML inference
    pred_dummy = predict_linecode_ml(dummy_ch, 'balanced', model);

    t_preproc_vec = zeros(N_test, 1);
    t_infer_vec   = zeros(N_test, 1);
    y_pred_vec    = zeros(N_test, 1);
    conf_vec      = zeros(N_test, 1);
    P_prob_matrix = zeros(N_test, 6);

    for i = 1:N_test
        ch_p = struct('SNR_dB', X_test(i, 1), ...
                      'distance_m', X_test(i, 4), ...
                      'multipath_k', X_test(i, 2), ...
                      'doppler_v', X_test(i, 3));
        prio_str = dataset(i).priority_name;

        % Time Preprocessing (one-hot vector formation and scaling)
        tic;
        x_raw = X_test(i, :); % 9-D one-hot vector
        x_norm = (x_raw - model.mu_X) ./ model.sigma_X;
        t_preproc_vec(i) = toc * 1000; % ms

        % Time Core Model Inference
        tic;
        pred = predict_linecode_ml(ch_p, prio_str, model);
        t_infer_vec(i) = toc * 1000; % ms

        y_pred_vec(i) = pred.class_index;
        conf_vec(i)   = pred.confidence;
        P_prob_matrix(i, :) = pred.class_scores; % Full 1x6 probability vector
    end

    mean_t_preproc_ms = mean(t_preproc_vec);
    mean_t_infer_ms   = mean(t_infer_vec);
    mean_t_ml_total   = mean_t_preproc_ms + mean_t_infer_ms;
    std_t_ml_total    = std(t_preproc_vec + t_infer_vec);
    speedup           = mean_t_sim_ms / max(mean_t_ml_total, 1e-4);

    % 5. Objective Performance & Multi-Class Brier Score
    acc_vs_saw    = mean(y_pred_vec == y_saw_true) * 100;
    acc_vs_oracle = mean(y_pred_vec == y_oracle_true) * 100;

    % Multi-Class Brier Score (Brier 1950):
    % BS = (1/N) * sum_{i=1}^N sum_{k=1}^6 (P_ik - Y_ik)^2
    % Range [0, 2], where 0 represents perfect probabilistic forecasting
    Y_onehot_oracle = zeros(N_test, 6);
    Y_onehot_saw    = zeros(N_test, 6);
    for i = 1:N_test
        Y_onehot_oracle(i, y_oracle_true(i)) = 1.0;
        Y_onehot_saw(i, y_saw_true(i))       = 1.0;
    end
    brier_score_oracle = mean(sum((P_prob_matrix - Y_onehot_oracle).^2, 2));
    brier_score_saw    = mean(sum((P_prob_matrix - Y_onehot_saw).^2, 2));

    delta_ber_vec = zeros(N_test, 1);
    for i = 1:N_test
        bers = dataset(i).all_bers;
        chosen_ber = bers(y_pred_vec(i));
        oracle_ber = bers(y_oracle_true(i));
        delta_ber_vec(i) = max(0, chosen_ber - oracle_ber);
    end
    mean_delta_ber = mean(delta_ber_vec);
    zero_penalty_pct = mean(delta_ber_vec == 0) * 100;

    % Fixed baselines agreement with Oracle
    acc_nrzl_oracle = mean(y_oracle_true == 1) * 100;
    acc_man_oracle  = mean(y_oracle_true == 4) * 100;
    acc_ami_oracle  = mean(y_oracle_true == 5) * 100;

    % 6. Print Formal Findings
    fprintf('-------------------------------------------------------------------------\n');
    fprintf('  BENCHMARK VERIFICATION RESULTS (MEASURED, NOT CLAIMED)\n');
    fprintf('-------------------------------------------------------------------------\n');
    fprintf('  Simulation Latency (Path A):      %.2f ± %.2f ms\n', mean_t_sim_ms, std_t_sim_ms);
    fprintf('  ML Feature Preprocessing:         %.4f ms\n', mean_t_preproc_ms);
    fprintf('  ML Core Classifier Inference:     %.4f ms\n', mean_t_infer_ms);
    fprintf('  Total ML Latency (Path B):        %.4f ± %.4f ms\n', mean_t_ml_total, std_t_ml_total);
    fprintf('  --> EMPIRICALLY MEASURED SPEEDUP: %.1fx FASTER\n\n', speedup);

    fprintf('  Accuracy vs SAW Objective:        %.1f%%\n', acc_vs_saw);
    fprintf('  Accuracy vs Oracle Min-BER:       %.1f%%\n', acc_vs_oracle);
    fprintf('  Multi-Class Brier Score (Oracle): %.4f (Range [0, 2]; 0 = perfect)\n', brier_score_oracle);
    fprintf('  Multi-Class Brier Score (SAW):    %.4f (Range [0, 2]; 0 = perfect)\n', brier_score_saw);
    fprintf('  Zero-Penalty Decisions (Exact):   %.1f%% of test channels\n', zero_penalty_pct);
    fprintf('  Mean Objective Penalty (Delta BER): %.4f\n', mean_delta_ber);
    fprintf('-------------------------------------------------------------------------\n\n');

    % 7. Generate Publication Figure
    fig = figure('Name','SignalForge: ML Benchmarking & Trade-offs', ...
                 'Position',[60 50 1200 650], 'Color','k');

    % Panel 1: Execution Latency Comparison (Log Scale)
    ax1 = subplot(2, 2, 1);
    lat_vals = [mean_t_sim_ms, mean_t_ml_total, mean_t_infer_ms];
    lat_lbls = {'Physical Sim.', 'Total ML Path', 'Core Inference'};
    b1 = bar(ax1, lat_vals, 'FaceColor','#00BFFF', 'EdgeColor','none');
    b1.FaceColor = 'flat';
    b1.CData(1, :) = [0.9 0.4 0.2];
    b1.CData(2, :) = [0.1 0.7 0.9];
    b1.CData(3, :) = [0.2 0.8 0.4];
    set(ax1, 'YScale','log', 'Color','[0.08 0.08 0.12]', 'XColor','w', 'YColor','w', ...
        'XTick', 1:3, 'XTickLabel', lat_lbls, 'GridColor','[0.3 0.3 0.3]', 'GridAlpha',0.4);
    grid(ax1, 'on');
    ylabel(ax1, 'Latency (ms) [Log Scale]', 'Color','w', 'FontSize',10);
    title(ax1, sprintf('Latency: Sim vs ML (%.0fx Speedup)', speedup), ...
        'Color','w', 'FontSize',11, 'FontWeight','bold');
    for k = 1:3
        text(ax1, k, lat_vals(k)*1.3, sprintf('%.3f ms', lat_vals(k)), ...
            'HorizontalAlignment','center', 'Color','w', 'FontSize',9, 'FontWeight','bold');
    end

    % Panel 2: Oracle Match Rate vs Baselines
    ax2 = subplot(2, 2, 2);
    comp_vals = [acc_vs_oracle, acc_nrzl_oracle, acc_man_oracle, acc_ami_oracle];
    comp_lbls = {'ML Model', 'Fixed NRZ-L', 'Fixed Man.', 'Fixed AMI'};
    b2 = bar(ax2, comp_vals, 'FaceColor','#77AC30', 'EdgeColor','none');
    b2.FaceColor = 'flat';
    b2.CData(1, :) = [0.2 0.7 1.0];
    b2.CData(2, :) = [0.8 0.3 0.3];
    b2.CData(3, :) = [0.9 0.6 0.2];
    b2.CData(4, :) = [0.5 0.5 0.5];
    set(ax2, 'Color','[0.08 0.08 0.12]', 'XColor','w', 'YColor','w', ...
        'XTick', 1:4, 'XTickLabel', comp_lbls, 'GridColor','[0.3 0.3 0.3]', 'GridAlpha',0.4);
    grid(ax2, 'on'); ylim(ax2, [0 100]);
    ylabel(ax2, 'Oracle Match Rate (%)', 'Color','w', 'FontSize',10);
    title(ax2, 'Oracle Minimum-BER Agreement vs Baselines', 'Color','w', 'FontSize',11, 'FontWeight','bold');
    for k = 1:4
        text(ax2, k, comp_vals(k)+4, sprintf('%.1f%%', comp_vals(k)), ...
            'HorizontalAlignment','center', 'Color','w', 'FontSize',9, 'FontWeight','bold');
    end

    % Panel 3: Objective Penalty Distribution (Delta BER)
    ax3 = subplot(2, 2, 3);
    histogram(ax3, delta_ber_vec, 12, 'FaceColor','#00D2D3', 'EdgeColor','none');
    set(ax3, 'Color','[0.08 0.08 0.12]', 'XColor','w', 'YColor','w', ...
        'GridColor','[0.3 0.3 0.3]', 'GridAlpha',0.4);
    grid(ax3, 'on');
    xlabel(ax3, 'Objective Penalty (Delta BER = BER_ML - BER_Oracle)', 'Color','w', 'FontSize',10);
    ylabel(ax3, 'Scenario Count', 'Color','w', 'FontSize',10);
    title(ax3, sprintf('Delta BER Penalty Distribution (Zero Penalty: %.1f%%)', zero_penalty_pct), ...
        'Color','w', 'FontSize',11, 'FontWeight','bold');

    % Panel 4: Nearest-Neighbor Vote Fraction vs Empirical Accuracy
    ax4 = subplot(2, 2, 4);
    scatter(ax4, 1:N_test, conf_vec * 100, 35, y_pred_vec == y_oracle_true, 'filled');
    colormap(ax4, [0.85 0.3 0.3; 0.2 0.8 0.4]); % Red for mismatch, Green for match
    set(ax4, 'Color','[0.08 0.08 0.12]', 'XColor','w', 'YColor','w', ...
        'GridColor','[0.3 0.3 0.3]', 'GridAlpha',0.4);
    grid(ax4, 'on'); ylim(ax4, [30 100]);
    xlabel(ax4, 'Held-Out Scenario Index', 'Color','w', 'FontSize',10);
    ylabel(ax4, 'k-NN Vote Fraction (%)', 'Color','w', 'FontSize',10);
    title(ax4, 'k-NN Vote Fraction vs Empirical Match (Green=Match)', ...
        'Color','w', 'FontSize',11, 'FontWeight','bold');

    sgtitle('SignalForge — Empirical ML Verification & Trade-off Quantification', ...
        'Color','w', 'FontSize',13, 'FontWeight','bold');

    % 8. Save artifacts
    res_dir = fullfile(base_dir, 'results');
    if ~exist(res_dir, 'dir'), mkdir(res_dir); end
    saveas(fig, fullfile(res_dir, 'ml_benchmark_tradeoff.png'));
    save(fullfile(res_dir, 'ml_benchmark_tradeoff.mat'), ...
        'mean_t_sim_ms', 'mean_t_ml_total', 'speedup', ...
        'acc_vs_saw', 'acc_vs_oracle', 'mean_delta_ber', 'zero_penalty_pct', ...
        'brier_score_oracle', 'brier_score_saw');

    % Write CSV report
    bench_tbl = table((1:N_test)', t_sim_vec, (t_preproc_vec+t_infer_vec), ...
                      y_pred_vec, y_oracle_true, delta_ber_vec, conf_vec, ...
        'VariableNames', {'ScenarioID', 'SimTime_ms', 'MLTime_ms', ...
                          'PredictedCode', 'OracleCode', 'DeltaBER', 'Confidence'});
    writetable(bench_tbl, fullfile(res_dir, 'ml_benchmark_tradeoff.csv'));

    fprintf('Benchmark artifacts saved to %s (.png, .mat, .csv)\n\n', res_dir);

    benchmark_results = struct('sim_time_ms', mean_t_sim_ms, ...
                               'ml_time_ms', mean_t_ml_total, ...
                               'speedup', speedup, ...
                               'accuracy_saw', acc_vs_saw, ...
                               'accuracy_oracle', acc_vs_oracle, ...
                               'mean_delta_ber', mean_delta_ber, ...
                               'zero_penalty_pct', zero_penalty_pct);
end
