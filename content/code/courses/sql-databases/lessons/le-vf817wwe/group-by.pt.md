---
title: GROUP BY, e a regra sobre quais colunas você pode selecionar
version: 1
---

`GROUP BY` separa as linhas em pilhas e roda as agregações uma vez por pilha.

```sql
SELECT   customer_id, count(*) AS orders, sum(total) AS spent
FROM     orders
GROUP BY customer_id;
```

Uma linha por cliente que tem pedido. Os mil pedidos sumiram: você tem os totais e não tem mais os
pedidos, e essa troca é o caráter inteiro do `GROUP BY`. A outra metade desta aula é a outra
ferramenta, que não faz essa troca.

## A regra

> **Toda coluna no `SELECT` tem que estar no `GROUP BY` ou dentro de uma agregação.**

Não é uma restrição arbitrária. Peça `o.total` ao lado de `count(*)` agrupado por cliente e você
pediu ao banco *um* total entre os três que a pilha contém, sem dizer qual. Não existe resposta,
então existe erro:

```
ERROR:  column "o.total" must appear in the GROUP BY clause
        or be used in an aggregate function
```

Essa mensagem é uma das mais úteis do SQL, porque quer dizer sempre a mesma coisa: **você pediu um
detalhe de um grupo que tem mais de um deles.** Decida qual você queria — `max(total)`, ou
`sum(total)`, ou a coluna acrescentada ao `GROUP BY` para as pilhas ficarem menores.

O MySQL passou anos sem exigir isso. Configurações antigas escolhiam um valor de uma linha qualquer
e o devolviam sem comentar, o que significava uma consulta de aparência correta devolvendo o total
de um cliente contra a data de outro. `ONLY_FULL_GROUP_BY` vem ligado desde o MySQL 5.7 e o
comportamento hoje é igual ao de todo mundo, mas você ainda vai encontrar consultas escritas sob as
regras antigas, e não dá para confiar nelas.

O PostgreSQL permite um relaxamento útil: agrupe pela **chave primária** de uma tabela e você pode
selecionar qualquer coluna dela, porque a chave já as determina.

```sql
SELECT   c.id, c.name, c.email, count(o.id)
FROM     customers c LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id;
```

`c.name` e `c.email` são legais aqui — um id de cliente é um cliente, então não há ambiguidade a
resolver. Economiza listar toda coluna que você quer exibir. O MySQL 8 faz a mesma análise; o
SQLite não reclama de nada, o que não é a mesma coisa que estar certo.

## Agrupar por mais de uma coisa

```sql
SELECT   customer_id, status, count(*)
FROM     orders
GROUP BY customer_id, status;
```

A pilha agora é a **combinação**: uma linha por cliente por status. Acrescentar uma coluna ao
`GROUP BY` sempre deixa os grupos menores e o resultado mais longo, e é esse o botão que você gira
quando um resumo está grosso demais.

A ordem das colunas no `GROUP BY` não importa — é um conjunto, não uma sequência. A ordem das
linhas que saem é indefinida sem um `ORDER BY`, exatamente como a aula 4 disse.

## Agrupar por uma expressão

O grupo não precisa ser uma coluna, e é assim que toda série temporal que você vier a construir é
feita:

```sql
SELECT   date_trunc('month', placed_at) AS month, sum(total)
FROM     orders
GROUP BY date_trunc('month', placed_at)
ORDER BY month;
```

Receita por mês, a partir de uma tabela que não sabe nada sobre meses. O mesmo formato dá por
semana, por dia, por hora. Outros bancos escrevem o truncamento de outro jeito — `DATE_FORMAT
(placed_at, '%Y-%m')` no MySQL, `strftime('%Y-%m', placed_at)` no SQLite — e a ideia é idêntica.

Repetir a expressão nas duas cláusulas é chato, e PostgreSQL, MySQL e SQLite deixam você escrever
`GROUP BY month`, nomeando a coluna de saída. Isso é uma extensão, e não SQL padrão, então vale
saber que é uma; todos eles também aceitam `GROUP BY 1`, a posição, que é compacta e vira um bug
silencioso no dia em que alguém insere uma coluna.

## Duas coisas que pegam as pessoas

**Todos os nulos formam um grupo só.** Agrupe por uma coluna anulável e toda linha em que ela é
nula acaba na mesma pilha, com `NULL` na saída. É o `GROUP BY` se afastando de propósito do `=`,
que nunca diz que dois desconhecidos são iguais — e é o que você quer, mas significa que uma linha
marcada `NULL` num relatório é um grupo de verdade e não um erro.

**Um grupo que não tem linhas não existe.** Não há linha para um cliente que nunca comprou, porque
um grupo é feito de linhas e esse cliente não contribuiu com nenhuma. Nenhuma quantidade de
`GROUP BY` vai inventá-los; a única coisa que vai é um `LEFT JOIN` a partir da tabela que os tem, o
que é a próxima seção depois desta, e onde contar deixa de ser óbvio.
