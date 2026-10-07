---
title: Provar, toda vez
version: 1
---

*Esta carga é idempotente* é uma afirmação, e o que a lição 12 ensinou foi que uma afirmação sobre dados
vale o que vale o teste que a confere. Então a Ana escreve o teste uma vez, para qualquer passo:

```
#!/bin/sh
# Run a step twice and say whether the second run changed anything.
#   sh twice.sh 'STEP' 'QUERY'
# QUERY is any SELECT that describes what the step leaves behind; the step is
# idempotent, as far as that query can see, when it gives the same answer after
# the first run and after the second.
set -e
step=$1 query=$2
sh -c "$step" >/dev/null
first=$(psql -d wh -Atc "$query")
sh -c "$step" >/dev/null
second=$(psql -d wh -Atc "$query")
echo "after one run:  $first"
echo "after two runs: $second"
if [ "$first" = "$second" ]; then echo "idempotent"; else echo "NOT idempotent"; exit 1; fi
```

Rodar o passo, descrever o que ele deixou; rodar de novo, descrever de novo; comparar. A descrição é
a consulta que servir ao passo — uma impressão digital da tabela que ele escreve, em geral. Depois
ela o roda sobre cada passo que a carga noturna tem:

```
ana@vm:~/etl$ sh twice.sh 'psql -q -d wh -At -f load/dim_book.sql' 'SELECT count(*), md5(string_agg(d::text, chr(10) ORDER BY book_id)) FROM marts.dim_book d'
psql:load/dim_book.sql:9: NOTICE:  relation "dim_book" already exists, skipping
psql:load/dim_book.sql:9: NOTICE:  relation "dim_book" already exists, skipping
after one run:  1200|1e2c91c165716d39f65b4be5211ade52
after two runs: 1200|1e2c91c165716d39f65b4be5211ade52
idempotent
ana@vm:~/etl$ sh twice.sh 'psql -q -d wh -f load/dim_customer.sql' 'SELECT count(*), md5(string_agg(d::text, chr(10) ORDER BY customer_key)) FROM marts.dim_customer d'
psql:load/dim_customer.sql:10: NOTICE:  relation "dim_customer" already exists, skipping
psql:load/dim_customer.sql:10: NOTICE:  relation "dim_customer" already exists, skipping
after one run:  5390|7a50cb47200d94b3580fa5aa406e5263
after two runs: 5390|7a50cb47200d94b3580fa5aa406e5263
idempotent
ana@vm:~/etl$ sh twice.sh 'dbt build --project-dir shop --quiet' 'SELECT count(*), md5(string_agg(f::text, chr(10) ORDER BY order_id, line_no)) FROM dbt_marts.fact_sales f'
after one run:  32886|7898a3d51049a824177c4fd81533f7e0
after two runs: 32886|7898a3d51049a824177c4fd81533f7e0
idempotent
ana@vm:~/etl$ sh twice.sh 'python load_raw.py' 'SELECT count(*), md5(string_agg(e::text, chr(10) ORDER BY e::text)) FROM raw.events e'
after one run:  41783|a11b783c5e5e3ef7e3af187848873be4
after two runs: 41783|a11b783c5e5e3ef7e3af187848873be4
idempotent
```

Quatro passos, quatro *idempotent*. O `dim_book` é um upsert, e a segunda execução não atualizou nada.
O `dim_customer` é a dimensão tipo 2 da lição 7, cujas atualizações só tocam clientes que se mudaram,
então uma segunda execução não acha ninguém para mudar. O `dbt build` refez todo modelo e toda tabela e
deixou as 32.886 linhas da tabela fato exatamente como estavam. O `load_raw.py` esvaziou o raw e o
encheu de novo com os mesmos documentos.

Duas coisas fazem isso valer mais do que parece. É barato o bastante para rodar a cada mudança numa
carga, que é quando a idempotência se perde: alguém acrescenta um passo, e o passo acrescenta linhas.
E **testa a propriedade em si, e não o código que deveria garanti-la**. O `twice.sh` não sabe o que é um
upsert; ele só sabe que a tabela não mudou, que é o que importa.

O que ele não consegue mostrar é um passo que é idempotente *hoje* por sorte — um insert que por acaso
não acha nada para inserir porque nada novo chegou. A impressão digital tem de ser tirada sobre as
linhas que o passo escreve, num dia em que ele tem linhas a escrever. A lição 17 torna execuções assim
parte dos testes.
