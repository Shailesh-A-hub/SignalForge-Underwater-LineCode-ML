function [dataset, X, y_saw, y_oracle] = generate_ml_dataset(N_samples, rng_seed, objective_type)
% GENERATE_ML_DATASET  Generates labeled training/testing dataset for ML line-code classifier.
%
%   [dataset, X, y_saw, y_oracle] = generate_ml_dataset(N_samples, rng_seed, objective_type)
%
%   Simulates diverse underwater channel conditions and evaluates all candidate
%   line codes using both:
%     1. SAW Multi-Criteria Selection (balances BER, bandwidth, DC balance, sync)
%     2. Empirical Minimum-BER Oracle (selects code with absolute lowest measured BER)
%
%   Inputs:
%     N_samples      - Number of channel instances to generate (default: 120)
%     rng_seed       - Random seed for reproducibility (default: 42)
%     objective_type - 'saw' (default) or 'oracle_min_ber'
%
%   Outputs:
%     dataset        - Struct array containing features, all 6 measured BERs, and labels
%     X              - Feature matrix [N_samples x 9]:
%                      [SNR_dB, multipath_k, doppler_v, distance_m,
%                       is_balanced, is_low_ber, is_low_bw, is_sync, is_dc_free]
%     y_saw          - SAW ground-truth label vector [N_samples x 1] (classes 1..6)
%     y_oracle       - Oracle minimum-BER label vector [N_samples x 1] (classes 1..6)

    if nargin < 1 || isempty(N_samples),      N_samples = 120;      end
    if nargin < 2 || isempty(rng_seed),       rng_seed = 42;        end
    if nargin < 3 || isempty(objective_type), objective_type = 'saw'; end

    rng(rng_seed);
    fprintf('Generating %d simulated channel scenarios (Seed %d, Objective: %s)...\n', ...
        N_samples, rng_seed, upper(objective_type));

    fs = 48000;
    Tb = 1e-3;
    N_bits = 400; % Representative bit count for fast, balanced dataset generation

    schemes = {'nrzl','nrzi','rz','manchester','ami','diff_manchester'};
    priority_names = {'balanced', 'low_ber', 'low_bandwidth', 'sync', 'dc_free'};

    dataset = struct('SNR_dB', cell(1, N_samples), ...
                     'multipath_k', [], ...
                     'doppler_v', [], ...
                     'distance_m', [], ...
                     'priority_id', [], ...
                     'priority_name', '', ...
                     'all_bers', [], ...
                     'saw_code_idx', [], ...
                     'saw_code_name', '', ...
                     'oracle_code_idx', [], ...
                     'oracle_code_name', '');

    X        = zeros(N_samples, 9);  % 4 continuous channel features + 5 one-hot priority features
    y_saw    = zeros(N_samples, 1);
    y_oracle = zeros(N_samples, 1);

    for i = 1:N_samples
        % Generate independent binary sequence for each channel scenario
        bits = randi([0 1], 1, N_bits);

        snr_val   = -5 + 35 * rand();         % [-5, 30] dB
        mp_val    = rand();                   % [0.0, 1.0]
        dop_val   = 4.0 * rand();             % [0.0, 4.0] m/s
        dist_val  = 50 + 950 * rand();        % [50, 1000] m
        prio_idx  = randi([1, 5]);            % 1..5
        prio_str  = priority_names{prio_idx};

        % One-hot categorical encoding for priorities (prevents artificial ordinal scaling)
        prio_onehot = zeros(1, 5);
        prio_onehot(prio_idx) = 1.0;

        ch_params = struct('SNR_dB', snr_val, ...
                           'distance_m', dist_val, ...
                           'fc_Hz', 5000, ...
                           'num_paths', 3, ...
                           'max_delay_s', 4e-3, ...
                           'multipath_k', mp_val, ...
                           'doppler_v', dop_val, ...
                           'bw_fraction', 0.4);

        % Simulate transmission across all candidate schemes
        res = run_simulation(bits, schemes, ch_params, fs, Tb);

        % Extract empirical metrics
        m_arr    = [res.metrics];
        all_bers = [m_arr.BER];
        all_bws  = [m_arr.bandwidth_hz];
        all_dcs  = [m_arr.dc_balance];

        % 1. Deterministic Oracle Minimum-BER with Secondary Tie-Breaking
        min_ber = min(all_bers);
        tied_candidates = find(abs(all_bers - min_ber) < 1e-6);
        if length(tied_candidates) == 1
            min_idx = tied_candidates(1);
        else
            % Tie-breaker: Among min-BER ties, pick code with lowest bandwidth
            tied_bws = all_bws(tied_candidates);
            min_bw   = min(tied_bws);
            bw_tied  = tied_candidates(abs(tied_bws - min_bw) < 1e-3);
            if length(bw_tied) == 1
                min_idx = bw_tied(1);
            else
                % Tertiary tie-breaker: Highest DC balance
                [~, dc_max_sub] = max(all_dcs(bw_tied));
                min_idx = bw_tied(dc_max_sub);
            end
        end
        oracle_scheme = schemes{min_idx};

        % 2. SAW multi-criteria label (imitating the multi-objective selector)
        dec = decision_engine([res.metrics], prio_str);
        saw_scheme = dec.best_scheme;
        saw_idx    = find(strcmpi(schemes, saw_scheme), 1);

        % Store record
        dataset(i).SNR_dB           = snr_val;
        dataset(i).multipath_k      = mp_val;
        dataset(i).doppler_v        = dop_val;
        dataset(i).distance_m       = dist_val;
        dataset(i).priority_id      = prio_idx;
        dataset(i).priority_name    = prio_str;
        dataset(i).priority_onehot  = prio_onehot;
        dataset(i).all_bers         = all_bers;
        dataset(i).saw_code_idx     = saw_idx;
        dataset(i).saw_code_name    = saw_scheme;
        dataset(i).oracle_code_idx  = min_idx;
        dataset(i).oracle_code_name = oracle_scheme;

        % 9-D Feature vector: [SNR, MP, DOP, DIST, ONE_HOT(5)]
        X(i, :) = [snr_val, mp_val, dop_val, dist_val, prio_onehot];
        y_saw(i, 1)    = saw_idx;
        y_oracle(i, 1) = min_idx;

        if mod(i, 30) == 0 || i == N_samples
            fprintf('  Processed [%d/%d] | SAW: %-12s | Oracle Min-BER: %-12s\n', ...
                i, N_samples, saw_scheme, oracle_scheme);
        end
    end

    fprintf('Dataset ready: %d scenarios. Feature matrix X: [%dx%d] (One-Hot Encoded).\n\n', ...
        N_samples, size(X, 1), size(X, 2));
end
