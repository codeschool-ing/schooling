---
title: Dois índices que são um só
version: 1
---

Um índice duplicado é o ganho mais barato desta aula: dois índices que guardam exatamente a mesma
coisa, então um deles pode sair e **nenhuma consulta em lugar nenhum fica mais lenta**, porque o
planejador vai usar o outro para tudo o que o primeiro fazia. A dificuldade está só em enxergá-los.
**Dois índices não são duplicados porque os nomes se parecem, e podem ser duplicados com nomes que
não têm nada em comum.** `orders_customer_id_idx` e `orders_customer_idx` por acaso parecem
parentes; `order_lines_product_id_idx1` é um nome que o PostgreSQL inventou quando uma migração
disse `CREATE INDEX ON order_lines (product_id)` sem dar um, e o `1` no fim é a única pista de que
um `order_lines_product_id_idx` já existia.

Ler as definições a olho também não é confiável. O PostgreSQL não recusa um segundo índice nas
mesmas colunas, e uma definição num arquivo de migração pode estar escrita de um jeito diferente
do que o servidor guardou, enquanto uma que parece igual pode diferir num ponto que importa. Então
pergunte ao catálogo.

## O que torna dois índices iguais

O `pg_index` tem uma linha por índice, e cinco de suas colunas, juntas, dizem o que um índice
contém:

| coluna | o que guarda |
|---|---|
| `indkey` | os números das colunas da tabela, na ordem do índice; 0 para uma expressão |
| `indclass` | a operator class de cada coluna, que também fixa o tipo de índice |
| `indcollation` | a collation de cada coluna, que decide a ordem do texto |
| `indexprs` | as expressões, para um índice em `lower(email)` e afins |
| `indpred` | o `WHERE` de um índice parcial |

Dois índices na mesma tabela que concordam nas cinco guardam as mesmas entradas na mesma ordem.
Cada uma delas importa. **Mesmas colunas com `indclass` diferente não são duplicatas**: um B-tree
e um índice hash em `customer_id` respondem perguntas diferentes, e o mesmo vale para dois B-trees
numa coluna de texto em que um usa `text_pattern_ops` para `LIKE 'abc%'`. Mesmas colunas com
`indpred` diferente também não: um índice parcial nos pedidos pendentes (aula 9) guarda alguns
milhares de entradas onde o completo guarda dois milhões.

A consulta agrupa o `pg_index` por essas cinco e fica com os grupos de mais de um membro. Duas das
colunas são de tipos que não se comparam diretamente, então viram texto antes, e o `pg_get_expr`
transforma as árvores de expressão guardadas de volta em SQL:

```sh
cat > ~/duplicate-indexes.sql <<'SQL'
-- duplicate-indexes.sql: indexes on the same table that store the same
-- thing, whatever they are called: the same columns in the same order,
-- the same operator classes and collations, the same expressions and
-- the same WHERE.
SELECT indrelid::regclass AS table,
       array_agg(indexrelid::regclass ORDER BY indexrelid) AS indexes
FROM pg_index
GROUP BY indrelid, indkey::text, indclass::text, indcollation::text,
         coalesce(pg_get_expr(indexprs, indrelid), ''),
         coalesce(pg_get_expr(indpred, indrelid), '')
HAVING count(*) > 1;
SQL
```

```
ana@vm:~$ psql market -f duplicate-indexes.sql
    table    |                         indexes                          
-------------+----------------------------------------------------------
 orders      | {orders_customer_id_idx,orders_customer_idx}
 order_lines | {order_lines_product_id_idx,order_lines_product_id_idx1}
(2 rows)

Time: 2.393 ms
```

Dois pares, que é o que o arquivo das sobras criou. Cada array está em ordem de criação, então o
primeiro nome é o índice mais antigo.

## Qual sai

Qualquer um, no que diz respeito aos dados: são o mesmo índice duas vezes. A escolha é sobre tudo o
que está em volta dos dados, e três coisas a decidem.

**Fique com o que pertence a uma constraint.** Se um do par sustenta uma chave primária ou uma
constraint de unicidade, é ele que fica, porque o servidor se recusa a apagá-lo sozinho de todo
modo. Apagar o gêmeo não único de uma chave primária é sempre seguro.

**Fique com o que as suas migrações conhecem.** O histórico de migrações, o código da aplicação e a
memória da próxima pessoa se referem a índices pelo nome. O `orders_customer_id_idx` está no
`market.sql`, que é a migração mais antiga deste banco; `order_lines_product_id_idx1` é um nome que
ninguém escolheu. Fique com os nomes que estão escritos em algum lugar.

**Ignore qual deles os contadores dizem que foi lido.** A seção 03 desta aula mostrou o planejador
lendo o `orders_customer_idx` 72.686 vezes e o original nenhuma. Isso registra um empate que o
planejador desfez, não uma preferência que valha guardar: no momento em que o gêmeo some, as mesmas
varreduras vão para o sobrevivente, com o mesmo plano. A seção 06 desta aula apaga o
`orders_customer_idx` e o `order_lines_product_id_idx1`, e a medição no fim dela mostra que nada
ficou mais lento.

## O que a consulta não pega

Ela acha índices idênticos, que é o caso que uma máquina consegue resolver. Dois quase-casos ficam
com você:

- **Um índice e uma constraint de unicidade nas mesmas colunas.** Um `CREATE UNIQUE INDEX` e um
  `CREATE INDEX` comum na mesma coluna têm as mesmas cinco colunas no `pg_index`, e a consulta os
  lista juntos; fique com o único. Se eles também diferirem em `indclass`, não serão listados, e
  você precisa lê-los.
- **Um índice que é o começo de outro.** `(seller_id)` e `(seller_id, placed_at)` não são o mesmo
  índice, e com razão esta consulta não diz nada sobre eles. Também não são independentes, e esse é
  o assunto da próxima seção.

**Rode a consulta uma vez em cada banco de que você cuida.** Duplicatas são comuns, saem de graça
e são o jeito mais fácil de mostrar a uma equipe do que trata o resto desta aula, porque ninguém
consegue defender que uma segunda cópia de um índice esteja se pagando.
