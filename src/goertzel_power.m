function P = goertzel_power(X, f, fs)
% GOERTZEL_POWER Calcule la puissance spectrale |X(f)|^2 par l'algorithme de Goertzel.
%
%   P = GOERTZEL_POWER(X, f, fs)
%
%   Entrées :
%       X  : Signal d'entrée (vecteur ou matrice [N_echantillons x N_blocs])
%       f  : Vecteurs des fréquences à analyser (Hz)
%       fs : Fréquence d'échantillonnage (Hz)
%
%   Sortie :
%       P  : Matrice des puissances [N_fréquences x N_blocs]

    if isvector(X)
        X = X(:); 
    end
    [N, B] = size(X);
    f = f(:);
    
    % Coefficient récurrent réel pour chaque fréquence d'analyse
    c = 2 * cos(2 * pi * f / fs); % Taille : [N_fréquences x 1]
    
    % États internes du filtre RII (second ordre)
    s1 = zeros(numel(f), B);
    s2 = zeros(numel(f), B);
    
    % Boucle temporelle sur la longueur du bloc N
    for n = 1:N
        % Équation aux différences (filtrage vectorisé fréquences x blocs)
        s0 = X(n, :) + c .* s1 - s2;
        s2 = s1;
        s1 = s0;
    end
    
    % Calcul de la puissance finale à partir des deux derniers états
    P = s1.^2 + s2.^2 - c .* s1 .* s2;
end
