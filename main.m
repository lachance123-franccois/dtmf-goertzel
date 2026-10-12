%% Decodeur DTMF par l'algorithme de Goertzel
% Reproduit toutes les figures du README. Aucune toolbox requise
% (Signal Processing Toolbox utilisee seulement, si presente, pour valider).
%
% Auteur : Lachance - github.com/lachance123-franccois

clear; close all; clc;
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'src'));
resDir = fullfile(root, 'results');
if ~exist(resDir, 'dir'), mkdir(resDir); end
rng(42);

fs = 8000;
[layout, fRows, fCols] = dtmf_tables();
keysAll = reshape(layout', 1, []);

%% 1. Signal de test : les 16 touches
[x, info] = dtmf_generate(keysAll, fs, 0.08, 0.06);
fprintf('Signal de test : %d touches, %.2f s\n', numel(keysAll), numel(x)/fs);

fig = figure('Position', [100 100 1000 550]);
subplot(2,1,1);
plot((0:numel(x)-1)/fs, x); grid on;
xlabel('Temps (s)'); ylabel('Amplitude'); title('Signal DTMF : 1 2 3 A 4 5 6 B 7 8 9 C * 0 # D');
subplot(2,1,2);
[S, f, t] = stft_mag(x, fs, 256, 64);
imagesc(t, f, 20*log10(S + 1e-6)); axis xy; ylim([500 1800]);
hold on;
for fr = [fRows fCols], yline(fr, 'w:'); end
xlabel('Temps (s)'); ylabel('Frequence (Hz)'); title('Spectrogramme (8 frequences DTMF en pointilles)');
colorbar; caxis([-20 40]);
save_fig(fig, fullfile(resDir, 'fig1_signal_spectrogramme.png'));

%% 2. Spectre des 16 touches
fig = figure('Position', [100 100 1100 800]);
for k = 1:16
    xk = dtmf_generate(keysAll(k), fs, 0.1, 0);
    Nf = 2048;
    Xk = abs(fft(xk, Nf));
    fk = (0:Nf/2-1) * fs / Nf;
    subplot(4, 4, k);
    plot(fk, 20*log10(Xk(1:Nf/2) + 1e-6)); hold on;
    xline(fRows, 'r:'); xline(fCols, 'g:');
    xlim([500 1800]); ylim([-20 40]); grid on;
    title(sprintf('Touche %s', keysAll(k)));
end
sgtitle('Spectre de chaque touche (rouge : lignes, vert : colonnes)');
save_fig(fig, fullfile(resDir, 'fig2_spectres_16_touches.png'));

%% 3. Decodage d'une sequence (numero de telephone fictif) avec bruit
number = '0612345789';
xs = dtmf_generate(number, fs, 0.07, 0.05);
sigma = sqrt(0.25 / 10^(10/10));                % SNR = 10 dB
ys = xs + sigma * randn(size(xs));
[digits, det] = dtmf_decode(ys, fs);
fprintf('Sequence emise  : %s\nSequence decodee : %s (SNR 10 dB)\n', number, digits);

fig = figure('Position', [100 100 1000 450]);
subplot(2,1,1);
plot((0:numel(ys)-1)/fs, ys); grid on; xlim([0 numel(ys)/fs]);
title(sprintf('Emis : %s   |   Decode : %s   (SNR = 10 dB)', number, digits));
ylabel('Amplitude');
subplot(2,1,2);
plot(det.t, det.frac, 'LineWidth', 1.2); hold on;
yline(0.4, 'r--', 'seuil');
for b = find(det.valid)
    text(det.t(b), det.frac(b) + 0.05, det.labels(b), 'HorizontalAlignment', 'center', 'FontSize', 8);
end
grid on; xlim([0 numel(ys)/fs]); ylim([0 1.2]);
xlabel('Temps (s)'); ylabel('Part d''energie DTMF');
title('Critere de decision par bloc de N = 205 echantillons (et etiquette detectee)');
save_fig(fig, fullfile(resDir, 'fig3_decodage_sequence.png'));

%% 4. Validation de Goertzel contre la FFT (et goertzel() de MATLAB si dispo)
N = 205;
xb = randn(N, 1);
kbin = round([fRows fCols] / fs * N);          % bins entiers les plus proches
fbin = kbin * fs / N;
Pg = goertzel_power(xb, fbin, fs);
Xf = fft(xb);
Pf = abs(Xf(kbin + 1)).^2;
fprintf('Erreur relative max Goertzel vs FFT : %.2e\n', max(abs(Pg - Pf) ./ Pf));
if exist('goertzel', 'file')
    Pm = abs(goertzel(xb, kbin + 1)).^2;
    fprintf('Erreur relative max Goertzel (maison) vs goertzel() MATLAB : %.2e\n', ...
        max(abs(Pg - Pm) ./ Pm));
end

%% 5. Cout de calcul : Goertzel vs FFT
% Goertzel : 1 multiplication reelle par echantillon et par frequence (+ 3 en fin)
% FFT radix-2 sur 256 points : (N/2)log2(N) multiplications complexes = 4 reelles chacune
nF = 8;
opsGoertzel = nF * (N + 3);
Nfft = 256;
opsFFT = 4 * (Nfft/2) * log2(Nfft);
fprintf('\nMultiplications reelles par bloc : Goertzel (8 freq.) = %d, FFT 256 pts = %d\n', ...
    opsGoertzel, opsFFT);
Xblocks = randn(N, 2000);
tic; goertzel_power(Xblocks, [fRows fCols], fs); tG = toc;
tic; F = fft(Xblocks, Nfft); %#ok<NASGU>
tF = toc;
fprintf('Temps pour 2000 blocs : Goertzel vectorise %.1f ms, FFT %.1f ms\n', 1e3*tG, 1e3*tF);
fprintf('(la FFT de MATLAB est tres optimisee : sur DSP/microcontroleur, Goertzel gagne)\n');

%% 6. Taux de bonne detection en fonction du SNR
snrDb = -6:1:20;
nTrials = 300;
fprintf('\nMonte-Carlo : %d tirages x %d SNR (quelques dizaines de secondes)...\n', nTrials, numel(snrDb));
res = dtmf_eval_snr(snrDb, nTrials, fs, 0.08);
res40 = dtmf_eval_snr(snrDb, nTrials, fs, 0.04);

fig = figure('Position', [100 100 800 450]);
plot(snrDb, 100*res.rate, 'o-', 'LineWidth', 1.5); hold on;
plot(snrDb, 100*res40.rate, 's-', 'LineWidth', 1.5);
plot(snrDb, 100*res.missed, '--', 'LineWidth', 1);
plot(snrDb, 100*res.wrong, ':', 'LineWidth', 1.5);
grid on; ylim([0 105]);
xlabel('SNR (dB)'); ylabel('%');
legend('Bonne detection (80 ms)', 'Bonne detection (40 ms)', ...
    'Non-detection (80 ms)', 'Fausse touche (80 ms)', 'Location', 'east');
title(sprintf('Decodeur DTMF : %d tirages par point', nTrials));
save_fig(fig, fullfile(resDir, 'fig4_detection_vs_snr.png'));

i0 = find(snrDb == 0, 1);
fprintf('A 0 dB : %.1f %% de bonne detection (80 ms), %.1f %% (40 ms)\n', ...
    100*res.rate(i0), 100*res40.rate(i0));
i90 = find(res.rate >= 0.99, 1);
if ~isempty(i90)
    fprintf('Detection >= 99 %% des %d dB (tonalite de 80 ms)\n', snrDb(i90));
end

%% 7. Matrice de confusion a faible SNR
iC = find(snrDb == -2, 1);
conf = res.conf{iC};
fig = figure('Position', [100 100 800 600]);
imagesc(conf ./ sum(conf, 2)); colorbar; colormap(flipud(gray));
set(gca, 'XTick', 1:18, 'XTickLabel', [cellstr(keysAll')' {'aucune', 'mult.'}], ...
    'YTick', 1:16, 'YTickLabel', cellstr(keysAll'));
xlabel('Touche decodee'); ylabel('Touche emise');
title(sprintf('Matrice de confusion a SNR = %d dB', snrDb(iC)));
save_fig(fig, fullfile(resDir, 'fig5_confusion.png'));

%% 8. Robustesse a la duree de la tonalite (SNR fixe)
durs = 0.02:0.01:0.10;
rateDur = zeros(size(durs));
for i = 1:numel(durs)
    r = dtmf_eval_snr(5, 200, fs, durs(i));
    rateDur(i) = r.rate;
end
fig = figure('Position', [100 100 700 400]);
plot(1e3*durs, 100*rateDur, 'o-', 'LineWidth', 1.5); grid on;
xlabel('Duree de la tonalite (ms)'); ylabel('Bonne detection (%)');
title('Influence de la duree de la tonalite (SNR = 5 dB, N = 205)');
save_fig(fig, fullfile(resDir, 'fig6_detection_vs_duree.png'));

%% 9. (Optionnel) Votre propre enregistrement
% Enregistrez les touches d'un telephone (ou d'un generateur en ligne) et
% placez le fichier dans data/mon_enregistrement.wav
recFile = fullfile(root, 'data', 'mon_enregistrement.wav');
if exist(recFile, 'file')
    [xr, fsr] = audioread(recFile);
    dr = dtmf_decode(xr, fsr);
    fprintf('\nEnregistrement reel (%s, fs = %d Hz) : %s\n', recFile, fsr, dr);
else
    fprintf('\n(Pas d''enregistrement dans data/ : etape 9 ignoree)\n');
end

% Exporter le signal de test en .wav pour l'ecouter
audiowrite(fullfile(resDir, 'sequence_0612345789.wav'), 0.9*ys/max(abs(ys)), fs);
fprintf('\nFigures et audio enregistres dans %s\n', resDir);
