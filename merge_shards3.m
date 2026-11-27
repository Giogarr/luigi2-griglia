function nome = merge_shards3(NI, NJ, omb, ll, cc, a0, as, e0, es)
% Riunisce shard_*.mat (Luigi3) in MD e FMD (NI x NJ) e li salva in MDFMD_<NI>x<NJ>_w<omega>[_l<ll>].mat
% Verifica: ogni cella calcolata esattamente una volta, valori finiti e >= 0.
    if nargin < 3; omb = 3.13; end
    if nargin < 4; ll = 1; end
    if ischar(NI); NI = str2double(NI); end
    if ischar(NJ); NJ = str2double(NJ); end
    if ischar(omb); omb = str2double(omb); end
    if ischar(ll); ll = str2double(ll); end
    if nargin < 5; cc = 0.1; end
    if nargin < 9; a0 = .5; as = 2; e0 = .1; es = .2; end
    if ischar(a0); a0 = str2double(a0); end;  if ischar(as); as = str2double(as); end
    if ischar(e0); e0 = str2double(e0); end;  if ischar(es); es = str2double(es); end
    zoom = ~(a0 == .5 && as == 2 && e0 == .1 && es == .2);
    if ischar(cc); cc = str2double(cc); end
    MDv = nan(NI*NJ, 1);  FMDv = nan(NI*NJ, 1);  cnt = zeros(NI*NJ, 1);  t_tot = 0;
    f = dir('**/shard_*.mat');
    for n = 1:numel(f)
        S = load(fullfile(f(n).folder, f(n).name));
        assert(isfield(S,'MDv'), 'shard %s: non e'' una fetta di Luigi3', f(n).name);
        assert(S.NI == NI && S.NJ == NJ, 'shard %s: griglia diversa', f(n).name);
        if isfield(S,'cc'); scc = S.cc; else; scc = 0.1; end
        if isfield(S,'a0'); assert(S.a0 == a0 && S.as == as && S.e0 == e0 && S.es == es, 'shard %s: finestra diversa', f(n).name); else; assert(~zoom, 'shard %s: senza finestra', f(n).name); end
        assert(S.omb == omb && S.ll == ll && scc == cc, 'shard %s: omega_base, ll o c diversi', f(n).name);
        MDv(S.idx) = S.MDv;  FMDv(S.idx) = S.FMDv;  cnt(S.idx) = cnt(S.idx) + 1;  t_tot = t_tot + S.el;
    end
    mancanti = find(cnt == 0);
    if ~isempty(mancanti)
        error('%d celle mancanti (prima: %d)', numel(mancanti), mancanti(1));
    end
    assert(all(cnt == 1), 'celle calcolate piu'' volte');
    assert(all(isfinite(MDv) & MDv >= 0) && all(isfinite(FMDv) & FMDv >= 0), 'valori non finiti o negativi');
    MD  = reshape(MDv,  NI, NJ);
    FMD = reshape(FMDv, NI, NJ);
    da = as/NJ;  de = es/NI;  omega_base = omb;  a_assi = a0 + (1:NJ)*da;  E_assi = e0 + (1:NI)*de;  p_ll = ll;  p_c = cc;
    nome = sprintf('MDFMD_%dx%d_w%s', NI, NJ, strrep(num2str(omb),'.','p'));
    if ll ~= 1; nome = [nome '_l' strrep(num2str(ll),'.','p')]; end
    if cc ~= 0.1; nome = [nome '_c' strrep(num2str(cc),'.','p')]; end
    if zoom; nome = sprintf('%s_z%s_%s_%s_%s', nome, strrep(num2str(a0),'.','p'), strrep(num2str(as),'.','p'), strrep(num2str(e0),'.','p'), strrep(num2str(es),'.','p')); end
    save([nome '.mat'], 'MD', 'FMD', 'NI', 'NJ', 'da', 'de', 'omega_base', 'p_ll', 'p_c', 'a0', 'as', 'e0', 'es', 'a_assi', 'E_assi');
    writematrix(MD,  [nome '_MD.csv']);
    writematrix(FMD, [nome '_FMD.csv']);
    fprintf('[Luigi3] omega_base %.4g · ll %.4g · c %.4g · VERIFICA merge: OK · %d shard · %d celle · somma tempi %.1f h\n', ...
        omb, ll, cc, numel(f), NI*NJ, t_tot/3600);
end
