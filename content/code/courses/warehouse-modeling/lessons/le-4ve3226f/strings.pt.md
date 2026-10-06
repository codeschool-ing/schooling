---
title: Textos
version: 1
---

Texto é o tipo de coluna mais difícil de comprimir e em geral o maior. A tabela fato não tem nenhum, que
é um dos motivos de comprimir tão bem; as dimensões estão cheias dele. O DuckDB, perguntado como guardou
quatro colunas de texto da `dim_book`:

```sql
SELECT column_name, compression, count(*) AS segments
FROM pragma_storage_info('dim_book')
WHERE column_name IN ('title', 'department', 'format', 'authors')
  AND segment_type <> 'VALIDITY'
GROUP BY ALL ORDER BY column_name;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < strings.sql
┌─────────────┬─────────────┬──────────┐
│ column_name │ compression │ segments │
│   varchar   │   varchar   │  int64   │
├─────────────┼─────────────┼──────────┤
│ authors     │ FSST        │        1 │
│ department  │ Dictionary  │        1 │
│ format      │ Dictionary  │        1 │
│ title       │ FSST        │        1 │
└─────────────┴─────────────┴──────────┘
```

Duas respostas diferentes, porque as colunas são tipos diferentes de texto.

**`department` e `format` ganharam um dicionário.** Quatro departamentos e três formatos em 3.000 livros:
as mesmas poucas strings de novo e de novo, e um dicionário guarda cada uma uma vez com um número pequeno
por linha, exatamente como para `shop_key`.

**`title` e `authors` ganharam FSST**, *Fast Static Symbol Table*. Quase todo título é diferente, então um
dicionário de títulos inteiros seria tão grande quanto a coluna. Mas os títulos compartilham pedaços:
`The `, ` of `, `Season`, `Harbour`. O FSST monta uma tabela de até 255 fragmentos frequentes de até oito
bytes e troca cada ocorrência por um byte. Descomprimir é uma consulta à tabela por byte, rápida o bastante
para um filtro rodar sobre o texto comprimido e decodificar só as linhas que passam.

Duas consequências para a modelagem:

- **Strings longas e repetidas numa tabela fato custam menos do que antes**, como a lição 6 mediu. Um banco
  por colunas as codifica por dicionário. Ainda custam algo, e ainda carregam o problema de atualização da
  lição 6.
- **Um identificador em string que poderia ser inteiro deveria ser.** Um e-mail como chave ocupou 66% a
  mais que um inteiro na lição 4, depois da compressão. Uma chave inteira é menor em toda codificação que
  existe.
