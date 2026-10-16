---
title: Por lista e por hash
version: 1
---

Faixa é o tipo que você vai usar mais, porque o tempo é a fatia pela qual a maioria das tabelas
envelhece. Os outros dois respondem a perguntas diferentes, e cada um tem um erro fácil de cometer.

## Por lista: uma partição por valor nomeado

O particionamento por **lista** dá a cada partição um conjunto de valores da chave. Serve para uma
coluna com poucos valores conhecidos que importam para o modo como os dados são guardados: um país
cujas linhas precisam ficar num lugar, um cliente grande o bastante para merecer tabela própria, um
status cujas linhas são tratadas de outro jeito. Em `events`, os tipos se dividem naturalmente em
navegar e comprar:

```
market=# CREATE TABLE events_by_kind (LIKE events_by_month) PARTITION BY LIST (kind);
CREATE TABLE
Time: 6.983 ms

market=# CREATE TABLE events_browse PARTITION OF events_by_kind FOR VALUES IN ('view', 'search');
CREATE TABLE
Time: 5.028 ms

market=# CREATE TABLE events_buy PARTITION OF events_by_kind FOR VALUES IN ('cart', 'checkout');
CREATE TABLE
Time: 4.037 ms

market=# INSERT INTO events_by_kind SELECT * FROM events;
INSERT 0 5000000
Time: 12876.632 ms (00:12.877)

market=# SELECT tableoid::regclass AS partition, kind, count(*) FROM events_by_kind GROUP BY 1, 2 ORDER BY 1, 2;
   partition   |   kind   |  count  
---------------+----------+---------
 events_browse | search   |  999127
 events_browse | view     | 3000104
 events_buy    | cart     |  500558
 events_buy    | checkout |  500211
(4 rows)

Time: 740.017 ms
```

`IN ('view', 'search')` e `IN ('cart', 'checkout')`: uma partição fica com quatro milhões de linhas e
a outra com um milhão. Uma lista não tenta equilibrar nada; ela põe cada valor **onde você disse**.
Esse é o objetivo quando o motivo é administrativo — os eventos de compra guardados por cinco anos e
os de navegação por noventa dias, cada partição removida no seu próprio calendário — e um problema
quando alguém esperava metades iguais.

O erro com uma lista é o valor que ninguém listou. Um tipo novo, `wishlist`, seria recusado
exatamente como a linha de março na seção 03, no dia em que a aplicação começasse a mandá-lo. Uma
partição padrão, na seção 05, o pega, e uma partição por lista é o lugar onde ela mais vale a pena.

## Por hash: linhas espalhadas por uma função da chave

O particionamento por **hash** dá a cada partição um resto: a chave passa por uma função de hash, o
resultado é dividido pelo **módulo** (modulus), e a linha vai para a partição cujo **resto**
(remainder) bate. Ninguém escolhe onde um dado cliente cai, e com uma chave de muitos valores as
linhas se espalham por igual. Serve para dividir uma tabela grande em pedaços de tamanho parecido
quando não há uma fatia que envelheça, de modo que cada pedaço seja menor para o vacuum, para
indexar e para reconstruir. É também o arranjo sobre o qual a aula 19 constrói quando os pedaços vão
para servidores diferentes.

Quatro partições por `customer_id`:

```
market=# CREATE TABLE events_by_customer (LIKE events_by_month) PARTITION BY HASH (customer_id);
CREATE TABLE
Time: 10.235 ms

market=# CREATE TABLE events_by_customer_0 PARTITION OF events_by_customer FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE
Time: 6.812 ms

market=# CREATE TABLE events_by_customer_1 PARTITION OF events_by_customer FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE
Time: 6.081 ms

market=# CREATE TABLE events_by_customer_2 PARTITION OF events_by_customer FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE
Time: 5.215 ms

market=# CREATE TABLE events_by_customer_3 PARTITION OF events_by_customer FOR VALUES WITH (MODULUS 4, REMAINDER 3);
CREATE TABLE
Time: 5.453 ms

market=# INSERT INTO events_by_customer SELECT * FROM events;
INSERT 0 5000000
Time: 12961.050 ms (00:12.961)

market=# SELECT tableoid::regclass AS partition, count(*), count(customer_id) AS with_customer FROM events_by_customer GROUP BY 1 ORDER BY 1;
      partition       |  count  | with_customer 
----------------------+---------+---------------
 events_by_customer_0 | 2372458 |        871797
 events_by_customer_1 |  880155 |        880155
 events_by_customer_2 |  873158 |        873158
 events_by_customer_3 |  874229 |        874229
(4 rows)

Time: 505.837 ms
```

Três partições com uns 875 mil linhas, que é o espalhamento uniforme que um hash promete. E uma com
**2372458**, quase o triplo das outras. A coluna `with_customer` diz por quê: a partição 0 guarda os
eventos dos seus 871797 clientes **mais todo evento sem cliente**. Três em cada dez eventos são de
visitantes sem conta, `customer_id` é `NULL` em todos eles, e todo `NULL` vai para a mesma partição.

Esse é o erro do hash, e a forma geral vale guardar: **um hash espalha valores, não linhas.** Um
valor muito comum, aqui o `NULL`, ou o vendedor 1, a loja do próprio marketplace, se isto fosse
`orders` por vendedor, põe todas as suas linhas num lugar só, não importa quantas partições existam.
Antes de escolher uma chave de hash, conte os valores mais comuns; a aula 7 mostrou onde as
estatísticas já os guardam.

As duas tabelas eram só para olhar. Remova-as, para que `market` fique com uma única tabela
particionada, a que a aula 18 usa:

```
market=# DROP TABLE events_by_kind, events_by_customer;
DROP TABLE
Time: 830.238 ms
```

## Escolhendo a chave

A chave decide todo o resto, e não muda sem reconstruir a tabela. Três perguntas a decidem, nesta
ordem:

- **Como as linhas saem?** Se as linhas antigas são removidas por data, a chave é a data e o tipo é
  faixa, seja o que for o resto. É o trabalho da seção 02.
- **Pelo que a maioria das consultas filtra?** A poda só funciona na chave, então uma chave que as
  consultas importantes nunca mencionam deixa toda consulta lendo todas as partições.
- **Algum valor é enorme?** Uma lista o põe onde você diz; um hash o põe num lugar que você não
  escolheu, junto com tudo o mais que divide a partição com ele.

`events` responde à primeira pergunta com `at`, e é por isso que `events_by_month` é cortada por
faixa. O PostgreSQL também deixa uma partição ser particionada de novo, um mês por hash por exemplo,
e de vez em quando isso é o certo; multiplica a quantidade de partições, e a aula 18 mede quanto
custam as quantidades de partições.
