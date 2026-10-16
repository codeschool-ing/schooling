---
title: Fazer commit de um offset, e quando isso acontece
version: 1
---

**Um commit registra, para um grupo e uma partição, o offset que o grupo deve ler em seguida.** É o
lugar do grupo no log, a mesma coisa que os arquivos de lugar do `minilog.py` guardavam na lição 2, e é
a única coisa em que um consumidor que reinicia pode se basear. **O que importa é quando um commit
acontece, em relação ao trabalho**: um commit diz "tudo antes disto está feito", e se
isso não for verdade no momento de uma queda, o reinício repete trabalho ou pula trabalho.

O Kafka guarda os commits num tópico próprio, o `__consumer_offsets`:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic __consumer_offsets | head -1
Topic: __consumer_offsets	TopicId: L73rMdVGSxKa6-xjwL1JZw	PartitionCount: 50	ReplicationFactor: 1	Configs: compression.type=producer,min.insync.replicas=1,cleanup.policy=compact,segment.bytes=104857600
```

Cinquenta partições, e `cleanup.policy=compact`: o commit mais recente de cada grupo para cada
partição é o valor de uma chave, e a compactação da lição 3 guarda só o mais recente. Um commit é uma
mensagem como outra qualquer.

## Commits automáticos

Por padrão o cliente faz o commit por você. **`enable.auto.commit` está ligado, e a cada cinco
segundos** (`auto.commit.interval.ms`) o cliente faz commit dos offsets das mensagens que o `poll` já
devolveu. Cinco segundos são uma janela, e uma queda dentro dela mostra o que a janela significa.
Inicie um consumidor num grupo novo, `auto`, e uns quatro segundos depois mate-o de outro shell, sem
chance de arrumar nada, como faria uma queda de energia: `kill -9 $(pgrep -f 'consumer.py x')`.

```
ubuntu@stream:~/work$ python consumer.py x --group auto
x: assigned [0, 1, 2]
x: partition 2 offset 0 rec-000005
x: partition 2 offset 1 rec-000010
x: partition 2 offset 2 rec-000005
x: partition 2 offset 3 rec-000010
x: partition 1 offset 0 car-000002
x: partition 1 offset 1 nat-000003
x: partition 1 offset 2 car-000007
x: partition 1 offset 3 nat-000008
x: partition 1 offset 4 car-000002
x: partition 1 offset 5 nat-000003
x: partition 1 offset 6 car-000007
x: partition 1 offset 7 nat-000008
x: partition 0 offset 0 oli-000001
x: partition 0 offset 1 joa-000004
x: partition 0 offset 2 oli-000006
x: partition 0 offset 3 joa-000009
x: partition 0 offset 4 oli-000001
x: partition 0 offset 5 joa-000004
x: partition 0 offset 6 oli-000006
x: partition 0 offset 7 joa-000009
Killed
```

O `x` leu as vinte vendas do tópico e as imprimiu, e o shell imprimiu `Killed`. Agora pergunte o que o
grupo commitou:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group auto

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID                                  HOST            CLIENT-ID
auto            sales           0          -               8               -               rdkafka-9cbc0880-3e59-41b7-b81a-a1cebd910f61 /127.0.0.1      rdkafka
auto            sales           1          -               8               -               rdkafka-9cbc0880-3e59-41b7-b81a-a1cebd910f61 /127.0.0.1      rdkafka
auto            sales           2          -               4               -               rdkafka-9cbc0880-3e59-41b7-b81a-a1cebd910f61 /127.0.0.1      rdkafka
```

**`CURRENT-OFFSET` é `-` em todas as partições: nada foi commitado.** O membro ainda aparece, porque o
Kafka ainda não percebeu que ele sumiu; o broker espera a sessão dele expirar, 45 segundos por padrão
(`session.timeout.ms`). Quando um membro novo do `auto` iniciar, não vai achar commit, vai cair no
`auto.offset.reset`, e vai ler as vinte vendas de novo. Se o `x` estivesse somando as vendas num total,
o total agora as contaria duas vezes.

## Fazendo o commit você mesmo

Com `--manual`, o `consumer.py` desliga os commits automáticos e faz commit depois de cada mensagem,
esperando o broker confirmar. Mesmo experimento, grupo `manual`:

