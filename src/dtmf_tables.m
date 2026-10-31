function [layout, fRows, fCols] = dtmf_tables()
% DTMF_TABLES Renvoie la matrice des touches et les fréquences standards DTMF.
%
%   [layout, fRows, fCols] = DTMF_TABLES()
%
%   Sorties :
%       layout : Matrice [4x4] de caractères représentant le pavé téléphonique
%       fRows  : Vecteur [1x4] des fréquences des lignes (basses) en Hz
%       fCols  : Vecteur [1x4] des fréquences des colonnes (hautes) en Hz

    layout = ['123A'; '456B'; '789C'; '*0#D'];
    fRows  =;
    fCols  =;
end
