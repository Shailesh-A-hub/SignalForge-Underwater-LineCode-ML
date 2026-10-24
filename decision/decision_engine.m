function result = decision_engine(metrics_table, priority)
% DECISION_ENGINE  Multi-objective adaptive line-code selection engine.
%
%   result = decision_engine(metrics_table, priority)
%
%   Selects the best line-coding scheme using a weighted scoring model
%   over six normalised criteria. Weights are adjusted based on the
%   declared transmission priority.
%
%   Inputs:
%     metrics_table - Struct array (one element per scheme) with fields:
%                     .scheme, .BER, .bandwidth_hz, .dc_balance,
%                     .transition_density, .power_dBm
%     priority      - String: 'balanced' | 'low_ber' | 'low_bandwidth' |
%                     'sync' | 'dc_free'  (default = 'balanced')
%
%   Output:
%     result  - Struct with fields:
%       .best_scheme      - Name of recommended scheme
%       .scores           - Weighted score for each scheme (struct)
%       .ranking          - Ordered list {best → worst}
%       .reasoning        - Human-readable explanation string
%       .weights          - Weight vector used
%       .criteria_names   - Names of criteria scored

    if nargin < 2, priority = 'balanced'; end

    schemes = {metrics_table.scheme};
    n       = length(schemes);

    % ---------------------------------------------------------------
    % 1. Define criteria weights per priority mode
    %    Criteria: [BER, BW, DC_balance, Sync, Power, BER_penalty]
    %    Higher weight → more important
    % ---------------------------------------------------------------
    switch lower(priority)
        case 'low_ber'
            % BER dominates — critical reliability applications
            w = [0.50, 0.10, 0.10, 0.15, 0.05, 0.10];
        case 'low_bandwidth'
            % Bandwidth constrained — congested underwater band
            w = [0.20, 0.40, 0.10, 0.10, 0.10, 0.10];
        case 'sync'
            % High clock recovery need — burst data
            w = [0.20, 0.10, 0.10, 0.45, 0.05, 0.10];
        case 'dc_free'
            % Transformer-coupled / DC-sensitive channel
            w = [0.20, 0.10, 0.40, 0.15, 0.05, 0.10];
        otherwise  % 'balanced'
            w = [0.30, 0.20, 0.15, 0.20, 0.05, 0.10];
    end

    criteria_names = {'BER','Bandwidth','DC_balance','Sync','Power','Robustness'};

    % ---------------------------------------------------------------
    % 2. Extract raw values
    % ---------------------------------------------------------------
    bers  = [metrics_table.BER];
    bws   = [metrics_table.bandwidth_hz];
    dcs   = [metrics_table.dc_balance];
    syncs = [metrics_table.transition_density];
    if isfield(metrics_table, 'power_rel_dB')
        pwrs = [metrics_table.power_rel_dB];
    else
        pwrs = [metrics_table.power_dBm];
    end

    % BER robustness penalty (log scale separation)
    robustness = 1 - (bers - min(bers)) / (max(bers) - min(bers) + eps);

    % ---------------------------------------------------------------
    % 3. Normalise to [0,1] — higher is BETTER for all criteria
    % ---------------------------------------------------------------
    norm_ber  = 1 - normalise_vec(bers);   % lower BER → higher score
    norm_bw   = 1 - normalise_vec(bws);    % lower BW  → higher score
    norm_dc   = normalise_vec(dcs);        % higher DC balance → better
    norm_sync = normalise_vec(syncs);      % higher transitions → better sync
    norm_pwr  = 1 - normalise_vec(pwrs);   % lower power → better
    norm_rob  = normalise_vec(robustness); % more robust → better

    % ---------------------------------------------------------------
    % 4. Weighted composite score
    % ---------------------------------------------------------------
    scores = w(1)*norm_ber  + w(2)*norm_bw   + w(3)*norm_dc  + ...
             w(4)*norm_sync + w(5)*norm_pwr  + w(6)*norm_rob;

    % ---------------------------------------------------------------
    % 5. Rank and select winner
    % ---------------------------------------------------------------
    [sorted_scores, idx] = sort(scores, 'descend');
    ranked_schemes       = schemes(idx);

    best_scheme = ranked_schemes{1};
    best_score  = sorted_scores(1);

    % Build score struct
    score_struct = struct();
    for i = 1:n
        fname = matlab.lang.makeValidName(schemes{i});
        score_struct.(fname) = scores(i);
    end

    % ---------------------------------------------------------------
    % 6. Reasoning string
    % ---------------------------------------------------------------
    best_idx = idx(1);
    reasoning = sprintf(['Priority: %s\n' ...
        'Recommended scheme: %s  (score = %.3f)\n\n' ...
        'Key drivers:\n' ...
        '  BER          = %.2e  (normalised: %.3f)\n' ...
        '  Bandwidth    = %.1f Hz (normalised: %.3f)\n' ...
        '  DC balance   = %.3f   (normalised: %.3f)\n' ...
        '  Sync density = %.2f   (normalised: %.3f)\n'], ...
        priority, best_scheme, best_score, ...
        bers(best_idx),  norm_ber(best_idx), ...
        bws(best_idx),   norm_bw(best_idx), ...
        dcs(best_idx),   norm_dc(best_idx), ...
        syncs(best_idx), norm_sync(best_idx));

    % ---------------------------------------------------------------
    % 7. Package result
    % ---------------------------------------------------------------
    result.best_scheme    = best_scheme;
    result.scores         = score_struct;
    result.score_values   = scores;
    result.ranking        = ranked_schemes;
    result.ranking_scores = sorted_scores;
    result.reasoning      = reasoning;
    result.weights        = w;
    result.criteria_names = criteria_names;
    result.priority       = priority;
end


function y = normalise_vec(x)
% Normalise vector to [0,1]; return 0.5 if all values identical.
    mn = min(x); mx = max(x);
    if abs(mx - mn) < eps
        y = 0.5 * ones(size(x));
    else
        y = (x - mn) / (mx - mn);
    end
end
