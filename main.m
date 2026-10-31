%% Decodeur DTMF par l'algorithme de Goertzel - Version Live Animee

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

fig = figure('Position', [100 100 1000 550], 'Name', 'Analyse Globale du Signal');
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
fig = figure('Position', [100 100 1100 800], 'Name', 'Spectres de Reference');
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

%% 3. Decodage d'une sequence avec animation en temps reel
number = '0612345789';
xs = dtmf_generate(number, fs, 0.07, 0.05);
sigma = sqrt(0.25 / 10^(10/10));                % SNR = 10 dB
ys = xs + sigma * randn(size(xs));

% Appel du decodeur
digits = dtmf_decode(ys, fs);

% Extraction des blocs pour l'animation
N = round(205 * fs / 8000); hop = round(N / 2);
nb = floor((numel(ys) - N) / hop) + 1;
X_block = ys((1:N)' + (0:nb-1) * hop);
P_block = goertzel_power(X_block, [fRows, fCols], fs);
E_block = sum(X_block.^2, 1) * N / 2;
det.t = ((0:nb-1) * hop + N/2) / fs;
det.frac = (max(P_block(1:4,:),[],1) + max(P_block(5:8,:),[],1)) ./ max(E_block, eps);
det.valid = (det.frac > 0.4) & (E_block > 1e-10);
[~, ir_block] = max(P_block(1:4,:), [], 1); [~, ic_block] = max(P_block(5:8,:), [], 1);
det.labels = repmat(' ', 1, nb);
det.labels(det.valid) = layout(sub2ind([4 4], ir_block(det.valid), ic_block(det.valid)));

% Fenetre de rendu live
figLive = figure('Position', [150 150 1000 500], 'Name', 'Decodage DTMF en Temps Reel');
subplot(2,1,1);
plot((0:numel(ys)-1)/fs, ys, 'Color', [0.5 0.5 0.5]); grid on; hold on;
hTimeLine = xline(0, 'r-', 'LineWidth', 1.5);
title('Signal Temporel Bruite (SNR = 10 dB)'); ylabel('Amplitude'); xlim([0 numel(ys)/fs]);

subplot(2,1,2);
hEnergy = plot(det.t, det.frac, 'LineWidth', 1.2, 'Color', [0 0.447 0.741]); hold on;
yline(0.4, 'r--', 'Seuil Detection');
hScanLine = xline(0, 'r-', 'LineWidth', 1.5);
grid on; xlim([0 numel(ys)/fs]); ylim([0 1.2]);
xlabel('Temps (s)'); ylabel('Part d''energie DTMF');
hTitle = title('Analyse Frequentielle Glissante...');

fprintf('\nLancement du decodage temps reel...\n');
stringLive = '';
for b = 1:3:nb % Balayage pas a pas accelere
    set(hTimeLine, 'Value', det.t(b));
    set(hScanLine, 'Value', det.t(b));
    
    if det.valid(b) && det.labels(b) ~= ' '
        plot(det.t(b), det.frac(b), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 4);
        text(det.t(b), det.frac(b) + 0.08, det.labels(b), 'Color', 'r', 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
        if isempty(stringLive) || stringLive(end) ~= det.labels(b)
            stringLive = [stringLive, det.labels(b)]; %#ok<AGROW>
        end
    end
    set(hTitle, 'String', sprintf('Flux en cours de lecture... Sequence captee : [%s]', stringLive));
    drawnow;
    pause(0.01);
end
set(hTitle, 'String', sprintf('Decodage Termine ! Resultat Final : %s', digits));
fprintf('Sequence emise  : %s\nSequence decodee : %s\n\n', number, digits);
save_fig(figLive, fullfile(resDir, 'fig3_decodage_sequence.png'));

%% 4. Validation de Goertzel contre la FFT
N = 205; xb = randn(N, 1);
kbin = round([fRows fCols] / fs * N);
fbin = kbin * fs / N;
Pg = goertzel_power(xb, fbin, fs);
Xf = fft(xb); Pf = abs(Xf(kbin + 1)).^2;
fprintf('Erreur relative max Goertzel vs FFT : %.2e\n', max(abs(Pg - Pf) ./ Pf));

%% 5. Cout de calcul : Goertzel vs FFT
nF = 8; opsGoertzel = nF * (N + 3); Nfft = 256;
opsFFT = 4 * (Nfft/2) * log2(Nfft);
fprintf('Multiplications reelles : Goertzel (8 freq.) = %d, FFT 256 pts = %d\n', opsGoertzel, opsFFT);

%% 6. Taux de bonne detection (Monte-Carlo avec barre de progression)
snrDb = -6:1:20;
nTrials = 300;
fprintf('\nLancement du test de robustesse Monte-Carlo...\n');

res.rate = zeros(size(snrDb)); res.missed = zeros(size(snrDb)); res.wrong = zeros(size(snrDb)); res.conf = cell(size(snrDb));
res40.rate = zeros(size(snrDb));

for i = 1:numel(snrDb)
    % Barre de progression ASCII
    fracProg = i / numel(snrDb);
    barLen = 20;
    nBars = round(fracProg * barLen);
    barStr = [repmat('=', 1, nBars), repmat('-', 1, barLen - nBars)];
    fprintf('\rCalcul SNR [%s] %3.0f%% (Courant: %d dB)', barStr, fracProg*100, snrDb(i));
    
    r80 = dtmf_eval_snr(snrDb(i), nTrials, fs, 0.08);
    r40 = dtmf_eval_snr(snrDb(i), nTrials, fs, 0.04);
    
    res.rate(i) = r80.rate; res.missed(i) = r80.missed; res.wrong(i) = r80.wrong; res.conf{i} = r80.conf{1};
    res40.rate(i) = r40.rate;
end
fprintf('\nMonte-Carlo termine avec succes.\n');

fig = figure('Position', [100 100 800 450], 'Name', 'Performances du Decodeur');
plot(snrDb, 100*res.rate, 'o-', 'LineWidth', 1.5); hold on;
plot(snrDb, 100*res40.rate, 's-', 'LineWidth', 1.5);
grid on; ylim([0 105]); xlabel('SNR (dB)'); ylabel('% Reussite');
legend('Tonalite 80 ms', 'Tonalite 40 ms', 'Location', 'east');
title('Performance du Decodeur DTMF en fonction du bruit');
save_fig(fig, fullfile(resDir, 'fig4_detection_vs_snr.png'));

%% 7. Matrice de confusion a faible SNR
iC = find(snrDb == -2, 1);
conf = res.conf{iC};
fig = figure('Position', [100 100 800 600], 'Name', 'Matrice de Confusion');
imagesc(conf ./ sum(conf, 2)); colorbar; colormap(flipud(gray));
set(gca, 'XTick', 1:18, 'XTickLabel', [cellstr(keysAll')' {'aucune', 'mult.'}], 'YTick', 1:16, 'YTickLabel', cellstr(keysAll'));
title(sprintf('Matrice de confusion a SNR = %d dB', snrDb(iC)));
save_fig(fig, fullfile(resDir, 'fig5_confusion.png'));
%% 8. Robustesse a la duree de la tonalite (SNR difficile)
durs = 0.02:0.01:0.10;
rateDur = zeros(size(durs));
for i = 1:numel(durs)
    % Passage à -2 dB pour voir la rupture de performance sous les 30 ms
    r = dtmf_eval_snr(-2, 200, fs, durs(i)); 
    rateDur(i) = r.rate;
end
fig = figure('Position', [100 100 700 400], 'Name', 'Limites de Duree');
plot(1e3*durs, 100*rateDur, 'o-', 'LineWidth', 1.5); grid on;
ylim([0 105]); % Fixe l'axe Y pour mieux voir la courbe descendre
xlabel('Duree (ms)'); ylabel('Bonne detection (%)');
title('Influence de la duree de la tonalite (SNR = -2 dB)');
save_fig(fig, fullfile(resDir, 'fig6_detection_vs_duree.png'));


%% 9. Enregistrement personnel 
recFile = fullfile(root, 'data', 'mon_enregistrement.wav');
if exist(recFile, 'file')
    [xr, fsr] = audioread(recFile);
    dr = dtmf_decode(xr, fsr);
    fprintf('\nEnregistrement reel (%s) : %s\n', recFile, dr);
end

audiowrite(fullfile(resDir, 'sequence_0612345789.wav'), 0.9*ys/max(abs(ys)), fs);
fprintf('\nTout a ete sauvegarde dans : %s\n', resDir);
