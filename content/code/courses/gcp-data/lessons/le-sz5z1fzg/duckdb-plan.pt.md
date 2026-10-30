---
title: Ler um plano, no DuckDB
version: 1
---

**Um plano de consulta é a resposta do motor a "como você vai fazer isto", escrita como uma árvore de
passos.** Cada passo recebe linhas dos passos de baixo e entrega linhas ao passo de cima, então um plano
se lê de baixo, onde a tabela é lida, para cima, onde a resposta sai. O DuckDB imprime um com `EXPLAIN`,
que planeja e não roda, e com `EXPLAIN ANALYZE`, que roda a consulta e escreve ao lado de cada passo
quantas linhas ele produziu e quanto tempo levou. Todo plano desta seção é do DuckDB, medido no seu
laptop; o equivalente do BigQuery é a próxima seção, e ele é desenhado de outro jeito por um motivo que
aquela seção dá.

## Setembro, por bairro

O `ask.py` da aula 13 imprime o plano como texto quando uma pergunta começa com `EXPLAIN`:

```
ana@laptop:~/gcp$ python3 ask.py "EXPLAIN ANALYZE SELECT district, sum(total_cents) AS sales FROM orders WHERE dt BETWEEN DATE '2026-09-01' AND DATE '2026-09-29' GROUP BY district ORDER BY sales DESC"
┌─────────────────────────────────────┐
│┌───────────────────────────────────┐│
││    Query Profiling Information    ││
│└───────────────────────────────────┘│
└─────────────────────────────────────┘
EXPLAIN ANALYZE SELECT district, sum(total_cents) AS sales FROM orders WHERE dt BETWEEN DATE '2026-09-01' AND DATE '2026-09-29' GROUP BY district ORDER BY sales DESC
┌────────────────────────────────────────────────┐
│┌──────────────────────────────────────────────┐│
││              Total Time: 0.0126s             ││
│└──────────────────────────────────────────────┘│
└────────────────────────────────────────────────┘
┌───────────────────────────┐
│           QUERY           │
└─────────────┬─────────────┘
┌─────────────┴─────────────┐
│      EXPLAIN_ANALYZE      │
│    ────────────────────   │
│                           │
│           0 rows          │
│           0.00s           │
└─────────────┬─────────────┘
┌─────────────┴─────────────┐
│          ORDER_BY         │
│    ────────────────────   │
│   sum(memory.main.orders  │
│     .total_cents) DESC    │
│                           │
│                           │
│                           │
│           8 rows          │
│           0.00s           │
└─────────────┬─────────────┘
┌─────────────┴─────────────┐
│       HASH_GROUP_BY       │
│    ────────────────────   │
│         Groups: #0        │
│    Aggregates: sum(#1)    │
│                           │
│                           │
│                           │
│           8 rows          │
│           0.01s           │
└─────────────┬─────────────┘
┌─────────────┴─────────────┐
│         PROJECTION        │
│    ────────────────────   │
│          district         │
│        total_cents        │
│                           │
│                           │
│                           │
│        594,882 rows       │
│           0.00s           │
└─────────────┬─────────────┘
┌─────────────┴─────────────┐
│         TABLE_SCAN        │
│    ────────────────────   │
│         Function:         │
│        READ_PARQUET       │
│                           │
│        Projections:       │
│          district         │
│        total_cents        │
│                           │
│       File Filters:       │
│ (dt BETWEEN '2026-09-01': │
│  :DATE AND '2026-09-29':  │
│           :DATE)          │
│                           │
│   Scanning Files: 29/60   │
│    Total Files Read: 29   │
│                           │
│        Filename(s):       │
│  warehouse/orders/dt=2026 │
│  -09-01/part-000.parquet, │
│  warehouse/orders/dt=2026 │
│  -09-02/part-000.parquet, │
│  warehouse/orders/dt=2026 │
│  -09-03/part-000.parquet, │
│  warehouse/orders/dt=2026 │
│  -09-04/part-000.parquet, │
│  warehouse/orders/dt=2026 │
│ -09-05/part-000.parquet, .│
│             ..            │
│                           │
│                           │
│                           │
│        594,882 rows       │
│           0.02s           │
└───────────────────────────┘
```

**Leia de baixo.** `TABLE_SCAN` é a leitura: a função `READ_PARQUET`, as duas colunas que ela **projeta**,
`district` e `total_cents`, e o **filtro de arquivo** em `dt` que manteve 29 dos 60 arquivos. Ela leu os
arquivos que nomeia e produziu 594.882 linhas, que são todos os pedidos de setembro. Repare no que ela
não lista: `dt` não está entre as projeções, porque o DuckDB tirou a data dos nomes das pastas e não
precisou de coluna para ela. O BigQuery cobraria `dt` como coluna, e a última seção desta aula volta a
isso.

**`PROJECTION` passa as duas colunas para cima**, e **`HASH_GROUP_BY` é a agregação**: agrupa por `#0`, a
primeira coluna que recebeu, `district`, e soma `#1`, `total_cents`. Entram 594.882 linhas e saem 8, uma
por bairro, que é o momento em que uma consulta deixa de ser grande. **`ORDER_BY` ordena essas 8 linhas**
pela soma, e `EXPLAIN_ANALYZE` no topo é o envoltório que mediu o resto; ele não devolve linhas próprias.

**Os tempos dizem onde estava o trabalho.** A leitura levou a maior parte, e o agrupamento e a ordenação
de 8 linhas quase nada. Esse é o formato normal de uma consulta analítica, e é o mesmo no BigQuery: ler
é o passo caro, e é por isso que os dois modelos de preço da aula 14 voltam a quanto uma consulta lê, um
cobrando os bytes e o outro cobrando os slots que os leem. O total no topo, alguns centésimos de
segundo, é o custo de 29 arquivos num laptop e não diz nada sobre a velocidade do BigQuery.

## O que o plano prova, e o que não consegue

**O plano é prova das duas coisas pelas quais este curso cobra.** A lista de projeções são as colunas
lidas, e a contagem de arquivos são as partições lidas. Se uma consulta que deveria ler um dia diz
`Scanning Files: 60/60`, o plano pegou o erro caro antes da conta, e esse é o hábito que vale manter em
qualquer motor: ler o plano de uma consulta que vai rodar muitas vezes antes que ela rode.

**O que ele não consegue provar é nada sobre o plano do BigQuery.** O DuckDB é um processo numa máquina,
com um plano de operadores passando linhas uns aos outros em memória. O BigQuery divide a mesma consulta
entre muitos slots e muitos estágios, com as linhas passando entre eles pela rede, e o plano dele tem uma
forma que o do DuckDB não tem. Os passos são reconhecivelmente os mesmos, uma leitura, uma projeção, uma
agregação, uma ordenação; como eles se arrumam e quanto custam é a próxima seção.
