---
title: O que o ANALYZE deixa para trás
version: 1
---

O planejador não olha as suas linhas quando planeja uma consulta. Nem poderia: contar quantos
pedidos o vendedor 42 tem, para decidir como achar os pedidos do vendedor 42, custaria tanto quanto
a própria consulta. O que ele lê no lugar disso é um **resumo por coluna**, escrito pelo `ANALYZE` a
partir de uma amostra da tabela e guardado no catálogo até o próximo `ANALYZE` substituí-lo. Toda
estimativa de todo plano deste curso saiu desse resumo, e esta aula o lê.

A crença que vale abandonar primeiro é a de que o resumo é uma cópia pequena dos dados. Não é. É um
punhado de números e duas listas curtas, no máximo cem valores comuns e cento e um limites de
histograma por coluna na configuração de fábrica, feitos a partir de uma amostra cujo tamanho uma
configuração decide:

```
market=# SHOW default_statistics_target;
 default_statistics_target 
---------------------------
 100
(1 row)

Time: 0.498 ms
```

**100** é o padrão. O `ANALYZE` lê 300 linhas para cada unidade dele, então **30.000 linhas** de cada
tabela, tenha a tabela mil linhas ou dois milhões. A aula 6 olhou quando essa amostra é tirada e o
que acontece quando ela fica velha; esta aula trata do que se anota a partir dela.

## A view: `pg_stats`

O resumo mora na tabela de catálogo `pg_statistic`, num formato feito para o planejador e não para
pessoas. `pg_stats` é a view legível por cima dela, uma linha por coluna de cada tabela, e ela só
mostra as colunas que você tem permissão de ler. Esse filtro tem motivo. O resumo guarda **valores
reais da tabela**, os mais comuns copiados como estão, e uma view que os mostrasse a qualquer um
vazaria um salário ou um endereço de e-mail para um usuário que não pode consultar a própria coluna.

Os campos que importam para as estimativas são estes:

| campo | o que guarda |
|---|---|
| `null_frac` | a fração da amostra que era NULL |
| `n_distinct` | quantos valores diferentes a coluna tem: uma contagem, ou uma fração das linhas quando negativo |
| `most_common_vals` e `most_common_freqs` | os valores vistos com mais frequência, e a fração das linhas que cada um representa |
| `histogram_bounds` | o resto dos valores, cortado em baldes que guardam o mesmo número de linhas cada |
| `correlation` | o quanto a ordem dos valores segue a ordem das linhas no disco, de -1 a 1 |

Peça os campos curtos de `orders` e de `events`:

```
market=# SELECT attname, null_frac, n_distinct, correlation FROM pg_stats WHERE tablename = 'orders' ORDER BY attname;
   attname   | null_frac | n_distinct | correlation  
-------------+-----------+------------+--------------
 customer_id |         0 |     184161 | 0.0064027454
 id          |         0 |         -1 |            1
 placed_at   |         0 |         -1 |            1
 seller_id   |         0 |       1000 |   0.07900135
 status      |         0 |          4 |    0.9481103
 total_cents |         0 |      49324 |   0.00571455
(6 rows)

Time: 4.783 ms

market=# SELECT attname, null_frac, n_distinct FROM pg_stats WHERE tablename = 'events' ORDER BY attname;
   attname   | null_frac | n_distinct  
-------------+-----------+-------------
 at          |         0 |          -1
 customer_id |    0.3054 |      181538
 id          |         0 |          -1
 kind        |         0 |           4
 payload     |         0 | -0.77623963
(5 rows)

Time: 1.345 ms
```

Cada linha diz algo que você pode conferir no `market.sql` da aula 1.

- **`orders.id` e `placed_at` mostram `-1` valores distintos.** Um `n_distinct` negativo é uma
  fração das linhas, e -1 quer dizer "tantos quantas são as linhas": todo valor diferente. O
  planejador guarda isso como fração porque uma fração continua certa quando a tabela cresce, e uma
  contagem de dois milhões estaria errada no dia seguinte.
- **`status` tem 4 e `seller_id` 1000**, escritos como contagens, porque esses números não crescem
  com a tabela. O próprio `ANALYZE` escolhe entre as duas formas: escreve uma fração quando acredita
  que o número de valores cresce junto com as linhas.
- **`events.customer_id` tem `null_frac` de 0.3054.** O `market.sql` deixou três eventos em cada dez
  anônimos, e a amostra viu 30,5% deles. Qualquer condição sobre `customer_id` vale só para os outros
  69,5%, e é aí que a fração é usada.
- **`placed_at` e `id` têm correlação 1**, porque o `market.sql` gravou os pedidos na ordem em que
  foram feitos. `customer_id` tem 0.0064: os números de cliente estão espalhados pela tabela ao
  acaso. A seção 04 trata do que o planejador faz com isso.
- **`payload` em `events` tem `-0.77623963`**: uns 78% dos payloads são diferentes entre si. Dois
  números aleatórios num objeto JSON às vezes coincidem, e a amostra viu com que frequência.

Nenhum desses números foi contado na tabela inteira. Eles são o retrato de 30.000 linhas, e cada
seção desta aula é um desses campos e o jeito como um único número errado nele vira um plano
errado.

## De um campo a uma estimativa

A aritmética do planejador tem sempre a mesma forma. Para cada condição de uma cláusula `WHERE` ele
calcula uma **seletividade**, a fração das linhas que ele espera que passem, a partir dos campos
acima. Depois multiplica as seletividades das condições entre si e o resultado pelo número de
linhas da tabela, que vem de `reltuples` em `pg_class`, e não de `pg_stats`. A resposta é o número
`rows=` de um nó do plano.

Então, quando uma estimativa está errada, só há três lugares para olhar: a contagem de linhas da
tabela, o resumo de cada coluna e o passo que os combinou. A aula 6 cuidou do primeiro, uma contagem
de linhas que tinha envelhecido. As seções 03 a 05 aqui são o segundo, e a seção 06 é o terceiro,
aquele que nenhuma quantidade de `ANALYZE` conserta sozinha.
