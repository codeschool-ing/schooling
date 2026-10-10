---
title: Backpressure, e um consumidor expulso do grupo
version: 1
---

**Num pipeline em que cada etapa empurra para a próxima, uma etapa lenta precisa empurrar de
volta.** Se não empurrar, a etapa rápida continua mandando, os buffers enchem, a memória acaba e algo
cai. Esse empurrar de volta se chama **backpressure** (contrapressão), e sistemas construídos sobre
empurrar precisam de um mecanismo para ele: créditos, filas limitadas, uma resposta que diz *pare por
enquanto*. O Flink tem um, entre os operadores de um job, e a lição 13 o encontra.

O Kafka entre um produtor e um consumidor não tem, e não precisa ter. **Consumidores puxam.** Um
consumidor pede mensagens quando está pronto para elas, então nunca recebe mais do que pediu, e o
produtor nunca espera por ele. O que seria um buffer cheio é o próprio log, em disco, dimensionado em
dias e não em megabytes. A seção anterior mostrou: os caixas mandaram 600 vendas em trinta segundos
enquanto o consumidor tinha tratado metade delas, e terminaram no horário. **O log é o buffer, e o lag
é o quanto ele está cheio.**

Isso muda o perigo de lugar em vez de removê-lo. Um consumidor que fica para trás não é derrubado por
uma enxurrada; ele só fica mais para trás, e é por isso que o lag precisa ser vigiado. E há um lugar
em que um consumidor lento é punido diretamente, pelo próprio grupo.

## Lento demais entre dois polls

O coordenador do grupo precisa saber se cada membro está vivo. Dois relógios decidem:

| configuração | o que ela vigia | padrão aqui |
|---|---|---|
| `session.timeout.ms` | heartbeats, que o cliente manda de uma thread própria | 45 s |
| `max.poll.interval.ms` | o tempo entre duas chamadas a `poll()` feitas pelo seu programa | 300 s |

Um consumidor cujo programa passa mais que `max.poll.interval.ms` sem fazer poll é presumido travado,
**e sai do grupo**: as partições dele vão para os outros membros, o que é um rebalanceamento. A ideia
é boa. Um programa preso num laço infinito continua mandando heartbeats pela thread do cliente, e só o
intervalo de poll o pega.

O problema começa quando o programa não está travado, só lento. Inicie dois membros de um grupo
chamado `audit`, ambos com seis segundos permitidos entre polls. No segundo shell, um membro que leva
meio segundo por venda:

```
ubuntu@stream:~/work$ python slow_consumer.py --group audit --delay 0.5 --max-poll 6000
```

E no terceiro, um que leva oito segundos por venda, como faria uma chamada a um serviço num dia ruim:

```
ubuntu@stream:~/work$ python slow_consumer.py --group audit --delay 8 --max-poll 6000
```

Depois de meio minuto, pare o lento com Ctrl+C. A tela dele:

