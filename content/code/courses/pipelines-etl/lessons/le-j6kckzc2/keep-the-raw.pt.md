---
title: Guarde as linhas cruas, e diga o que você viu
version: 1
---

Domingo à noite a Ana envia o relatório da primeira semana. Ela guarda uma cópia da tabela de onde
o tirou:

```
ana@vm:~/etl$ psql -d wh -c "CREATE TABLE sent_report AS SELECT * FROM etl_sales_by_category"
SELECT 98
ana@vm:~/etl$ psql -d wh -c "SELECT sum(books) AS books, sum(revenue_cents) AS revenue_cents FROM sent_report"
 books | revenue_cents 
-------+---------------
  3278 |      21941220
(1 row)
```

**Na quinta-feira um auditor pede que ela reproduza aquele número.** Mais quatro dias de vendas
aconteceram. Ela roda o ETL de novo para a mesma semana:

```
ana@vm:~/etl$ sudo bash ~/lab/lab.sh until 2026-03-11
ana@vm:~/etl$ python etl.py 2026-03-01 2026-03-07
read 3048 rows from the shop, wrote 98 to the warehouse
ana@vm:~/etl$ psql -d wh -c "SELECT sum(books) AS books, sum(revenue_cents) AS revenue_cents FROM etl_sales_by_category WHERE day <= '2026-03-07'"
 books | revenue_cents 
-------+---------------
  3252 |      21764780
(1 row)
```

Vinte e seis livros e R$ 1.764,40 sumiram de uma semana que terminou quatro dias antes. Ninguém
perdeu nada: entre domingo e quinta o escritório estornou e cancelou alguns pedidos da primeira
semana, e o `etl.py` pergunta à loja o que ela diz *agora*. **O pipeline ETL não consegue reproduzir
o próprio relatório**, porque aquilo que ele leu não existe mais na forma em que ele leu.

O pipeline ELT consegue. As tabelas cruas guardam as linhas como foram extraídas no domingo, e
reconstruir a resposta a partir delas dá exatamente o número de domingo:

```
ana@vm:~/etl$ psql -d wh -f sales_by_category.sql
DROP TABLE
SELECT 98
ana@vm:~/etl$ psql -d wh -c "SELECT sum(books) AS books, sum(revenue_cents) AS revenue_cents FROM elt_sales_by_category"
 books | revenue_cents 
-------+---------------
  3278 |      21941220
(1 row)
```

## Duas perguntas diferentes, as duas legítimas

Os dois números não são um certo e um errado. Eles respondem perguntas diferentes:

- **3.278 livros** é *o que o pipeline viu no domingo*. É o que o relatório disse, e com base em
  que se tomaram decisões. Uma auditoria precisa dele.
- **3.252 livros** é *o que a loja acredita agora sobre aquela semana*, com os estornos. O
  financeiro precisa dele.

Um dia alguém vai pedir o outro a um warehouse que guarda só um deles. **A camada crua é como
você guarda o primeiro**, e as lições 4 e 5 são como você acha as mudanças que fazem o segundo, para
que o warehouse possa dizer os dois e dizer qual é qual.

Três hábitos vêm daí, qualquer que seja o formato do pipeline:

- Guarde o que foi extraído, sem mudança, enquanto alguém puder perguntar sobre isso.
- Registre quando foi extraído. Estas tabelas cruas não registram, e a lição 4 acrescenta a coluna.
- Nunca "conserte" uma linha crua. Conserte a transformação e reconstrua a partir das linhas cruas;
  é para isso que elas existem.
