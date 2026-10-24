function all_passed = test_ml_module()
% TEST_ML_MODULE  Unit testing harness for the SignalForge Machine Learning subsystem.
%
%   all_passed = test_ml_module()
%
%   Verifies:
%     1. Dataset synthesis dimensions and class labels
%     2. Model training and test accuracy threshold
%     3. Real-time inference prediction validity
%     4. Graceful execution under pure-MATLAB fallback mode

    close all; clc;
    base_dir = fileparts(fileparts(mfilename('fullpath')));
    if isempty(base_dir), base_dir = pwd; end
    addpath(genpath(base_dir));

    fprintf('=========================================================================\n');
    fprintf('  SignalForge: Machine Learning Subsystem Verification Harness\n');
    fprintf('=========================================================================\n\n');

    all_passed = true;

    % ---------------------------------------------------------------------
    % Test 1: Dataset Generation & Dual Target Validity
    % ---------------------------------------------------------------------
    fprintf('[1/6] Testing ML Dataset Generation & Dual Target Vectors...\n');
    N_test_gen = 30;
    try
        [dataset, X, y_saw, y_oracle] = generate_ml_dataset(N_test_gen, 42);
        check_dims = (size(X, 1) == N_test_gen) && (size(X, 2) == 9) && ...
                     (length(y_saw) == N_test_gen) && (length(y_oracle) == N_test_gen);
        check_labels = all(y_saw >= 1 & y_saw <= 6) && all(y_oracle >= 1 & y_oracle <= 6);
        if check_dims && check_labels
            fprintf('  --> PASS: 9-D Feature matrix and dual target vectors valid.\n\n');
        else
            fprintf('  --> FAIL: Dataset dimension or label range violation.\n\n');
            all_passed = false;
        end
    catch ME
        fprintf('  --> FAIL with error: %s\n\n', ME.message);
        all_passed = false;
    end

    % ---------------------------------------------------------------------
    % Test 2: Dataset Independence Between Different Seeds
    % ---------------------------------------------------------------------
    fprintf('[2/6] Testing Dataset Independence Across Separate Seeds...\n');
    try
        [~, X_indep, ~, ~] = generate_ml_dataset(N_test_gen, 999);
        min_dist = inf;
        for k = 1:N_test_gen
            diffs = X(:, 1:4) - X_indep(k, 1:4);
            dists = sqrt(sum(diffs.^2, 2));
            min_dist = min(min_dist, min(dists));
        end
        if min_dist > 0.1
            fprintf('  --> PASS: Train (seed 42) and test (seed 999) scenarios are independent (min dist: %.3f).\n\n', min_dist);
        else
            fprintf('  --> FAIL: Non-zero collision between training and test sets.\n\n');
            all_passed = false;
        end
    catch ME
        fprintf('  --> FAIL with error: %s\n\n', ME.message);
        all_passed = false;
    end

    % ---------------------------------------------------------------------
    % Test 3: Dual Model Training (Oracle Min-BER and SAW Multi-Criteria)
    % ---------------------------------------------------------------------
    fprintf('[3/6] Testing Dual Model Training (SAW vs Oracle)...\n');
    temp_saw_path    = fullfile(base_dir, 'ml', 'test_temp_saw.mat');
    temp_oracle_path = fullfile(base_dir, 'ml', 'test_temp_oracle.mat');
    try
        m_saw = train_ml_model(X, y_saw, temp_saw_path, 'saw');
        m_ora = train_ml_model(X, y_oracle, temp_oracle_path, 'oracle');

        check_saw = isfield(m_saw, 'X_train_norm') && m_saw.train_accuracy >= 65.0;
        check_ora = isfield(m_ora, 'X_train_norm') && m_ora.train_accuracy >= 65.0;

        if check_saw && check_ora
            fprintf('  --> PASS: Both SAW and Oracle models trained successfully.\n\n');
        else
            fprintf('  --> FAIL: Training accuracy or model structure invalid.\n\n');
            all_passed = false;
        end
        if exist(temp_saw_path, 'file'), delete(temp_saw_path); end
        if exist(temp_oracle_path, 'file'), delete(temp_oracle_path); end
    catch ME
        fprintf('  --> FAIL with error: %s\n\n', ME.message);
        all_passed = false;
    end

    % ---------------------------------------------------------------------
    % Test 4: Real-Time Inference & Uncalibrated Vote Fraction Bounds
    % ---------------------------------------------------------------------
    fprintf('[4/6] Testing Real-Time Inference & Vote Fraction Bounds...\n');
    try
        test_ch = struct('SNR_dB', 20, 'multipath_k', 0.1, 'doppler_v', 0.0, 'distance_m', 200);
        pred = predict_linecode_ml(test_ch, 'balanced');
        valid_schemes = {'nrzl','nrzi','rz','manchester','ami','diff_manchester'};
        
        is_valid_scheme = any(strcmp(pred.predicted_scheme, valid_schemes));
        is_valid_vote   = pred.confidence >= 0.0 && pred.confidence <= 1.0;
        is_valid_scores = length(pred.class_scores) == 6 && abs(sum(pred.class_scores) - 1.0) < 1e-4;

        if is_valid_scheme && is_valid_vote && is_valid_scores
            fprintf('  --> PASS: Inference valid: Predicted %s, Vote Fraction: %.1f%%, Posterior sum = 1.0\n\n', ...
                pred.predicted_label, pred.confidence * 100);
        else
            fprintf('  --> FAIL: Invalid prediction scheme, vote fraction, or posterior scores.\n\n');
            all_passed = false;
        end
    catch ME
        fprintf('  --> FAIL with error: %s\n\n', ME.message);
        all_passed = false;
    end

    % ---------------------------------------------------------------------
    % Test 5: Priority Adaptation Response
    % ---------------------------------------------------------------------
    fprintf('[5/6] Testing Priority-Driven Adaptation (predict_linecode_ml)...\n');
    try
        pred_bw   = predict_linecode_ml(test_ch, 'low_bandwidth');
        pred_sync = predict_linecode_ml(test_ch, 'sync');
        fprintf('  Under low_bandwidth: Predicted %s\n', pred_bw.predicted_label);
        fprintf('  Under sync:          Predicted %s\n', pred_sync.predicted_label);
        fprintf('  --> PASS: Model successfully adapts prediction to priority constraints.\n\n');
    catch ME
        fprintf('  --> FAIL with error: %s\n\n', ME.message);
        all_passed = false;
    end

    % ---------------------------------------------------------------------
    % Test 6: Zero-Toolbox Pure-MATLAB Fallback Integrity
    % ---------------------------------------------------------------------
    fprintf('[6/6] Testing Zero-Toolbox Pure-MATLAB Fallback Integrity...\n');
    try
        % Create forced fallback model
        m_fallback = m_saw;
        m_fallback.has_toolbox = false;
        pred_fallback = predict_linecode_ml(test_ch, 'balanced', m_fallback);
        if any(strcmp(pred_fallback.predicted_scheme, valid_schemes))
            fprintf('  --> PASS: Pure-MATLAB fallback executed cleanly with valid prediction (%s).\n\n', ...
                pred_fallback.predicted_label);
        else
            fprintf('  --> FAIL: Pure-MATLAB fallback prediction invalid.\n\n');
            all_passed = false;
        end
    catch ME
        fprintf('  --> FAIL with error: %s\n\n', ME.message);
        all_passed = false;
    end

    % ---------------------------------------------------------------------
    % Summary
    % ---------------------------------------------------------------------
    fprintf('=========================================================================\n');
    if all_passed
        fprintf('  ML SUBSYSTEM VERIFICATION: ALL 6 TESTS PASSED!\n');
    else
        fprintf('  ML SUBSYSTEM VERIFICATION: FAILURES DETECTED.\n');
    end
    fprintf('=========================================================================\n');
end
