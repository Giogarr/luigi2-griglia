# Frattalità nelle matrici MD / FMD (Luigi3): 10 figure riproducibili

## Come riprodurre
1. Mettere `frattali.m` in una sottocartella accanto ai file `MDFMD_400x400_*.mat` (e, facoltativi, `M_400x400_*.mat` di Luigi2).
2. In MATLAB: `frattali`, oppure `frattali('MDFMD_400x400_w3p13.mat')`.
3. Escono `out_<nome file>/F01..F10_*.png` e `out/indici.txt`, con tutti i numeri delle figure.

Nessuna operazione è casuale: a parità di file, figure e numeri sono identici. Non servono toolbox.
Le mappe 2D sono orientate come `imagesc` di default (riga 1 in alto), come le figure di Silvia.

## Dati e notazione
- **Griglia**: righe `E = 0.1 + i·0.2/NI`, colonne `a = 0.5 + j·2/NJ`, con i, j = 1…400.
- `MD = |MF − MB|`
- `FMD = |FF − FB|`, sempre multiplo del passo dello sweep `Δω = 7/149`, quindi si usa l'intero `K = FMD/Δω`.
- **Frontiera di MD**: una cella è di frontiera se, verso almeno un vicino (su/giù/sx/dx), `|ΔMD| > τ`, con `τ = 1% · max(MD)`. È il bordo tra le "terrazze" che si vedono nella mappa di MD.

## Le figure
| Figura | Cosa si plotta | Operazione |
|---|---|---|
| F01 | MD lineare (come Silvia) e `log10 MD` | la scala log rende visibili ~10 ordini di grandezza |
| F02 | superficie 3D `z = MD(a,E)` | richiesta di Luigi: griglia come piano, valore come quota (`surf`) |
| F03 | superficie 3D `z = log10 MD(a,E)` | come F02, in scala log |
| F04 | mappa di `K = FMD/Δω` | numero di passi tra il picco in avanti e quello all'indietro |
| F05 | superficie 3D `z = FMD(a,E)` | FMD è discreto, quindi la superficie è fatta di terrazze |
| F06 | frontiere di MD e di FMD | definizione sopra; per FMD prima una mediana 3×3, che toglie le celle isolate |
| F07 | dimensione di box-counting D | `N(s)` = scatole s×s che toccano la frontiera, `N(s) ∝ s^(−D)`; D = pendenza in log-log (fit s = 1…8), più la pendenza locale `D(s)` |
| F08 | D per tutte le prove 400×400 | frontiera di MD (Luigi3) e frontiera 0/1 di M (Luigi2) |
| F09 | tre finestre 100×100 candidate per lo zoom | W1 = più frontiera di MD · W2 = MD medio massimo · W3 = più frontiera di FMD (massimo di una somma su finestra mobile) |
| F10 | zoom annidati 200/100/50 su W1 (frontiera) e su W2 (MD) | D ricalcolata in ogni zoom |

## Come leggere D
- Una curva liscia ha D = 1; un insieme che riempie il piano ha D = 2.
- L'indizio di frattalità è un valore intermedio **che resta stabile al cambiare della scala** (F07 a destra, F10).

**Limiti**
- Con 400 punti per lato le scale utili sono poche.
- Dove MF ≈ MB (MD molto piccolo) la frontiera può essere rumore numerico di `ode45`, e questo aumenta D.

**Passo successivo**, come suggerisce Luigi: ricalcolare una delle finestre W1/W2/W3 con 400×400 punti (risoluzione 4× più fine) e controllare se struttura e D si ripetono.
