---
title: acks, e quantas cópias vale um "sim"
version: 1
---

**`acks` é a escolha do produtor sobre quando o líder pode responder: antes de gravar, depois de
gravar no próprio log, ou depois que toda réplica da ISR tem o registro.** Ela é definida por
produtor, não por tópico, e decide quanto vale o "entregue" de um produtor quando um nó morre um
instante depois.

| `acks` | o produtor recebe o sim quando… | perdido se o líder morre logo depois |
|---|---|---|
| `0` | a requisição saiu do produtor; ninguém responde | qualquer coisa, e o produtor nunca fica sabendo |
| `1` | o líder gravou no próprio log | o que os seguidores ainda não tinham buscado |
| `all` | toda réplica da ISR o tem | nada que tenha sido confirmado |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Uma sequência no tempo, de cima para baixo, entre um produtor, o líder no nó 1 e dois seguidores. Com acks=0 o produtor dá a mensagem por enviada no instante em que ela sai. O líder a grava no log e, com acks=1, responde na hora. Os seguidores a buscam, e no fetch seguinte o líder fica sabendo que os dois a têm, move o high watermark e só então responde a um produtor que pediu acks=all.\" data-fig=\"l5-acks\"><defs><marker id=\"l5-acks-ah-726\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l5-acks-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l5-acks-ah-2105\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l5-acks-ah-0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker></defs><rect x=\"178\" y=\"14\" width=\"104\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"230\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">produtor</text><line x1=\"230\" y1=\"40\" x2=\"230\" y2=\"305\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><rect x=\"348\" y=\"14\" width=\"104\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"400\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">nó 1 · líder</text><line x1=\"400\" y1=\"40\" x2=\"400\" y2=\"305\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><rect x=\"488\" y=\"14\" width=\"104\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">nó 2</text><line x1=\"540\" y1=\"40\" x2=\"540\" y2=\"305\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><rect x=\"608\" y=\"14\" width=\"104\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"660\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">nó 3</text><line x1=\"660\" y1=\"40\" x2=\"660\" y2=\"305\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"230\" y1=\"62\" x2=\"398\" y2=\"82\" stroke=\"var(--paper)\" stroke-width=\"1.2\" marker-end=\"url(#l5-acks-ah-726)\"></line><text x=\"315.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">produce</text><circle cx=\"230\" cy=\"62\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"218\" y=\"62\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">acks=0: dada por enviada</text><rect x=\"352\" y=\"84\" width=\"96\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"400\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">gravada no log</text><line x1=\"398\" y1=\"110\" x2=\"232\" y2=\"130\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l5-acks-ah-0)\"></line><circle cx=\"230\" cy=\"130\" r=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"218\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor-dim)\">acks=1: respondida</text><line x1=\"538\" y1=\"150\" x2=\"402\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#l5-acks-ah-8343)\"></line><line x1=\"402\" y1=\"164\" x2=\"538\" y2=\"172\" stroke=\"var(--paper)\" stroke-width=\"1\" marker-end=\"url(#l5-acks-ah-726)\"></line><line x1=\"658\" y1=\"160\" x2=\"402\" y2=\"160\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#l5-acks-ah-8343)\"></line><line x1=\"402\" y1=\"174\" x2=\"658\" y2=\"182\" stroke=\"var(--paper)\" stroke-width=\"1\" marker-end=\"url(#l5-acks-ah-726)\"></line><text x=\"470.0\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">fetch</text><text x=\"610.0\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o registro</text><text x=\"540\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">copiada</text><text x=\"660\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">copiada</text><line x1=\"538\" y1=\"236\" x2=\"402\" y2=\"236\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#l5-acks-ah-8343)\"></line><line x1=\"658\" y1=\"244\" x2=\"402\" y2=\"244\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#l5-acks-ah-8343)\"></line><text x=\"478.0\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">fetch seguinte</text><rect x=\"338\" y=\"254\" width=\"124\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"400\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">high watermark avança</text><line x1=\"398\" y1=\"282\" x2=\"232\" y2=\"298\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" marker-end=\"url(#l5-acks-ah-2105)\"></line><circle cx=\"230\" cy=\"298\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"218\" y=\"298\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">acks=all: respondida</text></svg>", "caption": "Os três valores de acks são três momentos da mesma troca: quanto mais tarde a resposta, mais cópias estão por trás dela."}
```

**`acks=all` é o padrão do produtor**, no cliente Java desde o Kafka 3.0 e na librdkafka há mais
tempo, então um produtor que não define nada já está na ponta segura. Os outros dois existem para
dados em que velocidade importa mais que cada registro, como métricas amostradas a cada segundo.

## A outra metade: min.insync.replicas

`acks=all` espera pela ISR, e a ISR pode encolher. Com fator de replicação 3 e dois nós fora do ar,
a ISR é só o líder, e `acks=all` passa a querer dizer *o líder tem*, que é `acks=1` com um nome
melhor. **`min.insync.replicas` é o piso**: a menor ISR com que o líder aceita uma escrita
`acks=all`. Abaixo dela, o líder recusa a escrita com `NotEnoughReplicas` em vez de aceitá-la com
cópias de menos.

A configuração usual em produção é a com que este tópico foi criado: **fator de replicação 3 e
`min.insync.replicas=2`**. Um nó pode ser perdido, por falha ou manutenção, e as escritas
continuam; todo registro confirmado está em pelo menos dois discos.

## Medindo

Este programa manda vendas com um `acks` escolhido e conta as respostas: entregue, ou o nome do
erro. Ele dá ao cliente os endereços dos três nós, para que comece por qualquer um que esteja no
ar. Também define `message.timeout.ms` em trinta segundos, o tempo que o cliente passa tentando de
novo uma venda antes de desistir e informá-la como falha; o padrão é cinco minutos. Salve como
`~/work/acks.py`:

```python
"""acks.py: send sales with a chosen acks, and count what the cluster answered.

    python acks.py --acks all|1|0 [--count N] [--rate R] [--topic T] [--key K]
"""
import argparse
import collections
import json
import time

