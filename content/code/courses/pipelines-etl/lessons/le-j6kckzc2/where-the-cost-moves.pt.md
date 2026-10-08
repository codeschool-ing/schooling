---
title: Para onde o custo vai
version: 1
---

As duas versões levaram menos de um quarto de segundo, então não é a velocidade que as separa aqui.
**O que as separa é o que cada uma moveu, e o que cada uma ainda consegue fazer depois.**

O que cada uma deixou no warehouse:

```
ana@vm:~/etl$ psql -d wh -c "SELECT relname, n_live_tup AS rows, pg_size_pretty(pg_total_relation_size(relid)) AS size FROM pg_stat_user_tables ORDER BY relname"
        relname        | rows |  size  
-----------------------+------+--------
 books                 | 1200 | 168 kB
 elt_sales_by_category |   98 | 16 kB
 etl_sales_by_category |   98 | 16 kB
 order_lines           | 3048 | 224 kB
 orders                | 1933 | 152 kB
(5 rows)
```

A tabela do ETL tem 98 linhas em 16 kB. Para dar a mesma resposta, a versão ELT copiou 1.933
pedidos, 3.048 linhas e todos os 1.200 livros — 6.181 linhas e 544 kB, trinta e quatro vezes o
espaço, antes de responder qualquer coisa. Numa semana de uma loja pequena isso não é nada. Em cinco
anos de uma grande é a conta do warehouse, e a lição 19 põe um preço nisso.

## O que as linhas cruas compram

Na quinta-feira o comprador faz uma pergunta que ninguém planejou: **quais editoras venderam mais
livros naquela semana?** A tabela do ETL não sabe responder. Ela guarda categorias, e a editora foi
jogada fora em Python no caminho. Responder significa mudar o `etl.py`, extrair a semana de novo da
loja, e torcer para a loja ainda dizer o que dizia no domingo.

A camada crua já tem tudo o que a loja tinha, então a resposta é uma consulta, hoje, sem visitar a
origem:

```
ana@vm:~/etl$ psql -d wh -c "SELECT b.publisher, sum(l.quantity) AS books FROM raw.orders o JOIN raw.order_lines l USING (order_id) JOIN raw.books b USING (book_id) WHERE o.status = 'completed' GROUP BY 1 ORDER BY 2 DESC LIMIT 3"
 publisher | books 
-----------+-------
 Maré      |   543
 Farol     |   315
 Granito   |   290
(3 rows)
```

**Esse é o argumento que venceu.** O ELT gasta armazenamento, que ficou barato, para comprar a
capacidade de responder à pergunta de amanhã com a extração de ontem, que continuou valiosa.
Warehouses colunares que cobram armazenamento por terabyte-mês e rodam SQL em quantas máquinas você
pagar tornaram a troca fácil, e é por isso que a maioria dos pipelines novos carrega primeiro.

## O que o ETL ainda economiza

- **O tempo da origem.** As duas versões leem a origem uma vez. Mas cada pergunta nova no ETL
  significa lê-la de novo, e a origem é o sistema de que os caixas dependem.
- **O tempo do warehouse.** A transformação do ELT roda no warehouse, disputando com quem o está
  lendo. Uma transformação pesada às nove da manhã é um painel lento.
- **Exposição.** Cada coluna copiada crua é uma coluna que o warehouse agora guarda, e precisa
  proteger, e precisa apagar quando alguém pede. Esse é o assunto da última seção.
