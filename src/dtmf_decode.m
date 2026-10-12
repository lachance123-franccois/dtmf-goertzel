function [digits, det] = dtmf_decode(x, fs, opts)
%DTMF_DECODE  Decode une suite de touches DTMF avec l'algorithme de Goertzel.
%   [digits, det] = DTMF_DECODE(x, fs, opts)
%     x    : signal audio (vecteur)
%     fs   : frequence d'echantillonnage (Hz), quelconque (8 kHz, 44.1 kHz...)
%     opts : structure optionnelle
%       .N          taille de bloc (defaut 205 echantillons a 8 kHz, mise a l'echelle)
%       .hop        pas entre blocs (defaut N/2)
%       .minFrac    part minimale de l'energie du bloc portee par les 2 tonalites [0.4]
%       .peakRatio  rapport min entre la 1re et la 2e frequence d'un groupe      [4]
%       .maxTwistDb ecart max de niveau ligne/colonne (twist)                   [8 dB]
%       .maxHarm    rapport max 2e harmonique / fondamentale (rejet de la voix)  [0.2]
%       .minBlocks  nb de blocs consecutifs identiques pour valider une touche   [2]
%   digits : chaine decodee
%   det    : details par bloc (labels, temps, criteres) pour les figures

if nargin < 3, opts = struct(); end
if ~isvector(x), x = mean(x, 2); end   % stereo -> mono
x = x(:);

N = getopt(opts, 'N', round(205 * fs / 8000));
hop = getopt(opts, 'hop', round(N/2));
minFrac = getopt(opts, 'minFrac', 0.4);
peakRatio = getopt(opts, 'peakRatio', 4);
maxTwistDb = getopt(opts, 'maxTwistDb', 8);
maxHarm = getopt(opts, 'maxHarm', 0.2);
minBlocks = getopt(opts, 'minBlocks', 2);

[layout, fRows, fCols] = dtmf_tables();

% --- Decoupage en blocs (une colonne par bloc) ---------------------------
if numel(x) < N
    x = [x; zeros(N - numel(x), 1)];
end
nb = floor((numel(x) - N) / hop) + 1;
idx = (1:N)' + (0:nb-1) * hop;
X = x(idx);

% --- Goertzel sur les 8 fondamentales et leurs 2es harmoniques ------------
freqs = [fRows, fCols, 2*fRows, 2*fCols];
P = goertzel_power(X, freqs, fs);          % 16 x nb
Pr = P(1:4, :);
Pc = P(5:8, :);

[pr, ir] = max(Pr, [], 1);
[pc, ic] = max(Pc, [], 1);
sr = sort(Pr, 1, 'descend');
sc = sort(Pc, 1, 'descend');

% Energie de reference : pour une sinusoide pure d'energie totale E sur le
% bloc, |X(f)|^2 = E*N/2. frac ~ 1 pour deux tonalites pures sans bruit.
E = sum(X.^2, 1) * N / 2;
frac = (pr + pc) ./ max(E, eps);
twistDb = 10 * log10((pr + eps) ./ (pc + eps));
harmR = P(sub2ind(size(P), 8 + ir, 1:nb)) ./ (pr + eps);
harmC = P(sub2ind(size(P), 12 + ic, 1:nb)) ./ (pc + eps);

valid = frac > minFrac ...
    & pr > peakRatio * sr(2, :) ...
    & pc > peakRatio * sc(2, :) ...
    & abs(twistDb) < maxTwistDb ...
    & harmR < maxHarm & harmC < maxHarm ...
    & E > 1e-10;

labels = repmat(' ', 1, nb);
labels(valid) = layout(sub2ind([4 4], ir(valid), ic(valid)));

% --- Anti-rebond : une touche = au moins minBlocks blocs consecutifs ------
digits = '';
prev = ' ';
run = 0;
emitted = false;
for b = 1:nb
    L = labels(b);
    if L == prev
        run = run + 1;
    else
        run = 1;
        emitted = false;
        prev = L;
    end
    if L ~= ' ' && run >= minBlocks && ~emitted
        digits(end+1) = L; %#ok<AGROW>
        emitted = true;
    end
end

det.labels = labels;
det.t = ((0:nb-1) * hop + N/2) / fs;
det.frac = frac;
det.twistDb = twistDb;
det.valid = valid;
det.P = P;
det.N = N;
det.hop = hop;
end

function v = getopt(s, name, default)
if isfield(s, name) && ~isempty(s.(name))
    v = s.(name);
else
    v = default;
end
end