from confluent_kafka import Producer

args = argparse.ArgumentParser()
args.add_argument("--acks", default="all", choices=["0", "1", "all"])
args.add_argument("--count", type=int, default=10)
args.add_argument("--rate", type=float, default=0)
args.add_argument("--topic", default="sales")
args.add_argument("--key", default="recife")
args = args.parse_args()

producer = Producer({
    "bootstrap.servers": "localhost:9092,localhost:9093,localhost:9094",
    "acks": args.acks,
    "message.timeout.ms": 30000,
})
answers = collections.Counter()
offsets = collections.defaultdict(list)

def report(err, msg):
    if err is None:
        answers["delivered"] += 1
        offsets[msg.partition()].append(msg.offset())
    else:
        answers[err.name()] += 1

for n in range(1, args.count + 1):
    sale = {"sale": f"ack-{n:06d}", "shop": args.key, "book": "bk-01", "qty": 1, "cents": 3990}
    producer.produce(args.topic, key=args.key, value=json.dumps(sale), on_delivery=report)
    producer.poll(0)
    if args.rate:
        time.sleep(1 / args.rate)
producer.flush()

print(f"acks={args.acks}:", ", ".join(f"{v} {k}" for k, v in answers.items()))
if args.acks != "0":
    for p, o in sorted(offsets.items()):
        print(f"partition {p}: offsets {min(o)} to {max(o)}")
