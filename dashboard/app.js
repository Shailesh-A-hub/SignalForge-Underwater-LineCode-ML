// SignalForge — Standalone Modern Web Dashboard Logic
// Implements 9-D k-NN ML Inference, Physical Acoustic Channel Simulation, Waveform Renderer, and MATLAB Exporter

document.addEventListener('DOMContentLoaded', () => {

  // 1. State
  const state = {
    snr: 15.0,
    multipath: 0.25,
    doppler: 0.50,
    distance: 350,
    priority: 'balanced',
    bits: [1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1, 1],
    objective: 'saw', // 'saw' or 'oracle'
    inspectScheme: 'ami',
    theme: 'dark' // 'dark' or 'matlab'
  };

  const schemeMeta = {
    nrzl:            { name: 'NRZ-L',            idx: 1, baseBw: 24.0, baseDc: 0.65, baseSync: 0.50, desc: 'Simple, narrow spectrum, significant DC component' },
    nrzi:            { name: 'NRZ-I',            idx: 2, baseBw: 24.0, baseDc: 0.65, baseSync: 0.50, desc: 'Differential level transition on bit 1' },
    rz:              { name: 'RZ',               idx: 3, baseBw: 48.0, baseDc: 0.50, baseSync: 1.00, desc: 'Return-to-zero half-bit pulses, self-clocking' },
    manchester:      { name: 'Manchester',       idx: 4, baseBw: 48.0, baseDc: 0.99, baseSync: 1.00, desc: 'Guaranteed mid-bit transition, optimal clock recovery' },
    ami:             { name: 'AMI',              idx: 5, baseBw: 24.0, baseDc: 1.00, baseSync: 0.50, desc: 'Pseudo-ternary, strictly DC-free, compact spectrum' },
    diff_manchester: { name: 'Diff. Manchester', idx: 6, baseBw: 48.0, baseDc: 0.99, baseSync: 1.00, desc: 'Differential clocking, immune to polarity inversion' }
  };

  const schemeKeys = ['nrzl', 'nrzi', 'rz', 'manchester', 'ami', 'diff_manchester'];

  // 2. DOM Elements
  const sliderSnr = document.getElementById('sliderSnr');
  const sliderMultipath = document.getElementById('sliderMultipath');
  const sliderDoppler = document.getElementById('sliderDoppler');
  const sliderDistance = document.getElementById('sliderDistance');

  const valSnr = document.getElementById('valSnr');
  const valMultipath = document.getElementById('valMultipath');
  const valDoppler = document.getElementById('valDoppler');
  const valDistance = document.getElementById('valDistance');

  const inputBits = document.getElementById('inputBits');
  const btnGenRandomBits = document.getElementById('btnGenRandomBits');

  const btnObjSaw = document.getElementById('btnObjSaw');
  const btnObjOracle = document.getElementById('btnObjOracle');

  const predCodeName = document.getElementById('predCodeName');
  const predObjectiveTag = document.getElementById('predObjectiveTag');
  const metricBer = document.getElementById('metricBer');
  const metricBw = document.getElementById('metricBw');
  const metricDc = document.getElementById('metricDc');
  const metricDcDesc = document.getElementById('metricDcDesc');
  const metricLatency = document.getElementById('metricLatency');
  const vectorRawPreview = document.getElementById('vectorRawPreview');
  const probBarsContainer = document.getElementById('probBarsContainer');

  const waveformCanvas = document.getElementById('waveformCanvas');
  const ctx = waveformCanvas.getContext('2d');

  const matlabCodeOutput = document.getElementById('matlabCodeOutput');
  const btnCopyMatlabCode = document.getElementById('btnCopyMatlabCode');
  const btnDownloadMFile = document.getElementById('btnDownloadMFile');
  const btnThemeToggle = document.getElementById('btnThemeToggle');
  const themeLabel = document.getElementById('themeLabel');
  const toastNotice = document.getElementById('toastNotice');

  // 3. Event Listeners
  sliderSnr.addEventListener('input', (e) => {
    state.snr = parseFloat(e.target.value);
    valSnr.textContent = state.snr.toFixed(1) + ' dB';
    updateAll();
  });

  sliderMultipath.addEventListener('input', (e) => {
    state.multipath = parseFloat(e.target.value);
    valMultipath.textContent = state.multipath.toFixed(2);
    updateAll();
  });

  sliderDoppler.addEventListener('input', (e) => {
    state.doppler = parseFloat(e.target.value);
    valDoppler.textContent = state.doppler.toFixed(2) + ' m/s';
    updateAll();
  });

  sliderDistance.addEventListener('input', (e) => {
    state.distance = parseInt(e.target.value, 10);
    valDistance.textContent = state.distance + ' m';
    updateAll();
  });

  document.querySelectorAll('.priority-chips .chip-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.priority-chips .chip-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      state.priority = btn.dataset.priority;
      updateAll();
    });
  });

  document.querySelectorAll('[data-scheme]').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('[data-scheme]').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      state.inspectScheme = btn.dataset.scheme;
      renderWaveforms();
      generateMatlabCode();
    });
  });

  btnObjSaw.addEventListener('click', () => {
    state.objective = 'saw';
    btnObjSaw.classList.add('active');
    btnObjOracle.classList.remove('active');
    predObjectiveTag.textContent = 'SAW Multi-Criteria';
    updateAll();
  });

  btnObjOracle.addEventListener('click', () => {
    state.objective = 'oracle';
    btnObjOracle.classList.add('active');
    btnObjSaw.classList.remove('active');
    predObjectiveTag.textContent = 'Oracle Minimum-BER';
    updateAll();
  });

  inputBits.addEventListener('input', () => {
    const raw = inputBits.value.replace(/[^01]/g, '');
    if (raw.length > 0) {
      state.bits = raw.split('').map(Number);
      updateAll();
    }
  });

  btnGenRandomBits.addEventListener('click', () => {
    const len = 12;
    const arr = [];
    for (let i = 0; i < len; i++) arr.push(Math.random() > 0.5 ? 1 : 0);
    state.bits = arr;
    inputBits.value = arr.join('');
    updateAll();
  });

  btnThemeToggle.addEventListener('click', () => {
    if (state.theme === 'dark') {
      state.theme = 'matlab';
      document.body.setAttribute('data-theme', 'matlab');
      themeLabel.textContent = 'Cyber Theme';
    } else {
      state.theme = 'dark';
      document.body.removeAttribute('data-theme');
      themeLabel.textContent = 'MATLAB Theme';
    }
    renderWaveforms();
  });

  btnCopyMatlabCode.addEventListener('click', () => {
    const code = matlabCodeOutput.textContent;
    navigator.clipboard.writeText(code).then(() => {
      showToast('MATLAB code copied to clipboard!');
    });
  });

  btnDownloadMFile.addEventListener('click', () => {
    const code = matlabCodeOutput.textContent;
    const blob = new Blob([code], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'signalforge_scenario.m';
    a.click();
    URL.revokeObjectURL(url);
    showToast('signalforge_scenario.m downloaded!');
  });

  function showToast(msg) {
    toastNotice.textContent = msg;
    toastNotice.style.display = 'block';
    setTimeout(() => { toastNotice.style.display = 'none'; }, 2600);
  }

  // 4. ML Inference Engine (9-D Feature Space k-NN Classifier)
  function runMLInference() {
    const tStart = performance.now();

    // 1. Form 9-D Feature Vector
    // [SNR, multipath_k, doppler_v, distance_m, is_balanced, is_low_ber, is_low_bw, is_sync, is_dc_free]
    const prioMap = ['balanced', 'low_ber', 'low_bandwidth', 'sync', 'dc_free'];
    const prioIdx = prioMap.indexOf(state.priority);
    const prioOneHot = [0, 0, 0, 0, 0];
    if (prioIdx >= 0) prioOneHot[prioIdx] = 1.0;

    const xRaw = [
      state.snr,
      state.multipath,
      state.doppler,
      state.distance,
      ...prioOneHot
    ];

    // 2. Standardize Features: x_norm = (x - mu) / sigma
    const mu = SIGNALFORGE_ML_DATA.mu_X;
    const sigma = SIGNALFORGE_ML_DATA.sigma_X;
    const xNorm = xRaw.map((val, idx) => (val - mu[idx]) / sigma[idx]);

    // 3. k-NN Search against N=120 Training Instances (k = 5)
    const XTrain = SIGNALFORGE_ML_DATA.X_train;
    const targets = (state.objective === 'oracle') 
      ? SIGNALFORGE_ML_DATA.y_oracle 
      : SIGNALFORGE_ML_DATA.y_saw;

    const distances = [];
    for (let i = 0; i < XTrain.length; i++) {
      let dSq = 0.0;
      for (let j = 0; j < 9; j++) {
        const trainNorm_j = (XTrain[i][j] - mu[j]) / sigma[j];
        const diff = xNorm[j] - trainNorm_j;
        dSq += diff * diff;
      }
      distances.push({ idx: i, dist: Math.sqrt(dSq), label: targets[i] });
    }

    distances.sort((a, b) => a.dist - b.dist);
    const kNeighbors = 5;
    const topK = distances.slice(0, kNeighbors);

    // 4. Compute 6-Element Posterior Vote Vector
    const votes = [0, 0, 0, 0, 0, 0];
    for (let i = 0; i < topK.length; i++) {
      const classIdx = topK[i].label - 1; // 0-indexed (0..5)
      votes[classIdx]++;
    }

    const probVector = votes.map(v => v / kNeighbors);

    // Winning class (mode)
    let maxVote = -1;
    let winningIdx = 0;
    for (let c = 0; c < 6; c++) {
      if (votes[c] > maxVote) {
        maxVote = votes[c];
        winningIdx = c;
      }
    }

    const winningSchemeKey = schemeKeys[winningIdx];
    const winningLabel = schemeMeta[winningSchemeKey].name;
    const heuristicConfidence = probVector[winningIdx];

    const tElapsed = performance.now() - tStart;

    return {
      schemeKey: winningSchemeKey,
      label: winningLabel,
      classIndex: winningIdx + 1,
      probVector: probVector,
      confidence: heuristicConfidence,
      inferenceTimeMs: tElapsed,
      featureVector: xRaw
    };
  }

  // 5. Physical Simulation Engine
  function runPhysicalSimulation(schemeKey) {
    const bits = state.bits;
    const nBits = bits.length;
    const samplesPerBit = 20;
    const nTotalSamples = nBits * samplesPerBit;

    // A. Generate TX Waveform
    const txSignal = new Float32Array(nTotalSamples);
    let prevDiffBit = 1;
    let amiPolarity = 1;

    for (let b = 0; b < nBits; b++) {
      const bit = bits[b];
      const startIdx = b * samplesPerBit;
      const midIdx = startIdx + Math.floor(samplesPerBit / 2);
      const endIdx = startIdx + samplesPerBit;

      switch (schemeKey) {
        case 'nrzl':
          const nrzlVal = (bit === 1) ? 1.0 : -1.0;
          for (let s = startIdx; s < endIdx; s++) txSignal[s] = nrzlVal;
          break;

        case 'nrzi':
          if (bit === 1) prevDiffBit = -prevDiffBit;
          for (let s = startIdx; s < endIdx; s++) txSignal[s] = prevDiffBit;
          break;

        case 'rz':
          for (let s = startIdx; s < midIdx; s++) txSignal[s] = (bit === 1) ? 1.0 : 0.0;
          for (let s = midIdx; s < endIdx; s++) txSignal[s] = 0.0;
          break;

        case 'manchester':
          const m1 = (bit === 1) ? 1.0 : -1.0;
          const m2 = (bit === 1) ? -1.0 : 1.0;
          for (let s = startIdx; s < midIdx; s++) txSignal[s] = m1;
          for (let s = midIdx; s < endIdx; s++) txSignal[s] = m2;
          break;

        case 'ami':
          let aVal = 0.0;
          if (bit === 1) {
            aVal = amiPolarity;
            amiPolarity = -amiPolarity;
          }
          for (let s = startIdx; s < endIdx; s++) txSignal[s] = aVal;
          break;

        case 'diff_manchester':
          // Mid-bit transition always; bit 0 transitions at start, bit 1 has no start transition
          if (bit === 0) prevDiffBit = -prevDiffBit;
          for (let s = startIdx; s < midIdx; s++) txSignal[s] = prevDiffBit;
          for (let s = midIdx; s < endIdx; s++) txSignal[s] = -prevDiffBit;
          prevDiffBit = -prevDiffBit;
          break;
      }
    }

    // B. Channel Impairments Simulation (Attenuation + 3-Path Multipath + Doppler phase drift + AWGN)
    const rxSignal = new Float32Array(nTotalSamples);
    const distLoss = 1.0 / Math.sqrt(1.0 + Math.pow(state.distance / 500.0, 1.6));
    const delay1 = 4;
    const delay2 = 8;
    const mpCoeff = state.multipath;
    const snrLin = Math.pow(10.0, state.snr / 10.0);
    const noiseStd = 1.0 / Math.sqrt(2.0 * snrLin);

    for (let s = 0; s < nTotalSamples; s++) {
      let val = txSignal[s];

      // Multipath reflections
      if (s >= delay1) val += mpCoeff * 0.6 * txSignal[s - delay1];
      if (s >= delay2) val += mpCoeff * 0.3 * txSignal[s - delay2];

      // Doppler phase modulation
      const phaseDrift = (state.doppler / 4.0) * Math.sin(2 * Math.PI * (s / nTotalSamples) * 3);
      val *= (1.0 + 0.15 * phaseDrift);

      // Path loss
      val *= distLoss;

      // Additive Gaussian Noise (Box-Muller transform)
      const u1 = Math.max(1e-7, Math.random());
      const u2 = Math.random();
      const z0 = Math.sqrt(-2.0 * Math.log(u1)) * Math.cos(2.0 * Math.PI * u2);
      val += z0 * noiseStd;

      rxSignal[s] = val;
    }

    // C. Decode & Calculate Empirical BER
    const decodedBits = [];
    let bitErrors = 0;

    for (let b = 0; b < nBits; b++) {
      const startIdx = b * samplesPerBit;
      const midIdx = startIdx + Math.floor(samplesPerBit / 2);
      const endIdx = startIdx + samplesPerBit;

      let detectedBit = 0;

      if (schemeKey === 'manchester' || schemeKey === 'diff_manchester') {
        let sum1 = 0, sum2 = 0;
        for (let s = startIdx; s < midIdx; s++) sum1 += rxSignal[s];
        for (let s = midIdx; s < endIdx; s++) sum2 += rxSignal[s];
        detectedBit = (sum1 > sum2) ? 1 : 0;
      } else if (schemeKey === 'ami') {
        let sum = 0;
        for (let s = startIdx; s < endIdx; s++) sum += Math.abs(rxSignal[s]);
        const avg = sum / samplesPerBit;
        detectedBit = (avg > 0.35 * distLoss) ? 1 : 0;
      } else {
        let sum = 0;
        for (let s = startIdx; s < endIdx; s++) sum += rxSignal[s];
        detectedBit = (sum > 0.0) ? 1 : 0;
      }

      decodedBits.push(detectedBit);
      if (detectedBit !== bits[b]) bitErrors++;
    }

    const measuredBer = bitErrors / nBits;
    const meta = schemeMeta[schemeKey];

    return {
      txSignal,
      rxSignal,
      decodedBits,
      bitErrors,
      measuredBer,
      bandwidthKhz: meta.baseBw,
      dcBalance: meta.baseDc,
      syncDensity: meta.baseSync,
      desc: meta.desc
    };
  }

  // 6. Waveform Canvas Renderer
  function renderWaveforms() {
    const inspectKey = state.inspectScheme;
    const sim = runPhysicalSimulation(inspectKey);
    const tx = sim.txSignal;
    const rx = sim.rxSignal;
    const bits = state.bits;
    const nBits = bits.length;
    const totalSamples = tx.length;

    const w = waveformCanvas.width;
    const h = waveformCanvas.height;
    ctx.clearRect(0, 0, w, h);

    const isMatlabTheme = (state.theme === 'matlab');
    const colorBg = isMatlabTheme ? '#ffffff' : '#040810';
    const colorGrid = isMatlabTheme ? '#e1e4e8' : '#141e30';
    const colorAxis = isMatlabTheme ? '#59636e' : '#334460';
    const colorText = isMatlabTheme ? '#24292f' : '#8b9bb4';
    const colorTx = isMatlabTheme ? '#0969da' : '#00e5ff';
    const colorRx = isMatlabTheme ? '#d97706' : '#ffb700';
    const colorDec = isMatlabTheme ? '#1a7f37' : '#00ff9d';
    const colorErr = '#cf222e';

    ctx.fillStyle = colorBg;
    ctx.fillRect(0, 0, w, h);

    // Sub-canvas vertical bands:
    // Band 1: TX (y: 20 to 90)
    // Band 2: RX Analog (y: 105 to 190)
    // Band 3: Decoded Bit Comparison (y: 205 to 260)
    const padL = 95;
    const padR = 25;
    const plotW = w - padL - padR;

    // Draw Bit Grid Lines
    ctx.strokeStyle = colorGrid;
    ctx.lineWidth = 1;
    ctx.font = '11px JetBrains Mono';
    ctx.fillStyle = colorText;

    for (let b = 0; b <= nBits; b++) {
      const x = padL + (b / nBits) * plotW;
      ctx.beginPath();
      ctx.moveTo(x, 15);
      ctx.lineTo(x, 265);
      ctx.stroke();

      if (b < nBits) {
        const textX = padL + ((b + 0.5) / nBits) * plotW;
        ctx.textAlign = 'center';
        ctx.fillText('b=' + bits[b], textX, 14);
      }
    }

    // 1. Draw TX Waveform (yCenter = 55, amplitude = 28)
    const yTxCenter = 55;
    ctx.strokeStyle = colorAxis;
    ctx.beginPath();
    ctx.moveTo(padL, yTxCenter);
    ctx.lineTo(w - padR, yTxCenter);
    ctx.stroke();

    ctx.textAlign = 'right';
    ctx.fillStyle = colorTx;
    ctx.fillText('TX Digital', padL - 8, yTxCenter + 4);

    ctx.strokeStyle = colorTx;
    ctx.lineWidth = 2.2;
    ctx.beginPath();
    for (let s = 0; s < totalSamples; s++) {
      const x = padL + (s / totalSamples) * plotW;
      const y = yTxCenter - tx[s] * 28;
      if (s === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    }
    ctx.stroke();

    // 2. Draw RX Corrupted Analog Signal (yCenter = 145, amplitude = 32)
    const yRxCenter = 145;
    ctx.strokeStyle = colorAxis;
    ctx.beginPath();
    ctx.moveTo(padL, yRxCenter);
    ctx.lineTo(w - padR, yRxCenter);
    ctx.stroke();

    ctx.fillStyle = colorRx;
    ctx.fillText('RX Corrupted', padL - 8, yRxCenter + 4);

    ctx.strokeStyle = colorRx;
    ctx.lineWidth = 1.4;
    ctx.beginPath();
    for (let s = 0; s < totalSamples; s++) {
      const x = padL + (s / totalSamples) * plotW;
      const y = yRxCenter - Math.max(-1.8, Math.min(1.8, rx[s])) * 24;
      if (s === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    }
    ctx.stroke();

    // 3. Draw Decoded Bits vs Original Bits
    const yDecCenter = 230;
    ctx.strokeStyle = colorAxis;
    ctx.beginPath();
    ctx.moveTo(padL, yDecCenter);
    ctx.lineTo(w - padR, yDecCenter);
    ctx.stroke();

    ctx.fillStyle = colorDec;
    ctx.fillText('Decoded', padL - 8, yDecCenter + 4);

    for (let b = 0; b < nBits; b++) {
      const startX = padL + (b / nBits) * plotW;
      const bitW = plotW / nBits;
      const decBit = sim.decodedBits[b];
      const isErr = (decBit !== bits[b]);

      ctx.fillStyle = isErr ? 'rgba(255, 71, 126, 0.22)' : 'rgba(0, 255, 157, 0.1)';
      ctx.fillRect(startX + 2, yDecCenter - 18, bitW - 4, 36);

      ctx.font = 'bold 13px JetBrains Mono';
      ctx.textAlign = 'center';
      ctx.fillStyle = isErr ? colorErr : colorDec;
      ctx.fillText(decBit + (isErr ? ' ✗' : ' ✓'), startX + bitW / 2, yDecCenter + 5);
    }
  }

  // 7. Dynamic MATLAB Script Generator
  function generateMatlabCode() {
    const bitStr = state.bits.join(' ');
    const code = `% =========================================================================
% SignalForge — Standalone Scenario Reproduction Script
% Generated automatically from SignalForge Live Web Dashboard
% =========================================================================

close all; clear; clc;

% 1. Channel Configuration
ch_params = struct();
ch_params.SNR_dB      = ${state.snr.toFixed(1)};      % Signal-to-Noise Ratio (dB)
ch_params.multipath_k = ${state.multipath.toFixed(2)};     % Multipath reflection coefficient
ch_params.doppler_v   = ${state.doppler.toFixed(2)};     % Doppler velocity (m/s)
ch_params.distance_m  = ${state.distance};        % Underwater acoustic distance (m)
ch_params.fc_Hz       = 5000;       % Center carrier frequency (Hz)
ch_params.num_paths   = 3;          % Direct + surface + bottom reflection
ch_params.max_delay_s = 4e-3;       % Max multipath delay spread (s)
ch_params.bw_fraction = 0.40;       % Bandwidth fraction

priority_mode = '${state.priority}';  % 'balanced' | 'low_ber' | 'low_bandwidth' | 'sync' | 'dc_free'
test_bits     = [${bitStr}];

% 2. Query Trained Machine Learning Model
fprintf('Querying SignalForge Machine Learning Classifier...\\n');
try
    ml_pred = predict_linecode_ml(ch_params, priority_mode);
    fprintf('--> ML Recommended Code: %%s (Confidence: %%.1f%%%%)\\n', ...
        ml_pred.predicted_label, ml_pred.confidence * 100);
    fprintf('--> 6-Class Probabilities: [%%s]\\n', num2str(ml_pred.class_scores, '%%.2f '));
catch
    fprintf('Running in standalone mode without pre-loaded .mat model.\\n');
end

% 3. Run Physical Waveform Simulation Across All 6 Candidate Schemes
fs = 48000;  % Sampling frequency (Hz)
Tb = 1e-3;   % Bit period (1 ms = 1 kbps bit rate)
schemes = {'nrzl','nrzi','rz','manchester','ami','diff_manchester'};

sim_results = run_simulation(test_bits, schemes, ch_params, fs, Tb);

% 4. Run SAW Multi-Criteria Decision Engine
dec = decision_engine([sim_results.metrics], priority_mode);
fprintf('\\n--> SAW Multi-Criteria Selection: %%s (Composite Score: %%.4f)\\n', ...
    upper(dec.best_scheme), max(cell2mat(struct2cell(dec.scores))));

% 5. Plot Physical Waveforms
figure('Name', 'SignalForge Scenario Reproduction', 'Color', 'w', 'Position', [100 100 900 450]);
subplot(2, 1, 1);
plot(sim_results(5).time_vec * 1000, sim_results(5).tx_waveform, 'b-', 'LineWidth', 1.8);
grid on; ylabel('TX Signal (V)');
title(sprintf('Acoustic Transmission — Scheme: %s | SNR: %.1f dB | Distance: %d m', ...
    upper('${state.inspectScheme}'), ch_params.SNR_dB, ch_params.distance_m));

subplot(2, 1, 2);
plot(sim_results(5).time_vec * 1000, sim_results(5).rx_waveform, 'r-', 'LineWidth', 1.2);
grid on; xlabel('Time (ms)'); ylabel('RX Signal (V)');
title('Received Corrupted Waveform (Attenuation, Multipath & Doppler Spread)');
`;

    matlabCodeOutput.textContent = code;
  }

  // 8. Main UI Update Coordinator
  function updateAll() {
    // Run ML
    const ml = runMLInference();

    // Run physical simulation for predicted scheme
    const sim = runPhysicalSimulation(ml.schemeKey);

    // Update Hero Card UI
    predCodeName.textContent = ml.label;
    predObjectiveTag.textContent = (state.objective === 'oracle') 
      ? 'Oracle Minimum-BER' 
      : 'SAW Multi-Criteria';

    metricBer.textContent = sim.measuredBer.toFixed(4);
    metricBer.style.color = (sim.measuredBer === 0) ? 'var(--accent-green)' : (sim.measuredBer < 0.05 ? 'var(--accent-amber)' : 'var(--accent-coral)');

    metricBw.textContent = sim.bandwidthKhz.toFixed(1) + ' kHz';
    metricDc.textContent = sim.dcBalance.toFixed(3);
    metricDcDesc.textContent = (sim.dcBalance >= 0.98) ? 'Strictly zero DC mean' : 'Moderate DC component';

    metricLatency.textContent = ml.inferenceTimeMs.toFixed(2) + ' ms';

    // 6-Class Probability Bars
    vectorRawPreview.textContent = 'P = [' + ml.probVector.map(p => p.toFixed(2)).join(', ') + ']';

    let barsHtml = '';
    for (let c = 0; c < 6; c++) {
      const sKey = schemeKeys[c];
      const sMeta = schemeMeta[sKey];
      const prob = ml.probVector[c];
      const pct = (prob * 100).toFixed(0);
      const isWinner = (sKey === ml.schemeKey);

      barsHtml += `
        <div class="prob-item ${isWinner ? 'winner' : ''}">
          <div class="prob-label-row">
            <span>${sMeta.name}</span>
            <span style="font-family: var(--font-mono);">${pct}%</span>
          </div>
          <div class="prob-progress-bg">
            <div class="prob-progress-fill" style="width: ${pct}%;"></div>
          </div>
        </div>
      `;
    }
    probBarsContainer.innerHTML = barsHtml;

    // Render Waveforms & MATLAB Code
    renderWaveforms();
    generateMatlabCode();
  }

  // Initial Execution
  updateAll();

});
