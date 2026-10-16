---
title: O preço, medido e multiplicado
version: 1
---

O `pgbench` roda uma pequena carga bancária o mais rápido que consegue: aqui, quatro clientes por dez
segundos, imprimindo o tempo médio por transação e as transações por segundo. Primeiro com o standby
assíncrono, antes do reload da seção anterior:

```
ana@vm:~$ pgbench -c 4 -T 10 -n bench | grep -E "latency average|tps"
latency average = 1.610 ms
tps = 2484.004983 (without initial connection time)
```

Depois síncrono, com `synchronous_commit` no padrão, `on`:

```
ana@vm:~$ pgbench -c 4 -T 10 -n bench | grep -E "latency average|tps"
latency average = 1.969 ms
tps = 2031.340162 (without initial connection time)
```

Depois as duas pontas da escala, definidas só para as sessões do `pgbench` via `PGOPTIONS`:

```
ana@vm:~$ PGOPTIONS='-c synchronous_commit=remote_apply' pgbench -c 4 -T 10 -n bench | grep -E 'latency average|tps'
latency average = 2.019 ms
tps = 1981.525766 (without initial connection time)
ana@vm:~$ PGOPTIONS='-c synchronous_commit=off' pgbench -c 4 -T 10 -n bench | grep -E 'latency average|tps'
latency average = 0.837 ms
tps = 4776.640810 (without initial connection time)
```

| `synchronous_commit` | latência média | transações por segundo |
|---|---|---|
| `off` | 0,837 ms | 4777 |
| standby assíncrono, `on` | 1,610 ms | 2484 |
| standby síncrono, `on` | 1,969 ms | 2031 |
| standby síncrono, `remote_apply` | 2,019 ms | 1982 |

Esperar o flush do standby custou **cerca de um terço de milissegundo por transação, perto de um quinto
da vazão.** Esperar também o replay acrescentou só mais um vigésimo de milissegundo, porque um standby
sem mais nada para fazer reaplica assim que termina o flush. Rodadas de dez segundos variam alguns por
cento de uma para a outra, então leia as diferenças e não o último dígito; os seus números vão variar
com o seu disco. E este é o mais barato que isso vai ser: o standby aqui está na mesma máquina, a rede
entre os dois é uma cópia em memória, e este kernel não consegue acrescentar um atraso artificial para
simular uma.

O `off` é a outra surpresa: levou metade do tempo da rodada assíncrona, porque o primário não espera
nem o próprio disco. Ele perde a última fração de segundo de commits se o primário cair, **com ou sem
standby**, o que é aceitável para um contador de visualizações de página e para mais nada.

## Multiplicado para distâncias reais

Todo commit síncrono paga **uma ida e volta** até o standby, além do flush no disco do próprio standby.
A ida e volta é definida pela distância, não pelo hardware:

| standby | ida e volta típica | somado a cada commit |
|---|---|---|
| mesma máquina (este laboratório) | bem abaixo de 0,1 ms | o terço de milissegundo acima, quase todo o flush do standby |
| mesmo data center | uma fração de milissegundo | mais ou menos o mesmo |
| outro data center na mesma cidade ou região | de 1 a 5 ms | alguns milissegundos |
| outro continente | uns 100 ms ou mais | um décimo de segundo, no mínimo |

Uma transação que faz commit uma vez paga isso uma vez; uma aplicação que faz commit num loop, linha
por linha, paga por linha, e uma importação noturna de um milhão de linhas que levava dois minutos
levaria mais de um dia contra um standby em outro continente. É por isso que os standbys síncronos
costumam ficar **perto**, e as cópias distantes são assíncronas, que é a base da lição 20.

O outro custo não é latência, e é o assunto da próxima seção.
