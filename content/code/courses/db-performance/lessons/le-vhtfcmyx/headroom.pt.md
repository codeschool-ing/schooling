---
title: Folga, e o joelho da curva
version: 1
---

Um disco enche num ritmo que dá para ler numa tabela. O outro limite de um servidor não se comporta
assim de jeito nenhum, e é o que dói primeiro. **Um servidor ocupado não fica sem velocidade; fica
sem sala de espera.**

A crença comum é que um servidor a 80% da capacidade está a 20% do problema, e que cada pedido leva
o mesmo tempo a 80% que a 10%. Nenhuma das duas coisas é verdade, e você pode medir por quê na sua
própria máquina.

## O máximo que o servidor consegue

Rode a carga sem limite, e o `pgbench` manda a próxima transação no instante em que a anterior
volta. O que ele relata é o máximo que este servidor consegue fazer com oito clientes:

```
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(tps|latency average)'
latency average = 7.276 ms
tps = 1099.568477 (without initial connection time)
```

**1099 transações por segundo.** Essa é a parede da vazão, nesta máquina, com esta carga. Não é um
número para rodar em cima.

## A mesma carga, oferecida a uma taxa fixa

O `-R` muda o jeito de o `pgbench` mandar: em vez de o mais rápido possível, ele agenda transações a
uma taxa fixa, do jeito que usuários de verdade chegam, esteja o servidor pronto ou não. Quando o
servidor fica para trás, uma transação espera a vez dela, e essa espera — o **atraso de agenda**
(*schedule lag*) — entra na latência, como um usuário a contaria. Esta é a carga a 300, 600, 900 e
1050 por segundo:

```
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -R 300 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(tps|latency average|latency stddev|rate limit schedule lag)'
latency average = 3.969 ms
latency stddev = 10.333 ms
rate limit schedule lag: avg 0.535 (max 103.418) ms
tps = 298.196636 (without initial connection time)
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -R 600 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(tps|latency average|latency stddev|rate limit schedule lag)'
latency average = 11.184 ms
latency stddev = 27.263 ms
rate limit schedule lag: avg 6.653 (max 289.220) ms
tps = 595.973414 (without initial connection time)
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -R 900 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(tps|latency average|latency stddev|rate limit schedule lag)'
latency average = 29.304 ms
latency stddev = 50.155 ms
rate limit schedule lag: avg 23.920 (max 355.874) ms
tps = 889.709604 (without initial connection time)
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -R 1050 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(tps|latency average|latency stddev|rate limit schedule lag)'
latency average = 132.969 ms
latency stddev = 179.683 ms
rate limit schedule lag: avg 127.031 (max 900.691) ms
tps = 1042.545758 (without initial connection time)
```

