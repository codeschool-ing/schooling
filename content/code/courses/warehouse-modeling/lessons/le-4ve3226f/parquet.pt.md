---
title: Por dentro de um arquivo Parquet
version: 1
---

**Parquet** é o formato aberto de arquivo colunar que as lições 7 a 10 não param de gravar. É a língua
comum da análise de dados: DuckDB, Spark, BigQuery, Snowflake, Redshift, pandas e todo formato de tabela
de lakehouse leem e gravam Parquet, então um arquivo gravado por um é uma tabela para todos os outros.

A estrutura dele, de fora para dentro:

- **O arquivo** guarda um esquema, os nomes e tipos das colunas, e os seus metadados no fim, num
  **rodapé** (footer). Um leitor lê o rodapé primeiro, e assim sabe onde está tudo antes de ler qualquer
  dado.
- **Grupos de linhas** dividem as linhas em blocos, de 122.880 linhas cada nos arquivos que o DuckDB grava
  aqui.
- **Pedaços de coluna** (column chunks) ficam dentro de cada grupo: os valores de cada coluna juntos, com
  codificação e estatísticas próprias.
- **Páginas** dividem um pedaço de coluna mais ainda, e são a unidade que é comprimida.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"O arranjo de um arquivo Parquet como caixas aninhadas. O arquivo contém grupos de linhas, aqui oito, depois um rodapé. Cada grupo de linhas contém um pedaço de coluna por coluna, de date_key a net_cents. Cada pedaço de coluna contém páginas de valores codificados. O rodapé guarda o esquema e, para cada grupo de linhas e cada coluna, a posição, o tamanho, a codificação e o mínimo e o máximo, para um leitor decidir o que ler antes de ler.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"280\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">fact_sales.parquet</text><rect x=\"24\" y=\"45\" width=\"470\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">grupo de linhas 0 · 122.880 linhas</text><rect x=\"36\" y=\"75\" width=\"105\" height=\"52\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"88\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">date_key</text><rect x=\"44\" y=\"101\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"75\" y=\"101\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"106\" y=\"101\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"149\" y=\"75\" width=\"105\" height=\"52\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"201\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop_key</text><rect x=\"157\" y=\"101\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"188\" y=\"101\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"219\" y=\"101\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"262\" y=\"75\" width=\"105\" height=\"52\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"314\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">…</text><rect x=\"375\" y=\"75\" width=\"105\" height=\"52\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"427\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">net_cents</text><rect x=\"383\" y=\"101\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"414\" y=\"101\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"445\" y=\"101\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"24\" y=\"150\" width=\"470\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">grupo de linhas 1 · 122.880 linhas</text><rect x=\"36\" y=\"180\" width=\"105\" height=\"52\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"88\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">date_key</text><rect x=\"44\" y=\"206\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"75\" y=\"206\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"106\" y=\"206\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"149\" y=\"180\" width=\"105\" height=\"52\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"201\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop_key</text><rect x=\"157\" y=\"206\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"188\" y=\"206\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"219\" y=\"206\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"262\" y=\"180\" width=\"105\" height=\"52\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"314\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">…</text><rect x=\"375\" y=\"180\" width=\"105\" height=\"52\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"427\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">net_cents</text><rect x=\"383\" y=\"206\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"414\" y=\"206\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"445\" y=\"206\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"259\" y=\"263\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">… mais seis grupos de linhas …</text><rect x=\"510\" y=\"45\" width=\"186\" height=\"230\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"603\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">rodapé</text><text x=\"522\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">esquema: nomes, tipos</text><text x=\"522\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">por grupo, por coluna:</text><text x=\"522\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">onde começa</text><text x=\"522\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">quantos bytes</text><text x=\"522\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">que codificação</text><text x=\"522\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">mínimo e máximo</text><text x=\"259\" y=\"285\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as caixas pequenas são páginas</text></svg>", "caption": "Um arquivo Parquet: grupos de linhas feitos de pedaços de coluna feitos de páginas, e um rodapé que diz onde está tudo."}
```

O esquema e os metadados do arquivo `fact_sales.parquet`:

```
ana@lab:~/wh$ duckdb -c "SELECT name, type FROM parquet_schema('fact_sales.parquet')"
┌────────────────┬─────────┐
│      name      │  type   │
│    varchar     │ varchar │
├────────────────┼─────────┤
│ duckdb_schema  │ NULL    │
│ date_key       │ INT32   │
│ shop_key       │ INT64   │
│ book_key       │ INT64   │
│ customer_key   │ INT64   │
│ promotion_key  │ INT64   │
│ order_id       │ INT64   │
│ line_no        │ INT64   │
│ quantity       │ INT64   │
│ gross_cents    │ INT64   │
│ discount_cents │ INT64   │
│ net_cents      │ INT64   │
└────────────────┴─────────┘
  12 rows        2 columns
ana@lab:~/wh$ duckdb -c "SELECT num_rows, num_row_groups, format_version, created_by FROM parquet_file_metadata('fact_sales.parquet')"
┌──────────┬────────────────┬────────────────┬──────────────────────────────────────────┐
│ num_rows │ num_row_groups │ format_version │                created_by                │
│  int64   │     int64      │     int64      │                 varchar                  │
├──────────┼────────────────┼────────────────┼──────────────────────────────────────────┤
│   887477 │              8 │              1 │ DuckDB version v1.5.6 (build 069cc9f9b5) │
└──────────┴────────────────┴────────────────┴──────────────────────────────────────────┘
```

Os tipos são os do próprio arquivo, `INT32` e `INT64`, e são compartilhados por todo motor que lê
Parquet. `num_row_groups` é 8, e o rodapé registra que software gravou o arquivo.

**Tudo o que esta lição mediu está nesse rodapé**: os tamanhos por coluna da seção 04, as codificações da
seção 05, o mínimo e o máximo por grupo da seção 09. Um leitor que quer uma coluna de março abre o rodapé,
escolhe os grupos cujas estatísticas incluem março, e lê dentro deles os pedaços daquela coluna. Num
arquivo no armazenamento de objetos, isso são alguns trechos de bytes de um arquivo grande, e é o que torna
a separação de armazenamento e processamento da lição 7 rápida o bastante para ser usada.

O que o Parquet não tem é qualquer noção de mudança: um arquivo Parquet é gravado uma vez, inteiro, e nunca
editado. Uma tabela que muda são muitos arquivos e um registro de quais são os atuais, que é a lição 10.
