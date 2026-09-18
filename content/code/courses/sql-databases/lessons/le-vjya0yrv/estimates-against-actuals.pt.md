---
title: Quando o planejador erra, e por quê
version: 1
---

O planejador não roda a consulta para escolher um plano. Ele prevê quantas linhas cada passo vai
produzir, precifica cada plano com essa previsão, e escolhe o mais barato. **Todo plano ruim, no
sentido desta aula, é uma previsão errada** — o planejador fez a coisa certa para os números que
tinha, e os números estavam errados.

Então o jeito de ler um plano é comparar `rows=` na estimativa com `rows=` no real, em todo nó, e
parar na primeira distância grande. Um fator de dois é ruído. Um fator de cem é o achado.

## Uma função esconde a coluna

```
shop=# EXPLAIN ANALYZE SELECT * FROM orders WHERE date(placed_at) = DATE '2025-03-01';
                                                 QUERY PLAN                                                  
-------------------------------------------------------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..22466.00 rows=5000 width=28) (actual time=0.129..114.541 rows=1834 loops=1)
   Filter: (date(placed_at) = '2025-03-01'::date)
   Rows Removed by Filter: 998166
 Planning Time: 0.238 ms
 Execution Time: 114.682 ms
(5 rows)
```

Estimado 5000, real 1834. O planejador tem estatísticas sobre `placed_at` — a faixa, a
distribuição — e nenhuma sobre `date(placed_at)`, porque o resultado de uma função não é uma
coluna. Então ele recorreu a um padrão: meio por cento da tabela, seja qual for a tabela. Esse
chute está errado nas duas direções em dias diferentes, e um plano construído sobre ele às vezes
vai ser o plano errado.

A aula 9 deu a reescrita, e ela conserta os dois problemas de uma vez:

```sql
WHERE placed_at >= DATE '2025-03-01' AND placed_at < DATE '2025-03-02'
```

Uma faixa na coluna nua tem estatísticas por trás e um índice pela frente. O mesmo vale para toda
expressão da lista da aula 9 de razões para um índice não ser usado — aritmética, um cast, um
`coalesce` — e a estimativa é a segunda vítima em cada caso.

## Estatísticas que nunca foram recolhidas

```sql
CREATE TABLE returns (
    id        integer PRIMARY KEY,
    order_id  integer NOT NULL REFERENCES orders (id),
    reason    text NOT NULL,
    opened_at timestamptz NOT NULL
);
```

Uma tabela nova, vazia, e um plano para uma consulta nela:

```
shop=# EXPLAIN SELECT * FROM returns WHERE reason = 'damaged';
                       QUERY PLAN                        
---------------------------------------------------------
 Seq Scan on returns  (cost=0.00..23.38 rows=5 width=48)
   Filter: (reason = 'damaged'::text)
(2 rows)
```

`rows=5`, porque a tabela nunca foi analisada e o planejador está chutando pelo tamanho dela em
disco, que é nada. Agora duzentas mil linhas são carregadas, e o mesmo `EXPLAIN` é rodado de novo,
sem fazer mais nada:

```
shop=# EXPLAIN SELECT * FROM returns WHERE reason = 'damaged';
                         QUERY PLAN                          
-------------------------------------------------------------
 Seq Scan on returns  (cost=0.00..3293.54 rows=754 width=48)
   Filter: (reason = 'damaged'::text)
(2 rows)
```

O custo subiu — o planejador consegue ver que a tabela está maior — mas `rows=754` ainda é um
chute escalado a partir do nada, e a verdade é quarenta vezes isso. Então:

```
shop=# ANALYZE returns;
ANALYZE

shop=# EXPLAIN SELECT * FROM returns WHERE reason = 'damaged';
                          QUERY PLAN                           
---------------------------------------------------------------
 Seq Scan on returns  (cost=0.00..3909.00 rows=33400 width=26)
   Filter: (reason = 'damaged'::text)
(2 rows)
```

`rows=33400`, que é um quarto de duzentas mil, que está certo: quatro motivos, distribuídos por
igual. Uma instrução, e o planejador passou de chutar a saber.

O autovacuum roda `ANALYZE` sozinho quando uma tabela mudou o bastante, e numa tabela que cresce
devagar isso basta. Numa tabela que acabou de ser carregada, ou que acabou de ter metade das
linhas reescritas, a janela entre a mudança e a próxima análise automática é onde os planos ruins
moram. É o *"ontem era rápido"* da aula 9, e é o motivo de `ANALYZE` depois de uma carga em
massa não ser opcional.

## Colunas que andam juntas

O planejador supõe que condições são independentes. Numa tabela `addresses`,
`WHERE city = 'Manaus' AND state = 'AM'` é estimado como o produto das duas seletividades, como se
um endereço em Manaus pudesse estar em qualquer estado. Então a estimativa fica baixa demais, o
planejador escolhe um nested loop para um resultado que ele acha minúsculo, e o loop roda cem mil
vezes.

O PostgreSQL 10 em diante aceita ser avisado de que as duas colunas se relacionam:

```sql
CREATE STATISTICS addresses_city_state ON city, state FROM addresses;
ANALYZE addresses;
```

Depois disso o planejador tem uma distribuição conjunta e a estimativa é honesta. Procure por
isso sempre que um plano subestima um `WHERE` de várias colunas por ordens de grandeza e cada
coluna sozinha é estimada bem. É a forma do problema, e ele é comum em dados de endereço, em
colunas de status que dependem de uma coluna de tipo, e em qualquer coisa desnormalizada do jeito
que a aula 2 discutiu.

## O valor para o qual o plano foi feito

Uma instrução preparada, ou uma consulta que um ORM manda com marcadores, é planejada antes de o
valor ser conhecido. A aula 11 tem o mecanismo; o que importa aqui é a consequência: **um plano
para `$1` é um plano para o valor médio**, e o valor médio de `status` é `paid`, com sessenta por
cento. Um plano bom para `paid` é uma varredura sequencial, e é o plano errado para `pending`,
com um terço de por cento. O PostgreSQL planeja as primeiras execuções com o valor real e só troca
para um plano genérico quando este não parece pior; quando uma consulta é rápida no `psql` e lenta
vindo da aplicação, esta é a primeira coisa a suspeitar.

## Lendo a distância

| estimativa contra real | causa usual |
|---|---|
| muito abaixo, numa varredura com função ou aritmética | sem estatísticas para a expressão |
| muito abaixo ou acima numa tabela recém-carregada | nunca analisada |
| muito abaixo numa condição de várias colunas | colunas correlacionadas |
| certa em toda varredura, errada acima de uma junção | a seletividade da junção, e a ordem em que as junções foram tentadas |
| boa no `psql`, errada vinda da aplicação | um plano genérico para um marcador |

O hábito que acha todas elas: **leia as estimativas de baixo para cima, e o primeiro nó em que os
dois números discordam por um fator de cem é onde o plano deu errado** — todo nó acima dele
herdou esse erro.
