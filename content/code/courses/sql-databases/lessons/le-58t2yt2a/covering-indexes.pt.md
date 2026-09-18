---
title: Índices de cobertura, em que a tabela nunca é tocada
version: 1
---

A primeira seção deixou um fio solto. Usar um índice são dois passos: achar a entrada, e depois
seguir o ponteiro dela para buscar a linha. Esse segundo passo é uma leitura aleatória, e numa
consulta que devolve muitas linhas é a maior parte do custo.

Um **índice de cobertura** é um que contém toda coluna de que a consulta precisa, então o segundo
passo nunca acontece.

```sql
CREATE INDEX ON orders (customer_id, placed_at);

SELECT customer_id, placed_at FROM orders WHERE customer_id = 2;
```

As duas colunas pedidas estão no índice. O banco percorre a sequência de entradas do cliente 2 e as
devolve — a tabela `orders` não é lida. O PostgreSQL chama isso de **index-only scan**, e aparece
com esse nome no plano.

Acrescente uma coluna e acabou:

```sql
SELECT customer_id, placed_at, total FROM orders WHERE customer_id = 2;
```

`total` não está no índice, então toda entrada agora precisa da linha dela buscada. Mesmo índice,
mesmo `WHERE`, várias vezes o trabalho — e a única diferença é uma coluna na lista do `SELECT`, que
não é onde ninguém procura por uma mudança de desempenho.

O que é a lição prática, e é o argumento da aula 4 chegando com um número junto: **`SELECT *` não
pode ser coberto por nada.** Pedir colunas de que você não precisa não é só banda; pode ser a
diferença entre ler um índice e ler uma tabela.

## `INCLUDE`, para colunas que você só quer devolver

Há uma tensão. Para cobrir a consulta acima você teria que indexar `total` também:

```sql
CREATE INDEX ON orders (customer_id, placed_at, total);
```

Mas `total` não é algo por que você busque ou ordene. Pô-lo na chave deixa o índice maior, faz toda
comparação comparar três valores, e implica uma ordenação que ninguém quer.

O PostgreSQL 11 em diante, e o SQL Server antes dele, separam os dois trabalhos:

```sql
CREATE INDEX ON orders (customer_id, placed_at) INCLUDE (total);
```

`total` é guardado no índice e **não** faz parte da chave ordenada. O índice continua se comportando
como um índice de duas colunas para todo propósito da seção anterior — prefixo à esquerda,
ordenação, tudo — e a consulta fica coberta.

Use `INCLUDE` para colunas que aparecem no `SELECT` e nunca no `WHERE` nem no `ORDER BY`. Use a
chave para tudo o que você busca. Acertar essa divisão é a maior parte do que faz um índice de
cobertura valer o tamanho dele.

MySQL e MariaDB não têm `INCLUDE`; ali a coluna vai na chave ou não vai. O SQLite também não tem, e
vale o mesmo.

## O MySQL cobre uma coisa de graça

O InnoDB guarda a própria tabela em ordem de chave primária — um **índice agrupado** — e toda entrada
de índice secundário guarda a chave primária em vez de um ponteiro físico.

Duas consequências que surpreendem quem vem do PostgreSQL:

**Todo índice secundário cobre a chave primária.** Um índice em `(customer_id)` consegue responder a
`SELECT id, customer_id …` sem tocar a tabela, porque o `id` já está na entrada.

**E buscar uma linha são duas descidas de índice**, não um seguir de ponteiro: ache a entrada, leia a
chave primária dela, e desça o índice agrupado até a linha. O que torna uma chave primária larga
cara duas vezes — ela é copiada em todo índice secundário, e é percorrida em toda busca. É o
argumento mais forte para uma chave primária compacta especificamente no MySQL.

## O asterisco do PostgreSQL, que importa

Um index-only scan no PostgreSQL não é bem só o índice. A entrada de índice não registra se a linha
para a qual ela aponta é visível à sua transação — as versões de linha da aula 8 estão na tabela, e
não no índice. Então o banco consulta o **mapa de visibilidade**, uma estrutura pequena marcando
quais páginas contêm só linhas visíveis a todo mundo.

Se a página está marcada como toda visível, a entrada é usada como está. Se não está, a linha
precisa ser buscada afinal, e o index-only scan caladamente vira um comum.

O mapa de visibilidade é mantido pelo `VACUUM`. Então:

> **Um index-only scan numa tabela muito escrita deixa de ser só-índice até o `VACUUM` alcançar.**

É um efeito real e é um dos jeitos pelos quais a transação longa da aula 8 prejudica o desempenho em
vez de só o disco: ela segura o `VACUUM`, o mapa fica velho, e consultas que estavam rápidas voltam
a buscar linhas. Nada na consulta mudou.

## Quando recorrer a um

Um índice de cobertura vale construir quando uma consulta é **quente, estreita e seletiva**: roda
muito, precisa de poucas colunas, e devolve uma fatia pequena da tabela. Uma consulta de relatório
sobre a maior parte da tabela não quer um — ela quer a tabela.

E seja honesto quanto ao tamanho. Acrescentar duas colunas de `INCLUDE` a um índice numa tabela de
cem milhões de linhas pode somar gigabytes, todos disputando o mesmo cache. A resposta certa é quase
sempre medir a consulta primeiro, que é a aula 10, e acrescentar as colunas que você consegue provar
que são necessárias em vez das que a lista do `SELECT` por acaso tem hoje.
