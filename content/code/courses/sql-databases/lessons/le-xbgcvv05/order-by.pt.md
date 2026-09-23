---
title: ORDER BY, e o arranjo que ninguém te prometeu
version: 2
---

Linhas não têm ordem. A aula 1 disse isso como propriedade de uma tabela; aqui está o que significa
para uma consulta.

> **Sem `ORDER BY`, a ordem em que as linhas voltam não é definida e pode mudar.**

Não "normalmente ordem de inserção". Não "normalmente por chave". Indefinida — e na prática ela muda
quando a tabela cresce, quando um índice é acrescentado, quando o planejador escolhe outro caminho,
ou quando o PostgreSQL é atualizado. Uma consulta que produziu uma ordem estável por um ano pode
começar a produzir outra depois de uma mudança que ninguém ligou a ela.

```sql
SELECT name, price FROM products ORDER BY price;
```

## Direção, e várias chaves

```sql
ORDER BY price DESC
ORDER BY category, price DESC        -- category ascending, then price descending within it
ORDER BY 2                           -- by the second column of the SELECT list
```

`ASC` é o padrão e escrevê-lo é opcional. **Cada chave tem a própria direção** — `ORDER BY a, b DESC`
ordena `a` crescente e `b` decrescente, o que pega quem espera que o `DESC` valha para as duas.

`ORDER BY 2` funciona e vale evitar: ele aponta para uma posição na lista do `SELECT`, então
acrescentar uma coluna reordena em silêncio por outra coisa. É a mesma fragilidade posicional que
este curso não para de recusar.

## Para onde vão os nulos

```sql
ORDER BY price;                       -- nulls last, in PostgreSQL, ascending
ORDER BY price DESC;                  -- nulls first
ORDER BY price NULLS FIRST;           -- say it and stop guessing
```

O PostgreSQL trata nulo como maior que tudo, então ele cai por último no crescente e primeiro no
decrescente. **Outros bancos escolhem diferente** — o MySQL põe nulos primeiro no crescente — então
uma consulta que põe os vazios embaixo num banco põe no topo em outro.

Diga `NULLS FIRST` ou `NULLS LAST` sempre que a coluna aceitar nulo e a posição importar. São quatro
caracteres e removem uma diferença que ninguém testa.

## Ordenando por algo que você calculou

```sql
SELECT name, price * 1.23 AS gross FROM products ORDER BY gross DESC;
SELECT name FROM products ORDER BY length(name);
SELECT name, price FROM products ORDER BY (price > 100) DESC, name;
```

Os três funcionam. O `ORDER BY` roda depois do `SELECT`, então o apelido existe; e ele pode ordenar
por uma expressão que nem está na saída, que é como o segundo funciona.

Essa terceira linha é um truque útil: um booleano ordena falso antes de verdadeiro, então o `DESC`
põe os caros primeiro e depois ordena o resto por nome. É como você diz "estes primeiro, depois todo
o resto" sem duas consultas.

## Texto ordena pela collation

```sql
SELECT name FROM people ORDER BY name;
SELECT name FROM people ORDER BY name COLLATE "C";
```

Da aula 3: sob uma collation portuguesa `Álvaro` ordena entre os As; sob `C`, que é ordem de byte,
ordena depois do `Z`. Nenhuma está errada e são respostas diferentes, então a que não pode variar
entre máquinas deve dizer qual quer.

## A ordenação que não desempata

Esta é a que produz um bug real, e é a ponte para a próxima seção:

```sql
SELECT name FROM products ORDER BY category LIMIT 10;
```

Vinte produtos na categoria `kitchen`, e você pediu dez. **Quais dez é indefinido**, porque
`ORDER BY category` nada diz sobre como linhas de mesma categoria se arranjam entre si. Rode duas
vezes e você pode receber dois conjuntos diferentes.

O conserto é tornar a ordenação total, terminando em algo único:

```sql
SELECT name FROM products ORDER BY category, id LIMIT 10;
```

> **Toda consulta com `LIMIT` precisa de um `ORDER BY` que não empate.** Terminar na chave primária é
> o jeito mais barato de garantir.

Sem isso, a paginação mostra uma linha duas vezes e pula outra, os números de um relatório oscilam
entre atualizações, e cada um desses é intermitente e impossível de reproduzir numa tabela pequena.

## Custa algo

Ordenar é trabalho real: o banco reúne as linhas, ordena na memória, e vaza para disco se forem
demais. **Um índice pode remover esse custo por completo** — um índice já é uma estrutura ordenada,
então `ORDER BY price` sobre um índice em `price` pode ser respondido percorrendo-o.

Isso é a aula 9, e o que levar agora é que `ORDER BY` numa coluna com índice e `ORDER BY` numa
expressão não são o mesmo preço, do mesmo modo que `LIKE 'a%'` e `LIKE '%a%'` não são.
