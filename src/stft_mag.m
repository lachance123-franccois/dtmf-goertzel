function [S, f, t] = stft_mag(x, fs, nwin, hop)
%Spectrogramme en module (fenetre de Hann), sans toolbox.
%   [S, f, t] = STFT_MAG(x, fs, nwin, hop) renvoie S (nfreq x ntrames) en module,
%   f en Hz et t en s (centre des trames).

    x = x(:);
    if numel(x) < nwin, x = [x; zeros(nwin - numel(x), 1)]; end
    w = 0.5 - 0.5*cos(2*pi*(0:nwin-1)'/nwin);
    nb = floor((numel(x) - nwin) / hop) + 1;
    idx = (1:nwin)' + (0:nb-1) * hop;
    F = fft(x(idx) .* w, nwin);
    S = abs(F(1:floor(nwin/2)+1, :));
    f = (0:floor(nwin/2))' * fs / nwin;
    t = ((0:nb-1) * hop + nwin/2) / fs;
end