```
ubuntu@stream:~/work$ python consumer.py y --group manual --manual
y: assigned [0, 1, 2]
y: partition 2 offset 0 rec-000005
y: partition 2 offset 1 rec-000010
y: partition 2 offset 2 rec-000005
y: partition 2 offset 3 rec-000010
y: partition 1 offset 0 car-000002
y: partition 1 offset 1 nat-000003
y: partition 1 offset 2 car-000007
y: partition 1 offset 3 nat-000008
y: partition 1 offset 4 car-000002
y: partition 1 offset 5 nat-000003
y: partition 1 offset 6 car-000007
y: partition 1 offset 7 nat-000008
y: partition 0 offset 0 oli-000001
y: partition 0 offset 1 joa-000004
y: partition 0 offset 2 oli-000006
y: partition 0 offset 3 joa-000009
y: partition 0 offset 4 oli-000001
y: partition 0 offset 5 joa-000004
y: partition 0 offset 6 oli-000006
y: partition 0 offset 7 joa-000009
Killed
```

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group manual

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID                                  HOST            CLIENT-ID
manual          sales           0          8               8               0               rdkafka-fa239717-d289-4555-9d36-491690cb0ae2 /127.0.0.1      rdkafka
manual          sales           1          8               8               0               rdkafka-fa239717-d289-4555-9d36-491690cb0ae2 /127.0.0.1      rdkafka
manual          sales           2          4               4               0               rdkafka-fa239717-d289-4555-9d36-491690cb0ae2 /127.0.0.1      rdkafka
```

Commitados 8, 8 e 4: tudo o que o `y` imprimiu está registrado, e um reinício não leria nada duas
vezes. Fazer commit depois de cada mensagem custa uma ida e volta ao broker por mensagem, e é por isso
que consumidores de verdade fazem commit depois de um lote. Aí uma queda repete no máximo um lote.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"As mensagens de uma partição nos offsets 0 a 9, lidas por um consumidor que processou os offsets 0 a 6. O último commit diz offset 4. Uma queda agora significa que o reinício lê a partir do 4, então os offsets 4, 5 e 6 são processados duas vezes. Com um commit depois de cada mensagem, o commit diria 7, o próximo offset a ler, e nada se repetiria.\" data-fig=\"l4-commit\"><defs><marker id=\"l4-commit-ah-83\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l4-commit-ah-726\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"60\" y=\"80\" width=\"54\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"87.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">0</text><rect x=\"120\" y=\"80\" width=\"54\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"147.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">1</text><rect x=\"180\" y=\"80\" width=\"54\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"207.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">2</text><rect x=\"240\" y=\"80\" width=\"54\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"267.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">3</text><rect x=\"300\" y=\"80\" width=\"54\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"327.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">4</text><rect x=\"360\" y=\"80\" width=\"54\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"387.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">5</text><rect x=\"420\" y=\"80\" width=\"54\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"447.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">6</text><rect x=\"480\" y=\"80\" width=\"54\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"507.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">7</text><rect x=\"540\" y=\"80\" width=\"54\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"567.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8</text><rect x=\"600\" y=\"80\" width=\"54\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"627.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">9</text><line x1=\"297\" y1=\"40\" x2=\"297\" y2=\"76\" stroke=\"var(--paper)\" stroke-width=\"1.2\" marker-end=\"url(#l4-commit-ah-726)\"></line><text x=\"297\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">último commit</text><line x1=\"477\" y1=\"40\" x2=\"477\" y2=\"76\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#l4-commit-ah-83)\"></line><text x=\"477\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">queda</text><path d=\"M 60 128 L 60 136 L 474 136 L 474 128\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"270.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">processado até aqui</text><path d=\"M 300 165 L 300 173 L 474 173 L 474 165\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"390.0\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">lido de novo depois de reiniciar</text></svg>", "caption": "O que fica entre o último commit e a queda é lido de novo."}
```

Nenhuma das escolhas elimina o problema; cada uma o desloca. Fazer o commit **depois** do trabalho,
como o `--manual` faz, quer dizer que uma queda entre o trabalho e o commit repete aquela mensagem:
**pelo menos uma vez**. Fazer o commit **antes** do trabalho quer dizer que uma queda entre o commit e
o trabalho a perde: **no máximo uma vez**. A lição 7 faz os dois caírem de propósito e conta o
estrago, e a lição 8 torna inofensivo o trabalho repetido, que é a saída de costume.
