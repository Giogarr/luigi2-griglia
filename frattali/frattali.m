function frattali(fileRif)
% FRATTALI  10 figure deterministiche per cercare strutture frattali nelle matrici MD/FMD (Luigi3).
% Uso:  frattali                      (default: MDFMD_400x400_w2p8_l1p25.mat nella cartella superiore)
%       frattali('MDFMD_400x400_w3p13.mat')
% Uscite (cartella ./out_<nome file>): F01..F10 *.png  +  indici.txt (tutti i numeri delle figure).
% Mappe 2D orientate come imagesc di default (riga 1 in alto), come le figure di Silvia.
if nargin < 1, fileRif = 'MDFMD_400x400_w2p8_l1p25.mat'; end
base = fileparts(mfilename('fullpath'));  dati = fileparts(base);  out = fullfile(base, ['out_' erase(fileRif, '.mat')]);
if ~exist(out, 'dir'), mkdir(out); end
S = load(fullfile(dati, fileRif));
MD = S.MD;  FMD = S.FMD;  [NI, NJ] = size(MD);
a = 0.5 + (1:NJ) * (2/NJ);           % colonne (da = 2/NJ)
E = 0.1 + (1:NI) * (0.2/NI);         % righe   (de = 0.2/NI)
if isfield(S, 'a_assi'), a = S.a_assi; E = S.E_assi; end   % matrici calcolate su una finestra (zoom)
passo = 7/149;                       % passo dello sweep: linspace(1,8,150)
K = round(FMD / passo);              % FMD in numero di passi (intero)
tau = 0.01 * max(MD(:));             % soglia di salto per la frontiera di MD: 1% del massimo
tit = strrep(erase(fileRif, '.mat'), '_', '\_');
fid = fopen(fullfile(out, 'indici.txt'), 'w');
fprintf(fid, 'file: %s  (%dx%d)\n', fileRif, NI, NJ);
fprintf(fid, 'max |FMD/passo - round| = %.2e (deve essere ~0) · max MD = %.6f · tau = %.6f\n', max(abs(FMD(:)/passo - K(:))), max(MD(:)), tau);

% F01 - MD lineare (come Silvia) e log10(MD)
f = nuova([100 100 1500 560]);
subplot(1,2,1); imagesc(a, E, MD); colormap(gca, parula); c = colorbar; c.Label.String = 'MD'; xlabel('a'); ylabel('E'); title('MD (scala lineare)');
subplot(1,2,2); imagesc(a, E, log10(MD)); colormap(gca, parula); c = colorbar; c.Label.String = 'log_{10} MD'; xlabel('a'); ylabel('E'); title('log_{10} MD (fa emergere i valori piccoli)');
sgtitle(['F01 \cdot MD = |MF - MB| \cdot ' tit]);
salva(f, out, 'F01_MD_lineare_log');

% F02 - MD come terza dimensione (richiesta di Luigi)
f = nuova(); surf(a, E, MD, 'EdgeColor', 'none'); colormap(parula); c = colorbar; c.Label.String = 'MD';
set(gca, 'YDir', 'reverse'); view(-35, 45); camlight headlight; lighting gouraud; xlabel('a'); ylabel('E'); zlabel('MD');
title({['F02 \cdot superficie z = MD(a,E) \cdot ' tit], 'griglia (a,E) come piano, valore della matrice come quota'});
salva(f, out, 'F02_MD_superficie3D');

% F03 - log10(MD) come terza dimensione
f = nuova(); surf(a, E, log10(MD), 'EdgeColor', 'none'); colormap(parula); c = colorbar; c.Label.String = 'log_{10} MD';
set(gca, 'YDir', 'reverse'); view(-35, 45); camlight headlight; lighting gouraud; xlabel('a'); ylabel('E'); zlabel('log_{10} MD');
title({['F03 \cdot superficie z = log_{10} MD(a,E) \cdot ' tit], 'stessa superficie in scala log'});
salva(f, out, 'F03_log10MD_superficie3D');

% F04 - FMD in passi dello sweep
f = nuova(); imagesc(a, E, K); colormap(parula(max(K(:)) + 1)); c = colorbar; c.Label.String = 'FMD / passo sweep';
xlabel('a'); ylabel('E'); title({['F04 \cdot FMD in passi dello sweep (7/149) \cdot ' tit], 'distanza in frequenza tra picco in avanti e picco all''indietro'});
salva(f, out, 'F04_FMD_mappa');

% F05 - FMD come terza dimensione ("terrazze")
f = nuova(); surf(a, E, FMD, 'EdgeColor', 'none'); colormap(parula); c = colorbar; c.Label.String = 'FMD';
set(gca, 'YDir', 'reverse'); view(-35, 45); camlight headlight; lighting gouraud; xlabel('a'); ylabel('E'); zlabel('FMD');
title({['F05 \cdot superficie z = FMD(a,E) \cdot ' tit], 'FMD assume valori discreti: terrazze'});
salva(f, out, 'F05_FMD_superficie3D');

