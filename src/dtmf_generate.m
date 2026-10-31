function [x, info] = dtmf_generate(keys, fs, toneDur, gapDur, amp)

if nargin < 2 || isempty(fs),      fs = 8000;    end
if nargin < 3 || isempty(toneDur), toneDur = 0.08; end
if nargin < 4 || isempty(gapDur),  gapDur = 0.06;  end
if nargin < 5 || isempty(amp),     amp = 0.5;      end

[layout, fRows, fCols] = dtmf_tables();
nTone = round(toneDur * fs);
nGap  = round(gapDur * fs);
t = (0:nTone-1)' / fs;

x = zeros(nGap, 1);
info.keys = keys;
info.tStart = zeros(1, numel(keys));
info.tEnd   = zeros(1, numel(keys));

for k = 1:numel(keys)
    [r, c] = find(layout == upper(keys(k)));
    if isempty(r)
        error('dtmf_generate:badKey', 'Touche inconnue : %s', keys(k));
    end
    tone = amp * (sin(2*pi*fRows(r)*t) + sin(2*pi*fCols(c)*t));
    info.tStart(k) = numel(x) / fs;
    x = [x; tone]; %#ok<AGROW>
    info.tEnd(k) = numel(x) / fs;
    x = [x; zeros(nGap, 1)]; %#ok<AGROW>
end
info.fs = fs;
end

%Genere un signal DTMF pour une suite de touches.
%   [x, info] = DTMF_GENERATE(keys, fs, toneDur, gapDur, amp)
%     keys    : chaine de caracteres parmi 0-9, *, #, A-D
%     fs      : frequence d'echantillonnage (Hz)          [8000]
%     toneDur : duree de chaque tonalite (s)               [0.08]
%     gapDur  : duree des silences entre tonalites (s)     [0.06]
%     amp     : amplitude de CHAQUE sinusoide              [0.5]
%   x    : signal colonne (silence au debut et a la fin)
%   info : structure avec les instants de debut/fin de chaque touche (s)
