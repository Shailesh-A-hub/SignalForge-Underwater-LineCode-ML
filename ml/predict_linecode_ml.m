function prediction = predict_linecode_ml(channel_params, priority_str, model)
% PREDICT_LINECODE_ML  Predicts the optimal line code using the trained ML model.
%
%   prediction = predict_linecode_ml(channel_params, priority_str, model)
%
%   Inputs:
%     channel_params - Struct with fields (.SNR_dB, .multipath_k, .doppler_v, .distance_m)
%     priority_str   - String: 'balanced' | 'low_ber' | 'low_bandwidth' | 'sync' | 'dc_free'
%     model          - Optional trained model struct (loads from file if omitted)
%
%   Output:
%     prediction - Struct containing:
%       .predicted_scheme   - String identifier ('nrzl', 'manchester', etc.)
%       .predicted_label    - Formatted label ('NRZ-L', 'Manchester', etc.)
%       .confidence         - Heuristic vote fraction [0.0, 1.0] (uncalibrated k-NN proportion)
%       .feature_vector     - Raw input vector [1 x 9]
%       .normalized_vector  - Standardized feature vector [1 x 9]
%       .class_scores       - Empirical nearest-neighbor vote distribution across 6 schemes
%                             (uncalibrated heuristic posterior)

    base_dir = fileparts(fileparts(mfilename('fullpath')));

    % 1. Load model if not supplied
    if nargin < 3 || isempty(model)
        model_path = fullfile(base_dir, 'ml', 'trained_linecode_model.mat');
        if ~exist(model_path, 'file')
            fprintf('Model file not found. Auto-training initial ML model...\n');
            model = train_ml_model();
        else
            loaded = load(model_path, 'model');
            model  = loaded.model;
        end
    end

    if nargin < 2 || isempty(priority_str), priority_str = 'balanced'; end

    % Priority mapping with one-hot encoding (prevents artificial ordinal scaling)
    priority_names = {'balanced', 'low_ber', 'low_bandwidth', 'sync', 'dc_free'};
    prio_idx = find(strcmpi(priority_names, priority_str), 1);
    if isempty(prio_idx), prio_idx = 1; end
    prio_onehot = zeros(1, 5);
    prio_onehot(prio_idx) = 1.0;

    % Extract features
    snr_val  = get_field(channel_params, 'SNR_dB', 15);
    mp_val   = get_field(channel_params, 'multipath_k', 0.2);
    dop_val  = get_field(channel_params, 'doppler_v', 0.0);
    dist_val = get_field(channel_params, 'distance_m', 300);

    x_raw = [snr_val, mp_val, dop_val, dist_val, prio_onehot];
    assert(length(x_raw) == length(model.mu_X), ...
        'Feature dimension mismatch: model expects %d features, but got %d.', ...
        length(model.mu_X), length(x_raw));

    % Normalize
    x_norm = (x_raw - model.mu_X) ./ model.sigma_X;

    % Inference
    schemes = model.schemes;
    labels  = model.labels;
    k = model.k_neighbors;

    if model.has_toolbox && isfield(model, 'native_mdl')
        [pred_idx, scores] = predict(model.native_mdl, x_norm);
        class_dist = zeros(1, 6);
        % Map available class scores
        if length(scores) == 6
            class_dist = scores;
        else
            for c_i = 1:length(scores)
                class_dist(c_i) = scores(c_i);
            end
        end
        if sum(class_dist) > 0, class_dist = class_dist / sum(class_dist); end
        conf = max(class_dist);
    else
        % Pure-MATLAB k-NN inference
        dists = sum((model.X_train_norm - x_norm).^2, 2);
        [~, sort_idx] = sort(dists, 'ascend');
        top_k = model.y_train(sort_idx(1:min(k, length(sort_idx))));
        
        pred_idx = mode(top_k);
        % Vote fraction as 6-class probability distribution
        votes = histcounts(top_k, 0.5:1:6.5);
        class_dist = votes / max(sum(votes), 1);
        conf = class_dist(pred_idx);
    end

    prediction = struct();
    prediction.predicted_scheme = schemes{pred_idx};
    prediction.predicted_label  = labels{pred_idx};
    prediction.class_index      = pred_idx;
    prediction.confidence       = conf;
    prediction.feature_vector    = x_raw;
    prediction.normalized_vector = x_norm;
    prediction.class_scores      = class_dist;
end

function val = get_field(s, field, default)
    if isfield(s, field) && ~isempty(s.(field))
        val = s.(field);
    else
        val = default;
    end
end
