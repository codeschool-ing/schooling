---
title: WHERE, e a regra para manter uma linha
version: 1
---

`WHERE` mantém uma linha quando a condição é **verdadeira**. Não "não falsa" — verdadeira. Essa
distinção é a lógica de três valores da aula 1 chegando numa consulta, e ela tem uma seção própria
duas adiante.

```sql
SELECT name, price
FROM   products
WHERE  price > 20;
```

## As comparações

```sql
WHERE price = 20
WHERE price <> 20          -- != também funciona e <> é o do padrão
WHERE price > 20
WHERE price BETWEEN 20 AND 50      -- inclusivo nas duas pontas
WHERE category IN ('kitchen', 'garden')
WHERE created_at >= date '2026-01-01'
```

**`BETWEEN` é inclusivo nas duas pontas**, o que serve para inteiros e é armadilha para timestamps:

```sql
WHERE created_at BETWEEN '2026-03-01' AND '2026-03-31'
```

Isso perde quase todo o dia 31. Uma data pelada é meia-noite, então o limite superior é
`2026-03-31 00:00:00` e tudo daquele dia depois disso fica fora. O formato que está sempre certo:

```sql
WHERE created_at >= '2026-03-01' AND created_at < '2026-04-01'
```

Maior-ou-igual no começo, **estritamente menor** no começo do período seguinte. Lê um pouco pior e
está correto para datas, timestamps, meses e anos sem pensar em quantos dias fevereiro tem.

## Combinando, e a precedência que morde

`AND` liga mais forte que `OR`. O que significa que estas duas são consultas diferentes:

```sql
WHERE category = 'kitchen' OR category = 'garden' AND price < 50
WHERE (category = 'kitchen' OR category = 'garden') AND price < 50
```

A primeira é *cozinha a qualquer preço, ou jardim abaixo de 50* — quase certamente não o que quem
escreveu queria. A segunda é a pretendida.

> **Ponha parênteses sempre que `AND` e `OR` aparecerem juntos.** Mesmo quando você tem certeza. Quem
> lê não tem, e quem lê é você daqui a seis meses.

`NOT` nega, e combinado com nulos faz algo que você não preveria — a seção `null-in-a-query`.

## `WHERE` roda antes do `SELECT`

Da primeira seção, e é o erro mais comum de iniciante, então vale ver de novo com o conserto:

```sql
SELECT price * 1.23 AS gross FROM products WHERE gross > 100;          -- erro
SELECT price * 1.23 AS gross FROM products WHERE price * 1.23 > 100;   -- funciona
```

Se repetir a expressão fica feio — e numa expressão longa fica — as expressões de tabela comuns da
aula 7 são a resposta limpa:

```sql
WITH priced AS (
    SELECT name, price * 1.23 AS gross FROM products
)
SELECT * FROM priced WHERE gross > 100;
```

## Funções sobre uma coluna têm um custo que você ainda não vê

Estas duas acham as mesmas linhas:

```sql
WHERE extract(year FROM created_at) = 2026
WHERE created_at >= '2026-01-01' AND created_at < '2027-01-01'
```

A segunda consegue usar um índice em `created_at`. **A primeira não consegue**, porque o banco teria
que calcular a função em toda linha antes de comparar qualquer coisa, e um índice na coluna nada diz
sobre o resultado da função.

A regra, e é uma das poucas coisas que vale levar desta aula para a aula 9:

> **Deixe a coluna pelada de um lado da comparação. Faça a aritmética do outro.**

`WHERE price * 1.23 > 100` tem o mesmo problema, e `WHERE price > 100 / 1.23` não tem. Não é uma
diferença que você enxergue numa tabela pequena, e é a diferença entre milissegundos e minutos numa
grande.

## As duas cláusulas que não são filtros

Vale nomear agora para não confundir depois:

```sql
WHERE  price > 20        -- descarta LINHAS, antes do agrupamento
HAVING count(*) > 3      -- descarta GRUPOS, depois do agrupamento
```

Não são alternativas, rodam em momentos diferentes, e pôr um agregado no `WHERE` é erro e não uma
versão lenta da coisa certa. Aula 6.
