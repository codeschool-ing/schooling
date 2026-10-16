---
title: Shards e réplicas, de novo
version: 1
---

O índice do laboratório tem um shard e nenhuma réplica, definidos no `index.json`, porque roda num nó só.
Pergunte ao motor como ele está organizado:

```
ana@vm:~/lab/search$ curl -s "localhost:9200/_cat/shards/products?v"
index    shard prirep state   docs  store ip         node
products 0     p      STARTED   25 12.5kb 172.18.0.3 b39dfa53a3b6
```

Um shard primário, `p`, com 25 documentos, iniciado. Um cluster de produção parece a aula 10 num produto
só: o índice é dividido em vários **shards primários**, para um catálogo grande se espalhar por máquinas e
as buscas rodarem em todas em paralelo; e cada primário tem **réplicas** em outros nós, para um nó poder
ser perdido sem perder dados, e as réplicas também podem responder buscas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Um cluster de busca de três nós guardando um índice dividido em três shards primários, P0, P1 e P2, cada um com uma réplica, R0, R1 e R2, posta num nó diferente do seu primário. Uma consulta é mandada a uma cópia de cada shard, e os melhores resultados deles são juntados.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"40\" y=\"40\" width=\"190\" height=\"120\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"135\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nó 1</text><rect x=\"60\" y=\"80\" width=\"70\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">P0</text><rect x=\"140\" y=\"80\" width=\"70\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"175\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">R2</text><rect x=\"265\" y=\"40\" width=\"190\" height=\"120\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nó 2</text><rect x=\"285\" y=\"80\" width=\"70\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">P1</text><rect x=\"365\" y=\"80\" width=\"70\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"400\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">R0</text><rect x=\"490\" y=\"40\" width=\"190\" height=\"120\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"585\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nó 3</text><rect x=\"510\" y=\"80\" width=\"70\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">P2</text><rect x=\"590\" y=\"80\" width=\"70\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">R1</text><text x=\"360\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">P = shard primário, R = a réplica dele, nunca no mesmo nó</text></svg>", "caption": "Um índice é dividido em shards por tamanho e replicado por falhas, as duas respostas da aula 10 num produto só."}
```

Os avisos da aula 10 continuam valendo. O número de shards primários é fixado quando o índice é criado,
porque o shard de um documento é o hash do id dele módulo esse número: mudá-lo significa um índice novo e
uma reindexação, que os aliases deixam indolor e nada deixa de graça. E uma busca num índice dividido é um
**scatter-gather**: cada shard devolve os seus melhores resultados, e o nó que recebeu a consulta os junta,
o que é o problema do top três da aula 10 resolvido por você, ao custo de perguntar a todo shard.

Shards demais é um erro mais comum que shards de menos. Cada shard tem um custo fixo de memória e de
arquivos abertos, e um catálogo de 50.000 produtos cabe com folga num só. A orientação dos próprios
motores é mirar em shards de dezenas de gigabytes, e começar com menos do que você acha.
