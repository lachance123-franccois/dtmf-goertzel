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
        
        % MODIFICATION ICI : Appel de la version allégée à 2 arguments
        d = dtmf_decode(y, fs);
        
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
    % Petite correction mathématique : somme sur tous les essais pour le calcul des ratios finaux
    res.rate(i) = sum(diag(conf(:, 1:16))) / (16 * nTrials);
    res.missed(i) = sum(conf(:, 17)) / (16 * nTrials);
    res.wrong(i) = 1 - res.rate(i) - res.missed(i);
end
res.keys = keysAll;
end
