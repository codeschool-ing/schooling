---
title: Um orçamento
version: 1
---

Tudo o que esta aula mediu até aqui cabe num programa. O exemplo é um acervo maior que o da
Marginalia: **dois milhões de trechos de 300 tokens**, transformados em vetores pelo
text-embedding-3-small nas suas 1536 dimensões e guardados no PostgreSQL com um índice HNSW. Os
preços vêm da tabela gravada na seção 05 desta aula e os bytes por linha vêm da tabela de 1536
dimensões medida na seção 02, lidos de volta do banco em vez de digitados.

```schooling-example
{
  "language": "python",
  "file": "budget.py",
  "parts": [
    {
      "code": "import json\nimport psycopg\n\nprices = {p[\"model\"]: p for p in json.load(open(\"prices.json\"))}\nsmall, large = prices[\"text-embedding-3-small\"], prices[\"text-embedding-3-large\"]\nCHUNKS, PER = 2_000_000, 300\ntokens = CHUNKS * PER\nGB = 1e9",
      "note": "Os dois modelos da tabela e o tamanho do exemplo: dois milhões de trechos de 300 tokens."
    },
    {
      "code": "with psycopg.connect() as conn:\n    row, hnsw = conn.execute(\"\"\"SELECT pg_table_size('v1536') / 20000.0,\n                                       pg_relation_size('v1536_hnsw') / 20000.0\"\"\").fetchone()\nprint(f\"measured at 1536 dims: {row:.0f} B a row, {hnsw:.0f} B a row of HNSW\")",
      "note": "O que uma linha custa de verdade no Postgres com 1536 dimensões, lido da tabela e do índice HNSW medidos antes nesta aula, não suposto."
    },
    {
      "code": "print(f\"{CHUNKS:,} chunks x {PER} tokens = {tokens:,} tokens\")\nprint(f\"embed once, {small['model']}:  ${tokens / 1e6 * small['usd_per_mtok']:.2f}\"\n      f\"  (batch ${tokens / 1e6 * small['batch_usd_per_mtok']:.2f})\")\nprint(f\"raw float32 vectors:     {CHUNKS * small['dims'] * 4 / GB:6.2f} GB\")\nprint(f\"table in Postgres:       {CHUNKS * float(row) / GB:6.2f} GB\")\nprint(f\"HNSW index in Postgres:  {CHUNKS * float(hnsw) / GB:6.2f} GB\")",
      "note": "Transformar tudo em vetores uma vez, no preço normal e no preço em lote, e o espaço que os vetores ocupam como números crus, como tabela e como índice HNSW."
    },
    {
      "code": "churn = 0.05\nprint(f\"re-embed {churn:.0%} a month:     ${tokens * churn / 1e6 * small['usd_per_mtok']:.2f}\")\nprint(f\"move to {large['model']}: ${tokens / 1e6 * large['usd_per_mtok']:.2f}\"\n      f\"  raw vectors {CHUNKS * large['dims'] * 4 / GB:.2f} GB,\"\n      f\" {CHUNKS * (small['dims'] + large['dims']) * 4 / GB:.2f} GB while both exist\")",
      "note": "Duas coisas que voltam: refazer os vetores da fração dos trechos que muda a cada mês, e mudar o acervo inteiro para o modelo maior."
    }
  ]
}
```

```
ana@lab:~/emb$ python budget.py
measured at 1536 dims: 8348 B a row, 8192 B a row of HNSW
2,000,000 chunks x 300 tokens = 600,000,000 tokens
embed once, text-embedding-3-small:  $12.00  (batch $6.00)
raw float32 vectors:      12.29 GB
table in Postgres:        16.70 GB
HNSW index in Postgres:   16.38 GB
re-embed 5% a month:     $0.60
move to text-embedding-3-large: $78.00  raw vectors 24.58 GB, 36.86 GB while both exist
```

## Lendo a conta

**Transformar o acervo inteiro em vetores uma vez custa US$ 12,00**, ou US$ 6,00 pela Batch API
no preço em lote da tabela, que a aula 7 descreveu e que nada aqui rodou. Essa é a linha que
preocupa as pessoas, e é a mais barata da página.

**Os vetores têm 12,29 GB como números crus e mais que o dobro disso no Postgres**: 16,70 GB de
tabela e 16,38 GB de índice HNSW, a partir dos 8.348 e 8.192 bytes por linha medidos com 1536
dimensões. Isso é disco que você paga todo mês. O índice também é a parte que precisa caber na memória,
porque uma busca salta de página em página pelo grafo, e cada página fora da memória é uma leitura
do disco. Quanto custa um GB de memória ou de disco depende de onde você roda, e nenhuma tabela deste
curso tem esse preço; multiplique estes tamanhos pelos preços do seu provedor.

**Acompanhar as mudanças é barato.** Se 5% dos trechos mudam num mês, refazer os vetores deles custa
US$ 0,60. Essa fração é uma suposição do programa, não uma medida; ponha a sua.

**Trocar de modelo é onde está o dinheiro.** Passar para o text-embedding-3-large custa US$ 78,00
em tokens, os vetores crus dele têm 24,58 GB, e enquanto os antigos e os novos existem juntos são
36,86 GB, antes de qualquer custo extra de tabela ou de índice. E há um segundo problema nessa
dimensão: o pgvector do laboratório não consegue construir um índice HNSW sobre 3072 dimensões, como
a seção 03 mostrou, então a mudança também exige encurtar os vetores ou atualizar a extensão.

## O que muda a conta

Três alavancas, cada uma medida antes nesta aula:

| alavanca | onde foi medida | o que ela move |
|---|---|---|
| uma dimensão menor | `shrink.py`, WordLlama cortado em 128 e 64 | todas as linhas de bytes, ao custo de vizinhos |
| menos bytes por número | `shrink.py`, float16 e int8 | todas as linhas de bytes, quase de graça até o int8 |
| uma cópia só dos vetores | `graphs.py`, hnswlib contra pgvector | a linha do índice |

A linha dos tokens, a que tem um cifrão impresso ao lado, quase não se mexe com nenhuma delas. **Um
armazenamento de vetores é sobretudo uma conta de armazenamento**, e o tamanho de cada linha é fixado
no dia em que o modelo é escolhido. Escolha a dimensão pensando nisso, como pede a tabela de decisão
da aula 10, e meça o `per_row` no seu próprio banco antes de multiplicar.
