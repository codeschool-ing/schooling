---
title: Rebalanceamento, de três jeitos
version: 1
---

**Um rebalanceamento é o grupo distribuindo de novo as suas partições, e ele acontece toda vez que um
membro entra ou sai.** Iniciar uma cópia, parar uma, uma cópia cair, uma cópia lenta demais para chamar
`poll`: cada coisa dessas muda os membros, e as partições são redistribuídas. Enquanto uma partição
está sendo movida, nenhum membro a lê. Quanto isso dura, e quantas partições param enquanto acontece,
depende do protocolo.

Para ver só as atribuições, sem vendas passando na tela, use um tópico vazio:

```sh
kafka-topics.sh --bootstrap-server localhost:9092 --create --topic quiet --partitions 3
```

Em cada um dos três experimentos abaixo, inicie o `a`, depois o `b` alguns segundos mais tarde,
depois pare o `b` com Ctrl+C, espere alguns segundos e pare o `a`.

## Eager: todo mundo devolve tudo

O **protocolo classic** com a estratégia `range`, o arranjo mais antigo, é chamado de **eager**: a
cada rebalanceamento todo membro abre mão de todas as suas partições, e depois recebe um conjunto
novo.

```
ubuntu@stream:~/work$ python consumer.py a --group eager --topic quiet --strategy range
a: assigned [0, 1, 2]
a: revoked [0, 1, 2]
a: assigned [0, 1]
a: revoked [0, 1]
a: assigned [0, 1, 2]
a: revoked [0, 1, 2]
```

```
ubuntu@stream:~/work$ python consumer.py b --group eager --topic quiet --strategy range
b: assigned [2]
b: revoked [2]
```

Quando o `b` entrou, o `a` devolveu as três partições e recebeu de volta a 0 e a 1; o `b` recebeu a 2.
Quando o `b` saiu, o `a` devolveu a 0 e a 1 e recebeu as três. **As partições 0 e 1 nunca precisaram
mudar de dono, e pararam mesmo assim**, duas vezes. Com três partições isso custa um instante; com
duzentas partições e cinquenta membros, todo membro parando a cada entrada é uma pausa que o grupo
inteiro sente, e um deploy que reinicia os membros um a um causa uma pausa por membro.

## Cooperativo: só para o que muda

O mesmo protocolo classic com a estratégia `cooperative-sticky` é **incremental**: um membro só abre
mão das partições que vão para outro, e continua lendo o resto.

```
ubuntu@stream:~/work$ python consumer.py a --group coop --topic quiet --strategy cooperative-sticky
a: assigned [0, 1, 2]
a: revoked [0]
a: assigned []
a: assigned []
a: assigned [0]
a: revoked [0, 1, 2]
```

```
ubuntu@stream:~/work$ python consumer.py b --group coop --topic quiet --strategy cooperative-sticky
b: assigned []
b: assigned [0]
b: revoked [0]
```

Quando o `b` entrou, o `a` abriu mão só da partição 0 e ficou com a 1 e a 2 o tempo todo. Num protocolo
incremental os callbacks informam mudanças em vez do conjunto inteiro: `assigned []` quer dizer "nada
de novo para você nesta rodada", e o primeiro `assigned []` do `b` é a rodada em que a partição 0 foi
liberada pelo `a` antes de poder ser repassada. Quando o `b` saiu, o `a` recebeu a 0 de volta, e o
`revoked` final dele lista as três porque ele estava encerrando.

## O protocolo consumer: o broker decide

O Kafka 4 traz um protocolo novo, do KIP-848, aquele que o console consumer da lição 1 vivia
mencionando. No protocolo classic os membros negociam a atribuição entre si, por meio de um deles
escolhido como líder, e cada mudança é uma rodada de entrar e sincronizar. No **protocolo consumer** o
coordenador de grupos do broker calcula a atribuição e diz a cada membro o que acrescentar e o que
largar, membro a membro, sem uma rodada que todos precisem terminar. O cliente Python o suporta com
`group.protocol=consumer`:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group new --members

GROUP           CONSUMER-ID            HOST            CLIENT-ID       #PARTITIONS     
new             G2evwjPYQXq2Gm+sayNIXA /127.0.0.1      rdkafka         1               
new             IugrKrUnSoaj4KhHbSVW5A /127.0.0.1      rdkafka         2               
```

Isso foi com o `a` e o `b` rodando. Os ids dos membros têm outra forma, porque quem os emite é o
coordenador, e as partições estão divididas em duas e uma, como antes:

```
ubuntu@stream:~/work$ python consumer.py a --group new --topic quiet --protocol consumer
a: assigned [0, 1, 2]
a: revoked [2]
a: assigned []
a: assigned [2]
a: revoked [0, 1, 2]
```

```
ubuntu@stream:~/work$ python consumer.py b --group new --topic quiet --protocol consumer
b: assigned [2]
b: revoked [2]
```

O `a` abriu mão só da partição 2, o `b` a pegou, e quando o `b` saiu, o `a` a recebeu de volta. O mesmo
comportamento incremental do cooperative-sticky, decidido num lugar só. Com o protocolo consumer a
configuração `partition.assignment.strategy` nem se aplica, e é por isso que o `consumer.py` só a
configura no `classic`.

| | quem calcula a atribuição | o que para durante uma mudança |
|---|---|---|
| classic, `range` (eager) | o membro líder do grupo | toda partição de todo membro |
| classic, `cooperative-sticky` | o membro líder do grupo | só as partições que mudam de dono |
| consumer (KIP-848) | o coordenador de grupos do broker | só as partições que mudam de dono |

**Para uma aplicação nova no Kafka 4, o protocolo consumer é o que escolher**, desde que toda
biblioteca cliente do grupo o suporte. O librdkafka 2.16, por baixo do cliente Python usado aqui,
suporta, como a execução acima mostra.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Duas linhas do tempo do membro a enquanto o membro b entra. Eager: a tem as partições 0, 1 e 2, devolve as três quando b entra, e depois volta a ter 0 e 1, então toda partição para de ser lida por um momento. Incremental, como no cooperative-sticky e no protocolo consumer: a mantém 1 e 2 o tempo todo e só abre mão da partição 0, que vai para b; só a partição 0 para.\" data-fig=\"l4-rebalance\"><line x1=\"330\" y1=\"30\" x2=\"330\" y2=\"215\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"330\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">b entra</text><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">eager</text><text x=\"130\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a tem</text><rect x=\"120\" y=\"60\" width=\"190\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">0, 1, 2</text><rect x=\"310\" y=\"60\" width=\"50\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></rect><text x=\"335\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">nada é lido</text><rect x=\"360\" y=\"60\" width=\"330\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">0, 1</text><rect x=\"360\" y=\"105\" width=\"330\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><text x=\"700\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">b</text><text x=\"20\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">incremental</text><rect x=\"120\" y=\"155\" width=\"570\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"405.0\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">1, 2</text><rect x=\"120\" y=\"185\" width=\"190\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">0</text><rect x=\"310\" y=\"185\" width=\"50\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></rect><rect x=\"360\" y=\"185\" width=\"330\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"700\" y=\"197\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">b</text><text x=\"700\" y=\"167\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">a</text><text x=\"700\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">a</text></svg>", "caption": "Um rebalanceamento eager para todas as partições; um incremental para só as que mudam de dono.", "same": ["eager", "incremental"]}
```
