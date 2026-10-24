function signal = encode_manchester(bits, Tb, fs, A)
% ENCODE_MANCHESTER  Manchester (biphase-L) line encoder.
%
%   signal = encode_manchester(bits, Tb, fs, A)
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
%   Encoding rule (IEEE 802.3):
%     '1'  →  -A for first half, +A for second half  (low-to-high)
%     '0'  →  +A for first half, -A for second half  (high-to-low)

    if nargin < 4, A = 1; end

    Ns     = round(Tb * fs);
    Nhalf  = floor(Ns / 2);
    N      = length(bits);
    signal = zeros(1, N * Ns);

    for k = 1:N
        base = (k-1)*Ns;
        if bits(k) == 1
            signal(base+1      : base+Nhalf) = -A;  % first  half: low
            signal(base+Nhalf+1: base+Ns   ) = +A;  % second half: high
        else
            signal(base+1      : base+Nhalf) = +A;  % first  half: high
            signal(base+Nhalf+1: base+Ns   ) = -A;  % second half: low
        end
    end
end
