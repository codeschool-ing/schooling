---
title: Escolhendo colunas, e o hábito a quebrar cedo
version: 2
---

```sql
SELECT name, price FROM products;
```

A lista do `SELECT` é o que volta. Ela pode ter colunas, expressões, literais e funções, e cada
entrada pode receber um nome.

```sql
SELECT name,
       price,
       price * 1.23        AS gross,
       upper(sku)          AS code,
       'EUR'               AS currency,
       now()               AS as_of
FROM   products;
```

O `AS` é opcional — `price * 1.23 gross` funciona — e escrevê-lo deixa a lista legível, especialmente
quando alguém percorre uma lista longa procurando de onde veio um apelido.

**Sem nome, uma expressão recebe o que o banco decidir.** `price * 1.23` volta como `?column?`, que
todo cliente exibe e nenhum programa consegue usar. Nomeie tudo que não seja uma coluna simples.

## `SELECT *` é para o terminal

```sql
SELECT * FROM products;
```

É a coisa certa a digitar quando você está explorando uma tabela que nunca viu. É um hábito que vale
quebrar em todo o resto, por quatro razões que têm o mesmo formato — **você recebe o que a tabela
por acaso tem hoje**:

**Uma coluna nova muda seu resultado em silêncio.** Alguém acrescenta `internal_notes` em
`products`, e seu relatório ganha uma coluna, sua exportação CSV ganha um campo, e o parser de
linhas da sua aplicação recebe algo que não esperava.

**Ele busca colunas que ninguém lê.** Uma coluna `text` com uma descrição é transferida pela rede em
toda linha de toda consulta que não precisava dela. Numa tabela larga isso é a maior parte do custo.

**Ele impede uma varredura só de índice.** Assunto da aula 9, e a referência vale: se uma consulta
pede só colunas que estão num índice, o banco pode responder pelo índice sem tocar na tabela. Pedir
`*` garante que não pode.

**Ele esconde do que uma consulta depende.** `SELECT *` não diz a quem lê — nem a um programa
buscando no código — quais colunas de fato importam. Quando alguém propõe derrubar uma coluna, nada
encontra as consultas que quebrariam.

> Nomeie as colunas. É pouco mais para digitar, e cada uma das quatro falhas acima é algo de que você
> ficaria sabendo depois, por um usuário.

## Nomes duplicados, e por que qualificar vale o hábito

Duas tabelas podem ter `id` e `name`. Quando a aula 5 as juntar, o resultado tem dois de cada, e qual
você recebe não é coisa para deixar ao acaso:

```sql
SELECT p.name AS product, c.name AS category
FROM   products p
JOIN   categories c ON c.id = p.category_id;
```

O apelido curto — `products p` — é padrão e vale usar assim que houver mais de uma tabela. Qualifique
toda coluna mesmo quando é inequívoca hoje, porque uma coluna acrescentada na outra tabela amanhã
pode torná-la ambígua, e uma consulta que estava correta vira um erro ou, pior, lê a errada em
silêncio.

## Expressões, e onde elas moram

Tudo que você consegue calcular pode ir na lista:

```sql
SELECT name,
       round(price * 1.23, 2)                     AS gross,
       coalesce(description, 'No description')    AS description,
       price > 100                                AS is_expensive,
       extract(year FROM created_at)              AS created_year
FROM   products;
```

Dois hábitos que vale formar agora.

**`round(x, 2)` para dinheiro na saída, não na coluna.** O valor guardado é `numeric` e exato;
arredondar é decisão de apresentação, e fazer isso uma vez no fim é diferente de fazer em cada passo
intermediário, que é como totais deixam de fechar.

**`coalesce(a, b)` devolve o primeiro argumento que não é nulo.** É o jeito padrão de dar forma de
exibição a um valor ausente — e é decisão de exibição. Escrever `coalesce(price, 0)` no meio de um
cálculo é afirmar que um preço desconhecido é grátis, que é exatamente o erro da aula 1 de tratar
`NULL` como zero.

## Literais e o `FROM` vazio

O PostgreSQL avalia uma expressão sem tabela nenhuma, que é como você testa coisas:

```sql
SELECT 1 + 1;
SELECT now();
SELECT 'ana@Example.com' = lower('ana@Example.com');
```

Essa terceira linha é como você confere a questão de caixa da aula 3 em dois segundos em vez de
raciocinando. Boa parte do que este curso ensina pode ser confirmada assim, e confirmar é sempre
melhor que lembrar.
