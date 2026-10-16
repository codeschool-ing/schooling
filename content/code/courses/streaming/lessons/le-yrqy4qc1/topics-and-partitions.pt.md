---
title: Um tópico é um nome para vários logs
version: 1
---

**Um tópico não é um log. É um nome para um conjunto de logs, chamados partições, e cada partição é
um log exatamente como o que a lição 2 construiu**: registros anexados numa ponta, numerados a partir
de 0, lidos sem ser removidos. O tópico `sales` da lição 1 tem três partições, então são três logs,
cada um com o seu offset 0, o seu offset 1 e assim por diante. "O offset 5 de `sales`" não quer dizer
nada até você dizer de qual partição.

A imagem errada de costume é uma fila única de mensagens, com as partições como algum detalhe interno
de armazenamento. Elas não são detalhe. **A partição é a unidade que o Kafka mantém em ordem, a
unidade que ele espalha pelas máquinas, e a unidade que um consumidor lê.** Quase todo comportamento
desta lição e da próxima é uma propriedade de uma partição, e o tópico é só a etiqueta do grupo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um tópico chamado sales desenhado como uma caixa com três partições. Cada partição é uma fileira de registros numerados a partir do offset 0, e as fileiras têm comprimentos diferentes: a partição 0 tem sete registros, a partição 1 tem onze, a partição 2 tem quatro. Um produtor à esquerda faz o hash da chave de cada mensagem para escolher uma partição; registros novos são anexados na ponta direita da sua fileira.\" data-fig=\"l3-topic\"><defs><marker id=\"l3-topic-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"105\" width=\"80\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">produtor</text><text x=\"60\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">hash(chave) % 3</text><rect x=\"160\" y=\"30\" width=\"545\" height=\"200\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"175\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">tópico sales</text><path d=\"M 100 122 L 228 88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l3-topic-ah-8343)\"></path><text x=\"195\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partição 0</text><rect x=\"235\" y=\"75\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"252\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">0</text><rect x=\"273\" y=\"75\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"290\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">1</text><rect x=\"311\" y=\"75\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"328\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">2</text><rect x=\"349\" y=\"75\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"366\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">3</text><rect x=\"387\" y=\"75\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"404\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">4</text><rect x=\"425\" y=\"75\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"442\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">5</text><rect x=\"463\" y=\"75\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"480\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">6</text><rect x=\"501\" y=\"75\" width=\"34\" height=\"26\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><path d=\"M 100 122 L 228 143\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l3-topic-ah-8343)\"></path><text x=\"195\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partição 1</text><rect x=\"235\" y=\"130\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"252\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">0</text><rect x=\"273\" y=\"130\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"290\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">1</text><rect x=\"311\" y=\"130\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"328\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">2</text><rect x=\"349\" y=\"130\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"366\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">3</text><rect x=\"387\" y=\"130\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"404\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">4</text><rect x=\"425\" y=\"130\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"442\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">5</text><rect x=\"463\" y=\"130\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"480\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">6</text><rect x=\"501\" y=\"130\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"518\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">7</text><rect x=\"539\" y=\"130\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"556\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">8</text><rect x=\"577\" y=\"130\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"594\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">9</text><rect x=\"615\" y=\"130\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"632\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">10</text><rect x=\"653\" y=\"130\" width=\"34\" height=\"26\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><path d=\"M 100 122 L 228 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l3-topic-ah-8343)\"></path><text x=\"195\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partição 2</text><rect x=\"235\" y=\"185\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"252\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">0</text><rect x=\"273\" y=\"185\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"290\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">1</text><rect x=\"311\" y=\"185\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"328\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">2</text><rect x=\"349\" y=\"185\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"366\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">3</text><rect x=\"387\" y=\"185\" width=\"34\" height=\"26\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"620\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">registros novos aqui</text></svg>", "caption": "Um tópico, três logs. Cada partição tem seus próprios offsets, e nada ordena uma partição em relação a outra."}
```

## Criando um e olhando para ele

Comece de um cluster vazio de um nó: pare o que você tem, crie um novo e inicie.

```
ubuntu@stream:~/work$ ./cluster.sh stop
node 1: stopped
ubuntu@stream:~/work$ ./cluster.sh new 1
new: 1 node(s), cluster id mAc1snoQSM-zbCZ_Bkb0QA
ubuntu@stream:~/work$ ./cluster.sh start
node 1: up on localhost:9092
```

O `new` apaga tudo o que o cluster guardava, inclusive as cinco vendas da lição 1, e é isso que você
quer aqui: todo número abaixo começa do zero.

Agora crie `sales` de novo, com três partições, e peça ao Kafka para descrevê-lo:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3
Created topic sales.
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic sales
Topic: sales	TopicId: RSujK3biS5ihRVB5huS3Kw	PartitionCount: 3	ReplicationFactor: 1	Configs: min.insync.replicas=1
	Topic: sales	Partition: 0	Leader: 1	Replicas: 1	Isr: 1	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 1	Leader: 1	Replicas: 1	Isr: 1	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 2	Leader: 1	Replicas: 1	Isr: 1	Elr: 	LastKnownElr: 
```

A primeira linha da descrição é sobre o tópico. Ela traz um id que o Kafka deu a ele, que é como o
cluster o conhece (o nome pode ser reutilizado depois de um delete; o id não). Depois, o número de
partições, e o **fator de replicação**, o número de cópias de cada partição. Ele é 1 aqui porque só há um nó para
guardar cópias. Depois, uma linha por partição, numeradas a partir de 0:

- **`Leader`** é o nó que guarda a partição e recebe as escritas e as leituras dela. O nó 1, para as
  três, porque o nó 1 é tudo o que existe.
- **`Replicas`** lista todo nó com uma cópia, e **`Isr`** os que têm a cópia em dia.
- **`Elr`** e **`LastKnownElr`** estão vazios, e continuam vazios até a lição 5 ter três nós e
  derrubar alguns.

Com um nó, as quatro últimas colunas dizem a mesma coisa três vezes. **Elas começam a diferir na lição
5**, em que uma partição tem três cópias em três nós e perder uma é algo a acompanhar.

## Por que três, e não uma

Uma partição é lida em ordem por um leitor de cada vez dentro de um grupo, e escrita pelo seu líder
num nó. Isso tem duas consequências, e elas puxam para lados opostos:

- **A ordem só vale dentro de uma partição.** Duas vendas em duas partições não têm ordem nenhuma
  entre si, digam o que disserem os offsets. A lição 2 defendeu que ordem por chave basta; a próxima
  seção mostra como o Kafka manda cada chave para uma partição, e é isso que faz bastar.
- **O paralelismo para no número de partições.** Três partições podem ser lidas por três cópias de
  um programa ao mesmo tempo, cada uma pegando uma; uma quarta cópia não tem o que ler. A lição 4 roda
  exatamente isso. Num cluster de vários nós, as três partições também podem morar em três máquinas
  diferentes, que é o que a lição 5 faz.

Então o número de partições é uma decisão com custo dos dois lados, e a última seção desta lição é
sobre tomá-la.
