function model = train_ml_model(X, y, save_path, objective_type)
% TRAIN_ML_MODEL  Trains an intelligent machine learning classifier for line-code selection.
%
%   model = train_ml_model(X, y, save_path, objective_type)
%
%   Trains a robust multi-class classifier predicting optimal line-coding
%   schemes from channel features and priority constraints.
%   Includes 80/20 train/test validation and pure-MATLAB fallback for 100%
%   compatibility across MATLAB Online and desktop installations.
%
%   Inputs:
%     X              - Feature matrix [N x 9]:
%                      [SNR_dB, multipath_k, doppler_v, distance_m,
%                       is_balanced, is_low_ber, is_low_bw, is_sync, is_dc_free]
%     y              - Target label vector [N x 1] (class indices 1..6)
%     save_path      - Optional path to save model .mat (default: 'ml/trained_linecode_model.mat')
%     objective_type - Optional: 'saw' (default) or 'oracle'
%
%   Output:
%     model     - Trained model struct containing weights, normalization parameters,
%                 and classification inference handles.

    base_dir = fileparts(fileparts(mfilename('fullpath')));
    if nargin < 4 || isempty(objective_type)
        objective_type = 'saw';
    end
    if nargin < 3 || isempty(save_path)
        if strcmpi(objective_type, 'oracle') || strcmpi(objective_type, 'oracle_min_ber')
            save_path = fullfile(base_dir, 'ml', 'trained_model_oracle.mat');
        else
            save_path = fullfile(base_dir, 'ml', 'trained_model_saw.mat');
        end
    end

    if nargin < 2 || isempty(X) || isempty(y)
        fprintf('No training dataset provided. Synthesizing new dataset (Objective: %s)...\n', upper(objective_type));
        [~, X, y_saw, y_oracle] = generate_ml_dataset(120, 42, objective_type);
        if strcmpi(objective_type, 'oracle') || strcmpi(objective_type, 'oracle_min_ber')
            y = y_oracle;
        else
            y = y_saw;
        end
    end

    N = size(X, 1);
    rng(101); % Fixed seed for reproducible train/test partition
    cv_idx = randperm(N);
    n_train = round(0.80 * N);

    train_idx = cv_idx(1:n_train);
    test_idx  = cv_idx(n_train+1:end);

    X_train = X(train_idx, :);
    y_train = y(train_idx);
    X_test  = X(test_idx, :);
    y_test  = y(test_idx);

    % Feature normalization (Z-score parameters)
    mu_X    = mean(X_train, 1);
    sigma_X = std(X_train, 0, 1) + 1e-6;

    X_train_norm = (X_train - mu_X) ./ sigma_X;
    X_test_norm  = (X_test  - mu_X) ./ sigma_X;

    % Scheme definitions
    schemes = {'nrzl','nrzi','rz','manchester','ami','diff_manchester'};
    labels  = {'NRZ-L','NRZ-I','RZ','Manchester','AMI','Diff. Manchester'};

    % Check toolbox availability
    has_stats_toolbox = exist('fitcknn', 'file') == 2;
    model = struct();
    model.has_toolbox    = has_stats_toolbox;
    model.objective_type = objective_type;
    model.feature_dim    = size(X_train, 2);
    model.mu_X          = mu_X;
    model.sigma_X       = sigma_X;
    model.schemes       = schemes;
    model.labels        = labels;
    model.X_train_norm  = X_train_norm;
    model.y_train       = y_train;
    model.k_neighbors   = 5;

    if has_stats_toolbox
        fprintf('Training MATLAB Statistics & Machine Learning Toolbox KNN Classifier...\n');
        try
            model.native_mdl = fitcknn(X_train_norm, y_train, 'NumNeighbors', 5, 'Standardize', false);
            y_pred_train = predict(model.native_mdl, X_train_norm);
            y_pred_test  = predict(model.native_mdl, X_test_norm);
        catch
            model.has_toolbox = false;
        end
    end

    if ~model.has_toolbox
        fprintf('Using native Pure-MATLAB Weighted Distance Classifier (Zero-Toolbox Dependency)...\n');
        y_pred_train = pure_matlab_knn_predict(X_train_norm, X_train_norm, y_train, 5);
        y_pred_test  = pure_matlab_knn_predict(X_test_norm,  X_train_norm, y_train, 5);
    end

    % Evaluate accuracy
    acc_train = mean(y_pred_train == y_train) * 100;
    acc_test  = mean(y_pred_test  == y_test)  * 100;

    model.train_accuracy = acc_train;
    model.test_accuracy  = acc_test;
    model.training_samples = n_train;
    model.testing_samples  = length(test_idx);

    fprintf('=========================================================================\n');
    fprintf('  SignalForge Machine Learning Model Training Summary\n');
    fprintf('=========================================================================\n');
    fprintf('  Training Samples: %d | Test Samples: %d\n', n_train, length(test_idx));
    fprintf('  Training Accuracy: %.2f%%\n', acc_train);
    fprintf('  Test Accuracy:     %.2f%%\n', acc_test);
    fprintf('=========================================================================\n\n');

    % Save trained model
    save(save_path, 'model');
    fprintf('Trained ML model (%s) saved to: %s\n', upper(objective_type), save_path);

    % If SAW model, also update default model for backward compatibility with GUI
    if strcmpi(objective_type, 'saw')
        default_path = fullfile(base_dir, 'ml', 'trained_linecode_model.mat');
        save(default_path, 'model');
    end
    fprintf('\n');
end

function y_pred = pure_matlab_knn_predict(X_query, X_train, y_train, k)
% Vectorized, toolbox-independent k-NN prediction
    N_q = size(X_query, 1);
    y_pred = zeros(N_q, 1);
    for i = 1:N_q
        q = X_query(i, :);
        dists = sum((X_train - q).^2, 2);
        [~, sort_idx] = sort(dists, 'ascend');
        top_k = y_train(sort_idx(1:min(k, length(sort_idx))));
        y_pred(i) = mode(top_k);
    end
end
