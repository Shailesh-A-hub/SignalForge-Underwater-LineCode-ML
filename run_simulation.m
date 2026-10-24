function results = run_simulation(bits, schemes, channel_params, fs, Tb, equal_energy)
% RUN_SIMULATION  Core simulation runner for SignalForge.
%
%   Encodes bits with each scheme, passes through the UWAC channel,
%   decodes, and computes performance metrics.
%
%   results = run_simulation(bits, schemes, channel_params, fs, Tb, equal_energy)
%
%   Inputs:
%     bits          - Binary data vector
%     schemes       - Cell array of scheme name strings
%     channel_params- Struct passed to uwac_channel()
%     fs            - Sampling frequency (Hz)
%     Tb            - Bit period (seconds)
%     equal_energy  - Boolean (default false): if true, scale amplitude
%                     so that average bit energy Eb is equal across schemes
%                     (RZ: A=2.0, AMI: A=sqrt(2), others: A=1.0)
%
%   Output:
%     results  - Struct array (one per scheme) containing:
%       .scheme, .tx_signal, .rx_signal, .tx_bits, .rx_bits,
%       .metrics (from analyse_linecode), .channel_info

    if nargin < 6 || isempty(equal_energy), equal_energy = false; end

    n       = length(schemes);
    results = struct();

    for i = 1:n
        sc = schemes{i};

        % Amplitude normalisation
        A = 1.0;
        if equal_energy
            switch lower(sc)
                case 'rz'
                    A = 2.0;          % 25% active duty cycle energy compensation
                case 'ami'
                    A = sqrt(2);      % 50% mark activity energy compensation
                otherwise
                    A = 1.0;
            end
        end

        % Encode
        tx_sig = encode_linecode(bits, sc, Tb, fs, A);

        % Channel
        [rx_sig, ch_info] = uwac_channel(tx_sig, fs, channel_params);

        % Decode
        rx_bits = decode_linecode(rx_sig, sc, Tb, fs, A);

        % Analyse
        m = analyse_linecode(bits, tx_sig, rx_sig, rx_bits, sc, fs, Tb);

        % Store
        results(i).scheme       = sc;
        results(i).tx_signal    = tx_sig;
        results(i).rx_signal    = rx_sig;
        results(i).tx_bits      = bits;
        results(i).rx_bits      = rx_bits;
        results(i).metrics      = m;
        results(i).channel_info = ch_info;
        results(i).amplitude_A  = A;
    end
end
