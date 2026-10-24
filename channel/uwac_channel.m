function [rx_signal, channel_info] = uwac_channel(tx_signal, fs, params)
% UWAC_CHANNEL  Simplified Baseband Waveform Impairment Model for
%               Underwater Acoustic Communication Simulation.
%
%   SCOPE AND LIMITATIONS
%   ---------------------
%   This function applies a set of impairments — path loss, tap-delay-line
%   multipath, Doppler time-scale resampling, FIR bandpass filtering, and
%   additive coloured noise — to a discrete-time baseband waveform.
%
%   It is NOT a physically complete passband acoustic link. The waveform is
%   not modulated onto an acoustic carrier, and no carrier-phase or
%   carrier-frequency recovery is performed at the receiver. The bandpass
%   filter approximates spectral band-limitation without implementing full
%   acoustic propagation physics. This model is appropriate for comparative
%   line-code evaluation under parameterised channel impairments; it should
%   not be used to claim physically absolute acoustic performance figures.
%
%   BYPASS MODE
%   -----------
%   Set params.bypass = true to skip all channel effects (noise, filtering,
%   path loss, multipath, Doppler). This produces rx_signal == tx_signal
%   and is used for encoder/decoder correctness validation (Deliverable D1).
%
%   PATH LOSS MODEL
%   ---------------
%   Implements cylindrical spreading (k = 1) with reference distance
%   d0 = 1 m and Thorp absorption at centre frequency fc_Hz.
%   The spreading exponent is fixed at k=1; the model does not support
%   spherical (k=2) or mixed (k=1.5) spreading without code modification.
%
%   THORP ABSORPTION (verified values)
%   -----------------------------------
%   alpha(f) = 0.11f^2/(1+f^2) + 44f^2/(4100+f^2) + 2.75e-4*f^2 + 0.003
%   [dB/km, f in kHz]. Correct values:
%     f =  5 kHz:  alpha ≈ 0.382 dB/km
%     f = 10 kHz:  alpha ≈ 1.187 dB/km
%     f = 15 kHz:  alpha ≈ 2.463 dB/km
%   Valid for f in [0.2, 500] kHz approximately.
%
%   DOPPLER MODEL
%   -------------
%   Time-scale resampling at factor s = 1 + v/c_sound.
%   Sign convention: positive doppler_v = source approaching receiver
%   = time compression (s > 1). The model does not implement Doppler
%   compensation at the receiver; all Doppler distortion affects BER.
%
%   NOISE MODEL
%   -----------
%   Noise is calibrated to the desired SNR measured at the receiver after
%   filtering. Coloured noise is an illustrative approximation (70% AWGN
%   + 30% low-pass-filtered AWGN), representing a mild low-frequency boost
%   qualitatively consistent with wind-noise dominance in the 1-10 kHz
%   band. It is NOT a calibrated environmental noise model.
%
%   SNR CONVENTION
%   --------------
%   SNR_dB is the ratio of mean signal power (after all impairments except
%   noise) to mean noise power, measured at the receiver input.
%   This is an SNR target, not an Eb/N0 specification.
%
%   [rx_signal, channel_info] = uwac_channel(tx_signal, fs, params)
%
%   Inputs:
%     tx_signal - Transmitted baseband signal (row vector)
%     fs        - Sampling frequency (Hz)
%     params    - Struct with fields (all optional, defaults shown):
%       .bypass       Skip all impairments; return tx_signal  [false]
%       .SNR_dB       Desired receiver SNR (dB)               [20]
%       .distance_m   Propagation distance (m)                [500]
%       .d0_m         Reference distance for spreading (m)    [1]
%       .fc_Hz        Centre frequency for Thorp (Hz)         [5000]
%       .num_paths    Number of multipath taps                 [3]
%       .max_delay_s  Maximum multipath delay (s)             [5e-3]
%       .multipath_k  Multipath severity scale 0–1            [0.3]
%       .doppler_v    Source-receiver relative velocity (m/s) [0]
%                       Positive = approaching = time compression
%       .bw_fraction  Channel BW as fraction of fs/2          [0.4]
%
%   Outputs:
%     rx_signal    - Received signal (same length as tx_signal)
%     channel_info - Struct with diagnostic fields (see code)

    % ---------------------------------------------------------------
    % 0. Default parameters
    % ---------------------------------------------------------------
    if nargin < 3, params = struct(); end
    p.bypass       = get_param(params, 'bypass',       false);
    p.SNR_dB       = get_param(params, 'SNR_dB',       20);
    p.distance_m   = get_param(params, 'distance_m',   500);
    p.d0_m         = get_param(params, 'd0_m',         1);
    p.fc_Hz        = get_param(params, 'fc_Hz',        5000);
    p.num_paths    = get_param(params, 'num_paths',    3);
    p.max_delay_s  = get_param(params, 'max_delay_s',  5e-3);
    p.multipath_k  = get_param(params, 'multipath_k',  0.3);
    p.doppler_v    = get_param(params, 'doppler_v',    0);
    p.bw_fraction  = get_param(params, 'bw_fraction',  0.4);

    c_sound = 1500;   % speed of sound in seawater (m/s)
    N       = length(tx_signal);

    % ---------------------------------------------------------------
    % BYPASS MODE — encoder/decoder validation (Deliverable D1)
    % ---------------------------------------------------------------
    if p.bypass
        rx_signal = tx_signal;
        channel_info = struct( ...
            'bypass',          true, ...
            'path_loss_dB',    0, ...
            'attenuation_dB',  0, ...
            'spreading_dB',    0, ...
            'SNR_actual_dB',   Inf, ...
            'delay_spread_s',  0, ...
            'doppler_Hz',      0, ...
            'noise_power',     0, ...
            'tap_delays',      0, ...
            'thorp_alpha',     0);
        return;
    end

    % ---------------------------------------------------------------
    % 1. Path Loss
    %    Spreading loss: cylindrical (k=1) with reference d0_m.
    %      PL_spread = k * 10 * log10(d / d0)   [dB]
    %    Thorp absorption: evaluated at centre frequency fc_Hz.
    %    Total: PL = PL_spread + alpha * d/1000  [d in m, alpha in dB/km]
    %
    %    Note: k is fixed at 1 (cylindrical spreading for shallow water).
    %    Spherical (k=2) and mixed (k=1.5) spreading are not implemented.
    % ---------------------------------------------------------------
    f_kHz = p.fc_Hz / 1e3;
    alpha_dB_per_km = 0.11*f_kHz^2/(1+f_kHz^2) + ...
                      44*f_kHz^2/(4100+f_kHz^2) + ...
                      2.75e-4*f_kHz^2 + 0.003;   % Thorp (1967)

    d_ratio           = max(p.distance_m, p.d0_m) / p.d0_m;
    spreading_loss_dB = 10 * log10(d_ratio);              % k=1
    attenuation_loss_dB = alpha_dB_per_km * p.distance_m / 1000;
    path_loss_dB      = spreading_loss_dB + attenuation_loss_dB;

    path_loss_linear = 10^(path_loss_dB / 20);
    signal_after_pl  = tx_signal / path_loss_linear;

    % ---------------------------------------------------------------
    % 2. Multipath — tap-delay-line model
    %    Tap gains decay exponentially with delay.
    %    multipath_k = 0: direct path only; multipath_k = 1: severe.
    % ---------------------------------------------------------------
    if p.multipath_k > 0 && p.num_paths > 0
        rng(42, 'twister');   % fixed seed for reproducibility
        tap_delays = sort(rand(1, p.num_paths) * p.max_delay_s * p.multipath_k);
        tap_delays(1) = 0;    % first tap = direct path

        tap_gains    = exp(-3 * tap_delays / max(tap_delays + eps));
        tap_gains    = tap_gains * p.multipath_k;
        tap_gains(1) = 1.0;

        signal_mp = zeros(1, N);
        for t = 1:p.num_paths
            delay_samps = round(tap_delays(t) * fs);
            delayed     = [zeros(1, delay_samps), signal_after_pl];
            delayed     = delayed(1:N);
            signal_mp   = signal_mp + tap_gains(t) * delayed;
        end
        signal_mp = signal_mp / sum(tap_gains);  % normalise

        power_taps = tap_gains.^2;
        mean_delay = sum(tap_delays .* power_taps) / sum(power_taps);
        rms_delay  = sqrt(sum(power_taps .* (tap_delays - mean_delay).^2) / sum(power_taps));
    else
        signal_mp  = signal_after_pl;
        tap_delays = 0;
        rms_delay  = 0;
    end

    % ---------------------------------------------------------------
    % 3. Doppler — time-scale resampling
    %    scale_factor = 1 + v/c_sound
    %    Positive doppler_v (approach): scale_factor > 1 → time compression
    %    Negative doppler_v (recession): scale_factor < 1 → dilation
    %
    %    Implementation: stretch the sampling time axis, then resample
    %    back to the original grid. Samples beyond the original window
    %    are set to zero (simple boundary handling; introduces an edge
    %    artefact at the end of the signal that is negligible for long
    %    sequences). No Doppler compensation is applied at the receiver.
    % ---------------------------------------------------------------
    doppler_Hz = p.fc_Hz * p.doppler_v / c_sound;   % approx narrowband shift

    if abs(p.doppler_v) > 0
        scale_factor = 1 + p.doppler_v / c_sound;
        t_original   = (0:N-1) / fs;
        t_scaled     = t_original * scale_factor;
        t_clamped    = min(t_scaled, t_original(end));
        signal_dop   = interp1(t_original, signal_mp, t_clamped, 'linear', 0);
    else
        signal_dop = signal_mp;
    end

    % ---------------------------------------------------------------
    % 4. Bandwidth Limitation — FIR bandpass filter
    %    Approximates the spectral band-limitation of the acoustic channel.
    %    Centre: fc_Hz; bandwidth: bw_fraction * fs/2.
    %    This is a phenomenological filtering step, not a physical
    %    acoustic propagation model.
    % ---------------------------------------------------------------
    bw_hz  = p.bw_fraction * fs / 2;
    f_low  = max(10, p.fc_Hz - bw_hz/2);
    f_high = min(fs/2 - 10, p.fc_Hz + bw_hz/2);

    if f_low < f_high
        Wn = max(0.001, min(0.999, [f_low, f_high] / (fs/2)));
        try
            bpf       = fir1(64, Wn, 'bandpass');
            signal_bw = filtfilt(bpf, 1, signal_dop);
        catch
            signal_bw = signal_dop;
        end
    else
        signal_bw = signal_dop;
    end

    % ---------------------------------------------------------------
    % 5. Ambient Noise — AWGN calibrated to desired SNR
    %    Coloured noise: illustrative low-frequency boost (70% white
    %    + 30% LPF at 0.3*Nyquist), renormalised to target power.
    %    NOT a calibrated environmental acoustic noise model.
    %    SNR is defined as: mean(signal_bw^2) / mean(noise^2) in linear.
    % ---------------------------------------------------------------
    signal_power = mean(signal_bw .^ 2);
    if signal_power == 0 || ~isfinite(signal_power)
        signal_power = 1e-10;
    end

    noise_power = signal_power / (10^(p.SNR_dB / 10));
    white_noise = sqrt(noise_power) * randn(1, N);

    try
        noise_lpf     = fir1(32, 0.3, 'low');
        colored_noise = 0.7 * white_noise + 0.3 * filtfilt(noise_lpf, 1, white_noise);
        colored_noise = colored_noise * sqrt(noise_power / max(mean(colored_noise.^2), eps));
    catch
        colored_noise = white_noise;
    end

    rx_signal = signal_bw + colored_noise;

    % ---------------------------------------------------------------
    % 6. Diagnostics
    % ---------------------------------------------------------------
    actual_snr = 10*log10(mean(signal_bw.^2) / max(mean(colored_noise.^2), eps));

    channel_info.bypass           = false;
    channel_info.path_loss_dB     = path_loss_dB;
    channel_info.attenuation_dB   = attenuation_loss_dB;
    channel_info.spreading_dB     = spreading_loss_dB;
    channel_info.SNR_actual_dB    = actual_snr;
    channel_info.delay_spread_s   = rms_delay;
    channel_info.doppler_Hz       = doppler_Hz;
    channel_info.noise_power      = mean(colored_noise.^2);
    channel_info.tap_delays       = tap_delays;
    channel_info.thorp_alpha      = alpha_dB_per_km;
    channel_info.d0_m             = p.d0_m;
    channel_info.spreading_exp_k  = 1;   % cylindrical; fixed in this version
end


function val = get_param(s, field, default)
    if isfield(s, field)
        val = s.(field);
    else
        val = default;
    end
end
