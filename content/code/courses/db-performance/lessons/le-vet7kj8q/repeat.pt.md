---
title: Rode de novo, e de novo
version: 1
---

Uma execução de um benchmark é uma anedota. Produziu um número, e a próxima, sem nada mudado, vai
produzir outro. **A diferença entre execuções da mesma coisa é o ruído, e ela define o tamanho da
menor mudança em que dá para acreditar.** Sem ela, um resultado de "8% mais rápido" não se distingue
de "8% mais sortudo".

## Três execuções, do mesmo ponto de partida

O `place-order.sql` acrescenta pedidos toda vez que roda, então uma série de execuções muda aos
poucos o banco que está medindo. Comece a série de um estado conhecido, o `~/reset-market.sh` da aula
2, e depois rode o mesmo comando três vezes:

```
ana@vm:~$ ~/reset-market.sh
CREATE EXTENSION
Time: 8.774 ms
CREATE INDEX
Time: 720.199 ms
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(tps|latency average)'
latency average = 6.917 ms
tps = 1156.560488 (without initial connection time)
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(tps|latency average)'
latency average = 5.579 ms
tps = 1433.898020 (without initial connection time)
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(tps|latency average)'
latency average = 6.100 ms
tps = 1311.392039 (without initial connection time)
```

**1157, 1434 e 1311 transações por segundo**; latências médias de 6,9, 5,6 e 6,1 milissegundos. O
mesmo banco, os mesmos scripts, a mesma máquina, com um minuto e meio de distância. Ao lado dos
pedaços de execuções que esta aula já imprimiu, o quadro é coerente:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Um gráfico de pontos de transações por segundo, de 800 a 1500. Linha de cima, os três intervalos de dez segundos de uma execução: 1263, 1157 e 1289. Linha do meio, os seis intervalos de cinco segundos da execução fria: 1134, 1292, 975, 1086, 1103 e 864. Linha de baixo, três execuções de trinta segundos depois de uma cópia nova do market: 1157 na primeira, depois 1434 e 1311. Os pontos de toda linha se espalham por cem transações por segundo ou mais.\"><text x=\"14\" y=\"40\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma execução, intervalos de 10 s</text><path d=\"M230 40 L700 40\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"541.1400000000001\" cy=\"40\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"469.4985714285715\" cy=\"40\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"558.2614285714286\" cy=\"40\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"14\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">execução fria, intervalos de 5 s</text><path d=\"M230 92 L700 92\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"453.9885714285714\" cy=\"92\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"560.4771428571429\" cy=\"92\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"347.7685714285714\" cy=\"92\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"421.8942857142857\" cy=\"92\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"433.71142857142866\" cy=\"92\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"273.24\" cy=\"92\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"14\" y=\"144\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">três execuções após cópia nova</text><path d=\"M230 144 L700 144\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"469.43142857142857\" cy=\"144\" r=\"5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"655.6185714285715\" cy=\"144\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"573.3685714285714\" cy=\"144\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"469.43142857142857\" y=\"160\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--amber)\">1ª, descartada</text><path d=\"M230 186 L700 186\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M230.0 186 L230.0 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"230.0\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">800</text><path d=\"M297.1428571428571 186 L297.1428571428571 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"297.1428571428571\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">900</text><path d=\"M364.2857142857143 186 L364.2857142857143 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"364.2857142857143\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1000</text><path d=\"M431.42857142857144 186 L431.42857142857144 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"431.42857142857144\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1100</text><path d=\"M498.57142857142856 186 L498.57142857142856 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"498.57142857142856\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1200</text><path d=\"M565.7142857142858 186 L565.7142857142858 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"565.7142857142858\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1300</text><path d=\"M632.8571428571429 186 L632.8571428571429 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"632.8571428571429\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1400</text><path d=\"M700.0 186 L700.0 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"700.0\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1500</text><text x=\"700\" y=\"218\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"end\" fill=\"var(--paper-dim)\">transações por segundo</text></svg>", "caption": "A mesma carga na mesma máquina, medida em pedaços e em execuções inteiras. Nenhuma linha é um número só."}
```

Duas coisas aparecem na linha de baixo.

**A primeira execução é a mais baixa.** Ela rodou contra um banco recém-copiado do `market_base`,
cujas páginas ninguém tinha pedido ainda, e pagou para esquentá-las. É a execução fria da seção
anterior em outra forma, e é por isso que a primeira execução de uma série é rodada e depois jogada
fora, e não entra na média.

**As duas que sobram diferem em 9%**, 1311 contra 1434. Esse é o ruído desta máquina para uma
execução de trinta segundos desta carga, medido e não suposto, e quer dizer que uma mudança que mexe
o número em 5% não mostrou fazer coisa nenhuma com execuções desse tamanho.

## As regras de uma série

- **Comece do mesmo estado.** Restaure os dados se a carga escreve, reinicie ou não conforme decidiu
  na seção anterior, e não mude nada entre as execuções: o mesmo comando, os mesmos clientes, nada
  mais rodando na máquina.
- **Descarte uma execução de aquecimento** e depois guarde **pelo menos três**. Se a dispersão delas
  for larga, rode mais, ou rode por mais tempo: uma execução mais longa faz a média de mais intervalos,
  e o total dela se mexe menos.
- **Informe a mediana e a faixa**, nunca uma execução só e nunca só a melhor. "1311 por segundo, entre
  1311 e 1434 em duas execuções depois de um aquecimento" é uma medida; "1434" é uma escolha.
- **Guarde os comandos junto com os números.** Um resultado só é reproduzível se alguém puder rodar
  exatamente o que você rodou, e é por isso que todo número deste curso fica embaixo do comando que o
  produziu.

A aula 24 pega uma série como esta antes de uma mudança e outra depois, e faz a pergunta em que esta
aula para antes: a diferença é maior que o ruído, e vale o que a mudança custa? Tudo o que ela faz se
apoia em séries medidas do jeito que esta seção descreve.

## De volta às linhas conhecidas

As execuções desta aula acrescentaram milhares de pedidos ao `market` e criaram um banco chamado
`bench`, que já foi apagado. Devolva o `market` ao estado em que a aula 3 começa, rodando
`~/reset-market.sh` mais uma vez.
