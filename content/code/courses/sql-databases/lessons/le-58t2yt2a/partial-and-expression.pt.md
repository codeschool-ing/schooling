---
title: Dois tipos que pagam o trabalho
version: 2
---

Estes dois resolvem problemas que o índice comum não resolve, são baratos, e a maioria das pessoas
nunca escreveu um. Se você levar duas coisas desta aula, leve estas.

## Um índice parcial cobre algumas das linhas

```sql
CREATE INDEX ON jobs (created_at) WHERE status = 'pending';
```

O `WHERE` faz parte do índice, e não de uma consulta. Só as linhas pendentes ganham uma entrada.

Numa tabela de tarefas com cinquenta milhões de linhas terminadas e quatrocentas pendentes, esse
índice tem quatrocentas entradas. Ele cabe na memória, a busca é instantânea, e — a parte que passa
batida — **as inserções e os updates dos outros cinquenta milhões não o tocam.** Uma linha só entra
no índice quando fica pendente e sai quando deixa de estar, então o custo de escrita é proporcional
às linhas que lhe interessam em vez de à tabela.

Ele responde à objeção de duas seções atrás. Um índice comum numa coluna de status com três valores
não ganha nada, porque valor nenhum é seletivo o bastante. Um índice parcial no valor raro é
seletivo por construção.

Os formatos que vale reconhecer:

```sql
-- the small live subset of a big archive
CREATE INDEX ON orders (customer_id) WHERE NOT archived;

-- rows with a value, on a mostly-null column
CREATE INDEX ON users (deleted_at) WHERE deleted_at IS NOT NULL;

-- uniqueness that applies to some rows only
CREATE UNIQUE INDEX ON users (email) WHERE deleted_at IS NULL;
```

Vale parar nesse último. *"Um e-mail tem que ser único entre os usuários que não foram excluídos"*
não pode ser dito com uma restrição `UNIQUE` comum, e as pessoas acabam impondo isso no código da
aplicação — o que a aula 8 mostrou ser um desvio de escrita esperando duas requisições chegarem
juntas. Um índice único parcial impõe a regra direito, em todo nível de isolamento, contra toda
conexão.

**O planejador precisa provar que o índice se aplica.** Uma consulta dizendo `WHERE status =
'pending'` pode usar o índice acima; uma dizendo `WHERE status = $1` não pode, porque o valor não é
conhecido quando o plano é feito, e uma dizendo `WHERE status <> 'done'` também não, porque não é a
mesma condição. Mantenha a condição da consulta reconhecivelmente igual à do índice.

MySQL e MariaDB não têm índices parciais. PostgreSQL e SQLite têm.

## Um índice de expressão cobre um valor calculado

A seção sobre índices não usados disse que uma função em volta da coluna derruba o índice. Esta é a
outra saída: indexe a função.

```sql
CREATE INDEX ON customers (lower(email));

SELECT * FROM customers WHERE lower(email) = 'ana@example.com';   -- uses it
```

O índice guarda os valores em minúsculas, ordenados. A expressão da consulta bate com a expressão do
índice, então ele se aplica.

Duas regras governam isso, e as duas pegam as pessoas:

**A consulta tem que soletrar a expressão do mesmo jeito.** `lower(email)` no índice e
`lower(trim(email))` na consulta são duas expressões diferentes, e o índice não é usado. É a razão
mais comum de um índice de expressão parecer quebrado.

**A expressão tem que ser imutável.** A mesma entrada precisa dar sempre a mesma saída, para sempre —
senão o índice seria o registro de uma resposta que já mudou. Então `lower(x)` está bem e `now()`
não, e a que pega as pessoas é uma conversão de timestamp que depende do fuso horário da sessão. O
PostgreSQL recusa essas, e o erro está lhe dizendo algo verdadeiro sobre os seus dados em vez de
estar sendo chato.

Formatos úteis:

```sql
CREATE INDEX ON customers (lower(email));                        -- case-insensitive lookup
CREATE INDEX ON orders (date_trunc('month', placed_at));         -- lesson 6's monthly grouping
CREATE INDEX ON documents ((payload ->> 'customer_id'));         -- a field inside a JSON column
```

O último é como uma coluna JSON fica pesquisável sem ser desmontada em colunas de verdade — o que
vale conhecer, e não é argumento para pôr em JSON coisas que pertencem a colunas.

MySQL 8 tem índices funcionais, e o MariaDB e versões antigas do MySQL conseguem o mesmo efeito com
uma coluna gerada mais um índice sobre ela. O SQLite tem índices de expressão.

## Combine os dois

Nada impede:

```sql
CREATE UNIQUE INDEX ON users (lower(email)) WHERE deleted_at IS NULL;
```

*"Dois usuários ativos não podem ter o mesmo e-mail, seja lá em que caixa eles o digitaram."* Uma
linha, imposta pelo banco, imune a concorrência, e a alternativa é um parágrafo de código de
aplicação que está errado de um jeito que ninguém percebe até duas pessoas se cadastrarem no mesmo
segundo.
