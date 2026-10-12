function P = goertzel_power(X, f, fs)

if isvector(X), X = X(:); end
[N, B] = size(X);
f = f(:);
c = 2 * cos(2*pi*f/fs);          % nf x 1
s1 = zeros(numel(f), B);
s2 = zeros(numel(f), B);
for n = 1:N
    s0 = X(n, :) + c .* s1 - s2; % expansion implicite (nf x B)
    s2 = s1;
    s1 = s0;
end
P = s1.^2 + s2.^2 - c .* s1 .* s2;
end

%Puissance spectrale |X(f)|^2 par l'algorithme de Goertzel.
%   P = GOERTZEL_POWER(X, f, fs)
%     X  : signal (vecteur) ou matrice N x B (un bloc par colonne)
%     f  : vecteur de frequences d'analyse (Hz), pas forcement sur la grille FFT
%     fs : frequence d'echantillonnage (Hz)
%   P  : matrice numel(f) x B, P(i,b) = |sum_n X(n,b) exp(-j 2 pi f_i n / fs)|^2
%
%   Recurrence du second ordre (un seul coefficient reel par frequence) :
%       s[n] = x[n] + 2cos(w) s[n-1] - s[n-2]
%       |X(w)|^2 = s[N-1]^2 + s[N-2]^2 - 2cos(w) s[N-1] s[N-2]
%   Le calcul est vectorise sur les frequences ET sur les blocs : la boucle
%   ne porte que sur les N echantillons d'un bloc.
