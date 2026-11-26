function verifica_ci3(omb, ll, cc)
% Gate deterministico per Luigi3.m: lo script originale gira sulla SUA griglia 10x10
% (nessuna riga di griglia toccata); si cambiano solo, in una copia, le righe di omega_base e ll.
% Esito Si' solo se isequal(MD) e isequal(FMD) con la chain parallela sulla stessa 10x10.
    if nargin < 1; omb = 3.13; end
    if nargin < 2; ll = 1; end
    if ischar(omb); omb = str2double(omb); end
    if ischar(ll); ll = str2double(ll); end
    if nargin < 3; cc = 0.1; end
    if ischar(cc); cc = str2double(cc); end
    src = fileread('Luigi3.m');
    rif = 'p.omega_base = 3.13;';  rifl = 'p.ll  = 1;';  rifc = 'p.c = 0.1;';
    assert(numel(strfind(src, rif)) == 1,  'riga omega_base non trovata in Luigi3.m');
    assert(numel(strfind(src, rifl)) == 1, 'riga p.ll non trovata in Luigi3.m');
    assert(numel(strfind(src, rifc)) == 1, 'riga p.c non trovata in Luigi3.m');
    assert(numel(strfind(src, 'da=2/10')) == 1 && numel(strfind(src, 'de=.2/10')) == 1, 'griglia 10x10 attesa in Luigi3.m');
    src = strrep(src, rif,  sprintf('p.omega_base = %.15g;', omb));
    src = strrep(src, rifl, sprintf('p.ll  = %.15g;', ll));
    src = strrep(src, rifc, sprintf('p.c = %.15g;', cc));
    fid = fopen('Luigi3_rif.m','w'); fwrite(fid, src); fclose(fid);
    try
        fprintf('[1/3] originale Luigi3.m 10x10 (omega_base %.4g, ll %.4g, c %.4g)...\n', omb, ll, cc);
        t1 = tic;  [MD_o, FMD_o] = esegui('Luigi3_rif.m');  T_orig = toc(t1);
        fprintf('[2/3] run_shard3 10x10...\n');
        run_shard3(1, 1, 10, 10, omb, ll, cc);
        fprintf('[3/3] merge_shards3 10x10...\n');
        nome = merge_shards3(10, 10, omb, ll, cc);
    catch err
        fprintf('ERRORE VERIFICA:\n%s\n', getReport(err, 'extended', 'hyperlinks', 'off'));
        rethrow(err);
    end
    S = load([nome '.mat']);
    ok = isequal(MD_o, S.MD) && isequal(FMD_o, S.FMD);
    fprintf('max |MD diff| = %g · max |FMD diff| = %g\n', max(abs(MD_o(:)-S.MD(:))), max(abs(FMD_o(:)-S.FMD(:))));
    fprintf('VERIFICA MD e FMD identiche: %s\n', string(ok));
    fprintf('originale seriale: %.1f s/coppia\n', T_orig/100);
    delete(fullfile(pwd, 'shard_1.mat'));
    if ~ok; error('VERIFICA fallita: MD/FMD diverse dall''originale'); end
end

function [MD, FMD] = esegui(nome)
    % Luigi3.m termina con "SI" e "M=SI", che in Luigi3 non esistono: l'errore arriva
    % DOPO il doppio for, quando MD e FMD sono gia' completi. Lo accetto solo se e' quello.
    try
        run(nome);
    catch err
        if ~(contains(err.message, 'SI') && exist('MD','var') && exist('FMD','var'))
            rethrow(err);
        end
        fprintf('(atteso) fine di Luigi3.m: %s\n', err.message);
    end
end
