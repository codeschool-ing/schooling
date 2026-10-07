---
title: Um dia de vendas, quando você pedir
version: 1
---

**Um pipeline existe porque a origem não para de mudar.** Um laboratório cujo banco nunca se
mexesse ensinaria você a copiar uma tabela uma vez, e esse não é o trabalho. Por isso a loja deste
laboratório tem um relógio, e quem o gira é você.

Quando o laboratório é montado, o banco da loja está onde estava na noite de 28 de fevereiro de
2026:

```
ana@vm:~/etl$ psql -c "SELECT (SELECT count(*) FROM customers) AS customers, (SELECT count(*) FROM orders) AS orders, (SELECT max(ordered_at) FROM orders) AS last_order"
 customers | orders |       last_order       
-----------+--------+------------------------
      5079 |  17012 | 2026-02-28 23:57:44-03
(1 row)
```

Março ainda não aconteceu. O `shop day` toca um dia dele:

```
ana@vm:~/etl$ sudo shop day 2026-03-01
ana@vm:~/etl$ psql -c "SELECT (SELECT count(*) FROM customers) AS customers, (SELECT count(*) FROM orders) AS orders, (SELECT max(ordered_at) FROM orders) AS last_order"
 customers | orders |       last_order       
-----------+--------+------------------------
      5098 |  17195 | 2026-03-01 23:50:30-03
(1 row)

ana@vm:~/etl$ ls -l landing/events inbox
inbox:
total 52
-rw-r--r-- 1 ana ana 51310 Oct  7 05:24 stock_2026-03-01.csv

landing/events:
total 316
-rw-r--r-- 1 ana ana 321982 Oct  7 05:24 2026-03-01.jsonl
```

Dezenove clientes novos e 183 pedidos novos. Dois arquivos também apareceram: os eventos de clique
do site no dia, e o arquivo de estoque da distribuidora, deixado na caixa de entrada do jeito que um
fornecedor o deixaria num servidor. Esses são mais dois tipos de origem, e a lição 3 trata dos
quatro.

## Do que um dia é feito

O dia não é uma pilha de linhas. São as transações que os caixas, o site e o escritório rodaram, na
ordem em que rodaram, cada uma com seus próprios horários:

```
ana@vm:~/etl$ grep -c "^BEGIN" /var/lib/etl-data/days/2026-03-01.sql
211
ana@vm:~/etl$ grep -oE "^(INSERT INTO|UPDATE|DELETE FROM) [a-z_]+" /var/lib/etl-data/days/2026-03-01.sql | sort | uniq -c
     19 INSERT INTO customers
    272 INSERT INTO order_lines
    183 INSERT INTO orders
    183 INSERT INTO payments
      4 UPDATE customers
      5 UPDATE orders
```

**As duas linhas de `UPDATE` são as que fazem deste um curso de pipelines.** Quatro clientes
mudaram de cidade, e cinco pedidos de dias anteriores foram cancelados ou estornados. Uma cópia
tirada no dia 28 agora está errada sobre linhas que ninguém inseriu hoje. Em alguns dias o
escritório também apaga um cliente que pediu para ser esquecido. As lições 4 e 5 tratam de achar
mudanças assim sem ler o banco inteiro de novo.

## O relógio só anda para a frente

```
ana@vm:~/etl$ sudo shop day 2026-03-01
the shop has lived up to 2026-03-01: the next day to play is 2026-03-02
```

Um dia pode ser tocado uma vez, em ordem, como no mundo. **Para voltar, você reinicia** — o
`sudo shop reset` devolve a loja ao dia 28 e esvazia tudo o que os pipelines escreveram. O `sudo
shop until 2026-03-07` toca uma semana de uma vez, quando uma lição precisa de histórico para trabalhar.

Essa é a resposta do laboratório a um problema que nenhum outro curso daqui tem: **um job agendado
precisa que o tempo passe**, e ninguém espera um mês para ver um relatório mensal rodar. O tempo da
loja anda quando você manda. O tempo do Airflow, a partir da lição 9, é a data *para a qual* uma
execução existe, que você também escolhe — então um mês de execuções noturnas pode ser vivido em
poucos minutos e continuar sendo o mês que diz ser.
