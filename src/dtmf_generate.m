function [x, info] = dtmf_generate(keys, fs, toneDur, gapDur, amp)
% DTMF_GENERATE Génère un signal audio DTMF pour une suite de touches.
%
%   [x, info] = DTMF_GENERATE(keys, fs, toneDur, gapDur, amp)
%
%   Entrées :
%       keys    : Chaîne de caractères parmi '0'-'9', '*', '#', 'A'-'D'
%       fs      : Fréquence d'échantillonnage (Hz)          [Défaut: 8000]
%       toneDur : Durée de chaque tonalité (s)               [Défaut: 0.08]
%       gapDur  : Durée des silences entre tonalités (s)     [Défaut: 0.06]
%       amp     : Amplitude de CHAQUE sinusoïde              [Défaut: 0.5]
%
%   Sorties :
%       x       : Vecteur colonne du signal (silence au début et à la fin)
%       info    : Structure contenant les métadonnées (instants de début/fin)

    % Gestion des arguments par défaut
    if nargin < 2 || isempty(fs),      fs = 8000;    end
    if nargin < 3 || isempty(toneDur), toneDur = 0.08; end
    if nargin < 4 || isempty(gapDur),  gapDur = 0.06;  end
    if nargin < 5 || isempty(amp),     amp = 0.5;      end

    % Chargement des tables de fréquences de référence
    [layout, fRows, fCols] = dtmf_tables();
    
    % Calcul des tailles de blocs d'échantillons
    nTone = round(toneDur * fs);
    nGap  = round(gapDur * fs);
    nKeys = numel(keys);
    
    % Vecteur temps unitaire pour un bloc de tonalité
    t = (0:nTone-1)' / fs;

    % PREALLOCATION MÉMOIRE (Optimisation GitHub / Performance)
    totalSamples = nGap + nKeys * (nTone + nGap);
    x = zeros(totalSamples, 1);
    
    % Initialisation de la structure info
    info.keys = keys;
    info.tStart = zeros(1, nKeys);
    info.tEnd   = zeros(1, nKeys);
    info.fs = fs;

    % Curseur d'écriture dans le vecteur global (commence après le 1er silence)
    ptr = nGap + 1;

    % Boucle de génération des tonalités
    for k = 1:nKeys
        % Recherche des coordonnées (ligne, colonne) dans la matrice DTMF
        [r, c] = find(layout == upper(keys(k)));
        if isempty(r)
            error('dtmf_generate:badKey', 'Touche inconnue : %s', keys(k));
        end
        
        % Synthèse mathématique du double-ton
        tone = amp * (sin(2*pi*fRows(r)*t) + sin(2*pi*fCols(c)*t));
        
        % Enregistrement des marqueurs temporels physiques (s)
        info.tStart(k) = (ptr - 1) / fs;
        
        % Écriture directe dans la zone mémoire préallouée
        x(ptr : ptr + nTone - 1) = tone;
        ptr = ptr + nTone;
        
        info.tEnd(k) = (ptr - 1) / fs;
        
        % Le silence (gap) est déjà présent (zeros), on déplace simplement le pointeur
        ptr = ptr + nGap;
    end
end
