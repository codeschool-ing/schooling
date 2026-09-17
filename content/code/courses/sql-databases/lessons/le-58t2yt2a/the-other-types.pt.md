---
title: Os outros tipos de índice, e o problema de cada um
version: 1
---

Tudo até aqui foi a árvore B, que é o padrão e é a resposta certa para quase todo índice que você vá
criar. Os outros existem porque há perguntas que uma lista ordenada não responde, e vale saber quais
são — sobretudo para você reconhecer um problema como solúvel em vez de como lento.

## Hash

```sql
CREATE INDEX ON sessions USING hash (token);
```

Guarda um hash do valor. Responde a `=` e a mais nada: sem faixas, sem ordenação, sem `LIKE` de
prefixo, sem ajuda ao `ORDER BY`.

Ele pode ser menor que uma árvore B numa coluna de texto longa, que é o único argumento a favor.
Contra isso, uma árvore B responde a igualdade perfeitamente bem e também responde a todo o resto. Os
índices hash do PostgreSQL não eram escritos no log de escrita antecipada antes da versão 10, então
não sobreviviam a uma queda e eram amplamente desaconselhados; isso foi corrigido, e o conselho
sobreviveu ao problema.

**Recorra a uma árvore B, a menos que você tenha medido uma razão para não.**

## GIN — para valores que contêm muitas coisas

A coluna `tags` de uma linha guarda `{'sql', 'databases', 'beginner'}`. Uma árvore B conseguiria
indexar o array inteiro como um valor, o que deixa você achar linhas cujas tags sejam exatamente
aquelas. Ela não consegue achar linhas cujas tags *incluam* `'sql'`.

O GIN — índice invertido generalizado — indexa os **elementos**, com uma lista de linhas para cada:

```sql
CREATE INDEX ON articles USING gin (tags);
SELECT * FROM articles WHERE tags @> ARRAY['sql'];
```

A mesma estrutura serve a três coisas que você vai encontrar de verdade:

```sql
CREATE INDEX ON documents USING gin (payload jsonb_path_ops);  -- chaves dentro de uma coluna JSON
CREATE INDEX ON articles  USING gin (to_tsvector('english', body));  -- busca em texto completo
CREATE INDEX ON customers USING gin (name gin_trgm_ops);       -- e a de mais cedo
```

Essa última linha é a correção para `LIKE '%ana%'`. A extensão `pg_trgm` quebra cada string em
pedaços de três caracteres e indexa esses pedaços, então uma subcadeia vira um conjunto de trigramas
a buscar em vez de uma varredura. Ela também sustenta casamento aproximado por similaridade.

A troca: o GIN é **mais lento para atualizar** que uma árvore B, às vezes bastante, porque uma linha
produz muitas entradas. Ele é uma estrutura de busca, e combina com dado que é lido muito mais do que
é escrito.

## GiST — para coisas que não são pontos numa reta

Faixas e formas não se ordenam. Duas faixas de datas podem se sobrepor sem que nenhuma seja "menor
que" a outra, então lista ordenada nenhuma as arruma de modo útil. O GiST é um arcabouço para
índices sobre esse tipo de valor:

```sql
CREATE INDEX ON reservations USING gist (during);
```

É sobre ele que o PostGIS é construído para dado geográfico, e é o que a restrição de exclusão da
aula 8 exige:

```sql
ALTER TABLE reservations ADD CONSTRAINT no_overlap
EXCLUDE USING gist (room_id WITH =, during WITH &&);
```

Então este tipo de índice não é só uma ferramenta de desempenho — é o mecanismo pelo qual uma regra
de correção sobre sobreposições pode ser imposta.

## BRIN — minúsculo, para tabelas enormes e ordenadas

Uma árvore B numa tabela de um bilhão de linhas é grande. O BRIN guarda, por faixa de blocos, apenas
o menor e o maior valor encontrados ali:

```sql
CREATE INDEX ON events USING brin (created_at);
```

Kilobytes em vez de gigabytes. Uma consulta por faixa de datas pula toda faixa de blocos cujo mínimo
e máximo não possam contê-la, e lê o resto.

Ele funciona só quando **a coluna se correlaciona com a ordem física das linhas**, que é exatamente
o caso de um registro de eventos com carimbo de tempo: linhas escritas em março ficam juntas porque
foram escritas juntas. Embaralhe a tabela, ou indexe uma coluna sem relação com a ordem de inserção,
e toda faixa de blocos cobre tudo e o BRIN não elimina nada.

Para uma tabela grande, só de inserção e ordenada no tempo, é uma das melhores trocas disponíveis: um
índice desprezível que remove a maior parte das leituras.

## O que os outros bancos têm

**MySQL e MariaDB**: árvore B no InnoDB, mais `FULLTEXT` para busca em texto e `SPATIAL` para
geometria. Índices hash existem no motor em memória. Não há GIN nem BRIN; o MySQL 8.0.17 acrescentou
índices multivalorados para arrays dentro de JSON, o que cobre uma fatia do que o GIN faz.

**SQLite**: árvore B, e é essa a lista. Busca em texto completo é um módulo de tabela virtual, o
FTS5, e não um tipo de índice.

## O resumo honesto

| tipo | para | onde |
|---|---|---|
| **árvore B** | igualdade, faixas, ordenação, prefixos | em todo lugar, e quase sempre a resposta |
| **GIN** | elementos dentro de um valor: arrays, JSON, texto, trigramas | PostgreSQL |
| **GiST** | sobreposições e formas, e restrições de exclusão | PostgreSQL |
| **BRIN** | tabelas enormes cuja ordem casa com a coluna | PostgreSQL |
| **hash** | igualdade num valor longo, e mais nada | PostgreSQL, raramente vale |

O que se leva de útil não é a tabela. É que **`LIKE '%…%'`, buscar dentro de uma coluna JSON e "duas
reservas não podem se sobrepor" são todos solúveis** — e que, se você está no MySQL ou no SQLite,
dois deles são solúveis de outro jeito e um não é, o que é algo a saber antes de projetar a
funcionalidade e não depois.