```

Os três valores funcionam enquanto os três nós estão no ar. Com `acks=0` não há resposta, então não
há offset, e "entregue" só quer dizer "enviado":

```
ubuntu@stream:~/work$ python acks.py --acks 0
acks=0: 10 delivered
ubuntu@stream:~/work$ python acks.py --acks 1
acks=1: 10 delivered
partition 1: offsets 249 to 258
ubuntu@stream:~/work$ python acks.py --acks all
acks=all: 10 delivered
partition 1: offsets 259 to 268
```

Toda venda vai para a mesma partição, porque todas têm a chave `recife`. Agora pare um nó. Com duas
réplicas na ISR, `min.insync.replicas=2` continua atendido:

```
ubuntu@stream:~/work$ ./cluster.sh kill 3
node 3: killed
ubuntu@stream:~/work$ sleep 15; kafka-topics.sh --bootstrap-server localhost:9092,localhost:9093 --describe --topic sales
Topic: sales	TopicId: hBMADyrPSHqe-J4ZJkPq1A	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: sales	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1,2	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 1	Leader: 2	Replicas: 2,3,1	Isr: 1,2	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 2	Leader: 1	Replicas: 3,1,2	Isr: 1,2	Elr: 	LastKnownElr: 
ubuntu@stream:~/work$ python acks.py --acks all
acks=all: 10 delivered
partition 1: offsets 269 to 278
```

A ISR de toda partição caiu para os nós 1 e 2, duas réplicas, e `min.insync.replicas` pede duas:
dez vendas entregues com `acks=all`, nos offsets 269 a 278 da partição 1.

## Abaixo do piso

Perder um segundo nó deste cluster também levaria a maioria dos seus controllers, o que é outra
falha e assunto da seção depois da próxima. Então, para ver a recusa, suba o piso: com
`min.insync.replicas=3`, uma ISR de dois fica um abaixo.

```
ubuntu@stream:~/work$ kafka-configs.sh --bootstrap-server localhost:9092 --alter --entity-type topics --entity-name sales --add-config min.insync.replicas=3
Completed updating config for topic sales.
ubuntu@stream:~/work$ python acks.py --acks all
acks=all: 10 _MSG_TIMED_OUT
ubuntu@stream:~/work$ grep -h -m1 NotEnoughReplicasException ~/kafka-data/node*/logs/server.log
org.apache.kafka.common.errors.NotEnoughReplicasException: The size of the current ISR : 2 is insufficient to satisfy the min.isr requirement of 3 for partition sales-1, live replica(s) broker.id are : Set(1, 2)
ubuntu@stream:~/work$ python acks.py --acks 1
%3|1791683959.237|FAIL|rdkafka#producer-1| [thrd:localhost:9094/bootstrap]: localhost:9094/bootstrap: Connect to ipv4#127.0.0.1:9094 failed: Connection refused (after 0ms in state CONNECT)
acks=1: 10 delivered
partition 1: offsets 279 to 288
```

**Dez vendas, dez `_MSG_TIMED_OUT`.** O líder recusou cada escrita, o cliente tratou a recusa como
algo que podia passar e tentou de novo, e depois dos trinta segundos de `message.timeout.ms`
desistiu e informou as vendas como falhas. O nome que o cliente dá à falha é o do próprio timeout;
o motivo do líder está no log dele, e o `grep` o encontra: `NotEnoughReplicasException`, uma ISR de
2 contra uma exigência de 3. **Nada foi gravado**: a execução com `acks=1` logo depois começa no
offset 279, o seguinte à última venda entregue antes. É esse o sentido do piso: um produtor que
pediu todas as cópias ouve um não em vez de receber menos cópias do que pediu.

A mesma partição, no mesmo momento, com `acks=1`: entregue. O líder respondeu assim que as vendas
estavam no próprio disco, e teria feito o mesmo sem seguidor nenhum. A linha `%3|…|FAIL` acima é o
cliente informando que tentou o nó 3, o terceiro endereço que recebeu, e não achou ninguém; é uma
linha de log, não uma venda que falhou.

Ponha o tópico de volta como estava, e traga o nó 3 de volta:

```
ubuntu@stream:~/work$ kafka-configs.sh --bootstrap-server localhost:9092 --alter --entity-type topics --entity-name sales --add-config min.insync.replicas=2
Completed updating config for topic sales.
ubuntu@stream:~/work$ ./cluster.sh start 3
node 3: up on localhost:9094
```
