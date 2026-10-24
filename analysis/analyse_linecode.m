function metrics = analyse_linecode(tx_bits, tx_signal, rx_signal, rx_bits, scheme, fs, Tb)
% ANALYSE_LINECODE  Compute performance metrics for one line-coding scheme.
%
%   metrics = analyse_linecode(tx_bits, tx_signal, rx_signal, rx_bits, scheme, fs, Tb)
%
%   METRIC DEFINITIONS AND CONVENTIONS
%   -----------------------------------
%   BER
%     Empirical: errors / total_bits. Both tx_bits and rx_bits must
%     represent the same transmitted data block. BER is measured at equal
%     peak amplitude (A=1), not at equal bit energy. Schemes with lower
%     duty cycles (RZ, AMI) transmit less energy per bit at the same
%     amplitude; their BER is therefore at a disadvantage relative to NRZ-L
%     on an equal-energy basis (approximately 3 dB for RZ and AMI).
%
%   Bandwidth
%     First frequency at which the normalised PSD of tx_signal drops below
%     -20 dB. Computed from tx_signal (the transmitted waveform, not the
%     received signal), so it reflects the line code's spectral occupancy
%     independent of channel effects.
%
%   DC balance
%     1 - |mean(tx_signal)| / max(|tx_signal|)
%     Range [0, 1]; 1 = perfectly DC-balanced. Computed from tx_signal.
%     DC balance is a statistical property; it converges as N_bits → inf.
%     For finite test sequences, non-zero DC is expected even for DC-free
%     codes (Manchester, AMI, Differential Manchester).
%
%   Transition density
%     Zero-crossings of tx_signal per bit period. A proxy for
%     synchronisation quality; higher values indicate richer clock content.
%     Note: sign(0) = 0 in MATLAB; diff(sign(x)) may miss transitions
%     through zero. For AMI (which has zero-voltage symbols), interpret
%     with care.
%
%   Signal power (relative)
%     10*log10(mean(tx_signal^2) / 1e-3) is reported as a relative dB
%     quantity with a 1 mW, 1 Ohm reference. This is a NORMALISED metric
%     for comparing schemes at equal amplitude (A=1). It should NOT be
%     interpreted as a physical power in dBm unless the signal amplitude
%     is mapped to a calibrated voltage across a defined impedance.
%
%   Outputs struct fields:
%     .BER                Empirical bit error rate
%     .num_errors         Integer error count
%     .bandwidth_hz       First-null (-20 dB) bandwidth of tx_signal (Hz)
%     .dc_offset          Mean value of tx_signal
%     .dc_balance         DC balance score [0,1]
%     .transition_density Zero-crossings per bit in tx_signal
%     .power_rel_dB       Relative signal power (dB, 1 mW / 1 Ohm reference)
%     .psd_f              Frequency axis (Hz)
%     .psd_mag            PSD magnitude (dB)
%     .scheme             Scheme name string

    % ---------------------------------------------------------------
    % 1. BER — empirical, equal peak amplitude
    % ---------------------------------------------------------------
    N   = min(length(tx_bits), length(rx_bits));
    err = sum(tx_bits(1:N) ~= rx_bits(1:N));
    metrics.BER        = err / N;
    metrics.num_errors = err;

    % ---------------------------------------------------------------
    % 2. Bandwidth — 90% fractional power containment bandwidth
    %    (Standard telecommunications definition; prevents DC null at f=0
    %     from reporting 0 Hz on DC-free codes like Manchester/AMI)
    % ---------------------------------------------------------------
    Nfft       = 2^nextpow2(length(tx_signal));
    S          = abs(fft(tx_signal, Nfft)).^2 / length(tx_signal);
    S          = S(1:Nfft/2+1);
    f_ax       = (0:Nfft/2) * fs / Nfft;
    cum_power  = cumsum(S) / sum(S);
    idx90      = find(cum_power >= 0.90, 1);
    if ~isempty(idx90)
        metrics.bandwidth_hz = f_ax(idx90);
    else
        metrics.bandwidth_hz = fs / 2;
    end

    % ---------------------------------------------------------------
    % 3. DC component and DC balance
    % ---------------------------------------------------------------
    dc_val             = mean(tx_signal);
    peak               = max(abs(tx_signal)) + eps;
    metrics.dc_offset  = dc_val;
    metrics.dc_balance = 1 - abs(dc_val) / peak;

    % ---------------------------------------------------------------
    % 4. Transition density (zero-crossings per bit)
    %    For AMI, this counts crossings through zero in the sign-domain.
    %    Interpret with care: AMI zero-voltage symbols give sign(x) = 0
    %    and produce additional transitions in the sign vector.
    % ---------------------------------------------------------------
    Ns          = round(Tb * fs);
    Nbits       = max(floor(length(tx_signal) / Ns), 1);
    transitions = sum(abs(diff(sign(tx_signal))) > 0);
    metrics.transition_density = transitions / Nbits;

    % ---------------------------------------------------------------
    % 5. Signal power (relative dB, 1 mW / 1 Ohm reference)
    %    This is a normalised comparison metric at A=1. It is NOT a
    %    calibrated physical power measurement.
    % ---------------------------------------------------------------
    p_watts              = mean(tx_signal.^2);
    metrics.power_rel_dB = 10*log10(p_watts / 1e-3 + eps);
    metrics.power_dBm    = metrics.power_rel_dB;  % backward-compatible alias for GUI and decision engine

    % ---------------------------------------------------------------
    % 6. PSD
    % ---------------------------------------------------------------
    metrics.psd_f   = f_ax;
    metrics.psd_mag = 10*log10(S + eps);
    metrics.scheme  = scheme;
end