% F06 - insiemi di frontiera
Fm = frontiera(MD, tau);  Ff = frontiera(mediana3(K), 0);
f = nuova([100 100 1500 560]);
subplot(1,2,1); imagesc(a, E, Fm); colormap(gca, [1 1 1; 0 0 0]); xlabel('a'); ylabel('E');
title(sprintf('MD: salto > 1%% del max verso un vicino (%.1f%% celle)', 100*mean(Fm(:))));
subplot(1,2,2); imagesc(a, E, Ff); colormap(gca, [1 1 1; 0 0 0]); xlabel('a'); ylabel('E');
title(sprintf('FMD (dopo mediana 3x3): valore diverso da un vicino (%.1f%% celle)', 100*mean(Ff(:))));
sgtitle(['F06 \cdot frontiere tra "terrazze" (vicini: su/giu/sx/dx) \cdot ' tit]);
salva(f, out, 'F06_frontiere');

% F07 - box counting
s = [1 2 4 8 16 32 64];  fit = s <= 8;
Nm = boxcount(Fm, s);  Nf = boxcount(Ff, s);
pm = polyfit(log(1./s(fit)), log(Nm(fit)), 1);  pf = polyfit(log(1./s(fit)), log(Nf(fit)), 1);
f = nuova([100 100 1300 560]);
subplot(1,2,1); loglog(1./s, Nm, 'o-', 1./s, Nf, 's-', 'LineWidth', 1.5); grid on;
xlabel('1/s  (s = lato della scatola, in celle)'); ylabel('N(s) = scatole che toccano la frontiera');
legend(sprintf('frontiera MD   D = %.3f', pm(1)), sprintf('frontiera FMD D = %.3f', pf(1)), 'Location', 'northwest');
title('N(s) \propto s^{-D}: D = pendenza (fit su s = 1..8)');
subplot(1,2,2); sm = sqrt(s(1:end-1) .* s(2:end));
semilogx(sm, -diff(log(Nm)) ./ diff(log(s)), 'o-', sm, -diff(log(Nf)) ./ diff(log(s)), 's-', 'LineWidth', 1.5); grid on;
yline(1, ':'); yline(2, ':'); ylim([0.8 2.1]); xlabel('scala s'); ylabel('pendenza locale D(s)');
title('D(s): 1 = curva liscia, 2 = riempie il piano');
sgtitle(['F07 \cdot dimensione di box-counting delle frontiere \cdot ' tit]);
salva(f, out, 'F07_boxcounting');
fprintf(fid, 'F07 frontiera MD  N(s) = %s  D(1..8) = %.4f\n', mat2str(Nm), pm(1));
fprintf(fid, 'F07 frontiera FMD N(s) = %s  D(1..8) = %.4f\n', mat2str(Nf), pf(1));

% F08 - D per tutte le matrici 400x400 disponibili
L = [dir(fullfile(dati, 'MDFMD_400x400_*.mat')); dir(fullfile(dati, 'M_400x400_*.mat'))];
nomi = {}; Dv = [];
for q = 1:numel(L)
    T = load(fullfile(dati, L(q).name));
    if isfield(T, 'MD'), B = frontiera(T.MD, 0.01 * max(T.MD(:))); else, B = frontiera(T.M, 0); end
    N = boxcount(B, s); p = polyfit(log(1./s(fit)), log(N(fit)), 1);
    nomi{end+1} = erase(L(q).name, '.mat'); Dv(end+1) = p(1); %#ok<AGROW>
    fprintf(fid, 'F08 %-34s D = %.4f\n', L(q).name, p(1));
end
f = nuova([100 100 1100 560]); barh(Dv); set(gca, 'YTick', 1:numel(nomi), 'YTickLabel', strrep(nomi, '_', '\_'));
xlim([1 2]); grid on; xlabel('D (fit s = 1..8)');
title({'F08 \cdot dimensione della frontiera per ogni prova 400x400', 'MDFMD: frontiera di MD (salto > 1% del max) \cdot M: frontiera tra 0 e 1 (Luigi2)'});
salva(f, out, 'F08_D_confronto');

