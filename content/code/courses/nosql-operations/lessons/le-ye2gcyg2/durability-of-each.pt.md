---
title: Quanto cada um perde, e quanto custa
version: 1
---

As duas seções anteriores mataram o processo. **O que a queda de um processo perde e o que a queda de
uma máquina perde são quantidades diferentes**, e a configuração que decide a segunda, o
`appendfsync`, só mostra o seu valor no dia em que a energia acaba.

## Dois lugares onde uma escrita pode estar

Quando o Redis acrescenta um comando ao log, ele chama `write()`, e os bytes caem na memória do sistema
operacional, o page cache. Eles chegam ao disco quando o sistema operacional os descarrega, ou quando o
Redis pede com `fsync()`. Um processo do Redis morto deixa o page cache intacto: o kernel ainda grava
esses bytes, e é por isso que o `docker kill` da seção anterior não perdeu nada, embora menos de um
segundo tivesse passado. Uma máquina que perde energia perde o page cache também, e com ele toda
escrita ainda não descarregada.

O laboratório não consegue puxar o próprio cabo de energia, então a última coluna desta tabela é o que
a documentação do Redis afirma, **não algo que esta aula executou**:

| configuração | o Redis pede o descarregamento | o processo morre | a máquina perde energia |
| --- | --- | --- | --- |
| só snapshots (regras `save`) | quando um snapshot é gravado | toda escrita desde o último snapshot | toda escrita desde o último snapshot |
| `appendfsync always` | depois de cada escrita, antes da resposta | nada | nada que foi confirmado |
| `appendfsync everysec` | uma vez por segundo, em segundo plano | nada | mais ou menos o último segundo de escritas |
| `appendfsync no` | nunca; o sistema operacional decide | nada | o que o sistema operacional não tinha descarregado, em geral até 30 segundos no Linux |
| sem persistência | nunca | tudo | tudo |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Um eixo de tempo com escritas chegando sem parar e a energia caindo na ponta direita. Três linhas. Só snapshots: o último snapshot foi tirado minutos antes da falha, e toda escrita depois dele se perde. Arquivo append-only com everysec: só as escritas do último segundo se perdem. Arquivo append-only com always: nada que foi confirmado se perde.\"><line x1=\"170\" y1=\"30\" x2=\"640\" y2=\"30\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"178\" y1=\"25\" x2=\"178\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"197\" y1=\"25\" x2=\"197\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"216\" y1=\"25\" x2=\"216\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"235\" y1=\"25\" x2=\"235\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"254\" y1=\"25\" x2=\"254\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"273\" y1=\"25\" x2=\"273\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"292\" y1=\"25\" x2=\"292\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"311\" y1=\"25\" x2=\"311\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"330\" y1=\"25\" x2=\"330\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"349\" y1=\"25\" x2=\"349\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"368\" y1=\"25\" x2=\"368\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"387\" y1=\"25\" x2=\"387\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"406\" y1=\"25\" x2=\"406\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"425\" y1=\"25\" x2=\"425\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"444\" y1=\"25\" x2=\"444\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"463\" y1=\"25\" x2=\"463\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"482\" y1=\"25\" x2=\"482\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"501\" y1=\"25\" x2=\"501\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"520\" y1=\"25\" x2=\"520\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"539\" y1=\"25\" x2=\"539\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"558\" y1=\"25\" x2=\"558\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"577\" y1=\"25\" x2=\"577\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"596\" y1=\"25\" x2=\"596\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"615\" y1=\"25\" x2=\"615\" y2=\"35\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"170\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">escritas, um traço cada</text><line x1=\"650\" y1=\"20\" x2=\"650\" y2=\"230\" stroke=\"var(--amber)\" stroke-width=\"2\" stroke-dasharray=\"4 3\"></line><text x=\"650\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">energia cai</text><text x=\"20\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">só snapshots</text><rect x=\"170\" y=\"75\" width=\"130\" height=\"20\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"300\" y=\"75\" width=\"340\" height=\"20\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"640\" y=\"109\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">perde: tudo desde o snapshot</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">everysec</text><rect x=\"170\" y=\"130\" width=\"440\" height=\"20\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"610\" y=\"130\" width=\"30\" height=\"20\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"640\" y=\"164\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">perde: cerca de um segundo</text><text x=\"20\" y=\"195\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">always</text><rect x=\"170\" y=\"185\" width=\"470\" height=\"20\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"640\" y=\"219\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">perde: nada confirmado</text><text x=\"300\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">último snapshot</text><line x1=\"300\" y1=\"70\" x2=\"300\" y2=\"95\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line></svg>", "caption": "O que cada configuração perde quando a própria máquina perde energia. Um processo morto perde menos, porque o sistema operacional ainda grava o que recebeu."}
```

## Quanto custa o `always`

O `always` parece a escolha óbvia até ser medido. O `redis-benchmark` vem na imagem; `-t set` roda só
`SET`, `-n` é o número de requisições e `-c` o número de clientes mandando ao mesmo tempo, 50 se você
não disser outro. O contêiner `aof` da seção anterior, primeiro com `everysec`:

```
ana@vm:~$ docker exec redis redis-cli CONFIG SET appendfsync everysec
OK
ana@vm:~$ docker exec redis redis-benchmark -t set -n 100000 --csv
"test","rps","avg_latency_ms","min_latency_ms","p50_latency_ms","p95_latency_ms","p99_latency_ms","max_latency_ms"
"SET","87950.75","0.354","0.064","0.295","0.767","1.167","3.447"
ana@vm:~$ docker exec redis redis-benchmark -t set -n 20000 -c 1 --csv
"test","rps","avg_latency_ms","min_latency_ms","p50_latency_ms","p95_latency_ms","p99_latency_ms","max_latency_ms"
"SET","32733.22","0.028","0.008","0.023","0.071","0.103","1.567"
```

E com `always`:

```
ana@vm:~$ docker exec redis redis-cli CONFIG SET appendfsync always
OK
ana@vm:~$ docker exec redis redis-benchmark -t set -n 100000 --csv
"test","rps","avg_latency_ms","min_latency_ms","p50_latency_ms","p95_latency_ms","p99_latency_ms","max_latency_ms"
"SET","38124.29","1.201","0.256","1.087","2.063","3.583","16.751"
ana@vm:~$ docker exec redis redis-benchmark -t set -n 20000 -c 1 --csv
"test","rps","avg_latency_ms","min_latency_ms","p50_latency_ms","p95_latency_ms","p99_latency_ms","max_latency_ms"
"SET","2686.37","0.364","0.168","0.319","0.655","1.375","8.143"
```

No laboratório, com 50 clientes, **o `always` atendeu `38124.29` escritas por segundo contra `87950.75`**.
Com um cliente, o caso de um programa que espera cada resposta antes de mandar a próxima, caiu de
`32733.22` para `2686.37`, porque cada escrita agora espera o disco. Com 50 clientes a perda é menor porque o
Redis descarrega uma vez para todas as escritas que chegaram juntas.

Esses números são desta máquina nesta execução, uma máquina virtual com quatro processadores num disco
virtual, dividida com outros trabalhos. Os seus vão ser outros, e dependem acima de tudo de quanto o seu
disco leva para completar um descarregamento, que num SSD de notebook, num volume de nuvem e num disco
rígido diferem em ordens de grandeza. **Rode as mesmas quatro linhas na máquina que vai servir a
produção** antes de decidir. A proporção é o achado, não os números.

## Escolhendo

O `everysec` é o padrão porque é o meio-termo barato: a queda de um processo não perde nada e a falta
de energia perde cerca de um segundo. Para a loja, esse segundo só importa para dados cuja perda é um
incidente e que não estão em mais lugar nenhum, e eles são poucos: as chaves de idempotência da aula
12, talvez um contador de estoque. A aula 15 acrescenta a outra metade da resposta, uma cópia em outra
máquina, e mostra que essa cópia tem uma janela própria.