Leia a latência descendo as quatro execuções: **4, 11, 29 e 133 milissegundos**. De 300 para 600 por
segundo, o servidor faz o dobro do trabalho e cada pedido leva umas três vezes mais. De 900 para 1050
— um sexto a mais de trabalho — cada pedido leva quatro vezes e meia mais. E a 1050, 95% do máximo,
o servidor ainda entregou a taxa: `tps = 1042`. Ele não falhou. Acompanhou fazendo todo mundo
esperar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um gráfico de linha da latência média contra a taxa de transações oferecida ao servidor. A 300 por segundo a latência é de 4 milissegundos, a 600 é de 11, a 900 é de 29, e a 1050 é de 133. O máximo do servidor, medido sem limite de taxa, é de 1099 por segundo, marcado por uma linha vertical tracejada. A curva é quase plana até uns 600 e depois dobra para cima de repente.\"><rect x=\"14\" y=\"20\" width=\"692\" height=\"268\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M80 250 L660 250\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M80 250 L80 40\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"80.0\" y=\"266\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">0</text><text x=\"225.0\" y=\"266\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">300</text><text x=\"370.0\" y=\"266\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">600</text><text x=\"515.0\" y=\"266\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">900</text><text x=\"660.0\" y=\"266\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1200</text><text x=\"72\" y=\"250.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"end\" fill=\"var(--paper-dim)\">0</text><text x=\"72\" y=\"197.5\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"end\" fill=\"var(--paper-dim)\">35</text><text x=\"72\" y=\"145.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"end\" fill=\"var(--paper-dim)\">70</text><text x=\"72\" y=\"92.5\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"end\" fill=\"var(--paper-dim)\">105</text><text x=\"72\" y=\"40.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"end\" fill=\"var(--paper-dim)\">140</text><text x=\"370.0\" y=\"282\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">transações por segundo oferecidas</text><text x=\"74\" y=\"30\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--paper-dim)\">ms</text><path d=\"M225.0 244.0 L370.0 233.2 L515.0 206.0 L587.5 50.5\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><circle cx=\"225.0\" cy=\"244.0465\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"370.0\" cy=\"233.224\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"515.0\" cy=\"206.044\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"587.5\" cy=\"50.54650000000001\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"225.0\" y=\"230.0465\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">4 ms</text><text x=\"370.0\" y=\"219.224\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">11 ms</text><text x=\"505\" y=\"206\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--paper)\">29 ms</text><text x=\"577.5\" y=\"50.54650000000001\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--paper)\">133 ms</text><path d=\"M611.6666666666666 250 L611.6666666666666 40\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><text x=\"617.6666666666666\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">máximo</text><text x=\"617.6666666666666\" y=\"68\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">1099</text></svg>", "caption": "Latência média contra a taxa oferecida, no computador da gravação. O último décimo da capacidade custa mais que os nove primeiros.", "same": ["ms"]}
```

Esse formato tem nome na teoria das filas, e você não precisa da teoria para usá-lo. Quando os
pedidos chegam em momentos aleatórios, alguns chegam juntos; os que chegam com o servidor ocupado
esperam; e quanto mais perto o servidor está de totalmente ocupado, mais vezes uma chegada o encontra
ocupado e mais longa a fila que ela encontra. A espera cresce devagar no começo e depois sem limite
conforme a taxa se aproxima do máximo. **O joelho da curva é onde a folga acaba**, e nesta máquina e
nesta carga ele fica em algum lugar entre 600 e 900 por segundo — entre metade e quatro quintos do
máximo.

## A média esconde quem esperou

A média é o resumo mais gentil de uma latência, e o menos útil perto do joelho. Para ver o que os
usuários mais lentos viram, o `pgbench` pode registrar a latência de cada transação com `-l`, e este
script lê o registro e imprime três percentis — a latência abaixo da qual ficaram metade, noventa e
cinco e noventa e nove de cada cem transações:

```sh
cat > ~/workload/percentiles.sh <<'SH'
#!/bin/sh
# percentiles.sh PREFIX: the 50th, 95th and 99th percentile latency of a
# pgbench run that was logged with  -l --log-prefix=PREFIX
cat "$1".* | awk '{ print $3 }' | sort -n | awk -v run="$1" '
  { t[NR] = $1 }
  END { printf "%s  p50 %.1f ms  p95 %.1f ms  p99 %.1f ms\n", run,
        t[int(NR * .50)] / 1000, t[int(NR * .95)] / 1000, t[int(NR * .99)] / 1000 }'
SH
chmod +x ~/workload/percentiles.sh
```

Duas execuções, uma a 600 por segundo e outra a 1000, cada uma registrada, e depois o script em
cada uma:

```
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -R 600 -l --log-prefix=r600 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market > /dev/null
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -R 1000 -l --log-prefix=r1000 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market > /dev/null
ana@vm:~/workload$ ./percentiles.sh r600
r600  p50 0.7 ms  p95 30.9 ms  p99 93.5 ms
ana@vm:~/workload$ ./percentiles.sh r1000
r1000  p50 62.3 ms  p95 470.9 ms  p99 621.0 ms
```

A 600 por segundo, **metade das transações levou 0,7 milissegundo** e uma em cem levou mais de 93. A
1000 por segundo, a transação do meio levou 62 e uma em cem levou mais de **621 milissegundos** —
dois terços de segundo, numa carga cuja consulta típica roda em menos de um. Os percentis se mexeram
muito mais que a média, porque a fila não atrasa todo mundo por igual: atrasa quem chega atrás de uma
consulta lenta.

Então a folga que importa não é "quão longe do máximo", é **quão longe do joelho**. Nesta máquina,
rodar a carga a 1000 por segundo deixa um décimo do máximo sem uso e já faz os usuários mais lentos
esperarem mais de meio segundo. Um plano de capacidade que diz "estamos a 80%, temos espaço" está
lendo o eixo errado.
