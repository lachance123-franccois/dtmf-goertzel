function [layout, fRows, fCols] = dtmf_tables()
%     layout : matrice 4x4 de caracteres ('123A';'456B';'789C';'*0#D')
%     fRows  : frequences des lignes   [697 770 852 941] Hz
%     fCols  : frequences des colonnes [1209 1336 1477 1633] Hz

layout = ['123A'; '456B'; '789C'; '*0#D'];
fRows  = [697 770 852 941];
fCols  = [1209 1336 1477 1633];
end
