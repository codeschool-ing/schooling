---
title: O que o floco de neve economiza, e o que custa
version: 1
---

O argumento para normalizar uma dimensão é armazenamento e consistência. No warehouse, o primeiro é
pequeno e o segundo já está resolvido.

**Armazenamento.** Quantos bytes a estrela gasta repetindo nomes?

```sql
-- What the star repeats, in bytes of text, against the size of the fact table.
SELECT sum(strlen(category) + strlen(subcategory) + strlen(department) + strlen(publisher))
           AS repeated_text_bytes,
       (SELECT count(*) FROM fact_sales) AS fact_rows
FROM dim_book;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < repeated.sql
┌─────────────────────┬───────────┐
│ repeated_text_bytes │ fact_rows │
│       int128        │   int64   │
├─────────────────────┼───────────┤
│              130473 │    887477 │
└─────────────────────┴───────────┘
ana@lab:~/wh$ ls -l wh.duckdb
-rw-r--r-- 1 ana ana 46149632 Oct  6 13:29 wh.duckdb
```

130.473 bytes de texto repetido: os quatro nomes de cada livro, três mil vezes. O arquivo inteiro do
warehouse tem 46.149.632 bytes. **O floco de neve economizaria cerca de 0,3% do arquivo**, e menos que
isso depois que a compressão da lição 8 passar por essas palavras repetidas, que é o tipo de dado que
ela comprime melhor. Uma dimensão tem alguns milhares de linhas; a tabela fato tem quase novecentas
mil. Economizar espaço na tabela pequena não mexe no total.

**Consistência.** No banco operacional, a normalização impede que duas linhas discordem: renomeie um
departamento, e nada fica com o nome antigo. No warehouse **ninguém edita nada à mão**. A `dim_book` é
reconstruída pela carga a partir da cópia única de cada nome na origem, então as linhas também não
conseguem discordar entre si. A anomalia que o floco de neve evita é uma que a carga já evita.

**O que ele custa**, do outro lado:

- **Mais junções por pergunta**, e uma cadeia delas que alguém precisa conhecer. A seção 05 contou
  três a mais numa pergunta.
- **Ferramentas de relatório mais difíceis.** Uma ferramenta que oferece "departamento" como campo
  precisa saber o caminho de três passos até ele. A maioria aprende; todas são mais simples numa
  estrela.
- **Mais tabelas para documentar e carregar**: cinco onde havia uma, com chaves entre elas que a carga
  precisa manter consistentes.

Então o padrão é a estrela. A próxima seção é sobre quando a troca vira para o outro lado.
