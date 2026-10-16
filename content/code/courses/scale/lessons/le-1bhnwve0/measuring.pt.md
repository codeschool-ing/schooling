---
title: Medir antes de mudar qualquer coisa
version: 1
---

**Uma mudança feita num sistema que você não mediu é um palpite com uma implantação junto.** Então
a primeira coisa a fazer com a bilheteria é descobrir o que ela faz agora: quantos pedidos por
segundo responde, quanto tempo cada um leva e o que acontece com os dois quando mais pedidos chegam
ao mesmo tempo. O `load.py`, que você escreveu na seção 04, faz as três coisas.

## Um trabalhador, dois caminhos

Com um trabalhador, o `load.py` envia um pedido, espera a resposta e envia o próximo, durante dez
segundos. Primeiro o caminho barato, ler um show:

```
ana@lab:~/tickets$ python3 load.py -c 1 -d 10 http://localhost:8080/events/1
requests  10718 in 10.0 s = 1071.6 per second
latency   p50 0.9 ms  p95 1.3 ms  p99 2.0 ms  max 18.9 ms
status    200: 10718
```

Mais de mil leituras por segundo, a do meio respondida em menos de um milissegundo. Depois o
caminho caro, comprar um ingresso, espalhado pelos cem shows com `--events 100` para que duas
vendas seguidas nunca toquem o mesmo:

```
ana@lab:~/tickets$ python3 load.py -m POST -c 1 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  1189 in 10.0 s = 118.9 per second
latency   p50 7.8 ms  p95 12.5 ms  p99 14.2 ms  max 21.3 ms
status    201: 1189
```

Cerca de 119 vendas por segundo, 7,8 ms cada no meio. Quase tudo isso é o `sign()`, a parte lenta
de propósito de uma venda; o update e o insert em volta dele são uma fração de milissegundo. Uma
venda custa **nove vezes** o que uma leitura custa, e é por isso que o resto desta aula mede vendas.

## Lendo as quatro latências

O `load.py` imprime quatro pontos da distribuição, e cada um responde uma pergunta diferente:

- **p50**, a mediana: metade dos pedidos foi mais rápida que isso. Descreve o pedido típico.
- **p95** e **p99**: os tempos abaixo dos quais 95 e 99 de cada cem terminaram. Descrevem os lentos,
  e são o que um usuário ativo encontra, porque uma página que faz vinte pedidos encontra o p95
  mais ou menos uma vez por página.
- **max**: o mais lento de todos. Útil como alerta e inútil como meta; uma única travada da máquina
  o define.

**Não há média nessa lista, de propósito.** Uma média de latências mistura a maioria rápida com os
poucos lentos e não descreve nenhum dos dois: cem pedidos de 10 ms e um de 2 segundos dão média de
30 ms, um número que nenhum pedido levou. A aula 7 volta a isso quando a bilheteria passa a relatar
as próprias latências.

## Acrescentando trabalhadores

Um trabalhador deixa a bilheteria parada enquanto cada resposta volta e o próximo pedido chega.
Mais trabalhadores a mantêm ocupada. Aqui está a mesma venda com 1, 2, 4 e até 64 trabalhadores
enviando ao mesmo tempo:

