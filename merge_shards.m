function merge_shards(NI, NJ)
% Riunisce shard_*.mat in M (NI x NJ) e la salva in M_<NI>x<NJ>.mat.
% Verifica: ogni cella calcolata esattamente una volta, nessun NaN, valori solo 0/1.
    if ischar(NI); NI = str2double(NI); end
    if ischar(NJ); NJ = str2double(NJ); end
    SIv = nan(NI*NJ, 1);  cnt = zeros(NI*NJ, 1);  t_tot = 0;
    f = dir('**/shard_*.mat');
    for n = 1:numel(f)
        S = load(fullfile(f(n).folder, f(n).name));
        assert(S.NI == NI && S.NJ == NJ, 'shard %s: griglia diversa', f(n).name);
        SIv(S.idx) = S.SIv;  cnt(S.idx) = cnt(S.idx) + 1;  t_tot = t_tot + S.el;
    end
    mancanti = find(cnt == 0);
    if ~isempty(mancanti)
        error('%d celle mancanti (prima: %d)', numel(mancanti), mancanti(1));
    end
    assert(all(cnt == 1), 'celle calcolate più volte');
    assert(all(SIv == 0 | SIv == 1), 'valori diversi da 0/1');
    M  = reshape(SIv, NI, NJ);
    SI = M;
    da = 2/NJ;  de = .2/NI;
    save(sprintf('M_%dx%d.mat', NI, NJ), 'M', 'SI', 'NI', 'NJ', 'da', 'de');
    writematrix(M, sprintf('M_%dx%d.csv', NI, NJ));
    fprintf('VERIFICA merge: OK · %d shard · %d celle · somma tempi %.1f h\n', numel(f), NI*NJ, t_tot/3600);
end
