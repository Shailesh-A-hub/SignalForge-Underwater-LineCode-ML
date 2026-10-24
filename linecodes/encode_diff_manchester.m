function signal = encode_diff_manchester(bits, Tb, fs, A)
% ENCODE_DIFF_MANCHESTER  Differential Manchester line encoder.
%
%   signal = encode_diff_manchester(bits, Tb, fs, A)
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
%     Always a mid-bit transition (self-clocking).
%     '0'  →  additional transition at START of bit period
%     '1'  →  NO transition at start of bit period
%
%   Starting level is -A (first half of first bit).

    if nargin < 4, A = 1; end

    Ns     = round(Tb * fs);
    Nhalf  = floor(Ns / 2);
    N      = length(bits);
    signal = zeros(1, N * Ns);
    first_half_level = -A;       % initial level for first half

    for k = 1:N
        base = (k-1)*Ns;
        if bits(k) == 0
            % transition at start: flip first-half level
            first_half_level = -first_half_level;
        end
        % mid-bit transition: second half is opposite of first half
        second_half_level = -first_half_level;

        signal(base+1      : base+Nhalf) = first_half_level;
        signal(base+Nhalf+1: base+Ns   ) = second_half_level;

        % prepare for next bit: first half of next = second half of current
        first_half_level = second_half_level;
    end
end
