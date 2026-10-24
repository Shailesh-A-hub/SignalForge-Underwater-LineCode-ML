function signal = encode_linecode(bits, scheme, Tb, fs, A)
% ENCODE_LINECODE  Unified dispatcher for all six line-coding encoders.
%
%   signal = encode_linecode(bits, scheme, Tb, fs, A)
%
%   Inputs:
%     bits   - Binary data vector (0s and 1s)
%     scheme - String: 'nrzl','nrzi','rz','manchester','ami','diff_manchester'
%     Tb     - Bit period (seconds)
%     fs     - Sampling frequency (Hz)
%     A      - Amplitude (default = 1)
%
%   Output:
%     signal - Encoded waveform

    if nargin < 5, A = 1; end

    switch lower(scheme)
        case 'nrzl'
            signal = encode_nrzl(bits, Tb, fs, A);
        case 'nrzi'
            signal = encode_nrzi(bits, Tb, fs, A);
        case 'rz'
            signal = encode_rz(bits, Tb, fs, A);
        case 'manchester'
            signal = encode_manchester(bits, Tb, fs, A);
        case 'ami'
            signal = encode_ami(bits, Tb, fs, A);
        case 'diff_manchester'
            signal = encode_diff_manchester(bits, Tb, fs, A);
        otherwise
            error('encode_linecode: unknown scheme "%s"', scheme);
    end
end
