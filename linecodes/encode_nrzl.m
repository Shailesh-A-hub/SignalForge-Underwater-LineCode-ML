function signal = encode_nrzl(bits, Tb, fs, A)
% ENCODE_NRZL  Non-Return-to-Zero Level (NRZ-L) line encoder.
%
%   signal = encode_nrzl(bits, Tb, fs, A)
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
%     '1'  →  +A
%     '0'  →  -A

    if nargin < 4, A = 1; end

    Ns = round(Tb * fs);          % samples per bit
    N  = length(bits);
    signal = zeros(1, N * Ns);

    for k = 1:N
        idx = (k-1)*Ns + 1 : k*Ns;
        if bits(k) == 1
            signal(idx) = +A;
        else
            signal(idx) = -A;
        end
    end
end
