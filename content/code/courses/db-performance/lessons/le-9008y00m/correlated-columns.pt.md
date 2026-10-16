---
title: Duas colunas que dizem uma coisa só
version: 1
---

Tudo até aqui foi sobre uma coluna de cada vez, e cada um daqueles resumos estava bom. Esta seção é
sobre um plano que dá errado embora o resumo de cada coluna esteja certo, porque o erro está no passo
que os combina.

## A suposição de independência

Uma cláusula `WHERE` com duas condições recebe duas seletividades, uma por coluna, e o planejador as
**multiplica**. Isso está certo quando as colunas não têm nada a ver uma com a outra: se metade dos
clientes tem um nome que começa com vogal e um décimo mora em Recife, cerca de um vigésimo é as duas
coisas. Está errado quando uma coluna prevê a outra, e o `market.sql` fez `city` e `state` exatamente
assim: a cidade de um cliente vem sempre com o mesmo estado.

Eis o que o resumo sabe sobre Curitiba e sobre o Paraná, e o que o planejador faz com os dois juntos:

```
market=# SELECT attname, (most_common_vals::text::text[])[5] AS value, most_common_freqs[5] AS freq FROM pg_stats WHERE tablename = 'customers' AND attname = 'city';
 attname |  value   |  freq  
---------+----------+--------
 city    | Curitiba | 0.0685
(1 row)

Time: 3.626 ms

market=# SELECT attname, (most_common_vals::text::text[])[4] AS value, most_common_freqs[4] AS freq FROM pg_stats WHERE tablename = 'customers' AND attname = 'state';
 attname | value |  freq  
---------+-------+--------
 state   | PR    | 0.0685
(1 row)

Time: 1.391 ms

market=# EXPLAIN SELECT * FROM customers WHERE city = 'Curitiba' AND state = 'PR';
                                  QUERY PLAN                                  
------------------------------------------------------------------------------
 Gather  (cost=1000.00..5141.51 rows=938 width=59)
   Workers Planned: 1
   ->  Parallel Seq Scan on customers  (cost=0.00..4047.71 rows=552 width=59)
         Filter: ((city = 'Curitiba'::text) AND (state = 'PR'::text))
(4 rows)

Time: 1.072 ms

market=# SELECT count(*) FROM customers WHERE city = 'Curitiba' AND state = 'PR';
 count 
-------
 13578
(1 row)

Time: 19.107 ms
```

Cada metade está certa. Curitiba é **0.0685** dos clientes, e PR também, porque Curitiba é a única
cidade do Paraná aqui. Mas o plano espera **938** clientes, 0,0685 × 0,0685 × 200.000, como se saber a
cidade não dissesse nada sobre o estado. Há **13.578**: a estimativa é catorze vezes pequena demais,
e nada nela melhoraria com uma amostra maior, porque as duas frações já estão certas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Dois quadrados, cada um representando os 200.000 clientes. No da esquerda, o que o planejador supõe: uma faixa vertical estreita para a cidade Curitiba, 6,85% dos clientes, e uma faixa horizontal estreita para o estado PR, também 6,85%, cruzando-se num quadradinho de 0,47%, que são 938 clientes. No da direita, o que a tabela tem: a faixa de Curitiba inteira é PR, então a interseção é a faixa toda, 13.578 clientes.\"><text x=\"160.0\" y=\"24\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">o que o planejador supõe</text><rect x=\"60\" y=\"44\" width=\"200\" height=\"200\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"520.0\" y=\"24\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">o que a tabela tem</text><rect x=\"420\" y=\"44\" width=\"200\" height=\"200\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"120\" y=\"44\" width=\"13.7\" height=\"200\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"60\" y=\"164\" width=\"200\" height=\"13.7\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"120\" y=\"164\" width=\"13.7\" height=\"13.7\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"139.7\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">city = Curitiba, 6,85%</text><text x=\"266\" y=\"170.85\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">state = PR,</text><text x=\"266\" y=\"184.85\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6,85%</text><path d=\"M133.7 177.7 L160.0 268\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><text x=\"164\" y=\"272\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">0,47%: 938 linhas</text><rect x=\"480\" y=\"44\" width=\"13.7\" height=\"200\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"499.7\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Curitiba, toda ela PR</text><path d=\"M493.7 200 L520.0 268\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><text x=\"524\" y=\"272\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">6,85%: 13.578 linhas</text></svg>", "caption": "A suposição de independência, em escala. Multiplicar duas frações está certo quando as colunas não têm relação; para uma cidade e seu estado, deixa a interseção catorze vezes pequena demais.", "same": ["state = PR,"]}
```

Uma contagem catorze vezes pequena demais é o tipo de erro que a aula 6 seguiu através de um plano. Um scan que o planejador acredita devolver 938 linhas é um bom candidato para o lado de dentro de um
nested loop, e com 13.578 linhas esse laço roda catorze vezes mais do que foi custeado. Esquemas reais
estão cheios desses pares: um CEP e sua cidade, um produto e sua categoria, uma data e seu trimestre
fiscal, uma coluna e outra calculada a partir dela.

## `CREATE STATISTICS`

O planejador não consegue descobrir sozinho uma relação entre duas colunas, porque o `ANALYZE` olha
uma coluna de cada vez. Você precisa nomear o par, e o `CREATE STATISTICS` faz isso. Ele cria um
objeto que manda o `ANALYZE` medir também as duas colunas juntas:

```
market=# CREATE STATISTICS customers_city_state (dependencies, mcv) ON city, state FROM customers;
CREATE STATISTICS
Time: 2.461 ms