% F09 - tre finestre 100x100 candidate ("rettangolo piu' significativo"), tre criteri espliciti
w = 100;
[W(1,:), v1] = finestra(double(Fm), w);   % W1: piu' frontiera di MD
[W(2,:), v2] = finestra(MD, w);           % W2: MD medio massimo (isteresi piu' forte)
[W(3,:), v3] = finestra(double(Ff), w);   % W3: piu' frontiera di FMD
crit = {'W1 max frontiera MD', 'W2 max MD medio', 'W3 max frontiera FMD'};  col = {'r', 'w', 'm'};  val = [v1 v2 v3];
f = nuova([100 100 1100 700]); imagesc(a, E, MD); colormap(parula); c = colorbar; c.Label.String = 'MD'; hold on;
for q = 1:3
    i0 = W(q,1); j0 = W(q,2);
    rectangle('Position', [a(j0 + 1), E(i0 + 1), a(j0 + w) - a(j0 + 1), E(i0 + w) - E(i0 + 1)], 'EdgeColor', col{q}, 'LineWidth', 2);
    text(a(j0 + 1), E(i0 + 1), [' ' crit{q}(1:2)], 'Color', col{q}, 'FontWeight', 'bold', 'VerticalAlignment', 'top');
    fprintf(fid, 'F09 %s: righe %d-%d, colonne %d-%d, a=[%.4f,%.4f], E=[%.4f,%.4f], valore=%.4f\n', ...
        crit{q}, i0 + 1, i0 + w, j0 + 1, j0 + w, a(j0 + 1), a(j0 + w), E(i0 + 1), E(i0 + w), val(q));
end
xlabel('a'); ylabel('E');
title({['F09 \cdot finestre candidate 100x100 per lo zoom \cdot ' tit], 'W1 (rosso) max frontiera MD \cdot W2 (bianco) max MD medio \cdot W3 (magenta) max frontiera FMD'});
salva(f, out, 'F09_finestre_candidate');

% F10 - zoom annidati (200, 100, 50 celle) su W1 (frontiera) e W2 (MD)
lati = [200 100 50];
f = nuova([100 100 1500 950]);
for r = 1:2
    ci = W(r,1) + w/2;  cj = W(r,2) + w/2;
    for q = 1:3
        m = lati(q);  i0 = min(max(ci - m/2, 0), NI - m);  j0 = min(max(cj - m/2, 0), NJ - m);
        ii = i0 + 1:i0 + m;  jj = j0 + 1:j0 + m;
        B = Fm(ii, jj);  sq = s(s <= m/4);  N = boxcount(B, sq);  p = polyfit(log(1./sq(sq <= 8)), log(N(sq <= 8)), 1);
        subplot(2,3,(r - 1)*3 + q);
        if r == 1, imagesc(a(jj), E(ii), B); colormap(gca, [1 1 1; 0 0 0]); else, imagesc(a(jj), E(ii), MD(ii, jj)); colormap(gca, parula); end
        axis square; xlabel('a'); ylabel('E');
        title(sprintf('%s \\cdot %dx%d \\cdot D_{MD} = %.3f', crit{r}(1:2), m, m, p(1)));
        fprintf(fid, 'F10 %s zoom %dx%d: D frontiera MD = %.4f\n', crit{r}(1:2), m, m, p(1));
    end
end
sgtitle({['F10 \cdot zoom annidati: sopra frontiera di MD in W1, sotto MD in W2 \cdot ' tit], 'meno punti a ogni zoom: per andare oltre serve ricalcolare la finestra con 400x400 punti'});
salva(f, out, 'F10_zoom_annidati');
fclose(fid);
fprintf('FINE frattali: 10 figure e indici.txt in %s\n', out);
end

% ---------- funzioni di servizio ----------
function f = nuova(pos)
if nargin < 1, pos = [100 100 900 700]; end
f = figure('Visible', 'off', 'Color', 'w', 'Position', pos);
end
function salva(f, out, nome)
exportgraphics(f, fullfile(out, [nome '.png']), 'Resolution', 150); close(f);
end
function B = frontiera(Z, tau)  % cella di frontiera = almeno un vicino (su/giu/sx/dx) con |differenza| > tau
dx = abs(Z(:, 1:end-1) - Z(:, 2:end)) > tau;  dy = abs(Z(1:end-1, :) - Z(2:end, :)) > tau;
B = false(size(Z));
B(:, 1:end-1) = B(:, 1:end-1) | dx;  B(:, 2:end) = B(:, 2:end) | dx;
B(1:end-1, :) = B(1:end-1, :) | dy;  B(2:end, :) = B(2:end, :) | dy;
end
function Y = mediana3(Z)        % mediana 3x3 con bordo a zero (= medfilt2 di default), senza toolbox
[r, c] = size(Z);  P = zeros(r + 2, c + 2);  P(2:end-1, 2:end-1) = Z;  T = zeros(r, c, 9);  k = 0;
for i = 0:2, for j = 0:2, k = k + 1; T(:, :, k) = P(1 + i:r + i, 1 + j:c + j); end, end
Y = median(T, 3);
end
function N = boxcount(B, s)     % N(s) = numero di scatole s x s che contengono almeno una cella di B
N = zeros(size(s));
for q = 1:numel(s)
    n1 = ceil(size(B, 1) / s(q));  n2 = ceil(size(B, 2) / s(q));
    P = false(n1 * s(q), n2 * s(q));  P(1:size(B, 1), 1:size(B, 2)) = B;
    N(q) = nnz(squeeze(any(any(reshape(P, s(q), n1, s(q), n2), 1), 3)));
end
end
function [ij, best] = finestra(V, w)   % finestra w x w con somma di V massima (primo massimo in ordine riga, colonna)
[NI, NJ] = size(V);  C = zeros(NI + 1, NJ + 1);  C(2:end, 2:end) = cumsum(cumsum(V, 1), 2);
best = -Inf;  ij = [0 0];
for i = 0:NI - w
    for j = 0:NJ - w
        v = C(i + w + 1, j + w + 1) - C(i + 1, j + w + 1) - C(i + w + 1, j + 1) + C(i + 1, j + 1);
        if v > best, best = v; ij = [i j]; end
    end
end
best = best / w^2;   % valore medio nella finestra
end
