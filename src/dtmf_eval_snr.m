function res = dtmf_eval_snr(snrDb, nTrials, fs, toneDur, opts)

if nargin < 3 || isempty(fs), fs = 8000; end
if nargin < 4 || isempty(toneDur), toneDur = 0.08; end
if nargin < 5, opts = struct(); end

layout = dtmf_tables();
keysAll = reshape(layout', 1, []);         
amp = 0.5;
sigPow = 2 * amp^2 / 2;                    

res.snrDb = snrDb;
res.rate = zeros(size(snrDb));
res.missed = zeros(size(snrDb));
res.wrong = zeros(size(snrDb));
res.conf = cell(size(snrDb));

for i = 1:numel(snrDb)
    sigma = sqrt(sigPow / 10^(snrDb(i)/10));
    conf = zeros(16, 18);
    for t = 1:nTrials
        k = randi(16);
        x = dtmf_generate(keysAll(k), fs, toneDur, 0.05, amp);
        y = x + sigma * randn(size(x));
        d = dtmf_decode(y, fs, opts);
        if isempty(d)
            col = 17;
        elseif numel(d) > 1
            col = 18;
        else
            col = find(keysAll == d);
        end
        conf(k, col) = conf(k, col) + 1;
    end
    res.conf{i} = conf;
    res.rate(i) = trace(conf(:, 1:16)) / nTrials;
    res.missed(i) = sum(conf(:, 17)) / nTrials;
    res.wrong(i) = 1 - res.rate(i) - res.missed(i);
end
res.keys = keysAll;
end




%Taux de bonne detection d'une touche isolee en fonction du SNR.
%   res = DTMF_EVAL_SNR(snrDb, nTrials, fs, toneDur, opts)
%     snrDb   : vecteur de SNR (dB). SNR = puissance de la tonalite / puissance du bruit
%     nTrials : nombre de tirages par point
%   res.rate(i)      : proportion de touches decodees exactement (une seule touche, la bonne)
%   res.missed(i)    : proportion de non-detections
%   res.wrong(i)     : proportion de touches fausses ou multiples
%   res.conf{i}      : matrice de confusion 16 x 18 (16 touches + 'aucune' + 'multiple')
