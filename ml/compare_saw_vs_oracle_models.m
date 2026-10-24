function comp_results = compare_saw_vs_oracle_models(N_train, N_test, train_seed, test_seed)
% COMPARE_SAW_VS_ORACLE_MODELS
% =========================================================================
% Trains the Minimum-BER Oracle Predictor and SAW Multi-Criteria Imitator
% separately, verifies dataset independence, and rigorously compares them
% on an independent held-out test dataset.
%
% Objectives Compared:
%   1. Oracle Minimum-BER Predictor:
%      Trained on y_oracle (empirically best BER, tie-broken by bandwidth/DC)
%   2. SAW Multi-Criteria Imitator:
%      Trained on y_saw (composite ranking balancing BER, bandwidth, DC, sync)
%
% Outputs:
%   - Concordance rate between models
%   - BER penalty (Delta BER) relative to empirical lower bound
%   - Priority-driven constraint adaptation analysis
%   - Publication-quality comparison figures in 'results/'
% =========================================================================

    close all;
    base_dir = fileparts(fileparts(mfilename('fullpath')));
    if isempty(base_dir), base_dir = pwd; end
    addpath(genpath(base_dir));

    if nargin < 1 || isempty(N_train),    N_train    = 120; end
    if nargin < 2 || isempty(N_test),     N_test     = 60;  end
    if nargin < 3 || isempty(train_seed), train_seed = 42;  end
    if nargin < 4 || isempty(test_seed),  test_seed  = 999; end

    fprintf('=========================================================================\n');
    fprintf('  SignalForge: Dual-Model Training & Comparative Analysis\n');
    fprintf('  (Oracle Minimum-BER Predictor vs. SAW Multi-Criteria Imitator)\n');
    fprintf('=========================================================================\n\n');

    % ---------------------------------------------------------------------
    % Step 1: Generate Training Dataset
    % ---------------------------------------------------------------------
    fprintf('[Step 1/5] Synthesizing Shared Training Dataset (%d scenarios, Seed %d)...\n', ...
        N_train, train_seed);
    [train_dataset, X_train, y_saw_train, y_oracle_train] = ...
        generate_ml_dataset(N_train, train_seed);

    % ---------------------------------------------------------------------
    % Step 2: Train Model A (Oracle Min-BER Predictor)
    % ---------------------------------------------------------------------
    fprintf('[Step 2/5] Training Model A: Oracle Minimum-BER Predictor...\n');
    oracle_path = fullfile(base_dir, 'ml', 'trained_model_oracle.mat');
    model_oracle = train_ml_model(X_train, y_oracle_train, oracle_path, 'oracle');

    % ---------------------------------------------------------------------
    % Step 3: Train Model B: SAW Multi-Criteria Imitator
    % ---------------------------------------------------------------------
    fprintf('[Step 3/5] Training Model B: SAW Multi-Criteria Imitator...\n');
    saw_path = fullfile(base_dir, 'ml', 'trained_model_saw.mat');
    model_saw = train_ml_model(X_train, y_saw_train, saw_path, 'saw');

    % ---------------------------------------------------------------------
    % Step 4: Synthesize Independent Held-Out Test Dataset
    % ---------------------------------------------------------------------
    fprintf('[Step 4/5] Synthesizing Independent Test Dataset (%d scenarios, Seed %d)...\n', ...
        N_test, test_seed);
    [test_dataset, X_test, y_saw_test, y_oracle_test] = ...
        generate_ml_dataset(N_test, test_seed);

    % Verify Dataset Independence: compute minimum distance in continuous feature space
    % Features 1:4 are SNR, multipath, Doppler, distance
    min_dist_to_train = inf;
    for i = 1:N_test
        diffs = X_train(:, 1:4) - X_test(i, 1:4);
        dists = sqrt(sum(diffs.^2, 2));
        min_dist_to_train = min(min_dist_to_train, min(dists));
    end
    fprintf('  --> Dataset Independence Check: Minimum distance between test and train points: %.4f\n', ...
        min_dist_to_train);
    if min_dist_to_train > 0.1
        fprintf('  --> PASS: Training and test scenarios are strictly decoupled and non-overlapping.\n\n');
    else
        fprintf('  --> WARNING: Potential scenario proximity between training and test sets.\n\n');
    end

    % ---------------------------------------------------------------------
    % Step 5: Comparative Evaluation on Held-Out Test Set
    % ---------------------------------------------------------------------
    fprintf('[Step 5/5] Evaluating Both Models on Held-Out Test Scenarios...\n');
    pred_oracle_idx = zeros(N_test, 1);
    pred_saw_idx    = zeros(N_test, 1);
    vote_oracle     = zeros(N_test, 1);
    vote_saw        = zeros(N_test, 1);

    ber_oracle_model = zeros(N_test, 1);
    ber_saw_model    = zeros(N_test, 1);
    ber_true_oracle  = zeros(N_test, 1);

    for i = 1:N_test
        ch_p = struct('SNR_dB', X_test(i, 1), ...
                      'multipath_k', X_test(i, 2), ...
                      'doppler_v', X_test(i, 3), ...
                      'distance_m', X_test(i, 4));
        prio_str = test_dataset(i).priority_name;

        % Inference with Model A (Oracle)
        p_ora = predict_linecode_ml(ch_p, prio_str, model_oracle);
        pred_oracle_idx(i) = p_ora.class_index;
        vote_oracle(i)     = p_ora.confidence;

        % Inference with Model B (SAW)
        p_saw = predict_linecode_ml(ch_p, prio_str, model_saw);
        pred_saw_idx(i) = p_saw.class_index;
        vote_saw(i)     = p_saw.confidence;

        % Measure empirical BER under chosen schemes
        bers = test_dataset(i).all_bers;
        ber_oracle_model(i) = bers(pred_oracle_idx(i));
        ber_saw_model(i)    = bers(pred_saw_idx(i));
        ber_true_oracle(i)  = bers(y_oracle_test(i));
    end

    % Metrics
    concordance_pct = mean(pred_oracle_idx == pred_saw_idx) * 100;
    acc_ora_vs_oracle_target = mean(pred_oracle_idx == y_oracle_test) * 100;
    acc_saw_vs_saw_target    = mean(pred_saw_idx    == y_saw_test) * 100;
    acc_saw_vs_oracle_target = mean(pred_saw_idx    == y_oracle_test) * 100;

    delta_ber_oracle = mean(ber_oracle_model - ber_true_oracle);
    delta_ber_saw    = mean(ber_saw_model    - ber_true_oracle);

    mean_ber_true_oracle = mean(ber_true_oracle);
    mean_ber_ora_model   = mean(ber_oracle_model);
    mean_ber_saw_model   = mean(ber_saw_model);

    % Fixed baselines against Oracle target
    base_nrzl_ber = mean(cellfun(@(d) d(1), {test_dataset.all_bers}));
    base_man_ber  = mean(cellfun(@(d) d(4), {test_dataset.all_bers}));
    base_ami_ber  = mean(cellfun(@(d) d(5), {test_dataset.all_bers}));

    fprintf('=========================================================================\n');
    fprintf('  EXPERIMENTAL COMPARISON RESULTS (HELD-OUT TEST SET, N = %d)\n', N_test);
    fprintf('=========================================================================\n');
    fprintf('  Model Concordance (Mutual Agreement): %.1f%%\n\n', concordance_pct);
    fprintf('  Model A (Oracle Min-BER Predictor):\n');
    fprintf('    Accuracy vs True Oracle Target:     %.1f%%\n', acc_ora_vs_oracle_target);
    fprintf('    Mean Achieved BER:                  %.5f\n', mean_ber_ora_model);
    fprintf('    Mean Delta BER Penalty:             %.5f\n\n', delta_ber_oracle);

    fprintf('  Model B (SAW Multi-Criteria Imitator):\n');
    fprintf('    Accuracy vs True SAW Target:        %.1f%%\n', acc_saw_vs_saw_target);
    fprintf('    Agreement with Oracle Min-BER:      %.1f%%\n', acc_saw_vs_oracle_target);
    fprintf('    Mean Achieved BER:                  %.5f\n', mean_ber_saw_model);
    fprintf('    Mean Delta BER Penalty:             %.5f\n\n', delta_ber_saw);

    fprintf('  Reference Baselines:\n');
    fprintf('    Theoretical Lower Bound (Oracle):   %.5f BER\n', mean_ber_true_oracle);
    fprintf('    Fixed NRZ-L Baseline BER:           %.5f\n', base_nrzl_ber);
    fprintf('    Fixed Manchester Baseline BER:      %.5f\n', base_man_ber);
    fprintf('    Fixed AMI Baseline BER:             %.5f\n', base_ami_ber);
    fprintf('=========================================================================\n\n');

    % ---------------------------------------------------------------------
    % Generate Publication Comparison Figure
    % ---------------------------------------------------------------------
    fig = figure('Name','SignalForge: Oracle vs SAW Model Comparison', ...
                 'Position',[50 50 1200 680], 'Color','k');

    % Subplot 1: Confusion / Concordance Matrix between Oracle Model and SAW Model
    ax1 = subplot(2, 2, 1);
    conf_dual = zeros(6, 6);
    for i = 1:N_test
        conf_dual(pred_oracle_idx(i), pred_saw_idx(i)) = ...
            conf_dual(pred_oracle_idx(i), pred_saw_idx(i)) + 1;
    end
    imagesc(conf_dual);
    colormap(ax1, parula);
    cb = colorbar(ax1); cb.Color = 'w';
    set(ax1, 'Color','[0.08 0.08 0.12]', 'XColor','w', 'YColor','w', ...
        'XTick', 1:6, 'XTickLabel', model_oracle.labels, 'XTickLabelRotation', 30, ...
        'YTick', 1:6, 'YTickLabel', model_oracle.labels, 'FontSize', 9);
    xlabel(ax1, 'Model B: SAW Selection', 'Color','w', 'FontSize', 10, 'FontWeight','bold');
    ylabel(ax1, 'Model A: Oracle Selection', 'Color','w', 'FontSize', 10, 'FontWeight','bold');
    title(ax1, sprintf('Model Concordance Matrix (Agreement: %.1f%%)', concordance_pct), ...
        'Color','w', 'FontSize', 11, 'FontWeight','bold');

    % Subplot 2: BER Comparison across Models and Fixed Baselines
    ax2 = subplot(2, 2, 2);
    ber_bars = [mean_ber_true_oracle, mean_ber_ora_model, mean_ber_saw_model, ...
                base_nrzl_ber, base_man_ber, base_ami_ber];
    ber_lbls = {'True Oracle', 'Oracle Model', 'SAW Model', 'Fixed NRZ-L', 'Fixed Man.', 'Fixed AMI'};
    b2 = bar(ax2, ber_bars, 'FaceColor','#00BFFF', 'EdgeColor','none');
    b2.FaceColor = 'flat';
    b2.CData(1, :) = [0.2 0.8 0.4]; % Green
    b2.CData(2, :) = [0.1 0.7 0.9]; % Cyan
    b2.CData(3, :) = [0.9 0.6 0.2]; % Orange
    b2.CData(4, :) = [0.8 0.3 0.3]; % Red
    b2.CData(5, :) = [0.7 0.3 0.7]; % Purple
    b2.CData(6, :) = [0.5 0.5 0.5]; % Gray
    set(ax2, 'Color','[0.08 0.08 0.12]', 'XColor','w', 'YColor','w', ...
        'XTick', 1:6, 'XTickLabel', ber_lbls, 'XTickLabelRotation', 25, ...
        'GridColor','[0.3 0.3 0.3]', 'GridAlpha',0.4);
    grid(ax2, 'on');
    ylabel(ax2, 'Mean Measured BER', 'Color','w', 'FontSize', 10);
    title(ax2, 'Mean BER: ML Models vs Fixed Baselines', 'Color','w', 'FontSize', 11, 'FontWeight','bold');
    for k = 1:6
        text(ax2, k, ber_bars(k) + max(ber_bars)*0.03, sprintf('%.4f', ber_bars(k)), ...
            'HorizontalAlignment','center', 'Color','w', 'FontSize', 8, 'FontWeight','bold');
    end

    % Subplot 3: Priority Sensitivity (Selection under 'sync' vs 'low_bandwidth')
    ax3 = subplot(2, 2, 3);
    prio_sync_idx = find(strcmp({test_dataset.priority_name}, 'sync'));
    prio_bw_idx   = find(strcmp({test_dataset.priority_name}, 'low_bandwidth'));

    man_under_sync_saw = mean(ismember(pred_saw_idx(prio_sync_idx), [4 6])) * 100;
    man_under_sync_ora = mean(ismember(pred_oracle_idx(prio_sync_idx), [4 6])) * 100;

    nrz_under_bw_saw   = mean(ismember(pred_saw_idx(prio_bw_idx), [1 2 5])) * 100;
    nrz_under_bw_ora   = mean(ismember(pred_oracle_idx(prio_bw_idx), [1 2 5])) * 100;

    sens_data = [man_under_sync_ora, man_under_sync_saw; ...
                 nrz_under_bw_ora,   nrz_under_bw_saw];
    b3 = bar(ax3, sens_data, 'EdgeColor','none');
    b3(1).FaceColor = [0.1 0.7 0.9]; % Oracle Model
    b3(2).FaceColor = [0.9 0.6 0.2]; % SAW Model
    set(ax3, 'Color','[0.08 0.08 0.12]', 'XColor','w', 'YColor','w', ...
        'XTick', 1:2, 'XTickLabel', {'Sync Priority -> Manchester', 'Low-BW Priority -> NRZ/AMI'}, ...
        'GridColor','[0.3 0.3 0.3]', 'GridAlpha',0.4);
    grid(ax3, 'on'); ylim(ax3, [0 115]);
    ylabel(ax3, 'Selection Rate (%)', 'Color','w', 'FontSize', 10);
    legend(ax3, {'Model A (Oracle Min-BER)', 'Model B (SAW Multi-Criteria)'}, ...
        'TextColor','w', 'Color','[0.15 0.15 0.2]', 'EdgeColor','none', 'Location','NorthWest');
    title(ax3, 'Priority Adaptation: Multi-Criteria vs Pure BER', 'Color','w', 'FontSize', 11, 'FontWeight','bold');

    % Subplot 4: k-NN Vote Fraction Distribution (Uncalibrated Heuristic Posteriors)
    ax4 = subplot(2, 2, 4);
    histogram(ax4, vote_oracle * 100, 10, 'FaceColor',[0.1 0.7 0.9], 'FaceAlpha', 0.6, 'EdgeColor','none');
    hold(ax4, 'on');
    histogram(ax4, vote_saw * 100, 10, 'FaceColor',[0.9 0.6 0.2], 'FaceAlpha', 0.6, 'EdgeColor','none');
    hold(ax4, 'off');
    set(ax4, 'Color','[0.08 0.08 0.12]', 'XColor','w', 'YColor','w', ...
        'GridColor','[0.3 0.3 0.3]', 'GridAlpha',0.4);
    grid(ax4, 'on');
    xlabel(ax4, 'k-NN Vote Fraction (%) [Heuristic, Uncalibrated]', 'Color','w', 'FontSize', 10);
    ylabel(ax4, 'Scenario Count', 'Color','w', 'FontSize', 10);
    legend(ax4, {'Oracle Model', 'SAW Model'}, 'TextColor','w', ...
        'Color','[0.15 0.15 0.2]', 'EdgeColor','none');
    title(ax4, 'Vote Fraction Distribution Across Test Scenarios', 'Color','w', 'FontSize', 11, 'FontWeight','bold');

    sgtitle('SignalForge — Empirical Comparison: Oracle Min-BER vs. SAW Multi-Criteria Models', ...
        'Color','w', 'FontSize', 13, 'FontWeight','bold');

    % Save artifacts
    res_dir = fullfile(base_dir, 'results');
    if ~exist(res_dir, 'dir'), mkdir(res_dir); end

    saveas(fig, fullfile(res_dir, 'model_comparison_saw_vs_oracle.png'));
    save(fullfile(res_dir, 'model_comparison_saw_vs_oracle.mat'), ...
        'concordance_pct', 'acc_ora_vs_oracle_target', 'acc_saw_vs_saw_target', ...
        'acc_saw_vs_oracle_target', 'mean_ber_true_oracle', 'mean_ber_ora_model', ...
        'mean_ber_saw_model', 'delta_ber_oracle', 'delta_ber_saw', ...
        'min_dist_to_train');

    % CSV table
    comp_tbl = table((1:N_test)', pred_oracle_idx, pred_saw_idx, y_oracle_test, y_saw_test, ...
                     ber_oracle_model, ber_saw_model, ber_true_oracle, vote_oracle, vote_saw, ...
        'VariableNames', {'ScenarioID', 'PredOracleCode', 'PredSawCode', ...
                          'TrueOracleCode', 'TrueSawCode', ...
                          'BER_OracleModel', 'BER_SawModel', 'BER_TrueOracle', ...
                          'VoteOracle', 'VoteSaw'});
    writetable(comp_tbl, fullfile(res_dir, 'model_comparison_saw_vs_oracle.csv'));

    fprintf('Comparison artifacts saved to %s (.png, .mat, .csv)\n\n', res_dir);

    comp_results = struct('concordance_pct', concordance_pct, ...
                          'acc_oracle_target', acc_ora_vs_oracle_target, ...
                          'acc_saw_target', acc_saw_vs_saw_target, ...
                          'acc_saw_vs_oracle', acc_saw_vs_oracle_target, ...
                          'mean_ber_oracle_model', mean_ber_ora_model, ...
                          'mean_ber_saw_model', mean_ber_saw_model, ...
                          'mean_ber_true_oracle', mean_ber_true_oracle, ...
                          'delta_ber_oracle', delta_ber_oracle, ...
                          'delta_ber_saw', delta_ber_saw, ...
                          'min_dist_to_train', min_dist_to_train);
end
