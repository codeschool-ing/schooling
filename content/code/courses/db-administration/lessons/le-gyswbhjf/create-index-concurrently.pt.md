---
title: CREATE INDEX CONCURRENTLY, e o IF NOT EXISTS que mente
version: 1
---

Um índice novo tem o mesmo problema de um reconstruído. **Um `CREATE INDEX` comum pega `ShareLock`
na tabela**, o lock que o `REINDEX` do terminal 1 segurava: as leituras continuam, e todo insert,
update e delete espera a construção terminar. Numa tabela escrita o dia inteiro, é a interrupção de
novo, e o `CREATE INDEX CONCURRENTLY` é a mesma resposta: os mesmos passos da figura da seção
anterior, sem a troca, com o lock mais fraco, mais devagar, e fora de qualquer bloco de transação.

Ele falha do mesmo jeito também, e um índice único é o jeito comum. Todo cliente em `shop` tem vinte
pedidos, então um índice que promete um pedido por cliente não pode ser construído:

```
shop=# CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS orders_one_per_customer ON orders (customer_id);
ERROR:  could not create unique index "orders_one_per_customer"
DETAIL:  Key (customer_id)=(16120) is duplicated.
CONTEXT:  parallel worker

shop=# CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS orders_one_per_customer ON orders (customer_id);
NOTICE:  relation "orders_one_per_customer" already exists, skipping
CREATE INDEX

shop=# SELECT indexrelid::regclass, indisvalid, indisready FROM pg_index WHERE indrelid = 'orders'::regclass;
       indexrelid        | indisvalid | indisready 
-------------------------+------------+------------
 orders_pkey             | t          | t
 orders_customer_id      | t          | t
 orders_created_at       | t          | t
 orders_one_per_customer | f          | f
(4 rows)

shop=# DROP INDEX CONCURRENTLY orders_one_per_customer;
DROP INDEX
```

A primeira tentativa leu a tabela, achou uma duplicata e parou; `CONTEXT: parallel worker` diz que
foi um dos processos que ajudavam na construção que a achou. Um `CREATE UNIQUE INDEX` comum que
falha assim não deixa nada, porque o comando inteiro é uma transação e é desfeito. **O concorrente
deixa o índice que tinha começado, inválido**, pela razão que a figura dá: o primeiro passo dele já
estava confirmado.

A segunda tentativa é a armadilha. **O `IF NOT EXISTS` olha o nome e mais nada**, acha um índice
chamado `orders_one_per_customer`, diz que está pulando, e responde `CREATE INDEX` como se tivesse
dado certo. Uma ferramenta de migração que roda os comandos com `IF NOT EXISTS` para poder ser rodada
duas vezes vai relatar sucesso na segunda vez, sem índice utilizável e sem nada na própria saída
dizendo isso. Só a `pg_index` diz a verdade: `indisvalid` é `f`, então nenhuma consulta vai usá-lo.

`indisready` diz se o índice está sendo mantido em dia pelas escritas. Este falhou durante a
construção e nunca chegou lá, então só custa o nome e o disco. Uma construção concorrente que falha
mais tarde, no passo de validação, deixa um índice com `indisready` verdadeiro: mantido em toda
escrita e usado por nenhuma consulta, o pior dos dois mundos.

**Depois que qualquer comando com `CONCURRENTLY` falhar, olhe a `pg_index` antes de rodá-lo de
novo**, e apague o que ele deixou. Depois corrija a causa — aqui, os dados, ou a ideia de que cada
cliente compra uma vez — e rode o comando sem `IF NOT EXISTS`, para que uma sobra o faça falhar alto
em vez de pular quieto.

Um índice único construído assim pode depois sustentar uma constraint sem outra leitura da tabela,
que é como uma chave primária ou uma constraint única entra numa tabela em uso. A lição 22 faz isso,
com as outras mudanças no esquema de uma tabela em uso.
