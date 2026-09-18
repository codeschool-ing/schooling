---
title: As mesmas perguntas no MySQL e no SQLite
version: 1
---

Tudo acima é saída do PostgreSQL, porque ele é o mais detalhado dos quatro bancos deste curso e
os hábitos que ele ensina se transferem. Os outros bancos respondem às mesmas perguntas nas suas
próprias formas, e esta seção é a tabela de tradução. A aula 12 compara os bancos como um todo;
isto aqui é só o plano.

## MySQL e MariaDB

`EXPLAIN` na frente de uma consulta imprime uma **tabela, uma linha por tabela que a consulta
toca**, em vez de uma árvore. As colunas a ler:

| coluna | o que diz | o equivalente no PostgreSQL |
|---|---|---|
| `type` | como a tabela é acessada: `ALL` é uma varredura completa, `ref` e `range` usam um índice, `eq_ref` é uma busca por chave única, `const` é uma linha só | o nó de varredura |
| `key` | qual índice foi escolhido, ou `NULL` | `Index Scan using …` |
| `rows` | as linhas examinadas, estimadas | o `rows=` da estimativa |
| `Extra` | o que mais aconteceu: `Using where` é um `Filter`; `Using index` é um index-only scan; `Using filesort` é um `Sort`; `Using temporary` é um hash ou uma materialização | as linhas de detalhe |

A ordem das linhas é a ordem das junções: a primeira linha é a tabela condutora e cada linha
abaixo é juntada ao que veio antes, então um plano se lê de cima para baixo do jeito que um nested
loop roda. `type: ALL` em qualquer linha que não a primeira é a forma de índice faltando da seção
sobre junções — a tabela inteira lida uma vez por linha externa.

`Using filesort` é a linha que as pessoas leem errado. Não quer dizer que a ordenação foi para o
disco; quer dizer que houve ordenação, em memória ou não, porque nenhum índice forneceu a ordem.
É a grafia do MySQL para "um nó `Sort` sem índice embaixo", e a correção é a mesma.

**`EXPLAIN ANALYZE`** existe no MySQL 8.0.18 em diante, e imprime uma **árvore**, em texto, com
tempos e contagens reais — mais perto da saída do PostgreSQL do que da tabular do próprio MySQL.
Numa versão que o tem, prefira-o pela mesma razão do resto desta aula: a estimativa é uma
previsão, e o real é o que aconteceu.

Achar a consulta lenta é o slow query log, `long_query_time`, e na 8.0 as tabelas do
`performance_schema` resumidas por `sys.statement_analysis` — as mesmas duas ferramentas da
primeira seção, e a mesma regra sobre totais contra médias.

## SQLite

```sql
EXPLAIN QUERY PLAN SELECT * FROM orders WHERE customer_id = 42;
```

`EXPLAIN` sozinho imprime o bytecode que o SQLite vai executar, que não é o que ninguém quer.
`EXPLAIN QUERY PLAN` imprime uma linha por passo:

```
EXPLAIN QUERY PLAN SELECT * FROM orders WHERE customer_id = 42;
  SCAN orders

EXPLAIN QUERY PLAN SELECT * FROM customers WHERE email = 'user42@example.com';
  SEARCH customers USING INDEX sqlite_autoindex_customers_1 (email=?)

CREATE INDEX orders_customer_id_idx ON orders (customer_id);
EXPLAIN QUERY PLAN SELECT * FROM orders WHERE customer_id = 42;
  SEARCH orders USING INDEX orders_customer_id_idx (customer_id=?)
```

`SCAN` é uma leitura completa da tabela e `SEARCH … USING INDEX` é uma busca por índice; esse par
é o vocabulário inteiro, e a correção está nele. Não há variante `ANALYZE` que rode a consulta, e
as estatísticas que o planejador usa vêm de você rodar `ANALYZE`. O SQLite não tem um daemon de
autovacuum para fazer isso, então um banco que cresceu muito desde a última análise está
planejando com números velhos até alguém rodar o comando.

## As três perguntas, em todo lugar

| | PostgreSQL | MySQL | SQLite |
|---|---|---|---|
| qual consulta | `pg_stat_statements`, o log | slow query log, `performance_schema` | a medição da própria aplicação |
| como é feita | `EXPLAIN` | `EXPLAIN` | `EXPLAIN QUERY PLAN` |
| o que aconteceu de fato | `EXPLAIN ANALYZE` | `EXPLAIN ANALYZE` (8.0.18+) | rode, e meça o tempo |

O vocabulário muda; o método não. Ache a consulta com um número anexado, leia como o banco
pretende rodá-la, rode de verdade onde o banco permite, e compare os dois — e quando discordam, a
estimativa é o que está errado.
