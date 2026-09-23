---
title: DISTINCT, que normalmente é sintoma
version: 2
---

```sql
SELECT DISTINCT category FROM products;
```

`DISTINCT` remove linhas duplicadas do resultado. Ele se aplica à **linha de saída inteira**, não a
uma coluna, que é a primeira coisa que as pessoas erram:

```sql
SELECT DISTINCT category, name FROM products;
```

Isso é *pares* distintos. Como `name` é quase único, quase nada é removido e a consulta parece que o
`DISTINCT` não funcionou. Funcionou; você fez outra pergunta.

## Não é de graça

Remover duplicatas significa que o banco tem que comparar linhas entre si, o que ele faz ordenando
ou fazendo hash. Num resultado grande isso é trabalho e memória de verdade, e acontece depois de todo
o resto da consulta.

Isso sozinho não é argumento contra. O argumento é a próxima seção.

## A desconfiança útil

> **Quando o `DISTINCT` foi acrescentado para fazer uma resposta errada parecer certa, ele escondeu
> um defeito em vez de consertar um.**

Este é o padrão, e é um dos erros mais comuns em SQL. A aula 5 é sobre junções, e esta é a armadilha
em que ela cai:

```sql
SELECT DISTINCT c.name
FROM   customers c
JOIN   orders o ON o.customer_id = c.id;
```

Alguém queria "clientes que já pediram". A junção produz uma linha por **pedido**, então um cliente
com cinco pedidos aparece cinco vezes, e o `DISTINCT` colapsa. A resposta agora está certa e a
consulta faz muito mais trabalho do que precisa — e no momento em que alguém acrescentar uma coluna,
ou um `count(*)`, a duplicação volta numa forma que o `DISTINCT` já não esconde.

O que de fato se queria:

```sql
SELECT c.name
FROM   customers c
WHERE  EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);
```

`EXISTS` pergunta se existe pelo menos um, e para de procurar. Nenhuma duplicação é criada, então
nenhuma precisa ser removida, e o banco pode parar no primeiro casamento por cliente em vez de buscar
todos os pedidos.

Então o hábito a construir:

> **Quando você buscar o `DISTINCT`, pergunte de onde vieram as duplicatas.** Se a resposta for "a
> junção multiplicou as linhas", a junção é o que mudar.

Usos legítimos permanecem, e têm outro formato: você quer o conjunto de valores que uma coluna
assume, e as duplicatas estão no dado em vez de terem sido criadas pela consulta.

```sql
SELECT DISTINCT category FROM products ORDER BY category;
```

## `DISTINCT ON`, que é do PostgreSQL e é excelente

```sql
SELECT DISTINCT ON (customer_id) customer_id, id, ordered_on, total
FROM   orders
ORDER BY customer_id, ordered_on DESC;
```

**Uma linha por cliente — o pedido mais recente de cada um.** Essa é uma pergunta para a qual as
pessoas escrevem subconsultas complicadas, e aqui são quatro palavras.

A regra é exata e vale enunciar porque é a parte que as pessoas erram: `DISTINCT ON (x)` mantém a
**primeira** linha de cada grupo de `x`, e *primeira* significa primeira no `ORDER BY`. Então o
`ORDER BY` tem que começar com as mesmas expressões do `DISTINCT ON`, e o que vem depois decide qual
linha sobrevive.

Troque `DESC` por `ASC` e você recebe o primeiro pedido de cada cliente. Omita a segunda chave e você
recebe um qualquer deles, que é um bug com cara de consulta funcionando.

Não é SQL padrão. As funções de janela da aula 6 fazem o mesmo trabalho de forma portável e mais
verbosa, e a aula 12 é onde a diferença importa.

## `UNION` também remove duplicatas

Vale saber agora porque é o mesmo custo num lugar onde as pessoas não esperam:

```sql
SELECT name FROM products UNION     SELECT name FROM archived_products;   -- removes duplicates
SELECT name FROM products UNION ALL SELECT name FROM archived_products;   -- keeps them
```

**`UNION` deduplica e `UNION ALL` não**, o que significa que a grafia simples é a cara. Quando você
sabe que os dois lados não podem se sobrepor — ou quando duplicatas não incomodam — `UNION ALL` é ao
mesmo tempo mais rápido e mais honesto sobre o que você pediu.
