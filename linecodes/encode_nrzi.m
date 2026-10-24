function signal = encode_nrzi(bits, Tb, fs, A)
% ENCODE_NRZI  Non-Return-to-Zero Inverted (NRZ-I) line encoder.
%
%   signal = encode_nrzi(bits, Tb, fs, A)
%
%   Inputs:
%     bits  - Row vector of binary data (0s and 1s)
%     Tb    - Bit period (seconds)
%     fs    - Sampling frequency (Hz)
%     A     - Signal amplitude (default = 1)
%
%   Output:
%     signal - Encoded waveform samples
%
%   Encoding rule:
%     '1'  →  transition at start of bit period
%     '0'  →  no transition (level maintained)

    if nargin < 4, A = 1; end

    Ns     = round(Tb * fs);
    N      = length(bits);
    signal = zeros(1, N * Ns);
    level  = +A;                  % initial level

    for k = 1:N
        if bits(k) == 1
            level = -level;       % toggle on '1'
        end
        idx = (k-1)*Ns + 1 : k*Ns;
        signal(idx) = level;
    end
end
