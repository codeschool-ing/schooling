---
title: Escolhendo a partir dos seus próprios usuários
version: 1
---

**Os seus dados de uso já sabem que celulares os seus usuários têm; a matriz começa ali.** Toda
ferramenta de analytics que um app carrega registra o modelo do aparelho, o fabricante e a versão do
Android a cada sessão, e o Google Play Console mostra o mesmo para cada instalação. Exportado, é uma
tabela de aparelhos e de quanto foram usados. O que você quer dela é a lista mais curta de valores
que cobre a maior parte do uso, e um script curto responde isso para qualquer coluna.

## A exportação

Exportações reais têm mais colunas e muito mais linhas. Esta é pequena o bastante para ler, e **os
números dela foram inventados para esta lição**: têm o formato do público de um app brasileiro,
muitos celulares Samsung, Motorola e Xiaomi no meio da faixa de preço, e nada além disso. Crie uma
pasta `matrix` no seu projeto boxoffice e salve como `matrix/sessions.csv`:

```
maker,model,android,sessions
Samsung,Galaxy A15,14,18400
Samsung,Galaxy A05s,14,9100
Motorola,Moto G24,14,8700
Xiaomi,Redmi Note 13,14,7600
Samsung,Galaxy A54,15,6200
Xiaomi,Redmi 13C,14,5400
Motorola,Moto G84,14,5100
Samsung,Galaxy A32,13,4800
Motorola,Moto E13,13,4300
Motorola,Moto G22,12,3900
Samsung,Galaxy S23,15,2900
Xiaomi,Redmi 9A,11,2100
Xiaomi,Poco X6,15,1800
Realme,C53,13,1500
Google,Pixel 7a,15,900
LG,K62,11,600
```

## O script

Ele lê a exportação, soma as sessões de cada valor da coluna que você nomear, ordena do mais usado
para o menos, e imprime a fatia acumulada até uma meta que você escolhe, 90% se você não disser
outra. Salve como `matrix/coverage.mjs`:

```js
// matrix/coverage.mjs: which values of one column cover most of the sessions
import { readFileSync } from 'node:fs';

const column = process.argv[2] ?? 'android';
const target = Number(process.argv[3] ?? 90);

const text = readFileSync(new URL('./sessions.csv', import.meta.url), 'utf8');
const [header, ...lines] = text.trim().split('\n');
const names = header.split(',');
if (!names.includes(column)) {
  console.error(`no column "${column}"; the columns are ${names.join(', ')}`);
  process.exit(2);
}

const totals = new Map();
let all = 0;
for (const line of lines) {
  const row = Object.fromEntries(line.split(',').map((v, i) => [names[i], v]));
  const n = Number(row.sessions);
  totals.set(row[column], (totals.get(row[column]) ?? 0) + n);
  all += n;
}

const pct = (n) => `${((n * 100) / all).toFixed(1).padStart(6)}%`;
let sum = 0;
let picked = 0;
console.log(`${column.padEnd(16)}sessions    share  running`);
for (const [value, n] of [...totals].sort((a, b) => b[1] - a[1])) {
  const needed = sum * 100 < target * all;
  sum += n;
  if (needed) picked++;
  const mark = needed && sum * 100 >= target * all ? `  <- ${target}% reached` : '';
  console.log(`${value.padEnd(16)}${String(n).padStart(8)}  ${pct(n)}  ${pct(sum)}${mark}`);
}
console.log(`${picked} of ${totals.size} values cover ${target}% of ${all} sessions`);
```

## Versões do Android

```
ana@laptop:~/boxoffice$ node matrix/coverage.mjs android
android         sessions    share  running
14                 54300    65.2%    65.2%
15                 11800    14.2%    79.4%
13                 10600    12.7%    92.1%  <- 90% reached
12                  3900     4.7%    96.8%
11                  2700     3.2%   100.0%
3 of 5 values cover 90% of 83300 sessions
```

**Três versões de cinco cobrem 92.1% das sessões**, o que passa dos 90% pedidos. O Android 14
sozinho é 65.2%. Os 3.2% no Android 11 são dois modelos antigos; eles não somem, vão para a cauda
longa, testados com menos frequência e numa nuvem de aparelhos.

## Fabricantes

```
ana@laptop:~/boxoffice$ node matrix/coverage.mjs maker
maker           sessions    share  running
Samsung            41400    49.7%    49.7%
Motorola           22000    26.4%    76.1%
Xiaomi             16900    20.3%    96.4%  <- 90% reached
Realme              1500     1.8%    98.2%
Google               900     1.1%    99.3%
LG                   600     0.7%   100.0%
3 of 6 values cover 90% of 83300 sessions
```

Três fabricantes cobrem 96.4%. Uma matriz com Samsung, Motorola e Xiaomi alcança quase todo mundo
que este app tem; o próprio Pixel do Google, o celular que o emulador imita mais de perto, é 1.1%
aqui.

## Modelos

```
ana@laptop:~/boxoffice$ node matrix/coverage.mjs model
model           sessions    share  running
Galaxy A15         18400    22.1%    22.1%
Galaxy A05s         9100    10.9%    33.0%
Moto G24            8700    10.4%    43.5%
Redmi Note 13       7600     9.1%    52.6%
Galaxy A54          6200     7.4%    60.0%
Redmi 13C           5400     6.5%    66.5%
Moto G84            5100     6.1%    72.6%
Galaxy A32          4800     5.8%    78.4%
Moto E13            4300     5.2%    83.6%
Moto G22            3900     4.7%    88.2%
Galaxy S23          2900     3.5%    91.7%  <- 90% reached
Redmi 9A            2100     2.5%    94.2%
Poco X6             1800     2.2%    96.4%
C53                 1500     1.8%    98.2%
Pixel 7a             900     1.1%    99.3%
K62                  600     0.7%   100.0%
11 of 16 values cover 90% of 83300 sessions
```

**Modelos são onde a cauda é longa.** São precisos onze dos dezesseis para chegar a 90%, e uma
exportação real teria centenas, cada um uma fração de um por cento. Nenhuma equipe tem onze celulares
para um app, e é por isso que a prateleira da lição 19 guarda dois ou três escolhidos, e por isso que
os modelos que a seção 05 aluga são tirados desta lista, de cima para baixo.

## Lendo como quem testa

- **Escolha uma meta antes de olhar**, 90% ou 95%, e escreva no plano de testes. Uma meta escolhida
  depois de ver os números tende a cair onde a lista era conveniente de parar.
- **Rode de novo a cada poucos meses.** Celulares são trocados; a versão que era 65% este ano é a
  cauda longa daqui a três.
- **Confira a versão mais antiga em separado.** O SDK mínimo que o app declara é uma promessa para
  esses usuários também, por poucos que sejam, e uma falha ali é defeito qualquer que seja a fatia.
