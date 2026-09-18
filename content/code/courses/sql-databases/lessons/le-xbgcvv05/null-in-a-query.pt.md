---
title: NULL, agora que você escreve consultas
version: 1
---

A aula 1 disse o que `NULL` é: não zero, não vazio, **desconhecido** — e que comparar qualquer coisa
com um desconhecido dá desconhecido. Esta seção é o que isso faz com as consultas que você agora
escreve.

## A regra que produz toda surpresa abaixo

> **`WHERE` mantém uma linha quando a condição é verdadeira. Desconhecido não é verdadeiro.**

É isso. Todo o resto decorre.

## Linhas que não estão em nenhuma das metades

Dez produtos, três sem categoria:

```sql
SELECT count(*) FROM products WHERE category = 'kitchen';     -- 4
SELECT count(*) FROM products WHERE category <> 'kitchen';    -- 3
```

Quatro e três é sete, e há dez. Os três desconhecidos estão em **nenhuma** das respostas, e nada te
avisou.

Esse é o formato do bug na natureza: um relatório de "produtos fora da categoria cozinha" omite
caladamente tudo que está sem categoria, o número fica um pouco baixo, e continua um pouco baixo por
anos porque é plausível.

Para incluí-los, diga:

```sql
SELECT count(*) FROM products WHERE category <> 'kitchen' OR category IS NULL;   -- 6
```

## `= NULL` não é erro, o que é pior

```sql
SELECT count(*) FROM products WHERE category = NULL;      -- 0, sempre
SELECT count(*) FROM products WHERE category IS NULL;     -- 3
```

A primeira é SQL válido que nunca é verdadeiro. Sem erro, sem aviso, e uma resposta de zero que
parece um achado real. `IS NULL` e `IS NOT NULL` perguntam sobre o estado em vez de comparar valores,
e são o único jeito.

## `NOT IN` com um nulo devolve nada

O mais traiçoeiro deles, e vale escrever por extenso:

```sql
SELECT * FROM products WHERE category_id NOT IN (1, 2, NULL);
```

Zero linhas. Sempre, não importa o que a tabela tenha. `x NOT IN (1, 2, NULL)` se desdobra em
`x <> 1 AND x <> 2 AND x <> NULL`, e esse último termo é desconhecido, então o `AND` inteiro nunca
pode ser verdadeiro.

É raro escrever um `NULL` literal numa lista. **Não** é raro uma subconsulta devolver um:

```sql
SELECT * FROM products
WHERE  category_id NOT IN (SELECT id FROM categories WHERE archived);
```

Uma categoria arquivada com `id` nulo — ou, mais comum, uma subconsulta sobre uma coluna que aceita
nulo — e isso devolve nada. A consulta é SQL correto, a resposta é vazia, e ninguém é avisado.

**Use `NOT EXISTS`**, que é assunto da aula 7 e é imune a isso:

```sql
SELECT * FROM products p
WHERE  NOT EXISTS (SELECT 1 FROM categories c WHERE c.id = p.category_id AND c.archived);
```

## `NOT` não vira desconhecido

```sql
WHERE NOT (price > 100)
```

Se `price` for nulo, `price > 100` é desconhecido, e `NOT desconhecido` **continua desconhecido** —
então a linha é descartada por esta condição exatamente como era descartada pela original. Negar uma
condição não te dá as linhas que ela excluía; te dá as linhas em que ela era definitivamente falsa.

A tabela-verdade de três valores, uma vez, porque ela explica tudo acima:

| | AND | OR |
|---|---|---|
| **verdadeiro, desconhecido** | desconhecido | **verdadeiro** |
| **falso, desconhecido** | **falso** | desconhecido |
| **desconhecido, desconhecido** | desconhecido | desconhecido |

Duas dessas merecem nota: `verdadeiro OR desconhecido` é **verdadeiro**, e `falso AND desconhecido`
é **falso**. O desconhecido nem sempre se espalha — quando o outro operando já resolve a questão, a
resposta é conhecida.

## As ferramentas

```sql
coalesce(price, 0)                  -- o primeiro argumento que não é nulo
nullif(status, '')                  -- NULL quando os dois são iguais, senão o primeiro
price IS DISTINCT FROM 20           -- como <>, mas trata NULL como valor comparável
```

**`IS DISTINCT FROM` é o que as pessoas não conhecem e frequentemente querem.** O `<>` comum diz
desconhecido quando um lado é nulo; `IS DISTINCT FROM` responde verdadeiro ou falso, tratando nulo
como só mais um valor diferente de 20. Quando você quer "tudo que não é 20, incluindo os que não
sabemos", é um operador em vez de um `OR`.

**E `coalesce` numa cláusula `WHERE` merece desconfiança.** `WHERE coalesce(price, 0) > 100` lê bem e
faz duas coisas ao mesmo tempo: afirma que um preço desconhecido é zero, e — da seção `where` — põe
uma função em volta da coluna e perde o índice. Normalmente o que se queria era `WHERE price > 100`,
que já exclui os desconhecidos, ou `WHERE price > 100 OR price IS NULL` se eles pertencem à resposta.
Decidir qual é o ponto.

## O hábito

Toda vez que você escrever uma condição sobre uma coluna que aceita nulo, faça uma pergunta:

> **O que deve acontecer com as linhas em que isto é desconhecido?**

Há três respostas honestas — mantê-las, descartá-las, ou a coluna nunca deveria aceitar nulo. O
conselho da aula 1 era o último, aplicado no projeto. Isto é o que você faz sobre as colunas em que
não foi.
