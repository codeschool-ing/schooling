---
title: O tempo, e o dia que não está lá
version: 1
---

Quase todo número de negócio é um número por período, então a última coluna a explorar é o tempo.
Duas coisas valem saber antes de construir qualquer relatório sobre ela: a **tendência** e os
**buracos**.

## A tendência

```
lantern=# SELECT to_char(date_trunc('month', ordered_at), 'YYYY-MM') AS month,
lantern-#        count(*) AS orders, repeat('#', count(*)::int / 20) AS bar
lantern-# FROM orders GROUP BY 1 ORDER BY 1;
  month  | orders |                    bar                     
---------+--------+--------------------------------------------
 2025-01 |     12 | 
 2025-02 |     28 | #
 2025-03 |     62 | ###
 2025-04 |     86 | ####
 2025-05 |    143 | #######
 2025-06 |    178 | ########
 2025-07 |    237 | ###########
 2025-08 |    281 | ##############
 2025-09 |    325 | ################
 2025-10 |    412 | ####################
 2025-11 |    636 | ###############################
 2025-12 |    592 | #############################
 2026-01 |    619 | ##############################
 2026-02 |    598 | #############################
 2026-03 |    746 | #####################################
 2026-04 |    779 | ######################################
 2026-05 |    855 | ##########################################
 2026-06 |    513 | #########################
(18 rows)
```

A Lantern cresce quase todo mês, de 12 pedidos em janeiro de 2025 a 855 em maio de 2026. Três
meses quebram o padrão, e cada um é uma pergunta para depois, e não uma conclusão agora.

Novembro de 2025 salta para 636, acima dos 592 de dezembro que vem depois: a loja fez uma campanha
de Black Friday, e a aula 9 acompanha os clientes que ela trouxe. Janeiro de 2026 quase não se
mexe. E junho de 2026 cai para 513 — **porque os dados terminam em 17 de junho**. Um mês cortado
ao meio parece um colapso em todo gráfico que o desenha como mês inteiro, e a aula 6 o trata como
o retrato enganoso que ele é.

## Os buracos

Um dia sem pedidos é um dia calmo ou um dia em que os dados nunca chegaram. Gerar todas as datas do
período com `generate_series` e ficar com as que não têm pedido nenhum os encontra:

```
lantern=# SELECT d::date AS day, extract(isodow FROM d) AS weekday
lantern-# FROM generate_series(date '2025-04-01', date '2026-06-17', interval '1 day') AS d
lantern-# WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.ordered_at::date = d::date)
lantern-# ORDER BY 1;
    day     | weekday 
------------+---------
 2025-04-24 |       4
 2025-08-14 |       4
(2 rows)
```

Dois dias desde abril de 2025. Nenhum dos dois é suspeito até você perguntar como era um dia normal
na época. No fim de abril de 2025 a loja recebia uns três pedidos por dia, então uma quinta sem
nenhum é plausível. O meio de agosto é outra história:

```
lantern=# SELECT ordered_at::date AS day, count(*) AS orders
lantern-# FROM orders
lantern-# WHERE ordered_at::date BETWEEN '2025-08-07' AND '2025-08-21'
lantern-# GROUP BY 1 ORDER BY 1;
    day     | orders 
------------+--------
 2025-08-07 |     10
 2025-08-08 |     12
 2025-08-09 |      9
 2025-08-10 |      5
 2025-08-11 |     12
 2025-08-12 |     10
 2025-08-13 |      6
 2025-08-15 |     10
 2025-08-16 |     15
 2025-08-17 |      9
 2025-08-18 |     13
 2025-08-19 |     11
 2025-08-20 |     13
 2025-08-21 |      9
(14 rows)
```

Todos os outros dias dessas duas semanas têm entre 5 e 15 pedidos. Um dia com zero, numa quinta,
no meio deles, não é um dia calmo. **É uma extração que faltou**: o pipeline que copia os pedidos
para este banco falhou em 14 de agosto de 2025, e ninguém percebeu. Qualquer total mensal de agosto
de 2025 está curto em cerca de um dia de pedidos, e um gráfico diário tirado desta tabela mostra uma
queda que nunca aconteceu.

A correção fica na origem, na carga. O seu trabalho, na análise exploratória, é achar o buraco e
dizer isso antes que alguém o leia como um fato sobre clientes.

## A semana

```
lantern=# SELECT extract(isodow FROM ordered_at) AS weekday, to_char(ordered_at, 'Dy') AS name,
lantern-#        count(*) AS orders
lantern-# FROM orders GROUP BY 1, 2 ORDER BY 1;
 weekday | name | orders 
---------+------+--------
       1 | Mon  |   1495
       2 | Tue  |   1009
       3 | Wed  |   1070
       4 | Thu  |    962
       5 | Fri  |   1010
       6 | Sat  |   1019
       7 | Sun  |    537
(7 rows)
```

O domingo tem cerca de metade dos pedidos de um dia útil, e a segunda tem cerca de metade a mais
que qualquer outro dia útil. **Um padrão assim muda o que significa uma comparação diária**: no
período inteiro, as segundas têm 178% mais pedidos que os domingos, então um relatório que compara
uma segunda com o dia anterior descreve o calendário, e não o negócio. Comparar um dia com o mesmo
dia da semana anterior elimina o efeito — a aula 6 usa exatamente essa comparação num painel.
