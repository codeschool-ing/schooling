---
title: Batch: um dia por vez
version: 1
---

**A ingestão em batch move dados em pedaços delimitados, num horário.** Um pedaço é quase sempre um
período — ontem, a última hora — e tudo o que aconteceu nele é lido, processado e escrito junto,
depois que o período fechou. É o tipo mais antigo de pipeline e ainda a maioria deles, porque a
maior parte das perguntas que as pessoas fazem a um warehouse é sobre períodos que já acabaram.

O primeiro batch da Ana lê um dia de vendas por loja do banco da loja e o escreve no warehouse:

```schooling-example
{
  "language": "python",
  "file": "batch.py",
  "parts": [
    {
      "code": "\"\"\"One day of sales per shop, from the shop's database into the warehouse.\"\"\"\nimport datetime as dt\nimport sys\n\nimport psycopg\n\n",
      "note": "Python e uma biblioteca, `psycopg`, que fala o protocolo do PostgreSQL."
    },
    {
      "code": "day = dt.date.fromisoformat(sys.argv[1])\n",
      "note": "O dia vem da linha de comando. **O script não decide que dia é hoje**, e é essa escolha que deixa o mesmo script carregar qualquer dia que você pedir."
    },
    {
      "code": "with psycopg.connect(\"dbname=shop\") as shop, psycopg.connect(\"dbname=wh\") as wh:\n    rows = shop.execute(\n        \"\"\"SELECT o.shop_id, count(*), sum(p.amount_cents)\n             FROM orders o JOIN payments p USING (order_id)\n            WHERE o.ordered_at >= %s AND o.ordered_at < %s\n              AND o.status = 'completed'\n            GROUP BY o.shop_id\n            ORDER BY o.shop_id\"\"\",\n        (day, day + dt.timedelta(days=1)),\n    ).fetchall()\n",
      "note": "Duas conexões, uma para cada banco. A consulta pede à loja um dia, da meia-noite até a meia-noite seguinte, e só os pedidos que não foram cancelados nem estornados."
    },
    {
      "code": "    wh.execute(\"\"\"CREATE TABLE IF NOT EXISTS daily_sales (\n                    day date, shop_id integer, orders integer, revenue_cents bigint)\"\"\")\n",
      "note": "A tabela de destino é criada se não existir. Um pipeline de verdade não criaria tabelas no caminho; a lição 18 diz onde isso mora."
    },
    {
      "code": "    with wh.cursor() as cur:\n        cur.executemany(\"INSERT INTO daily_sales VALUES (%s, %s, %s, %s)\",\n                        [(day, *r) for r in rows])\n",
      "note": "Entram sete linhas, uma por loja, numa transação só: o bloco `with` faz commit quando termina e desfaz tudo se algo dentro dele lançou erro."
    },
    {
      "code": "print(f\"{day}: {len(rows)} shops, {sum(r[1] for r in rows)} orders\")"
    }
  ]
}
```

Ela o roda para o dia que o laboratório acabou de tocar:

```
ana@vm:~/etl$ time python batch.py 2026-03-01
2026-03-01: 7 shops, 183 orders

real	0m0.190s
user	0m0.159s
sys	0m0.016s
ana@vm:~/etl$ psql -d wh -c "SELECT * FROM daily_sales ORDER BY shop_id"
    day     | shop_id | orders | revenue_cents 
------------+---------+--------+---------------
 2026-03-01 |       1 |     47 |        525660
 2026-03-01 |       2 |     21 |        198750
 2026-03-01 |       3 |     17 |        165140
 2026-03-01 |       4 |     19 |        234280
 2026-03-01 |       5 |     16 |        183730
 2026-03-01 |       6 |     12 |        151640
 2026-03-01 |       7 |     51 |        520010
(7 rows)
```

## O que um batch custa, e em que moeda

A execução levou um quinto de segundo. Esse não é o número que importa. **O que importa é quão
velha a resposta está quando alguém a lê**, e para um batch noturno isso é o tempo desde que o
período fechou, mais o tempo até a próxima execução começar, mais o quanto ela demora. Um relatório
aberto às quatro da tarde de 2 de março, alimentado por uma execução às 2 da manhã, mostra um dia
que terminou dezesseis horas antes. Para um relatório de vendas, tudo bem. Para "este livro está
sem estoque agora" não serve.

O batch compra três coisas com esse atraso:

- **Completude.** O dia acabou, então todos os pedidos do dia estão lá, inclusive os que o site
  escreveu às 23:59.
- **Simplicidade.** Uma execução, um período, uma transação. Se falhar, você roda de novo para o
  mesmo dia, e a alternativa da próxima seção não tem nada tão simples.
- **Eficiência.** Ler 183 pedidos de uma vez custa quase o mesmo que ler um, e um warehouse é feito
  para receber linhas em grandes goles — a lição 19 mede quão grandes.

**Rode duas vezes e olhe a tabela:**

```
ana@vm:~/etl$ python batch.py 2026-03-01
2026-03-01: 7 shops, 183 orders
ana@vm:~/etl$ psql -d wh -c "SELECT count(*), sum(orders) FROM daily_sales"
 count | sum 
-------+-----
    14 | 366
(1 row)
```

Ela agora tem o dia em dobro, catorze linhas e 366 pedidos onde havia 183. Este script ainda não tem nenhuma das quatro propriedades da seção anterior; a lição 15 o
torna seguro de rodar de novo, e as lições entre uma e outra dão o resto.
