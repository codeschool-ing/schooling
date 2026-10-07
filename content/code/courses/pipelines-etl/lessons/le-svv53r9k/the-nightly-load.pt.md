---
title: A carga noturna
version: 1
---

A lição 6 montou tabelas apagando e recriando cada uma. Isso serve para o staging, que ninguém lê
além da camada seguinte, e é errado para os marts, que as pessoas leem o dia todo e que precisam
**guardar o que já têm** — as vendas do ano passado, onde um cliente morava em janeiro. A carga é o
passo que escreve numa tabela que já tem algo dentro, e **cada jeito de fazê-la é uma decisão sobre o
que acontece com as linhas que estão lá**.

O warehouse da Ana ganha três tabelas em `marts`, cada uma carregada de um jeito:

| tabela | o que uma linha é | como é carregada |
|---|---|---|
| `dim_book` | um livro, como está agora | upsert: insere os novos, sobrescreve os alterados |
| `dim_customer` | um cliente, num lugar, por um período | tipo 2: fecha a versão antiga, abre uma nova |
| `fact_sales` | uma linha de pedido vendida | substitui o dia inteiro |

Um script roda uma noite: copia a loja para o `raw`, refaz o `staging`, e depois as três cargas,
nessa ordem, porque a tabela fato procura o cliente na dimensão:

```
#!/bin/sh
# One night: copy the shop into raw, rebuild staging, then load the marts.
set -e
day=${1:?usage: nightly.sh YYYY-MM-DD}
export PGOPTIONS="-c client_min_messages=warning"
python load_raw.py >/dev/null
sh run_sql.sh >/dev/null
psql -q -v ON_ERROR_STOP=1 -d wh -f load/dim_customer.sql
psql -q -v ON_ERROR_STOP=1 -d wh -At -f load/dim_book.sql | sort | uniq -c | sed 's/t$/inserted/; s/f$/updated/'
psql -q -v ON_ERROR_STOP=1 -d wh -v day="$day" -f load/fact_sales.sql
psql -d wh -At -c "SELECT '$day: ' || count(*) || ' fact rows' FROM marts.fact_sales WHERE order_date = '$day'"
```

Na primeira noite tudo é novo — 1.200 livros inseridos, 272 linhas de pedido, uma versão para cada um
dos 5.098 clientes:

```
ana@vm:~/etl$ sh nightly.sh 2026-03-01
   1200 inserted
2026-03-01: 272 fact rows
ana@vm:~/etl$ psql -d wh -c "SELECT count(*) AS versions, count(DISTINCT customer_id) AS customers FROM marts.dim_customer"
 versions | customers 
----------+-----------
     5098 |      5098
(1 row)
```

Na segunda noite, depois que o `shop` toca o dia 2 de março, os livros não mudaram e nada é
impresso sobre eles; as vendas do dia entram:

```
ana@vm:~/etl$ sudo shop day 2026-03-02
ana@vm:~/etl$ sh nightly.sh 2026-03-02
2026-03-02: 415 fact rows
```

As seções a seguir tratam das três cargas uma de cada vez, começando pela que este script não usa.
