---
title: Um lake são arquivos, guardados como chegaram
version: 1
---

Um warehouse decide o formato dos dados antes que qualquer um deles chegue: uma tabela de staging, um
modelo, tipos conferidos na porta. Um **data lake** inverte isso. É armazenamento, quase sempre de objetos,
onde cada arquivo fica guardado como chegou, no formato em que veio, e o formato da tabela é decidido por
quem lê, na hora em que lê.

O lake de Ana é um diretório no disco do laboratório, fazendo as vezes de um bucket. Ela solta ali a
exportação de pedidos da loja, do jeito que está:

```
ana@lab:~/wh$ mkdir -p lake/raw/orders && cp extract/orders.csv lake/raw/orders/orders_2025-12-31.csv
ana@lab:~/wh$ duckdb -c "SELECT count(*) AS orders, min(ordered_at) AS first, max(ordered_at) AS last FROM read_csv('lake/raw/orders/*.csv')"
┌────────┬──────────────────────────┬──────────────────────────┐
│ orders │          first           │           last           │
│ int64  │ timestamp with time zone │ timestamp with time zone │
├────────┼──────────────────────────┼──────────────────────────┤
│ 577468 │ 2024-01-01 01:26:22-03   │ 2025-12-31 23:22:18-03   │
└────────┴──────────────────────────┴──────────────────────────┘
```

Nenhuma tabela foi criada, nenhum tipo declarado, nada carregado. O arquivo está numa pasta, e o DuckDB o
leu ali mesmo, deduziu os tipos pelo conteúdo e respondeu. Essa é toda a oferta do lake:

- **Uma fonte nova é uma pasta, não um projeto.** Logs do site, imagens de capas de livros, a lista de preços
  de um parceiro, um fluxo de cliques: cada um chega como arquivos e pode ser guardado antes que alguém saiba
  para que serve.
- **O armazenamento é barato**, o mais barato que a lição 5 de `cloud` cotou, e guarda qualquer coisa,
  estruturada ou não.
- **Qualquer motor consegue ler.** Os arquivos são CSV, JSON ou Parquet, formatos que toda ferramenta entende,
  então a mesma pasta serve ao DuckDB, ao Spark, a um notebook Python e a um warehouse na nuvem ao mesmo tempo.
  É a separação entre armazenamento e processamento da lição 7, com o armazenamento aberto a todos.

O preço dessa liberdade é pago por quem lê, e as duas próximas seções mostram a conta.
