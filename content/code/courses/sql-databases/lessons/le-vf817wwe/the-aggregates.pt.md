---
title: As funções de agregação, e a única coisa que todas fazem com NULL
version: 1
---

Uma função de agregação recebe muitas linhas e devolve um valor. É a ideia inteira, e as cinco que
você vai usar não têm nada de notável:

```sql
SELECT count(*)      AS orders,
       sum(total)    AS revenue,
       avg(total)    AS average,
       min(ordered_on) AS first_order,
       max(ordered_on) AS last_order
FROM   orders;
```

Volta uma linha. Não uma linha por pedido — **uma linha, para a tabela inteira**, porque não há
`GROUP BY`, e a próxima seção é o que acontece quando há.

`min` e `max` não são só para números: funcionam com qualquer coisa que o banco saiba ordenar, o que
inclui texto e datas. `min(name)` é o primeiro nome em ordem alfabética, e `max(ordered_on)` é o
pedido mais recente, que é como você pergunta "quando esse cliente comprou pela última vez" sem
ordenar nada com as próprias mãos.

## A regra que está por baixo de todas elas

> **Toda agregação ignora as linhas em que o argumento dela é nulo. Todas, menos `count(*)`.**

Essa única frase produz quase toda esta seção, e a consequência mais cara é uma que as pessoas
carregam por anos sem perceber.

Dez avaliações, três ainda não dadas:

```sql
SELECT count(*)      FROM reviews;           -- 10
SELECT count(rating) FROM reviews;           -- 7
SELECT sum(rating)   FROM reviews;           -- 28
SELECT avg(rating)   FROM reviews;           -- 4.0
```

`28 / 10` é 2,8. A média diz 4,0. Nenhum dos dois números está errado — eles respondem perguntas
diferentes, e só uma delas foi feita em voz alta.

```
avg(rating)  =  sum(rating) / count(rating)      a média das notas que existem
28 / count(*)                                    a média se uma nota ausente fosse zero
```

**E nada na saída diz quais linhas ela contou.** Uma coluna preenchida em 99% dá uma média quase
certa, então o defeito fica invisível até o mês em que alguém acrescenta um campo novo e a coluna
está 40% preenchida. Aí a média se move e ninguém sabe dizer por quê.

Se um valor ausente realmente deve contar como zero, diga isso, e diga onde um leitor consiga ver:

```sql
SELECT avg(coalesce(rating, 0)) FROM reviews;    -- 2.8
```

Agora a afirmação está na consulta, e não na cabeça de alguém.

## `count(*)` contra `count(coluna)`

São funções diferentes que por acaso dividem um nome, e a diferença é exatamente a regra acima:

| escrito | conta |
|---|---|
| `count(*)` | linhas — não tem argumento, então não há o que ser nulo |
| `count(rating)` | linhas em que `rating` não é nulo |
| `count(DISTINCT rating)` | os valores distintos, sem nulo entre eles |
| `count(1)` | linhas, igualzinho a `count(*)`, e não mais rápido |

`count(1)` merece uma frase porque você vai encontrá-lo em código antigo e alguém vai lhe dizer que
é mais rápido. Não é, em nenhum banco que ainda receba manutenção; o planejador trata os dois do
mesmo jeito. Escreva `count(*)`, que diz o que quer dizer.

## Soma sobre nenhuma linha não é zero

A assimetria que quebra relatórios:

```sql
SELECT count(*), sum(total) FROM orders WHERE customer_id = 999;
```

Para um cliente sem pedidos isso é `0` e **`NULL`** — não `0` e `0`. `count` começa em zero e fica
lá; `sum` não tem o que somar e não tem opinião, então devolve desconhecido.

É defensável, e ainda assim cai numa divisão, num total, ou num template que imprime a palavra
`null` para um cliente. A correção é uma função:

```sql
SELECT coalesce(sum(total), 0) FROM orders WHERE customer_id = 999;   -- 0
```

Use sempre que uma soma for para qualquer lugar que não os seus próprios olhos. Vale igual para
`avg`, `min` e `max`, que são todos nulos sobre um conjunto vazio.

E repare no formato disso: **uma consulta com agregação e sem `GROUP BY` sempre devolve exatamente
uma linha**, mesmo com a tabela vazia ou com o `WHERE` não casando nada. Zero linhas entram, uma
linha sai. É o oposto de todo o resto do SQL e de vez em quando é útil — uma consulta de painel que
precisa mostrar um número sempre vai ter um número para mostrar, depois que você a envolveu em
`coalesce`.

## Inteiros dividem como inteiros

```sql
SELECT sum(quantity) / count(*) FROM order_lines;
```

Se os dois forem inteiros, alguns bancos fazem divisão inteira: 7 itens em 2 pedidos dá `3`, não
`3,5`, e o arredondamento é silencioso. `avg()` não tem esse problema — promove para um tipo
decimal — o que é mais uma razão para usá-la em vez de dividir à mão. Quando precisar dividir,
converta:

```sql
SELECT sum(quantity)::numeric / count(*) FROM order_lines;   -- PostgreSQL
SELECT sum(quantity) * 1.0  / count(*) FROM order_lines;     -- portável
```

## As outras, rapidamente

Vale saber que existem, porque cada uma substitui um laço que alguém escreveria no código da
aplicação:

```sql
string_agg(name, ', ' ORDER BY name)   -- os nomes, juntados numa string só
array_agg(id)                          -- os ids, como um array
bool_or(is_paid)                       -- verdadeiro se alguma linha for
bool_and(is_paid)                      -- verdadeiro só se toda linha for
stddev(total), variance(total)         -- a dispersão, não só o meio
```

`string_agg` é a primeira que você vai querer: "as etiquetas deste artigo, separadas por vírgula" é
uma linha aqui e uma segunda consulta mais um laço em qualquer outro lugar. MySQL e MariaDB
escrevem `group_concat`; SQLite também `group_concat`. O `ORDER BY` dentro dos parênteses não é erro
de digitação — uma agregação que monta uma lista pode receber a ordem em que montar, e sem ele a
ordem é a que o banco achou conveniente.
