---
title: ETL: transformar no caminho
version: 1
---

A pergunta desta lição: **quantos livros, e quanta receita, cada categoria vendeu em cada dia da
primeira semana de março?** A Ana toca a semana na loja primeiro:

```
ana@vm:~/etl$ sudo bash ~/lab/lab.sh until 2026-03-07
```

A versão ETL lê as linhas de que precisa, faz a conta em Python e escreve só a resposta:

```schooling-example
{
  "language": "python",
  "file": "etl.py",
  "parts": [
    {
      "code": "\"\"\"ETL: books and revenue by day and category, worked out in Python before\nanything reaches the warehouse.\"\"\"\nimport collections\nimport datetime as dt\nimport sys\n\nimport psycopg\n\n"
    },
    {
      "code": "first, last = (dt.date.fromisoformat(a) for a in sys.argv[1:3])\nwith psycopg.connect(\"dbname=shop\") as shop:\n    rows = shop.execute(\n        \"\"\"SELECT o.ordered_at, o.status, b.category, l.quantity, l.unit_price_cents\n             FROM orders o\n             JOIN order_lines l USING (order_id)\n             JOIN books b USING (book_id)\n            WHERE o.ordered_at >= %s AND o.ordered_at < %s\"\"\",\n        (first, last + dt.timedelta(days=1)),\n    ).fetchall()\n\n",
      "note": "**Extrair.** Cada linha de pedido do período, com o status do pedido e a categoria do livro, lidas da loja numa consulta só. Nada é decidido aqui ainda: os pedidos cancelados vêm junto."
    },
    {
      "code": "totals = collections.defaultdict(lambda: [0, 0])\nfor ordered_at, status, category, quantity, price in rows:\n    if status != \"completed\":\n        continue\n    key = (ordered_at.date(), category)\n    totals[key][0] += quantity\n    totals[key][1] += quantity * price\n\n",
      "note": "**Transformar**, em Python, na memória deste programa. Pedidos cancelados e estornados saem, e cada linha é somada ao seu dia e à sua categoria. O `ordered_at` chega no horário de São Paulo, então `.date()` é o dia da própria loja."
    },
    {
      "code": "with psycopg.connect(\"dbname=wh\") as wh:\n    wh.execute(\"\"\"CREATE TABLE IF NOT EXISTS etl_sales_by_category (\n                    day date, category text, books integer, revenue_cents bigint)\"\"\")\n    wh.execute(\"DELETE FROM etl_sales_by_category WHERE day BETWEEN %s AND %s\", (first, last))\n    with wh.cursor() as cur:\n        cur.executemany(\"INSERT INTO etl_sales_by_category VALUES (%s, %s, %s, %s)\",\n                        [(d, c, b, r) for (d, c), (b, r) in sorted(totals.items())])\n",
      "note": "**Carregar** só a resposta. O `DELETE` limpa os mesmos dias antes, para que rodar de novo uma semana substitua a semana em vez de somá-la duas vezes; a lição 15 trata de por que isso importa."
    },
    {
      "code": "print(f\"read {len(rows)} rows from the shop, wrote {len(totals)} to the warehouse\")"
    }
  ]
}
```

```
ana@vm:~/etl$ time python etl.py 2026-03-01 2026-03-07
read 3048 rows from the shop, wrote 98 to the warehouse

real	0m0.232s
user	0m0.175s
sys	0m0.036s
```

Três mil linhas entram, noventa e oito saem: catorze categorias em sete dias. O warehouse não vê
nada além da resposta:

```
ana@vm:~/etl$ psql -d wh -c "SELECT * FROM etl_sales_by_category WHERE day = '2026-03-07' ORDER BY revenue_cents DESC LIMIT 5"
    day     |    category     | books | revenue_cents 
------------+-----------------+-------+---------------
 2026-03-07 | Picture books   |   106 |        621790
 2026-03-07 | Cooking         |    57 |        405980
 2026-03-07 | Science fiction |    61 |        363240
 2026-03-07 | Graphic novels  |    47 |        340630
 2026-03-07 | History         |    46 |        327440
(5 rows)
```

## No que este formato é bom

**O warehouse fica pequeno e limpo.** Nada chega nele que um relatório não use, e nada chega sem
ter sido conferido. Durante décadas isso importou mais que tudo: armazenamento e processador de
warehouse eram as máquinas mais caras do prédio, e carregar linhas cruas nelas para serem limpas lá
seria desperdiçar os dois.

**A transformação pode ser qualquer coisa.** Ela roda numa linguagem de uso geral, então pode
chamar uma API, ler um PDF, redimensionar uma imagem ou aplicar uma regra que seria ilegível em
SQL.

**E alguns dados nunca chegam.** Uma transformação que tira o e-mail de um cliente ou mascara um
número de cartão antes de carregar significa que o warehouse nunca o teve — o que é uma afirmação
diferente e mais forte que "apagamos depois". A última seção desta lição volta a isso.

O que ele custa fica para daqui a duas seções, e é a razão de o outro formato existir.
