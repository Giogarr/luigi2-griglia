function run_shard3(k, K, NI, NJ, omb, ll, cc, a0, as, e0, es)
    if nargin < 5; omb = 3.13; end
    if nargin < 6; ll = 1; end
    if ischar(omb); omb = str2double(omb); end
    if ischar(ll); ll = str2double(ll); end
    if nargin < 7; cc = 0.1; end
    if nargin < 11; a0 = .5; as = 2; e0 = .1; es = .2; end   % finestra: a in (a0, a0+as], E in (e0, e0+es]
    if ischar(a0); a0 = str2double(a0); end;  if ischar(as); as = str2double(as); end
    if ischar(e0); e0 = str2double(e0); end;  if ischar(es); es = str2double(es); end
    if ischar(cc); cc = str2double(cc); end
% Calcola la fetta k di K della griglia NI x NJ (indici lineari k, k+K, k+2K, ...:
% coppie "facili" e "difficili" mescolate, fette di durata simile).
% Salva shard_<k>.mat con idx e SIv. Passo della griglia: da = 2/NJ, de = .2/NI (= originale per 4x4).
    if ischar(k);  k  = str2double(k);  end
    if ischar(K);  K  = str2double(K);  end
    if ischar(NI); NI = str2double(NI); end
    if ischar(NJ); NJ = str2double(NJ); end
    da = as/NJ;  de = es/NI;    % con la finestra di default = 2/NJ e .2/NI dell'originale
    idx = k:K:NI*NJ;
    MDv = nan(size(idx));  FMDv = nan(size(idx));

    try
        if isempty(gcp('nocreate')); parpool('Processes'); end
        nw = gcp().NumWorkers;
        modo = sprintf('parfor · %d worker', nw);
    catch err
        nw = 0;   % parfor (.., 0) = esecuzione seriale, stesso risultato
        modo = ['seriale (parpool non disponibile: ' err.message ')'];
    end
    fprintf('[Luigi3] shard %d/%d · omega_base %.4g · ll %.4g · c %.4g · %d coppie · %s\n', k, K, omb, ll, cc, numel(idx), modo);

    t0 = tic;
    parfor (q = 1:numel(idx), nw)
        [iL, jL] = ind2sub([NI NJ], idx(q));
        [MDv(q), FMDv(q)] = una_coppia3(iL, jL, da, de, omb, ll, cc, a0, e0);
    end
    el = toc(t0);
    fprintf('shard %d: %.1f min · %.1f s/coppia (tempo reale)\n', k, el/60, el/numel(idx));
    save(sprintf('shard_%d.mat', k), 'idx', 'MDv', 'FMDv', 'NI', 'NJ', 'da', 'de', 'el', 'modo', 'omb', 'll', 'cc', 'a0', 'as', 'e0', 'es');
end
