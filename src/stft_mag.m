function [S, f, t] = stft_mag(x, fs, nwin, hop)
% STFT_MAG Calcule la magnitude de la Transformée de Fourier à Court Terme (STFT).
%
%   [S, f, t] = STFT_MAG(x, fs, nwin, hop)
%
%   Entrées :
%       x    : Vecteur du signal temporel (mono)
%       fs   : Fréquence d'échantillonnage (Hz)
%       nwin : Taille de la fenêtre de Hann (nombre d'échantillons)
%       hop  : Pas d'avancement de la fenêtre (nombre d'échantillons)
%
%   Sorties :
%       S    : Matrice des magnitudes spectrales [Fréquences x Blocs]
%       f    : Vecteur des fréquences physiques associées (Hz)
%       t    : Vecteur des instants temporels centraux des blocs (s)

    % Vectorisation du signal d'entrée
    x = x(:);
    
    % Zéro-padding initial si le signal est plus court que la fenêtre
    if numel(x) < nwin
        x = [x; zeros(nwin - numel(x), 1)]; 
    end
    
    % Génération mathématique de la fenêtre de Hann
    w = 0.5 - 0.5 * cos(2 * pi * (0:nwin-1)' / nwin);
    
    % Calcul du nombre de blocs et création de la matrice de fenêtrage
    nb = floor((numel(x) - nwin) / hop) + 1;
    idx = (1:nwin)' + (0:nb-1) * hop;
    
    % Calcul de la FFT vectorisée avec application de la fenêtre
    F = fft(x(idx) .* w, nwin);
    
    % Extraction du spectre unilatéral (Nyquist) et calcul de la magnitude
    nBins = floor(nwin / 2) + 1;
    S = abs(F(1:nBins, :));
    
    % Cartographie des axes physiques (Fréquence et Temps)
    f = (0:nBins-1)' * fs / nwin;
    t = ((0:nb-1) * hop + nwin/2) / fs;
end
