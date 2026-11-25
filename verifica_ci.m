function verifica_ci(omb, ll)
    if nargin < 1; omb = 3.13; end
    if nargin < 2; ll = 1; end
    if ischar(omb); omb = str2double(omb); end
    if ischar(ll); ll = str2double(ll); end
    src = fileread('Luigi2.m');
    rif = 'p.omega_base = 3.13;';
    assert(numel(strfind(src, rif)) == 1, 'riga omega_base non trovata in Luigi2.m');
    rifl = 'p.ll  = 1;';
    assert(numel(strfind(src, rifl)) == 1, 'riga p.ll non trovata in Luigi2.m');
    src = strrep(src, rif, sprintf('p.omega_base = %.15g;', omb));
    src = strrep(src, rifl, sprintf('p.ll  = %.15g;', ll));
    fid = fopen('Luigi2_rif.m','w'); fwrite(fid, src); fclose(fid);
% Gate deterministico: Luigi2.m originale (4x4) vs run_shard + merge_shards (4x4).
% Esito Sì solo se isequal(M_orig, M_new). Stampa anche i secondi per coppia.
    try
        fprintf('[1/3] originale Luigi2.m 4x4 (omega_base %.4g, ll %.4g)...\n', omb, ll); fprintf('\n');
        t1 = tic;  M_orig = esegui('Luigi2_rif.m');  T_orig = toc(t1);
        fprintf('[2/3] run_shard 4x4...\n');
        run_shard(1, 1, 4, 4, omb, ll);
        fprintf('[3/3] merge_shards 4x4...\n');
        nome = merge_shards(4, 4, omb, ll);
    catch err
        fprintf('ERRORE VERIFICA:\n%s\n', getReport(err, 'extended', 'hyperlinks', 'off'));
        rethrow(err);
    end
    S = load([nome '.mat']);
    ok = isequal(M_orig, S.M);
    fprintf('M originale:\n'); disp(M_orig);
    fprintf('M nuova:\n');     disp(S.M);
    fprintf('VERIFICA M identica: %s\n', string(ok));
    fprintf('originale seriale: %.1f s/coppia\n', T_orig/16);
    if ~ok; error('VERIFICA fallita: M diversa dall''originale'); end
end

function M = esegui(nome)
    run(nome);   % il 'clear' dello script agisce solo su questo workspace
end
