---
title: A moldura, e por que acrescentar ORDER BY muda a resposta
version: 1
---

Acrescente um `ORDER BY` dentro do `OVER` e o número muda. Não a ordem das linhas — o número:

```sql
SELECT id, ordered_on, total,
       sum(total) OVER (PARTITION BY customer_id)                    AS a,
       sum(total) OVER (PARTITION BY customer_id ORDER BY ordered_on) AS b
FROM   orders;
```

A coluna `a` é o total do cliente, igual em todas as linhas dele. A coluna `b` sobe: 34,90, 85,90,
97,90. É um **total acumulado**.

Ninguém pediu um total acumulado. Ele apareceu por causa de um padrão que ninguém menciona.

## Toda janela tem uma moldura

`PARTITION BY` escolhe as linhas que a função pode ver. Dentro dessa partição, a **moldura** escolhe
quantas delas contam para a linha que está sendo calculada — e a moldura tem um padrão que depende
de você ter escrito ou não um `ORDER BY`:

| escrito | moldura padrão | significado |
|---|---|---|
| `OVER (PARTITION BY x)` | a partição inteira | toda linha vê o mesmo valor |
| `OVER (PARTITION BY x ORDER BY y)` | `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` | tudo até aqui |

Então o `ORDER BY` dentro de uma janela faz duas coisas de uma vez: diz em que ordem as linhas estão
e — trocando a moldura padrão — transforma um total num total acumulado. É muito significado para
duas palavras, e é por isso que esta é a seção a que as pessoas voltam.

Se você quer a ordem e **não** o acúmulo, diga a moldura você mesmo:

```sql
sum(total) OVER (PARTITION BY customer_id ORDER BY ordered_on
                 ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
```

Agora é o total do cliente de novo, em toda linha, com a ordenação ainda disponível para as funções
da próxima seção, que precisam dela.

## Escrever uma moldura

```sql
ROWS BETWEEN <início> AND <fim>
```

onde cada ponta é `UNBOUNDED PRECEDING`, `n PRECEDING`, `CURRENT ROW`, `n FOLLOWING` ou `UNBOUNDED
FOLLOWING`. As duas que você mais vai escrever:

```sql
-- um total acumulado, dito em voz alta em vez de herdado de um padrão
sum(total) OVER (ORDER BY ordered_on ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)

-- uma média móvel de quatro dias: esta linha e as três anteriores
avg(total) OVER (ORDER BY day ROWS BETWEEN 3 PRECEDING AND CURRENT ROW)
```

A média móvel merece um aviso. No começo da partição não existem três linhas anteriores, então a
primeira linha tira a média de um valor, a segunda de dois, e nada diz isso. Esses números iniciais
são mais ruidosos que o resto e parecem idênticos num gráfico. Se isso importa, conte as linhas da
moldura ao lado — `count(*) OVER (mesma moldura)` — e descarte ou marque as que estiverem abaixo de
quatro.

## `ROWS` contra `RANGE`, que é a sutil

`ROWS` conta linhas. `RANGE` conta **valores da expressão do `ORDER BY`**, o que significa que toda
linha com o mesmo valor — os seus pares — entra ou sai junto.

Dois pedidos feitos no mesmo dia:

```
dia      total   ROWS acumulado   RANGE acumulado
dia 1    10      10               10
dia 2    20      30               50
dia 2    30      60               50
dia 3     5      65               55
```

`ROWS` dá às duas linhas do dia 2 acumulados diferentes, na ordem que o banco quiser. `RANGE` dá o
mesmo às duas, porque para uma linha do dia 2 a moldura termina no fim do dia 2.

Nenhum dos dois está errado. `RANGE` é possivelmente mais honesto — as linhas estão empatadas, então
um acumulado que as distingue está inventando uma ordem que o dado não tem. Mas **`RANGE` é o
padrão**, e um total acumulado que repete um valor em linhas empatadas surpreende quem esperava
`ROWS`. Escreva o que você quer dizer. Quando a coluna do `ORDER BY` é única, os dois são idênticos e
a questão não se coloca.

`RANGE` também aceita um deslocamento, e este é o caso em que ele é claramente a ferramenta certa:

```sql
sum(total) OVER (ORDER BY ordered_on
                 RANGE BETWEEN INTERVAL '7 days' PRECEDING AND CURRENT ROW)
```

Sete **dias** corridos, não sete linhas corridas — a diferença importa no instante em que um dia não
tem pedidos, porque `ROWS 6 PRECEDING` iria silenciosamente mais para trás até achar seis linhas. A
forma com deslocamento precisa de exatamente uma coluna no `ORDER BY` e de um tipo que ela saiba
subtrair, então uma data ou um número. O PostgreSQL tem; o MySQL 8 tem `RANGE` com deslocamentos
numéricos; o SQLite também tem `RANGE` com deslocamentos.

O PostgreSQL acrescenta `GROUPS`, que conta valores *distintos* do `ORDER BY` — `GROUPS BETWEEN 2
PRECEDING AND CURRENT ROW` é "este dia e os dois dias com dado antes dele". É a rara, e é a resposta
certa quando as suas linhas já são uma por balde.

## A regra para levar

> **Um `ORDER BY` dentro do `OVER` lhe dá uma janela acumulativa, a menos que você diga outra
> coisa.**

Quando uma função de janela devolve um número que cresce página abaixo e você esperava uma
constante, esse padrão é o motivo — todas as vezes.
