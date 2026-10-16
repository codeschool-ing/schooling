---
title: O modelo do Kafka, nas palavras da lição 20
version: 1
---

**O Apache Kafka e o Kinesis Data Streams resolvem o mesmo problema com o mesmo formato**: um log
ordenado, dividido em pedaços que têm ordem cada um por conta própria, guardado por um tempo e lido por
quantos leitores quiserem. O MSK é a AWS rodando o Kafka para você, então o modelo a aprender é o do
Kafka. As palavras mudam, e algumas das diferenças são reais, não de vocabulário:

| Kinesis, lição 20 | Kafka | o que é diferente |
|---|---|---|
| stream | **tópico** (*topic*) | nada que importe |
| shard | **partição** (*partition*) | uma partição mora num broker que você sabe nomear, um shard em máquinas que você nunca vê |
| número de sequência | **offset** | um offset é um inteiro simples a partir de 0, contado por partição |
| chave de partição | **chave** (*key*) | a chave passa por murmur2 módulo o número de partições, não por MD5 em faixas |
| iterador e checkpoint | **offset confirmado de um grupo de consumidores** | quem guarda a posição é o broker, não o seu programa |
| retenção, de 24 horas a 365 dias | **retenção por tempo, por tamanho, ou os dois**, ou para sempre, ou **compactação** | o Kafka pode guardar o registro mais recente de cada chave e nada mais velho |

**O grupo de consumidores é a ideia que o Kinesis não traz embutida.** Um grupo (*consumer group*) é
um nome, `fraud` ou `lake-copy`, compartilhado por um ou mais processos consumidores. O Kafka entrega
cada partição do tópico a exatamente um membro do grupo, e quando um membro entra ou morre ele move
partições entre os membros que sobraram; isso é um **rebalanceamento** (*rebalance*). Cada grupo guarda
o próprio offset confirmado por partição, no broker, então dois grupos leem o mesmo tópico de forma
independente, e um grupo que reinicia continua de onde confirmou. No Kinesis essa contabilidade é da
Kinesis Client Library, que guarda os leases e os checkpoints numa tabela do DynamoDB sua.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O tópico orders com três partições, lido por dois grupos de consumidores. O grupo fraud tem dois membros: o primeiro recebe as partições 0 e 1, o segundo a partição 2, e cada partição vai para exatamente um membro. O grupo lake-copy tem um membro, que recebe as três partições. Cada grupo guarda no broker o próprio offset confirmado por partição, então os dois leem os mesmos registros de forma independente.\" data-fig=\"l22-groups\"><text x=\"20.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">tópico</text><text x=\"70.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders</text><rect x=\"205.0\" y=\"105.0\" width=\"90.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">partição 0</text><rect x=\"315.0\" y=\"105.0\" width=\"90.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">partição 1</text><rect x=\"425.0\" y=\"105.0\" width=\"90.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">partição 2</text><rect x=\"190.0\" y=\"95.0\" width=\"340.0\" height=\"56.0\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"20.0\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">grupo</text><text x=\"62.0\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">fraud</text><rect x=\"180.0\" y=\"30.0\" width=\"100.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"230.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">membro 1</text><rect x=\"420.0\" y=\"30.0\" width=\"100.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">membro 2</text><line x1=\"250.0\" y1=\"105.0\" x2=\"230.0\" y2=\"60.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></line><line x1=\"360.0\" y1=\"105.0\" x2=\"230.0\" y2=\"60.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></line><line x1=\"470.0\" y1=\"105.0\" x2=\"470.0\" y2=\"60.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></line><text x=\"20.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">grupo</text><text x=\"62.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">lake-copy</text><rect x=\"310.0\" y=\"195.0\" width=\"100.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">membro 1</text><line x1=\"250.0\" y1=\"141.0\" x2=\"360.0\" y2=\"195.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></line><line x1=\"360.0\" y1=\"141.0\" x2=\"360.0\" y2=\"195.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></line><line x1=\"470.0\" y1=\"141.0\" x2=\"360.0\" y2=\"195.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></line><text x=\"560.0\" y=\"45.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">offsets de fraud: um por partição</text><text x=\"560.0\" y=\"210.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">offsets de lake-copy: os seus</text></svg>", "caption": "Dentro de um grupo cada partição tem um leitor; entre grupos, todo grupo lê tudo."}
```

**A ordem é por partição, exatamente como é por shard**, e segue a mesma consequência: o que tem ordem
na prática são os registros de cada chave. Duas diferenças deixam a versão do Kafka menos tolerante. A
partição é `murmur2(key) mod N`, então **acrescentar partições a um tópico muda chaves de lugar**: uma
chave que ia para a partição 1 de 3 pode ir para a partição 3 de 4, e os registros novos dela podem ser
lidos antes dos antigos. O reshard do Kinesis mantém uma chave dentro da faixa de hash do pai e
registra a linhagem, que foi o que deixou o consumidor da lição 20 terminar o pai primeiro. E as
partições de um tópico podem ser acrescentadas e nunca removidas.

**A retenção pode ser um tamanho além de um tempo.** `retention.ms` guarda os registros por um
período, `retention.bytes` limita o log de cada partição a um tamanho, e o que for atingido primeiro
apaga o **segmento** mais antigo, um arquivo do log, inteiro. Com `cleanup.policy=compact` o Kafka
guarda, em vez disso, pelo menos o registro mais recente de cada chave, o que transforma um tópico numa
tabela: o endereço atual de cada cliente, por exemplo, guardado enquanto o tópico existir. O Kinesis
não tem equivalente; os registros dele expiram só por idade.

A próxima seção roda um broker na sua própria máquina e faz tudo isso de verdade. O MSK não muda nada
disso: um cluster MSK são brokers Kafka, e os mesmos comandos funcionam contra eles.
