function eval_results = evaluate_ml_model(N_test_samples, rng_seed)
% EVALUATE_ML_MODEL  Evaluates trained ML model on held-out test channels.
%
%   eval_results = evaluate_ml_model(N_test_samples, rng_seed)
%
%   Demonstrates the ML model's generalization capabilities, computes
%   confusion matrix, benchmarks against fixed baselines, and generates
%   a comprehensive diagnostic figure in 'results/ml_model_evaluation.png'.

    close all;
    base_dir = fileparts(fileparts(mfilename('fullpath')));
    if isempty(base_dir), base_dir = pwd; end
    addpath(genpath(base_dir));

    if nargin < 1 || isempty(N_test_samples), N_test_samples = 60; end
    if nargin < 2 || isempty(rng_seed),       rng_seed = 777;       end

    fprintf('=========================================================================\n');
    fprintf('  SignalForge: Machine Learning Model Evaluation & Benchmarking\n');
    fprintf('=========================================================================\n\n');

    % 1. Load or train model
    model_path = fullfile(base_dir, 'ml', 'trained_linecode_model.mat');
    if ~exist(model_path, 'file')
        fprintf('Training base model first...\n');
        train_ml_model([], [], model_path);
    end
    loaded = load(model_path, 'model');
    model  = loaded.model;

    % 2. Generate independent held-out evaluation dataset
    fprintf('Generating %d independent held-out test scenarios (Seed: %d)...\n', N_test_samples, rng_seed);
    [dataset, X_test, y_true] = generate_ml_dataset(N_test_samples, rng_seed);

    % 3. Run ML Inference and benchmark latency
    fprintf('Running ML inference across test set...\n');
    t_start = tic;
    y_pred = zeros(N_test_samples, 1);
    confs  = zeros(N_test_samples, 1);

    for i = 1:N_test_samples
        ch_p = struct('SNR_dB', X_test(i, 1), ...
                      'multipath_k', X_test(i, 2), ...
                      'doppler_v', X_test(i, 3), ...
                      'distance_m', X_test(i, 4));
        prio_str = dataset(i).priority_name;

        pred = predict_linecode_ml(ch_p, prio_str, model);
        y_pred(i) = pred.class_index;
        confs(i)  = pred.confidence;
    end
    t_elapsed_ms = (toc(t_start) / N_test_samples) * 1000;

    % 4. Performance Metrics
    accuracy = mean(y_pred == y_true) * 100;
    fprintf('\n--> Held-Out Test Accuracy: %.2f%%\n', accuracy);
    fprintf('--> Mean Inference Latency: %.3f ms per channel evaluation\n\n', t_elapsed_ms);

    % Compute confusion matrix (6x6)
    conf_mat = zeros(6, 6);
    for i = 1:N_test_samples
        conf_mat(y_true(i), y_pred(i)) = conf_mat(y_true(i), y_pred(i)) + 1;
    end

    % Baseline comparison
    % Fixed NRZ-L (Class 1) agreement
    match_nrzl = mean(y_true == 1) * 100;
    % Fixed Manchester (Class 4) agreement
    match_man  = mean(y_true == 4) * 100;
    % Fixed AMI (Class 5) agreement
    match_ami  = mean(y_true == 5) * 100;

    fprintf('-------------------------------------------------------------------------\n');
    fprintf('  Baseline Agreement Comparison (Ground Truth Oracle Matches)\n');
    fprintf('-------------------------------------------------------------------------\n');
    fprintf('  ML Classifier Selection:       %.2f%% agreement with optimal choice\n', accuracy);
    fprintf('  Fixed NRZ-L Baseline:          %.2f%% agreement\n', match_nrzl);
    fprintf('  Fixed Manchester Baseline:     %.2f%% agreement\n', match_man);
    fprintf('  Fixed AMI Baseline:            %.2f%% agreement\n', match_ami);
    fprintf('-------------------------------------------------------------------------\n\n');

    % 5. Publication Plot
    fig = figure('Name','SignalForge: ML Model Evaluation', ...
                 'Position',[100 80 1100 500], 'Color','k');

    % Subplot 1: Confusion Matrix
    ax1 = subplot(1, 2, 1);
    imagesc(conf_mat);
    colormap(ax1, parula);
    cb = colorbar(ax1); cb.Color = 'w';
    set(ax1, 'Color','[0.08 0.08 0.12]', 'XColor','w', 'YColor','w', ...
        'XTick', 1:6, 'XTickLabel', model.labels, 'XTickLabelRotation', 30, ...
        'YTick', 1:6, 'YTickLabel', model.labels, ...
        'FontSize', 10);
    xlabel(ax1, 'ML Predicted Line Code', 'Color','w', 'FontSize', 11, 'FontWeight','bold');
    ylabel(ax1, 'Ground Truth Optimal Code', 'Color','w', 'FontSize', 11, 'FontWeight','bold');
    title(ax1, sprintf('Confusion Matrix (Acc: %.1f%%)', accuracy), ...
        'Color','w', 'FontSize', 12, 'FontWeight','bold');

    % Text overlay on matrix
    for r = 1:6
        for c = 1:6
            if conf_mat(r, c) > 0
                text(ax1, c, r, num2str(conf_mat(r, c)), ...
                    'HorizontalAlignment','center', 'Color','w', ...
                    'FontWeight','bold', 'FontSize', 11);
            end
        end
    end

    % Subplot 2: Baseline Comparison Bar Chart
    ax2 = subplot(1, 2, 2);
    bar_vals = [accuracy, match_nrzl, match_man, match_ami];
    bar_labels = {'SignalForge ML', 'Fixed NRZ-L', 'Fixed Man.', 'Fixed AMI'};
    b = bar(ax2, bar_vals, 'FaceColor','#00A86B', 'EdgeColor','none');
    b.FaceColor = 'flat';
    b.CData(1, :) = [0.0 0.7 1.0];   % Cyan for ML
    b.CData(2, :) = [0.8 0.3 0.3];   % Red for Fixed NRZ
    b.CData(3, :) = [0.9 0.6 0.2];   % Orange for Fixed Man
    b.CData(4, :) = [0.5 0.5 0.5];   % Gray for Fixed AMI

    set(ax2, 'Color','[0.08 0.08 0.12]', 'XColor','w', 'YColor','w', ...
        'XTick', 1:4, 'XTickLabel', bar_labels, ...
        'GridColor','[0.3 0.3 0.3]', 'GridAlpha', 0.5, 'FontSize', 10);
    grid(ax2, 'on');
    ylabel(ax2, 'Optimal Choice Match Rate (%)', 'Color','w', 'FontSize', 11, 'FontWeight','bold');
    ylim(ax2, [0 100]);
    title(ax2, 'ML Adaptation vs Fixed Baselines', 'Color','w', 'FontSize', 12, 'FontWeight','bold');

    % Text values on bars
    for k = 1:4
        text(ax2, k, bar_vals(k) + 3, sprintf('%.1f%%', bar_vals(k)), ...
            'HorizontalAlignment','center', 'Color','w', 'FontWeight','bold');
    end

    sgtitle('SignalForge — Intelligent ML Model Framework Validation', ...
        'Color','w', 'FontSize', 14, 'FontWeight','bold');

    % Save results
    res_dir = fullfile(base_dir, 'results');
    if ~exist(res_dir, 'dir'), mkdir(res_dir); end
    saveas(fig, fullfile(res_dir, 'ml_model_evaluation.png'));
    save(fullfile(res_dir, 'ml_model_evaluation.mat'), ...
        'accuracy', 'conf_mat', 't_elapsed_ms', 'bar_vals');

    fprintf('Evaluation figure saved to: %s\n\n', fullfile(res_dir, 'ml_model_evaluation.png'));

    eval_results = struct('accuracy', accuracy, ...
                          'latency_ms', t_elapsed_ms, ...
                          'confusion_matrix', conf_mat, ...
                          'baseline_matches', bar_vals);
end
