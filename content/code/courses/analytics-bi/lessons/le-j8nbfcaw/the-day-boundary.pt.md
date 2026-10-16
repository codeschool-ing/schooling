---
title: Onde um dia começa
version: 1
---

A parte de tempo de uma definição tem um detalhe que produz mais discordâncias do que qualquer
outro: **um dia é um período em algum fuso**, e um timestamp pertence a um dia diferente conforme
o fuso. O banco da Lantern está em São Paulo. Aqui está a primeira semana inteira de maio de 2026,
contada pelos dias de São Paulo:

```
lantern=# SELECT ordered_at::date AS day, to_char(ordered_at, 'Dy') AS name, count(*) AS orders
lantern-# FROM orders WHERE ordered_at::date BETWEEN '2026-05-04' AND '2026-05-10'
lantern-# GROUP BY 1, 2 ORDER BY 1;
    day     | name | orders 
------------+------+--------
 2026-05-04 | Mon  |     42
 2026-05-05 | Tue  |     23
 2026-05-06 | Wed  |     33
 2026-05-07 | Thu  |     23
 2026-05-08 | Fri  |     31
 2026-05-09 | Sat  |     34
 2026-05-10 | Sun  |     15
(7 rows)
```

E os mesmos pedidos, contados pelos dias do UTC, como uma ferramenta rodando num servidor em UTC
os contaria se ninguém dissesse o contrário:

```
lantern=# SET timezone = 'UTC';
SET

lantern=# SELECT ordered_at::date AS day, to_char(ordered_at, 'Dy') AS name, count(*) AS orders
lantern-# FROM orders WHERE ordered_at::date BETWEEN '2026-05-04' AND '2026-05-10'
lantern-# GROUP BY 1, 2 ORDER BY 1;
    day     | name | orders 
------------+------+--------
 2026-05-04 | Mon  |     35
 2026-05-05 | Tue  |     32
 2026-05-06 | Wed  |     24
 2026-05-07 | Thu  |     28
 2026-05-08 | Fri  |     29
 2026-05-09 | Sat  |     35
 2026-05-10 | Sun  |     21
(7 rows)
```

Todo dia é diferente, e até o total da semana muda, de 201 para 204, porque a própria semana começa
e termina num instante diferente. Segunda cai de 42 para 35, terça sobe de 23 para 32. **O padrão
semanal que a aula 1 encontrou, a segunda cheia, é em parte um artefato de qual relógio se usa.** O
motivo é que São Paulo está três horas atrás do UTC, então todo pedido feito depois das 21:00 no
horário local já é o dia seguinte em UTC, e os clientes da Lantern pedem tarde:

```
lantern=# SELECT count(*) FILTER (WHERE extract(hour FROM ordered_at) >= 21) AS after_21h,
lantern-#        count(*) AS orders
lantern-# FROM orders;
 after_21h | orders 
-----------+--------
      2278 |   7102
(1 row)
```

2.278 de 7.102 pedidos, quase um terço, mudam de dia entre os dois relógios. O mesmo acontece na
borda de todo mês e todo trimestre, mais de leve porque a borda é uma fatia menor de um período mais
longo:

```
lantern=# SELECT current_setting('timezone') AS zone, count(*) AS orders,
lantern-#        round(sum(gross_cents) / 100.0, 2) AS gross
lantern-# FROM order_totals WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01';
       zone        | orders |   gross   
-------------------+--------+-----------
 America/Sao_Paulo |   1963 | 329036.20
(1 row)

lantern=# SET timezone = 'UTC';
SET

lantern=# SELECT current_setting('timezone') AS zone, count(*) AS orders,
lantern-#        round(sum(gross_cents) / 100.0, 2) AS gross
lantern-# FROM order_totals WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01';
 zone | orders |   gross   
------+--------+-----------
 UTC  |   1962 | 329250.80
(1 row)
```

A contagem difere em um pedido e o valor em R$ 214,60: pedidos cruzam a fronteira nas duas
direções, nas duas pontas do trimestre, e o que sobra é o saldo das travessias. Esse é o tamanho de
diferença que faz duas pessoas que deveriam concordar passarem uma tarde procurando-a.

A correção é uma frase na definição — **os dias são dias de São Paulo** — e um mecanismo que a
garanta. O mecanismo da Lantern é a configuração do banco da aula 1, que vale para toda sessão; uma
ferramenta de BI tem um fuso próprio para relatórios, e a aula 3 confere se o do Metabase
concorda. Uma coluna de timestamp que guarda o instante com o fuso, `timestamptz` no PostgreSQL, é
o que torna a escolha possível: uma coluna que guarda um horário local sem fuso já fez a escolha, e
ninguém anotou qual.
