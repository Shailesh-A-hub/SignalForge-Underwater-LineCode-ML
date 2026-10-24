function signal = encode_ami(bits, Tb, fs, A)
% ENCODE_AMI  Alternate Mark Inversion (AMI) line encoder.
%
%   signal = encode_ami(bits, Tb, fs, A)
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
%     '0'  →  0
%     '1'  →  alternates between +A and -A

    if nargin < 4, A = 1; end

    Ns     = round(Tb * fs);
    N      = length(bits);
    signal = zeros(1, N * Ns);
    polarity = +1;                % first '1' gets +A

    for k = 1:N
        idx = (k-1)*Ns + 1 : k*Ns;
        if bits(k) == 0
            signal(idx) = 0;
        else
            signal(idx) = polarity * A;
            polarity     = -polarity;  % flip for next '1'
        end
    end
end
