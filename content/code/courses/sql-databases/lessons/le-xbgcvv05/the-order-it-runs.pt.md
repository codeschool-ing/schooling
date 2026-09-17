---
title: A ordem em que você escreve, e a ordem em que roda
version: 1
---

Uma ideia primeiro, porque ela explica a maior parte dos erros confusos que você vai encontrar no
próximo ano.

**Você escreve as cláusulas numa ordem. O banco as roda em outra.**

```sql
SELECT   name, price                  -- 5. e finalmente, escolhe as colunas
FROM     products                     -- 1. primeiro, quais linhas existem
WHERE    price > 20                   -- 2. joga fora as que falham
GROUP BY category                     -- 3. aula 6
HAVING   count(*) > 1                 -- 4. aula 6
ORDER BY price DESC                   -- 6. arruma o que sobreviveu
LIMIT    10;                          -- 7. pega as primeiras
```

Os números são a ordem em que de fato acontece. `FROM` vem primeiro porque nada pode ser filtrado
antes de se saber o que existe. `SELECT` — a cláusula que você escreveu primeiro — acontece perto do
**fim**.

## O que isso explica

Dê um nome novo a uma coluna e tente usá-lo:

```sql
SELECT price * 1.23 AS gross
FROM   products
WHERE  gross > 100;
```

```
ERROR:  column "gross" does not exist
LINE 3: WHERE  gross > 100;
               ^
```

`gross` é inventado pelo `SELECT`, e o `WHERE` rodou antes do `SELECT`. Quando o filtro estava sendo
avaliado o nome não existia. O erro está correto e não diz nada sobre o motivo.

Repita a expressão em vez disso:

```sql
SELECT price * 1.23 AS gross
FROM   products
WHERE  price * 1.23 > 100;
```

## E o que é diferente no ORDER BY

```sql
SELECT price * 1.23 AS gross
FROM   products
ORDER BY gross DESC;
```

Isso funciona. O `ORDER BY` roda **depois** do `SELECT`, então quando ele procura `gross`, o nome
existe.

Então a regra não é "apelidos nunca funcionam". É exatamente:

> **Um apelido do `SELECT` é usável no `ORDER BY`, e não no `WHERE`, `GROUP BY` nem `HAVING`.**

O que não é uma esquisitice para decorar, uma vez que você enxerga a ordem. É a ordem.

## A sequência inteira, uma vez

| | cláusula | o que faz |
|---|---|---|
| 1 | `FROM` / `JOIN` | reúne as linhas a considerar |
| 2 | `WHERE` | descarta linhas que falham um teste |
| 3 | `GROUP BY` | colapsa as sobreviventes em grupos |
| 4 | `HAVING` | descarta grupos inteiros |
| 5 | `SELECT` | calcula as colunas de saída, e as nomeia |
| 6 | `ORDER BY` | arruma o resultado |
| 7 | `LIMIT` / `OFFSET` | pega uma fatia dele |

Mais duas consequências que vale ter agora, e as duas aparecem em aulas seguintes:

**`WHERE` filtra linhas, `HAVING` filtra grupos.** Não são alternativas; rodam em momentos
diferentes sobre coisas diferentes. Aula 6.

**`LIMIT` é o último**, então ele pega uma fatia de um resultado já ordenado. Ele não faz o banco
parar cedo de nenhum jeito sobre o qual você possa raciocinar — e sem `ORDER BY` ele pega uma fatia
arbitrária de um arranjo arbitrário, que é a seção `limit-and-paging`.

## É um modelo, não uma promessa sobre a máquina

Um cuidado que importa a partir da aula 10.

A lista acima é a ordem **lógica** — o que a resposta é definida como sendo. O banco tem liberdade
para fazer o trabalho em qualquer ordem que produza a mesma resposta, e vai: ele pode usar um índice
para evitar ordenar, filtrar enquanto lê em vez de depois, ou parar de ler quando o `LIMIT` estiver
satisfeito.

Essa liberdade é o assunto inteiro do plano de execução. O que ele nunca faz é mudar a resposta.
Então use esta ordem para raciocinar sobre **o que uma consulta significa**, e o plano da aula 10
para raciocinar sobre **quanto ela custa**. Confundir as duas é como as pessoas acabam acreditando
que rearranjar as cláusulas deixa uma consulta mais rápida, o que não deixa, porque você não mudou o
que pediu.
