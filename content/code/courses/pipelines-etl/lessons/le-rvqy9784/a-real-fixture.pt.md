---
title: Uma fixture que são dados reais
version: 1
---

Um teste de integração precisa de uma loja contra a qual rodar, e a escolha da loja decide o que o
teste consegue achar. Uma fixture escrita à mão guarda os casos que o autor imaginou. A Ana corta a
dela da loja de verdade: um dia inteiro, todo pedido feito nele, e tudo o que esses pedidos tocam.

```
#!/bin/sh
# One real day of the shop, cut out of its database into files that are kept
# with the tests: every order placed that day in São Paulo, its lines and its
# payments, the customers they name, and every shop and book. Customers keep
# their city and state and lose their name and e-mail.
#   sh tests/make_fixture.sh 2026-03-02
set -e
day=${1:?usage: make_fixture.sh YYYY-MM-DD}
out=tests/fixture
mkdir -p $out
pg_dump -d shop --schema-only --no-owner --no-privileges > $out/schema.sql
orders="SELECT order_id FROM orders WHERE (ordered_at AT TIME ZONE 'America/Sao_Paulo')::date = '$day'"
cut() { psql -q -d shop -c "\copy ($2) TO '$out/$1.csv' WITH (FORMAT csv, HEADER)"; }
cut shops       "SELECT * FROM shops ORDER BY shop_id"
cut books       "SELECT * FROM books ORDER BY book_id"
# Names and e-mails are personal and no test needs them: replaced on the way out.
cut customers   "SELECT customer_id, 'customer ' || customer_id AS name, customer_id || '@example.invalid' AS email, city, state, created_at, updated_at FROM customers WHERE customer_id IN (SELECT customer_id FROM orders WHERE order_id IN ($orders)) ORDER BY customer_id"
cut orders      "SELECT * FROM orders WHERE order_id IN ($orders) ORDER BY order_id"
cut order_lines "SELECT * FROM order_lines WHERE order_id IN ($orders) ORDER BY order_id, line_no"
cut payments    "SELECT * FROM payments WHERE order_id IN ($orders) ORDER BY order_id"
wc -l $out/*.csv
```

O `pg_dump --schema-only` copia as definições de tabela da loja exatamente, restrições incluídas,
então o banco da fixture tem a mesma forma do real. Depois um `\copy` por tabela, cada um escrito como
a consulta que decide o que pertence ao dia: os pedidos feitos no dia 2 no horário de São Paulo, as
linhas e os pagamentos deles, e os clientes que eles nomeiam. Todas as lojas e todos os livros vão
junto, porque são poucos e todo pedido precisa deles.

```
ana@vm:~/etl$ sh tests/make_fixture.sh 2026-03-02
  1201 tests/fixture/books.csv
   180 tests/fixture/customers.csv
   416 tests/fixture/order_lines.csv
   259 tests/fixture/orders.csv
   259 tests/fixture/payments.csv
     8 tests/fixture/shops.csv
  2323 total
```

Duzentos e cinquenta e oito pedidos, 415 linhas, 179 clientes: pequeno o bastante para guardar no
repositório ao lado dos testes, e é um dia de verdade, com tudo o que um dia de verdade tem. Alguns
pedidos foram feitos num caixa por ninguém; alguns foram reembolsados; algum cliente pode ter pedido
depois para ser esquecido. **Nada disso precisou ser imaginado para estar no teste.**

Um recorte de dados reais pede dois cuidados. **É dado pessoal até que alguém o faça deixar de ser.**
A tabela `customers` da loja guarda nomes e endereços de e-mail, e nenhum teste precisa de nenhum dos
dois. O script os troca na saída — `customer 4211`, `4211@example.invalid` — e mantém a cidade e o
estado que o pipeline usa. Qualquer coisa pessoal de que um teste precise de fato tem de ser tratada
como o banco de onde veio. E é uma foto: quando as tabelas da loja mudam de forma, a Ana corta a
fixture de novo rodando o mesmo script, e é por isso que o script é guardado junto com ela.
