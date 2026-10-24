% VALIDATE_D1_BYPASS
% =========================================================
% Deliverable D1 Validation: Encoder/Decoder Distortion-Free Channel Test
%
% Tests all six line-coding schemes (NRZ-L, NRZ-I, RZ, Manchester,
% AMI, Differential Manchester) through the channel in genuine BYPASS mode
% (params.bypass = true). Verifies that in the absence of channel
% impairments, every scheme achieves exactly BER = 0 across diverse bit
% patterns (all zeros, all ones, alternating 0/1, and pseudo-random sequences).
% =========================================================

close all;

% Ensure project directories are on MATLAB search path
base_dir = fileparts(fileparts(mfilename('fullpath')));
if isempty(base_dir), base_dir = pwd; end
addpath(genpath(base_dir));

fprintf('=========================================================\n');
fprintf('  SignalForge: Deliverable D1 Bypass Validation\n');
fprintf('=========================================================\n\n');

fs = 48000;
Tb = 1e-3;

schemes = {'nrzl', 'nrzi', 'rz', 'manchester', 'ami', 'diff_manchester'};
labels  = {'NRZ-L', 'NRZ-I', 'RZ', 'Manchester', 'AMI', 'Diff. Manchester'};

% Test patterns
patterns = struct();
patterns(1).name = 'All Zeros [100 bits]';
patterns(1).bits = zeros(1, 100);

patterns(2).name = 'All Ones [100 bits]';
patterns(2).bits = ones(1, 100);

patterns(3).name = 'Alternating 0-1 [100 bits]';
patterns(3).bits = repmat([0 1], 1, 50);

rng(42);
patterns(4).name = 'Random PRBS (Seed 42) [500 bits]';
patterns(4).bits = randi([0 1], 1, 500);

rng(100);
patterns(5).name = 'Random PRBS (Seed 100) [1000 bits]';
patterns(5).bits = randi([0 1], 1, 1000);

bypass_params = struct('bypass', true);

all_passed = true;

for p_idx = 1:length(patterns)
    p_name = patterns(p_idx).name;
    bits   = patterns(p_idx).bits;
    fprintf('Pattern %d: %s\n', p_idx, p_name);
    fprintf('---------------------------------------------------------\n');
    fprintf('  %-18s | %-12s | %-12s | %-8s\n', 'Scheme', 'Bits Tested', 'Bit Errors', 'Status');
    fprintf('  -------------------+--------------+--------------+---------\n');

    for s = 1:length(schemes)
        sc = schemes{s};
        % Run simulation with channel bypass enabled
        res = run_simulation(bits, {sc}, bypass_params, fs, Tb);
        n_err = res(1).metrics.num_errors;
        n_tot = length(bits);

        if n_err == 0
            status = 'PASS';
        else
            status = 'FAIL';
            all_passed = false;
        end
        fprintf('  %-18s | %-12d | %-12d | %-8s\n', labels{s}, n_tot, n_err, status);
    end
    fprintf('\n');
end

fprintf('=========================================================\n');
if all_passed
    fprintf('  DELIVERABLE D1 RESULT: ALL TESTS PASSED (BER = 0.000)\n');
    fprintf('  The encoder/decoder implementations are verified correct\n');
    fprintf('  in genuine bypass mode across all test sequences.\n');
else
    fprintf('  DELIVERABLE D1 RESULT: FAILURES DETECTED.\n');
end
fprintf('=========================================================\n');
