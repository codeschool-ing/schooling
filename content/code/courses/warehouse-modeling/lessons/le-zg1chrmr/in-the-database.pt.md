---
title: Descrições guardadas no banco
version: 1
---

Um dicionário guardado num documento separado, uma página de wiki ou uma planilha, começa certo e vai se desviando.
Colunas são acrescentadas, renomeadas e removidas por pessoas mexendo em SQL, que não estão pensando na wiki. A
primeira defesa é guardar **a descrição onde a coluna está**, para que quem muda uma esteja olhando para a outra.

A maioria dos bancos consegue guardar um comentário numa tabela ou numa coluna. O DuckDB, como o PostgreSQL, usa
`COMMENT ON`:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "COMMENT ON COLUMN fact_sales.net_cents IS 'Net sales: gross_cents minus discount_cents, in centavos, without shipping. Additive.'"
ana@lab:~/wh$ duckdb -readonly wh.duckdb -c "SELECT column_name, comment FROM duckdb_columns() WHERE table_name = 'fact_sales' AND column_name LIKE '%cents'"
┌────────────────┬───────────────────────────────────────────────────────────────────────────────────────┐
│  column_name   │                                        comment                                        │
│    varchar     │                                        varchar                                        │
├────────────────┼───────────────────────────────────────────────────────────────────────────────────────┤
│ gross_cents    │ NULL                                                                                  │
│ discount_cents │ NULL                                                                                  │
│ net_cents      │ Net sales: gross_cents minus discount_cents, in centavos, without shipping. Additive. │
└────────────────┴───────────────────────────────────────────────────────────────────────────────────────┘
```

O comentário fica no catálogo do banco, ao lado do nome e do tipo da coluna, e volta pela mesma view de sistema que
lista as colunas. Não custa nada na hora da consulta e não precisa de ferramenta extra. Duas colunas ao lado,
`gross_cents` e `discount_cents` ainda mostram `NULL`, que é o estado honesto da maioria dos warehouses: algumas colunas
foram explicadas, por quem por acaso se importou.

Guardar descrições no banco tem um limite que vale conhecer. Um comentário está preso a uma coluna, então sobrevive a
um `SELECT` mas não a uma reconstrução: o warehouse de Ana é reconstruído a partir de arquivos SQL pelo `lab.sh
warehouse`, e uma tabela reconstruída volta sem comentários. **Os comentários precisam estar num arquivo que a
construção executa**, no controle de versão junto com o SQL que cria as tabelas. Esse arquivo é a seção 6.
