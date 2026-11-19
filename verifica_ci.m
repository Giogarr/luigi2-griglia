function verifica_ci()
% Gate deterministico: Luigi2.m originale (4x4) vs run_shard + merge_shards (4x4).
% Esito Sì solo se isequal(M_orig, M_new). Stampa anche i secondi per coppia.
    t1 = tic;  M_orig = esegui('Luigi2.m');  T_orig = toc(t1);
    run_shard(1, 1, 4, 4);
    merge_shards(4, 4);
    S = load('M_4x4.mat');
    ok = isequal(M_orig, S.M);
    fprintf('M originale:\n'); disp(M_orig);
    fprintf('M nuova:\n');     disp(S.M);
    fprintf('VERIFICA M identica: %s\n', string(ok));
    fprintf('originale seriale: %.1f s/coppia\n', T_orig/16);
    delete('shard_1.mat'); delete('M_4x4.mat'); delete('M_4x4.csv');
    if ~ok; error('VERIFICA fallita: M diversa dall''originale'); end
end

function M = esegui(nome)
    run(nome);   % il 'clear' dello script agisce solo su questo workspace
end
