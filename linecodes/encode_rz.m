function signal = encode_rz(bits, Tb, fs, A)
% ENCODE_RZ  Return-to-Zero (RZ) line encoder.
%
%   signal = encode_rz(bits, Tb, fs, A)
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
%     '1'  →  +A for first half of Tb, then 0 for second half
%     '0'  →  0 for entire Tb

    if nargin < 4, A = 1; end

    Ns     = round(Tb * fs);
    Nhalf  = floor(Ns / 2);
    N      = length(bits);
    signal = zeros(1, N * Ns);

    for k = 1:N
        base = (k-1)*Ns;
        if bits(k) == 1
            signal(base+1 : base+Nhalf) = +A;
            % second half remains zero
        end
        % '0': entire bit period is zero
    end
end