market=# ANALYZE customers;
ANALYZE
Time: 191.553 ms

market=# EXPLAIN SELECT * FROM customers WHERE city = 'Curitiba' AND state = 'PR';
                           QUERY PLAN                            
-----------------------------------------------------------------
 Seq Scan on customers  (cost=0.00..5283.00 rows=13320 width=59)
   Filter: ((city = 'Curitiba'::text) AND (state = 'PR'::text))
(2 rows)

Time: 0.970 ms

market=# SELECT statistics_name, attnames, dependencies FROM pg_stats_ext WHERE tablename = 'customers';
   statistics_name    |   attnames   |               dependencies               
----------------------+--------------+------------------------------------------
 customers_city_state | {city,state} | {"4 => 5": 1.000000, "5 => 4": 0.421733}
(1 row)

Time: 3.503 ms
```

A mesma consulta, depois de um `ANALYZE`: **13.320** esperados onde há 13.578, 2% de distância. O
plano mudou junto, de um scan paralelo para um simples: um número diferente de linhas é um conjunto
diferente de custos, e o plano mais barato mudou de lugar.

A instrução pede dois tipos de medida entre parênteses, e `pg_stats_ext` mostra o que eles acharam:

- **`dependencies`** mede o quanto uma coluna determina a outra. Os números são as posições das
  colunas na tabela, então `4` é `city` e `5` é `state`. `"4 => 5": 1.000000` diz que saber a cidade
  fixa o estado em toda linha da amostra; `"5 => 4": 0.421733` diz que o estado fixa a cidade em
  menos da metade das vezes, porque SP e RJ têm várias cidades cada. Quando as duas colunas aparecem
  numa cláusula `WHERE`, o planejador usa a dependência para parar de multiplicar.
- **`mcv`** guarda uma lista dos **pares** de valores mais comuns, com as frequências, do jeito que a
  lista da seção 03 faz para valores sozinhos. Para um par que está na lista, a estimativa é lida
  direto dela em vez de ser multiplicada.

## O terceiro tipo: `ndistinct`

Os objetos acima consertam uma cláusula `WHERE`. Um `GROUP BY` sobre as duas colunas precisa de outra
coisa:

```
market=# EXPLAIN SELECT city, state, count(*) FROM customers GROUP BY city, state;
                                            QUERY PLAN                                             
---------------------------------------------------------------------------------------------------
 Finalize GroupAggregate  (cost=5346.56..5360.87 rows=108 width=21)
   Group Key: city, state
   ->  Gather Merge  (cost=5346.56..5358.98 rows=108 width=21)
         Workers Planned: 1
         ->  Sort  (cost=4346.55..4346.82 rows=108 width=21)
               Sort Key: city, state
               ->  Partial HashAggregate  (cost=4341.82..4342.90 rows=108 width=21)
                     Group Key: city, state
                     ->  Parallel Seq Scan on customers  (cost=0.00..3459.47 rows=117647 width=13)
(9 rows)

Time: 2.585 ms
```

**108 grupos** esperados: 12 cidades vezes 9 estados, toda combinação suposta possível. Há doze, um
por cidade. Nem `dependencies` nem `mcv` são usados para contar grupos, então o objeto precisa do seu
terceiro tipo, `ndistinct`, que guarda o número de combinações distintas. Os tipos de um objeto são
fixados quando ele é criado, então ele é apagado e criado de novo com os três:

```
market=# DROP STATISTICS customers_city_state;
DROP STATISTICS
Time: 1.498 ms

market=# CREATE STATISTICS customers_city_state (ndistinct, dependencies, mcv) ON city, state FROM customers;
CREATE STATISTICS
Time: 1.335 ms

market=# ANALYZE customers;
ANALYZE
Time: 161.593 ms

market=# EXPLAIN SELECT city, state, count(*) FROM customers GROUP BY city, state;
                                            QUERY PLAN                                             
---------------------------------------------------------------------------------------------------
 Finalize GroupAggregate  (cost=5342.17..5343.76 rows=12 width=21)
   Group Key: city, state
   ->  Gather Merge  (cost=5342.17..5343.55 rows=12 width=21)
         Workers Planned: 1
         ->  Sort  (cost=4342.16..4342.19 rows=12 width=21)
               Sort Key: city, state
               ->  Partial HashAggregate  (cost=4341.82..4341.94 rows=12 width=21)
                     Group Key: city, state
                     ->  Parallel Seq Scan on customers  (cost=0.00..3459.47 rows=117647 width=13)
(9 rows)

Time: 0.759 ms
```

**12 grupos**, o número certo. Sem lista de tipos nenhuma, o `CREATE STATISTICS` constrói os três, que
é o jeito usual de escrevê-lo; esta aula os nomeou para mostrar o que cada um faz.

## O que custa, e quando vale a pena

Um objeto de estatísticas estendidas custa algum tempo a cada `ANALYZE` da tabela e uma linha pequena
no catálogo, e só ajuda consultas que filtram ou agrupam por aquelas colunas juntas. Então não é algo
para criar para todo par de colunas. Crie um quando um plano mostrar uma diferença grande entre linhas
estimadas e reais numa condição sobre duas colunas, e as duas colunas forem ligadas pelo que
significam. É a situação que a aula 6 ensinou você a reconhecer, e este é o conserto dela.

## De volta ao início da aula 3

Esta aula deixou três coisas no `market`: o alvo e a configuração de `n_distinct` em
`order_lines.order_id`, e o objeto de estatísticas em `customers`. Feche o `psql` e devolva o banco ao
estado que a aula 2 ensinou:

```sh
~/reset-market.sh
```
