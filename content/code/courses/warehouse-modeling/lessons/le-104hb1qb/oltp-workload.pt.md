---
title: Do que o caixa precisa
version: 1
---

O nome do lado do caixa é **OLTP**, processamento de transações online. A palavra que importa é
*transação*: uma pequena unidade de trabalho que acontece inteira ou não acontece, muitas por
segundo, cada uma de uma pessoa diferente.

Peça ao PostgreSQL o pedido que o caixa acabou de gravar, e que diga como o encontrou:

```sql
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT o.ordered_at, o.status, l.line_no, l.book_id, l.quantity, l.unit_price_cents
FROM orders o JOIN order_lines l USING (order_id)
WHERE o.order_id = 900001;
```

```
ana@lab:~/wh$ psql -f one-order.sql
                                             QUERY PLAN                                             
----------------------------------------------------------------------------------------------------
 Nested Loop (actual time=0.126..0.128 rows=2 loops=1)
   Buffers: shared hit=11
   ->  Index Scan using orders_pkey on orders o (actual time=0.087..0.087 rows=1 loops=1)
         Index Cond: (order_id = 900001)
         Buffers: shared hit=7
   ->  Index Scan using order_lines_pkey on order_lines l (actual time=0.036..0.036 rows=2 loops=1)
         Index Cond: (order_id = 900001)
         Buffers: shared hit=4
 Planning:
   Buffers: shared hit=188
 Planning Time: 0.596 ms
 Execution Time: 0.192 ms
(12 rows)
```

Leia o plano de dentro para fora. Um **index scan** em `orders_pkey` percorreu a árvore B da chave
primária até o pedido 900001 e leu 7 páginas. Um segundo index scan em `order_lines_pkey` achou as
duas linhas em mais 4. **Onze páginas de 8 kB, em 0,192 milissegundo**, numa tabela de quase
novecentas mil linhas. O tamanho da tabela quase não conta: uma árvore B sobre um milhão de chaves
tem três ou quatro níveis, então uma tabela dez vezes maior custa à busca cerca de uma página a
mais.

Tudo no esquema operacional serve a esse tipo de trabalho:

- **Tabelas normalizadas.** A cidade de um cliente fica guardada uma vez, em `customers`. Mudá-la é
  um `UPDATE` numa linha, e nenhum pedido precisa ser tocado. É o que a terceira forma normal
  compra, e `sql-databases` dedicou a lição 2 inteira a ela.
- **Um índice para cada jeito de buscar uma linha.** Por número de pedido, por cliente, por data.
  Cada um barateia a busca e encarece um pouco cada inserção, uma troca que compensa quando as
  buscas são por chave.
- **Restrições que recusam dado ruim na porta.** Uma linha que cita um livro inexistente é recusada
  pela chave estrangeira, no momento em que é gravada, enquanto quem digitou ainda está ali para
  corrigir.
- **O estado atual, e só o estado atual.** A linha em `customers` diz onde o cliente mora *agora*.
  Quando muda, o valor antigo some daquela linha.

**Esse último é uma decisão de projeto, não um defeito.** Um caixa não precisa saber onde o cliente
morava no ano passado. A seção 08 mostra quanto isso custa a quem precisa.
