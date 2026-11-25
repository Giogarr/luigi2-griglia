function nome = merge_shards(NI, NJ, omb, ll)
    if nargin < 3; omb = 3.13; end
    if nargin < 4; ll = 1; end
    if ischar(omb); omb = str2double(omb); end
    if ischar(ll); ll = str2double(ll); end
% Riunisce shard_*.mat in M (NI x NJ) e la salva in M_<NI>x<NJ>.mat.
% Verifica: ogni cella calcolata esattamente una volta, nessun NaN, valori solo 0/1.
    if ischar(NI); NI = str2double(NI); end
    if ischar(NJ); NJ = str2double(NJ); end
    SIv = nan(NI*NJ, 1);  cnt = zeros(NI*NJ, 1);  t_tot = 0;
    f = dir('**/shard_*.mat');
    for n = 1:numel(f)
        S = load(fullfile(f(n).folder, f(n).name));
        assert(S.NI == NI && S.NJ == NJ, 'shard %s: griglia diversa', f(n).name);
        assert(isfield(S,'omb') && S.omb == omb, 'shard %s: omega_base diversa', f(n).name);
        if isfield(S,'ll'); sll = S.ll; else; sll = 1; end
        assert(sll == ll, 'shard %s: ll diverso', f(n).name);
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
    omega_base = omb;  p_ll = ll;
    nome = sprintf('M_%dx%d_w%s', NI, NJ, strrep(num2str(omb),'.','p'));
    if ll ~= 1; nome = [nome '_l' strrep(num2str(ll),'.','p')]; end
    save([nome '.mat'], 'M', 'SI', 'NI', 'NJ', 'da', 'de', 'omega_base', 'p_ll');
    writematrix(M, [nome '.csv']);
    fprintf('omega_base %.4g · ll %.4g · VERIFICA merge: OK',omb,ll); fprintf(' · %d shard · %d celle · somma tempi %.1f h\n', numel(f), NI*NJ, t_tot/3600);
end
