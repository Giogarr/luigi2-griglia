function run_shard(k, K, NI, NJ)
% Calcola la fetta k di K della griglia NI x NJ (indici lineari k, k+K, k+2K, ...:
% coppie "facili" e "difficili" mescolate, fette di durata simile).
% Salva shard_<k>.mat con idx e SIv. Passo della griglia: da = 2/NJ, de = .2/NI (= originale per 4x4).
    if ischar(k);  k  = str2double(k);  end
    if ischar(K);  K  = str2double(K);  end
    if ischar(NI); NI = str2double(NI); end
    if ischar(NJ); NJ = str2double(NJ); end
    da = 2/NJ;  de = .2/NI;
    idx = k:K:NI*NJ;
    SIv = nan(size(idx));

    try
        if isempty(gcp('nocreate')); parpool('Processes'); end
        nw = gcp().NumWorkers;
        modo = sprintf('parfor · %d worker', nw);
    catch err
        nw = 0;   % parfor (.., 0) = esecuzione seriale, stesso risultato
        modo = ['seriale (parpool non disponibile: ' err.message ')'];
    end
    fprintf('shard %d/%d · %d coppie · %s\n', k, K, numel(idx), modo);

    t0 = tic;
    parfor (q = 1:numel(idx), nw)
        [iL, jL] = ind2sub([NI NJ], idx(q));
        SIv(q) = una_coppia(iL, jL, da, de);
    end
    el = toc(t0);
    fprintf('shard %d: %.1f min · %.1f s/coppia (tempo reale)\n', k, el/60, el/numel(idx));
    save(sprintf('shard_%d.mat', k), 'idx', 'SIv', 'NI', 'NJ', 'da', 'de', 'el', 'modo');
end
