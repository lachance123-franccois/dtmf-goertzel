function digits = dtmf_decode(x, fs)
% DTMF_DECODE Décode les touches DTMF à partir d'un signal audio x à la fréquence fs.
if ~isvector(x), x = mean(x, 2); end % Stéréo -> Mono
x = x(:);

% Paramètres fixes (optimisés pour fs = 8000 Hz)
N = round(205 * fs / 8000);
hop = round(N / 2);
[layout, fRows, fCols] = dtmf_tables();

% Fenêtrage matriciel
if numel(x) < N, x = [x; zeros(N - numel(x), 1)]; end
nb = floor((numel(x) - N) / hop) + 1;
X = x((1:N)' + (0:nb-1) * hop);

% Analyse spectrale (Goertzel) sur les fréquences fondamentales
P = goertzel_power(X, [fRows, fCols], fs); 
Pr = P(1:4, :); Pc = P(5:8, :);

[~, ir] = max(Pr, [], 1);
[~, ic] = max(Pc, [], 1);

% Validation basique (énergie minimale et émergence des pics)
E = sum(X.^2, 1) * N / 2;
valid = ((max(Pr,[],1) + max(Pc,[],1)) ./ max(E, eps) > 0.4) & (E > 1e-10);

% Extraction et filtrage des doublons successifs
labels = repmat(' ', 1, nb);
labels(valid) = layout(sub2ind([4 4], ir(valid), ic(valid)));

% Suppression des répétitions pour ne garder que la séquence de touches
idx = [true, labels(1:end-1) ~= labels(2:end)];
digits = labels(valid & idx);
digits(digits == ' ') = [];
end
