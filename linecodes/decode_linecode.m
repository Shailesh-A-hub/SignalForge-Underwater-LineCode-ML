function bits_rx = decode_linecode(rx_signal, scheme, Tb, fs, A)
% DECODE_LINECODE  Universal decoder for all six line-coding schemes.
%
%   bits_rx = decode_linecode(rx_signal, scheme, Tb, fs, A)
%
%   Inputs:
%     rx_signal - Received (possibly noisy) waveform
%     scheme    - String: 'nrzl','nrzi','rz','manchester','ami','diff_manchester'
%     Tb        - Bit period (seconds)
%     fs        - Sampling frequency (Hz)
%     A         - Nominal signal amplitude (default = 1.0)
%
%   Output:
%     bits_rx - Decoded binary vector

    if nargin < 5 || isempty(A), A = 1.0; end

    Ns      = round(Tb * fs);
    N       = floor(length(rx_signal) / Ns);
    bits_rx = zeros(1, N);

    switch lower(scheme)
        % ---------------------------------------------------------------
        case 'nrzl'
            % Threshold at 0: positive → 1, negative → 0
            for k = 1:N
                seg = rx_signal((k-1)*Ns+1 : k*Ns);
                bits_rx(k) = double(mean(seg) >= 0);
            end

        % ---------------------------------------------------------------
        case 'nrzi'
            % Detect transitions: transition → 1, no transition → 0
            % Initial reference level before bit 1 is +1 (per encode_nrzi)
            prev_level = 1.0;
            for k = 1:N
                seg        = rx_signal((k-1)*Ns+1 : k*Ns);
                curr_level = mean(seg);
                if sign(curr_level) ~= sign(prev_level)
                    bits_rx(k) = 1;
                else
                    bits_rx(k) = 0;
                end
                prev_level = curr_level;
            end

        % ---------------------------------------------------------------
        case 'rz'
            % Positive energy in first half → 1, else 0
            Nhalf = floor(Ns / 2);
            for k = 1:N
                base = (k-1)*Ns;
                first_half = rx_signal(base+1 : base+Nhalf);
                bits_rx(k) = double(mean(first_half) >= 0.5 * A);
            end

        % ---------------------------------------------------------------
        case 'manchester'
            % Mid-bit transition detection:
            % first half < second half → 1 (low→high)
            % first half > second half → 0 (high→low)
            Nhalf = floor(Ns / 2);
            for k = 1:N
                base  = (k-1)*Ns;
                v1    = mean(rx_signal(base+1      : base+Nhalf));
                v2    = mean(rx_signal(base+Nhalf+1: base+Ns  ));
                bits_rx(k) = double(v2 > v1);
            end

        % ---------------------------------------------------------------
        case 'ami'
            % Threshold: non-zero → 1, zero → 0
            for k = 1:N
                seg = rx_signal((k-1)*Ns+1 : k*Ns);
                bits_rx(k) = double(abs(mean(seg)) >= 0.3 * A);
            end

        % ---------------------------------------------------------------
        % ---------------------------------------------------------------
        case 'diff_manchester'
            % '0': transition at start of bit (compare last level of
            %      previous bit to first level of current bit)
            % '1': NO transition at start
            % Initial level before first bit is -1 (per encode_diff_manchester)
            Nhalf         = floor(Ns / 2);
            v_prev_second = -1.0;
            for k = 1:N
                base = (k-1)*Ns;
                v_curr_first = mean(rx_signal(base+1 : base+Nhalf));
                if sign(v_curr_first) ~= sign(v_prev_second)
                    bits_rx(k) = 0;    % transition at start → '0'
                else
                    bits_rx(k) = 1;    % no transition at start → '1'
                end
                v_prev_second = mean(rx_signal(base+Nhalf+1 : base+Ns));
            end

        % ---------------------------------------------------------------
        otherwise
            error('decode_linecode: unknown scheme "%s"', scheme);
    end
end