```
ana@lab:~/tickets$ python3 load.py -m POST -c 1 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  1149 in 10.0 s = 114.8 per second
latency   p50 8.0 ms  p95 12.6 ms  p99 15.6 ms  max 25.0 ms
status    201: 1149
ana@lab:~/tickets$ python3 load.py -m POST -c 2 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  1572 in 10.0 s = 157.1 per second
latency   p50 7.9 ms  p95 45.3 ms  p99 49.3 ms  max 55.3 ms
status    201: 1572
ana@lab:~/tickets$ python3 load.py -m POST -c 4 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  1476 in 10.0 s = 147.5 per second
latency   p50 11.4 ms  p95 75.6 ms  p99 81.1 ms  max 93.5 ms
status    201: 1476
ana@lab:~/tickets$ python3 load.py -m POST -c 8 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  1471 in 10.0 s = 146.5 per second
latency   p50 75.6 ms  p95 96.1 ms  p99 102.4 ms  max 179.6 ms
status    201: 1471
ana@lab:~/tickets$ python3 load.py -m POST -c 16 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  1437 in 10.0 s = 143.3 per second
latency   p50 103.1 ms  p95 196.4 ms  p99 262.6 ms  max 333.8 ms
status    201: 1437
ana@lab:~/tickets$ python3 load.py -m POST -c 32 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  1483 in 10.1 s = 146.3 per second
latency   p50 204.3 ms  p95 384.5 ms  p99 499.7 ms  max 783.7 ms
status    201: 1483
ana@lab:~/tickets$ python3 load.py -m POST -c 64 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  1400 in 10.2 s = 137.8 per second
latency   p50 407.9 ms  p95 797.3 ms  p99 1778.3 ms  max 3179.8 ms
status    201: 1400
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Dois gráficos das mesmas sete rodadas, com 1, 2, 4, 8, 16, 32 e 64 trabalhadores. À esquerda, os ingressos vendidos por segundo sobem de 115 para 157 entre um e dois trabalhadores e depois ficam entre 138 e 148. À direita, a latência mediana fica perto de 8 milissegundos até dois trabalhadores e depois dobra a cada vez que os trabalhadores dobram, chegando a 408 milissegundos com 64.\"><text x=\"205.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">ingressos por segundo</text><path d=\"M70 40 L70 240\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M70 240 L340 240\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"64\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><text x=\"88.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"127.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"166.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"205.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><text x=\"244.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">16</text><text x=\"283.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">32</text><text x=\"322.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">64</text><path d=\"M88.0 125.2 L127.0 82.9 L166.0 92.5 L205.0 93.5 L244.0 96.7 L283.0 93.7 L322.0 102.2\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"88.0\" cy=\"125.2\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"88.0\" y=\"113.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">115</text><circle cx=\"127.0\" cy=\"82.9\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"127.0\" y=\"70.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">157</text><circle cx=\"166.0\" cy=\"92.5\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"166.0\" y=\"80.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">148</text><circle cx=\"205.0\" cy=\"93.5\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"205.0\" y=\"81.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">146</text><circle cx=\"244.0\" cy=\"96.69999999999999\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"244.0\" y=\"84.69999999999999\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">143</text><circle cx=\"283.0\" cy=\"93.69999999999999\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"283.0\" y=\"81.69999999999999\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">146</text><circle cx=\"322.0\" cy=\"102.19999999999999\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"322.0\" y=\"90.19999999999999\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">138</text><text x=\"205.0\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">trabalhadores</text><text x=\"555.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">latência mediana, ms</text><path d=\"M420 40 L420 240\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M420 240 L690 240\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"414\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"414\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">450</text><text x=\"438.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"477.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"516.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"555.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><text x=\"594.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">16</text><text x=\"633.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">32</text><text x=\"672.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">64</text><path d=\"M438.0 236.4 L477.0 236.5 L516.0 234.9 L555.0 206.4 L594.0 194.2 L633.0 149.2 L672.0 58.7\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"438.0\" cy=\"236.44444444444446\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"438.0\" y=\"224.44444444444446\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">8</text><circle cx=\"477.0\" cy=\"236.48888888888888\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"477.0\" y=\"224.48888888888888\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">8</text><circle cx=\"516.0\" cy=\"234.93333333333334\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"516.0\" y=\"222.93333333333334\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">11</text><circle cx=\"555.0\" cy=\"206.4\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"555.0\" y=\"194.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">76</text><circle cx=\"594.0\" cy=\"194.17777777777778\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"594.0\" y=\"182.17777777777778\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">103</text><circle cx=\"633.0\" cy=\"149.2\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"633.0\" y=\"137.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">204</text><circle cx=\"672.0\" cy=\"58.71111111111111\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"672.0\" y=\"46.71111111111111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">408</text><text x=\"555.0\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">trabalhadores</text><text x=\"360\" y=\"304\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o joelho: depois de dois trabalhadores, mais carga só aumenta a fila</text></svg>", "caption": "A mesma bilheteria, um processador, cada vez mais trabalhadores. A vazão para no joelho; a latência continua."}
```

Duas coisas acontecem, e elas são a forma que todo sistema tem.

**A vazão sobe, e depois para.** De um trabalhador para dois ela vai de 115 para 157 por segundo,
porque a bilheteria deixa de esperar a rede entre um pedido e outro. Daí em diante fica perto de
145, com 4 trabalhadores ou com 64. O tempo de um processador, que é o que `cpus: 1` dá ao
contêiner, assina uns 150 ingressos por segundo, e nada que o gerador de carga faça muda isso.

**A latência fica parada, e depois sobe em proporção.** Até o ponto em que a vazão para de subir,
cada pedido leva mais ou menos o tempo do trabalho que precisa. Depois dele, cada trabalhador a
mais é mais um pedido esperando o processador, e a mediana dobra a cada vez que os trabalhadores
dobram: 103 ms com 16, 204 com 32, 408 com 64. **A carga extra não fez a bilheteria fazer mais; fez
a fila ficar maior.** Esse é o joelho da curva, e achá-lo é a primeira medida a fazer em qualquer
sistema.

Os números estão amarrados por uma regra que este curso reencontra na aula 11: com 16 pedidos
sempre dentro do sistema e 143 saindo a cada segundo, cada um passa 16 ÷ 143 ≈ 0,11 segundo lá
dentro, que é a latência impressa. Quando a vazão está parada, a latência é só o número de pedidos
esperando dividido pelo ritmo em que eles saem.

## O gargalo, com nome

A curva diz que a bilheteria deixou de dar conta perto de 150 vendas por segundo. Não diz por quê,
e "o processador" é um palpite até alguma coisa confirmar. `docker stats` num segundo terminal,
enquanto roda um teste com 16 trabalhadores, mostra a fatia de processador e a memória de cada
contêiner:

```
ana@lab:~/tickets$ docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
NAME            CPU %     MEM USAGE / LIMIT
tickets-lb-1    2.30%     2.77MiB / 15.72GiB
tickets-app-1   100.12%   25.68MiB / 15.72GiB
tickets-db-1    10.74%    59.79MiB / 15.72GiB
```

`100.12%` é um processador inteiro, tudo o que `cpus: 1` permite, enquanto o banco usa um décimo de
um e o nginx quase nada. **O processador da bilheteria é o gargalo**, e as duas próximas seções dão
a ela mais processadores, dos dois jeitos que existem.
