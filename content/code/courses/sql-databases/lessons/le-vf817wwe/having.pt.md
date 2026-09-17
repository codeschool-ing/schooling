---
title: HAVING filtra grupos, WHERE filtra linhas
version: 1
---

Duas aulas prometeram esta seção, então aqui está a frase que elas prometiam:

> **`WHERE` roda antes do agrupamento e decide quais linhas entram. `HAVING` roda depois dele e
> decide quais grupos saem.**

Todo o resto sobre o `HAVING` decorre disso, inclusive por que ele existe — quando você já tem uma
contagem, as linhas que foram contadas sumiram, e o `WHERE` terminou faz tempo.

A ordem de execução da aula 4, estendida com as duas cláusulas que esta aula acrescenta:

```
FROM      quais linhas existem
WHERE     joga linhas fora        <- nenhuma agregação aqui: nenhuma foi calculada
GROUP BY  separa em pilhas
HAVING    joga pilhas fora        <- agregações aqui, porque agora elas existem
SELECT    calcula as colunas
ORDER BY  ordena o resultado
LIMIT     pega algumas
```

Leia essa lista e o erro que você está prestes a encontrar deixa de ser misterioso:

```sql
SELECT customer_id FROM orders WHERE count(*) > 3 GROUP BY customer_id;
```

```
ERROR:  aggregate functions are not allowed in WHERE
```

Quando o `WHERE` roda, não há grupos e não há contagem — há uma linha, sozinha, e `count(*)` de uma
linha não é uma pergunta. Mude de lugar:

```sql
SELECT   customer_id, count(*)
FROM     orders
GROUP BY customer_id
HAVING   count(*) > 3;
```

## A consulta que precisa dos dois, que é a maioria delas

*"Clientes com mais de três pedidos em 2026."* Duas condições, e elas vão em cláusulas diferentes,
porque uma é sobre uma linha e a outra é sobre uma pilha:

```sql
SELECT   customer_id, count(*) AS orders_2026
FROM     orders
WHERE    placed_at >= DATE '2026-01-01'
  AND    placed_at <  DATE '2027-01-01'
GROUP BY customer_id
HAVING   count(*) > 3;
```

O ano é uma propriedade de um pedido, então é `WHERE`. A contagem é uma propriedade da pilha do
cliente, então é `HAVING`. Troque os dois e um deles é erro e o outro é outra pergunta inteiramente
— `HAVING max(placed_at) >= DATE '2026-01-01'` daria os clientes com mais de três pedidos **na
vida**, que também compraram pelo menos uma vez em 2026. É uma pergunta de verdade, e não é a de
cima.

Que é a distinção honesta para levar embora: as duas cláusulas não são dois jeitos de escrever um
filtro. Mudar onde uma condição fica muda o sentido, não o estilo.

## Um `HAVING` sem agregação dentro

É legal e quase sempre é um erro:

```sql
SELECT   customer_id, count(*)
FROM     orders
GROUP BY customer_id
HAVING   customer_id <> 7;          -- funciona, e pertence ao WHERE
```

Dá a resposta certa. Também agrupa cada um dos pedidos do cliente 7, calcula a contagem deles, e
depois joga o grupo fora. Filtrar no `WHERE` teria pulado essas linhas antes de o agrupamento
começar, o que é menos trabalho — às vezes muito menos, porque um `WHERE` sobre uma coluna indexada
pode evitar ler as linhas, e o `HAVING` nunca pode.

**A regra prática: se a condição pode ser escrita no `WHERE`, escreva no `WHERE`.** `HAVING` é para
condições que precisam de uma agregação, e para mais nada.

## `HAVING` sem `GROUP BY`

Também é legal, e de vez em quando é exatamente certo:

```sql
SELECT sum(total) FROM orders WHERE customer_id = 7 HAVING sum(total) > 1000;
```

Sem `GROUP BY`, a tabela inteira é um grupo, então isso devolve **uma linha ou nenhuma** — o total,
se ele passar do limite, e nada se não passar. É o único caso em que uma consulta com agregação
pode devolver zero linhas, e é um truque útil para "me avise só se importar".

## Apelidos, que não são portáveis aqui

```sql
SELECT   customer_id, count(*) AS orders
FROM     orders
GROUP BY customer_id
HAVING   orders > 3;             -- MySQL e SQLite: sim.  PostgreSQL: erro.
```

MySQL e SQLite deixam você nomear a coluna de saída. O PostgreSQL não, mesmo permitindo exatamente
isso no `GROUP BY` — o que é inconsistente, e é culpa do padrão, não deles. As respostas portáveis
são repetir a expressão, ou calcular a agregação numa subconsulta e filtrar por fora, o que lê
melhor conforme a consulta cresce e é assunto da aula 7:

```sql
SELECT *
FROM  (SELECT customer_id, count(*) AS orders FROM orders GROUP BY customer_id) t
WHERE t.orders > 3;
```

Repare no que aconteceu: uma vez que a agregação virou coluna de uma consulta interna, o filtro de
fora é um `WHERE` comum de novo. `HAVING` não é um tipo especial de filtro — é um `WHERE` para um
resultado que você ainda não terminou de calcular.
