---
title: Um carrinho aberto por cliente
version: 1
---

Uma restrição `UNIQUE` diz que um valor pode aparecer uma vez na tabela inteira. Regras de negócio
raramente são tão amplas. Elas dizem **um de cada coisa por vez**: um carrinho aberto por cliente,
uma assinatura ativa por conta, um endereço principal por pessoa, uma fatura em aberto por pedido. Os
outros carrinhos, assinaturas e faturas, os fechados e terminados, podem se repetir quanto quiserem.
Um índice **único** parcial diz exatamente isso: único, mas só entre as linhas que o seu `WHERE`
admite.

## Uma tabela para experimentar

O `market` não tem carrinhos, então crie uma tabela pequena para eles. Grave este arquivo como
`carts.sql`; o botão de copiar leva o SQL sem as notas:

```schooling-example
{
  "language": "sql",
  "file": "carts.sql",
  "parts": [
    {
      "code": "-- carts.sql: shopping carts, at most one open per customer.\n"
    },
    {
      "code": "CREATE TABLE carts (\n    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,\n    customer_id integer     NOT NULL REFERENCES customers (id),\n    status      text        NOT NULL DEFAULT 'open'\n                CHECK (status IN ('open', 'ordered', 'abandoned')),\n    created_at  timestamptz NOT NULL DEFAULT now()\n);\n\n",
      "note": "**Um carrinho passa por três estados.** Fica `open` enquanto o cliente acrescenta coisas, e vira `ordered` ou `abandoned` quando termina. Carrinhos velhos ficam guardados: são o histórico do que as pessoas quase compraram."
    },
    {
      "code": "CREATE UNIQUE INDEX carts_one_open_idx ON carts (customer_id)\n    WHERE status = 'open';\n",
      "note": "**A regra, como índice.** Único em `customer_id`, mas só entre as linhas em que `status = 'open'`. Um cliente pode ter quantos carrinhos encomendados e abandonados quiser, e um aberto. Um `UNIQUE (customer_id)` comum permitiria um carrinho por cliente, para sempre."
    }
  ]
}
```

Rode-o no `market`:

```
ana@vm:~$ psql market -f carts.sql
CREATE TABLE
Time: 14.756 ms
CREATE INDEX
Time: 1.757 ms
```

A regra mora no índice, `carts_one_open_idx`, e em nenhum outro lugar. Nada na definição da tabela
diz "um carrinho aberto"; apague o índice e a regra some.

## Tentando quebrá-la

```
market=# INSERT INTO carts (customer_id) VALUES (42);
INSERT 0 1
Time: 4.751 ms

market=# INSERT INTO carts (customer_id) VALUES (42);
ERROR:  duplicate key value violates unique constraint "carts_one_open_idx"
DETAIL:  Key (customer_id)=(42) already exists.
Time: 0.817 ms

market=# INSERT INTO carts (customer_id) VALUES (42) ON CONFLICT (customer_id) WHERE status = 'open' DO NOTHING;
INSERT 0 0
Time: 0.614 ms

market=# UPDATE carts SET status = 'ordered' WHERE customer_id = 42 AND status = 'open';
UPDATE 1
Time: 1.642 ms

market=# INSERT INTO carts (customer_id) VALUES (42);
INSERT 0 1
Time: 1.533 ms

market=# SELECT id, customer_id, status FROM carts ORDER BY id;
 id | customer_id | status  
----+-------------+---------
  1 |          42 | ordered
  4 |          42 | open
(2 rows)

Time: 1.058 ms
```

Leia de cima para baixo.

- **O primeiro insert** cria o carrinho aberto do cliente 42.
- **O segundo** tenta criar outro e é recusado, com o índice citado no erro e o valor em que colidiu.
  O banco garantiu a regra de negócio, e nenhum código da aplicação foi consultado.
- **`ON CONFLICT … DO NOTHING`** é a forma educada para uma aplicação: "crie um carrinho aberto, a
  menos que já exista um". `INSERT 0 0` é a resposta "já existia". O `WHERE status = 'open'` depois de
  `ON CONFLICT (customer_id)` não é enfeite. O PostgreSQL precisa achar um índice único que combine
  com o alvo do conflito, e só um alvo que repete o predicado do próprio índice combina com um índice
  parcial.
- **O update** fecha o carrinho, e a partir daí a linha não está mais no índice.
- **O último insert** abre um carrinho novo para o mesmo cliente, e ele entra.

O `SELECT` final mostra dois carrinhos do cliente 42, um encomendado e um aberto, que é o estado que a
regra permite. Os ids são 1 e 4, não 1 e 2: o insert recusado e o pulado já tinham tirado cada um um
número da sequência da identity, e uma sequência nunca devolve um número. Um buraco numa coluna
identity pode ser um insert que nunca aconteceu, além de uma linha que foi apagada.

## Por que não conferir na aplicação

A alternativa que todo mundo escreve primeiro é um `SELECT` procurando um carrinho aberto, e um
`INSERT` se não houver. Funciona em todo teste, porque um teste manda uma requisição por vez. Em
produção, dois cliques em "adicionar ao carrinho" com poucos milissegundos de diferença rodam o mesmo
`SELECT` ao mesmo tempo, os dois não acham nada, e os dois inserem. Agora o cliente tem dois carrinhos
abertos, e a próxima consulta da aplicação, que espera um, pega qualquer um deles. A aula 14 trata de
corridas exatamente com esse formato, e a cura geral ali é um nível de isolamento mais estrito com
novas tentativas. Para uma regra deste formato a cura é mais barata: o índice único confere cada
insert contra todos os outros, confirmados ou não, e o segundo de dois inserts simultâneos espera o
primeiro e então falha.

## O tamanho

O índice guarda uma entrada por carrinho aberto, então o tamanho dele acompanha o número de clientes
comprando agora, não o número de carrinhos já criados. É a propriedade da seção 02 de novo, aplicada a
uma regra em vez de uma consulta: a fatia da tabela que importa é pequena, e o índice é essa fatia.
