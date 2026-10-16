---
title: Replicação, e as réplicas em sincronia
version: 1
---

**Um shard do Kinesis é replicado pela AWS e você nunca vê as cópias; as cópias de uma partição do
Kafka fazem parte da configuração dela.** Cada partição tem um **fator de replicação**, o número de
brokers que guardam uma cópia dela. Uma dessas cópias é a **líder**, que recebe toda escrita e, por
padrão, toda leitura; as outras são **seguidoras**, que buscam da líder e ficam o mais perto possível
atrás dela. As seguidoras que estão perto o bastante são as **réplicas em sincronia**, o ISR, e são as
únicas que podem virar líder quando o broker da líder morre.

O broker único da seção anterior mostra o vocabulário e não o comportamento. O `--describe` do tópico
disse `Leader: 1  Replicas: 1  Isr: 1` para toda partição: o broker 1 guarda a única cópia, lidera, e
está em sincronia consigo mesmo. Pedir três cópias num broker só falha, com o motivo na mensagem:

```
ana@laptop:~/aws/kafka_2.13-4.4.0$ bin/kafka-topics.sh --bootstrap-server localhost:9092 --create --topic orders-rf3 --partitions 3 --replication-factor 3
Error while executing topic command : Unable to replicate the partition 3 time(s): The target replication factor of 3 cannot be reached because only 1 broker(s) are registered or some brokers have all their log directories cordoned.
[2026-10-16 13:27:54,168] ERROR org.apache.kafka.common.errors.InvalidReplicationFactorException: Unable to replicate the partition 3 time(s): The target replication factor of 3 cannot be reached because only 1 broker(s) are registered or some brokers have all their log directories cordoned.
 (org.apache.kafka.tools.TopicCommand)
```

**No MSK os brokers ficam espalhados por zonas de disponibilidade, e as cópias também.** Um cluster de
três brokers em três zonas, com fator de replicação 3, guarda cada partição uma vez em cada zona, com
os líderes espalhados para que cada broker lidere um terço delas:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Três brokers, um em cada uma de três zonas de disponibilidade, guardando um tópico de três partições com fator de replicação 3. Todo broker guarda uma cópia de toda partição. O broker 1 lidera a partição 0, o broker 2 a partição 1 e o broker 3 a partição 2; as outras duas cópias de cada partição são seguidoras que buscam do líder dela. Perder uma zona deixa duas cópias de toda partição.\" data-fig=\"l22-replicas\"><rect x=\"30.0\" y=\"20.0\" width=\"200.0\" height=\"175.0\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"130.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1a</text><rect x=\"50.0\" y=\"50.0\" width=\"160.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">broker 1</text><rect x=\"65.0\" y=\"82.0\" width=\"130.0\" height=\"24.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">partição 0, líder</text><rect x=\"65.0\" y=\"114.0\" width=\"130.0\" height=\"24.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">partição 1, seguidora</text><rect x=\"65.0\" y=\"146.0\" width=\"130.0\" height=\"24.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">partição 2, seguidora</text><rect x=\"260.0\" y=\"20.0\" width=\"200.0\" height=\"175.0\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1b</text><rect x=\"280.0\" y=\"50.0\" width=\"160.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">broker 2</text><rect x=\"295.0\" y=\"82.0\" width=\"130.0\" height=\"24.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">partição 0, seguidora</text><rect x=\"295.0\" y=\"114.0\" width=\"130.0\" height=\"24.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">partição 1, líder</text><rect x=\"295.0\" y=\"146.0\" width=\"130.0\" height=\"24.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">partição 2, seguidora</text><rect x=\"490.0\" y=\"20.0\" width=\"200.0\" height=\"175.0\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"590.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1c</text><rect x=\"510.0\" y=\"50.0\" width=\"160.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">broker 3</text><rect x=\"525.0\" y=\"82.0\" width=\"130.0\" height=\"24.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">partição 0, seguidora</text><rect x=\"525.0\" y=\"114.0\" width=\"130.0\" height=\"24.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">partição 1, seguidora</text><rect x=\"525.0\" y=\"146.0\" width=\"130.0\" height=\"24.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">partição 2, líder</text><text x=\"360.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma zona perdida: toda partição ainda tem duas cópias</text></svg>", "caption": "Fator de replicação 3 em três zonas: uma cópia de toda partição em toda zona, e os líderes espalhados.", "same": ["broker 1", "broker 2", "broker 3"]}
```

## O que torna uma escrita durável

**Uma escrita é tão segura quanto a configuração que a confirmou.** O `acks` do produtor decide quando
a líder responde: `acks=0` é não esperar nada, `acks=1` é só a líder ter escrito, e `acks=all`, o
padrão desde o Kafka 3.0, é toda réplica em sincronia ter o registro. O `min.insync.replicas` do
tópico, que aparece como `1` no `--describe` acima, decide com quão poucas réplicas em sincronia a
líder passa a recusar escritas em vez de aceitá-las com cópias de menos.

A combinação que não perde nada quando uma zona cai é fator de replicação 3, `min.insync.replicas` 2 e
`acks=all`. Uma escrita só é confirmada quando duas zonas a têm, qualquer zona pode ser perdida, e se
duas forem perdidas a partição para de aceitar escrita em vez de aceitá-la numa cópia só. Com
`min.insync.replicas=1`, o padrão aqui, uma escrita confirmada pode viver num broker só por um
instante, e a falha desse broker nesse instante a perde. **Essa é a durabilidade que o Kinesis dá sem
configuração nenhuma**, e no Kafka é uma decisão que alguém tem de tomar e conferir.

Nada disso foi rodado, porque um broker só não tem seguidoras; vem da documentação do Kafka, e é igual
no MSK, cuja configuração padrão para um cluster em três zonas põe fator de replicação 3 e
`min.insync.replicas` 2. As duas coisas que um broker só mostrou são as duas que vale conferir em
qualquer cluster: o que o `--describe` imprime em `Replicas` e `Isr`, e o valor de
`min.insync.replicas`.

**Replicação também é tráfego, e no MSK ela é de graça.** Todo registro escrito numa partição com fator
de replicação 3 atravessa para outras duas zonas. A AWS não cobra esse tráfego entre os brokers de um cluster MSK. Cobra, ao preço de travessia de zona da lição 1 de `aws-foundations`, um produtor ou um
consumidor numa zona falando com uma líder em outra, e a última seção desta lição põe um número nisso.
