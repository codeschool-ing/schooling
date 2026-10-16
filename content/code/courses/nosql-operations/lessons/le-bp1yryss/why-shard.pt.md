---
title: Quando uma máquina deixa de bastar
version: 1
---

Um replica set são três cópias dos mesmos dados, então **ele multiplica segurança, não capacidade**.
Todo membro guarda tudo, e toda escrita cai no único primário. Quando os dados não cabem mais no
disco de uma máquina, ou as escritas não cabem mais nos processadores de uma máquina, acrescentar
secundários não ajuda: cada novo é mais uma cópia inteira que precisa acompanhar o mesmo primário.

Sharding é a outra direção. **A coleção é cortada em faixas de um campo, a chave de shard, e cada
faixa mora num shard.** Um shard é um replica set próprio, então cada pedaço mantém as garantias da
aula 9, e cada shard guarda só a sua parte dos dados e recebe só as escritas dessa parte.

## Os três tipos de servidor

| servidor | o que faz | o que guarda |
|---|---|---|
| `mongos` | o roteador: recebe a requisição de cada cliente e a manda aos shards que têm o dado | nada |
| config server | guarda o mapa, qual faixa de qual coleção mora em qual shard | os metadados do cluster |
| shard | executa as consultas e escritas das suas faixas | a sua parte de cada coleção shardeada |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"As partes de um cluster shardeado. Os clientes mandam toda requisição ao mongos. O mongos lê o mapa de faixas no config server e manda cada requisição ao shard ou aos shards que guardam o dado. Cada shard é um replica set com parte da coleção: aqui o shard1 guarda os pedidos abaixo de 5001 e o shard2 os pedidos de 5001 para cima.\"><defs><marker id=\"arch10-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"arch10-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"arch10-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"270\" y=\"15\" width=\"160\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">aplicação</text><rect x=\"270\" y=\"95\" width=\"160\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"112.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mongos</text><text x=\"350.0\" y=\"127.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">roteador, não guarda nada</text><line x1=\"350\" y1=\"55\" x2=\"350\" y2=\"93\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#arch10-ah-paper-dim)\"></line><rect x=\"500\" y=\"95\" width=\"180\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"112.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">config server</text><text x=\"590.0\" y=\"127.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o mapa de faixas</text><line x1=\"432\" y1=\"120\" x2=\"498\" y2=\"120\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#arch10-ah-amber)\" marker-start=\"url(#arch10-ah-amber)\"></line><text x=\"465.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lê o mapa</text><rect x=\"90\" y=\"200\" width=\"220\" height=\"70\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"200.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shard1</text><text x=\"200.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">replica set</text><text x=\"200.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">orderId &lt; 5001</text><rect x=\"390\" y=\"200\" width=\"220\" height=\"70\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shard2</text><text x=\"500.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">replica set</text><text x=\"500.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">orderId ≥ 5001</text><line x1=\"320\" y1=\"147\" x2=\"205\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#arch10-ah-phosphor)\"></line><line x1=\"380\" y1=\"147\" x2=\"495\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#arch10-ah-phosphor)\"></line></svg>", "caption": "Um roteador, um mapa, dois shards. A aplicação nunca fala direto com um shard; o mongos decide para onde vai cada requisição, a partir do mapa que o config server guarda.", "same": ["config server", "replica set"]}
```

**A aplicação fala só com o `mongos`**, com os mesmos comandos que mandaria a um replica set. Uma
consulta que cita a chave de shard vai ao único shard que guarda aquela faixa. Uma consulta que não
cita vai a todos os shards, e o `mongos` junta as respostas, então ela custa tanto quanto o cluster
tem de shards. O resto desta aula gira em torno dessa diferença.

## Antes de shardear

Sharding é a última coisa a buscar, e o motivo está no título desta aula. **A chave de shard decide
onde mora cada documento**, toda consulta ou a usa ou paga por não usar, e escolher de novo depois
quer dizer mover a coleção inteira. Os índices da aula 7, uma máquina maior, um arquivo para
pedidos antigos ou leituras em secundários custam menos, e cada um se desfaz numa tarde.

O que o sharding compra e nenhum deles compra é espaço para crescer além de uma máquina. Uma
coleção já maior que o disco de um servidor, ou um ritmo de escrita que um primário não absorve,
não tem outra resposta.