```
ubuntu@stream:~/work$ python slow_consumer.py --group audit --delay 8 --max-poll 6000
16:38:21 assigned [0, 2]
%4|1791661108.167|MAXPOLL|rdkafka#consumer-1| [thrd:main]: Application maximum poll interval (6000ms) exceeded by 398ms (adjust max.poll.interval.ms for long-running message processing): leaving group
16:38:29 1 done, last car-000010 from partition 0 offset 0
16:38:29 error: Application maximum poll interval (6000ms) exceeded by 398ms
16:38:29 revoked [0, 2]
16:38:30 assigned [1]
%4|1791661116.192|MAXPOLL|rdkafka#consumer-1| [thrd:main]: Application maximum poll interval (6000ms) exceeded by 3ms (adjust max.poll.interval.ms for long-running message processing): leaving group
16:38:38 2 done, last oli-000044 from partition 1 offset 35
16:38:38 error: Application maximum poll interval (6000ms) exceeded by 3ms
16:38:38 revoked [1]
16:38:39 assigned [1]
%4|1791661125.220|MAXPOLL|rdkafka#consumer-1| [thrd:main]: Application maximum poll interval (6000ms) exceeded by 1ms (adjust max.poll.interval.ms for long-running message processing): leaving group
16:38:47 3 done, last joa-000045 from partition 1 offset 36
16:38:47 error: Application maximum poll interval (6000ms) exceeded by 1ms
16:38:47 revoked [1]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma linha do tempo de dois membros de um grupo. O membro lento faz poll, recebe uma venda e trabalha nela por oito segundos. Aos seis segundos o intervalo de poll se esgota e ele sai do grupo, que rebalanceia: as partições do membro rápido são revogadas e atribuídas de novo. Aos oito segundos o membro lento faz poll e volta ao grupo, o que é um segundo rebalanceamento, e a próxima venda começa o mesmo ciclo.\" data-fig=\"l16-maxpoll\"><defs><marker id=\"l16-maxpoll-ah-83\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"20\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">membro lento</text><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">membro rápido</text><text x=\"120\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0 s</text><line x1=\"120\" y1=\"38\" x2=\"120\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><text x=\"296\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">8 s</text><line x1=\"296\" y1=\"38\" x2=\"296\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><text x=\"472\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">16 s</text><line x1=\"472\" y1=\"38\" x2=\"472\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><text x=\"648\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">24 s</text><line x1=\"648\" y1=\"38\" x2=\"648\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><rect x=\"122\" y=\"67\" width=\"172\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"208\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">8 s numa venda</text><line x1=\"252\" y1=\"58\" x2=\"252\" y2=\"102\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><rect x=\"128\" y=\"159\" width=\"160\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"246\" y=\"159\" width=\"12\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M 252 102 L 252 152\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#l16-maxpoll-ah-83)\"></path><rect x=\"290\" y=\"159\" width=\"12\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M 296 102 L 296 152\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#l16-maxpoll-ah-83)\"></path><rect x=\"298\" y=\"67\" width=\"172\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><line x1=\"428\" y1=\"58\" x2=\"428\" y2=\"102\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><rect x=\"298\" y=\"159\" width=\"166\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"422\" y=\"159\" width=\"12\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M 428 102 L 428 152\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#l16-maxpoll-ah-83)\"></path><rect x=\"466\" y=\"159\" width=\"12\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M 472 102 L 472 152\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#l16-maxpoll-ah-83)\"></path><rect x=\"474\" y=\"67\" width=\"172\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><line x1=\"604\" y1=\"58\" x2=\"604\" y2=\"102\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><rect x=\"474\" y=\"159\" width=\"166\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"598\" y=\"159\" width=\"12\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M 604 102 L 604 152\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#l16-maxpoll-ah-83)\"></path><rect x=\"642\" y=\"159\" width=\"12\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M 648 102 L 648 152\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#l16-maxpoll-ah-83)\"></path><text x=\"252\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">6 s: sai do grupo</text><text x=\"300\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">poll, volta</text><text x=\"208\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tratando vendas</text><text x=\"274\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">dois rebalanceamentos</text></svg>", "caption": "Oito segundos de trabalho contra um limite de seis: toda venda custa dois rebalanceamentos, e o membro que acompanhava paga por ele também.", "same": ["0 s", "8 s", "16 s", "24 s"]}
```

Leia como um laço. O membro recebe as partições 0 e 2 e uma venda, e passa oito segundos nela. Aos
seis, o cliente desiste dele e sai do grupo: é a linha que começa com `%4|`, que a biblioteca do
cliente escreve por conta própria. Quando o programa finalmente faz poll de novo, recebe o erro, as
partições dele são revogadas, ele volta ao grupo e recebe partições de novo, e a próxima venda começa
os mesmos oito segundos. **Cada venda custa dois rebalanceamentos**, um quando o membro sai e outro
quando volta. Ele avança um pouco, uma venda por ciclo (os offsets 35 e depois 36 da partição 1), só
porque o cliente confirma o que já fez quando as partições são tiradas dele.

O custo não fica com o membro lento. O outro, que estava acompanhando, tem as partições tiradas e
devolvidas a cada saída e a cada volta:

```
ubuntu@stream:~/work$ python slow_consumer.py --group audit --delay 0.5 --max-poll 6000
16:38:12 assigned [0, 1, 2]
16:38:21 revoked [0, 1, 2]
16:38:21 assigned [1]
16:38:30 revoked [1]
16:38:30 assigned [0, 2]
16:38:37 50 done, last car-000092 from partition 0 offset 15
16:38:39 revoked [0, 2]
16:38:39 assigned [0, 2]
16:38:45 revoked [0, 2]
16:38:45 assigned [0, 1, 2]
16:38:48 revoked [0, 1, 2]
16:38:48 assigned [0, 1, 2]
16:38:48 revoked [0, 1, 2]
```

## O que resolve

Não um cluster maior. As correções estão todas no consumidor:

- **Deixe o intervalo entre polls menor que o limite, com folga.** Se uma venda pode levar oito
  segundos, o limite não pode ser seis. O padrão, cinco minutos, é generoso por um motivo, e baixá-lo,
  como esta demonstração fez, é como a maioria das pessoas conhece esse laço.
- **Pegue menos mensagens por poll.** Um cliente que busca 500 registros e os trata um a um antes de
  fazer poll de novo precisa de 500 vezes o tempo por registro. No cliente Java, `max.poll.records`
  limita isso; o cliente Python entrega uma mensagem por `poll()`, ou quantas você pedir ao
  `consume()`.
- **Tire o trabalho lento da thread de poll**, e pause as partições enquanto ele roda:
  `consumer.pause()` mantém o membro fazendo poll, e vivo, sem buscar mais. É mais código, e é o que
  trabalho demorado precisa.

A regra geral é a que esta seção inteira defende: **um stream dá tempo a um consumidor lento, não
perdão**. O lag absorve uma hora lenta. Um membro que não cumpre a promessa de fazer poll é removido,
e a própria remoção é trabalho que o grupo inteiro paga.
