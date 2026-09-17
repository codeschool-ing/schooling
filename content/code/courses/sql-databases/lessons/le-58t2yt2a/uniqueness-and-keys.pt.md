---
title: Os índices que você já tem, e o que está faltando
version: 1
---

Alguns dos seus índices nunca foram criados por ninguém. Declare uma chave e você ganha um:

```sql
CREATE TABLE customers (
    id    integer PRIMARY KEY,          -- um índice único em (id)
    email text UNIQUE                   -- um índice único em (email)
);
```

Uma regra de unicidade precisa ser conferida em toda inserção, e conferir varrendo a tabela seria
inutilizável — então a regra é **implementada como** um índice único. É por isso que a restrição da
aula 3 e o índice desta aula são o mesmo objeto visto de dois lados, e é por isso que acrescentar o
seu próprio índice numa coluna de chave primária é desperdício puro.

## Nulos não colidem

```sql
INSERT INTO customers (id, email) VALUES (1, NULL);
INSERT INTO customers (id, email) VALUES (2, NULL);   -- aceito
```

As duas linhas entram. Um índice único recusa duas linhas que sejam **iguais**, e a aula 1 resolveu
que dois desconhecidos não são conhecidos como iguais. Então uma coluna única anulável permite
qualquer número de nulos, o que em geral é o que você quer e de vez em quando é uma surpresa.

O PostgreSQL 15 acrescentou o outro comportamento, para quando não é:

```sql
CREATE UNIQUE INDEX ON customers (email) NULLS NOT DISTINCT;
```

## O que está faltando

> **O PostgreSQL não cria um índice para uma chave estrangeira. O MySQL cria.**

Essa única frase é a coisa mais valiosa desta aula, porque o índice ausente é invisível até ficar
caro.

```sql
CREATE TABLE orders (
    id          integer PRIMARY KEY,
    customer_id integer REFERENCES customers (id)      -- sem índice em customer_id
);
```

O `REFERENCES` lhe dá a restrição. O lado **pai** está indexado, porque `customers.id` é chave
primária. O `customer_id` do filho não tem nada, e três coisas sofrem:

**Toda busca por cliente.** `WHERE customer_id = 7` é uma varredura, e a junção de toda consulta do
formato sobre o qual as aulas 5 e 6 foram construídas também. Esta as pessoas acham rápido.

**Toda exclusão de uma linha pai.** Excluir um cliente exige que o banco prove que nenhum pedido o
referencia — o que, sem índice em `orders.customer_id`, significa ler a tabela `orders` inteira.
Excluir cem clientes a lê cem vezes. É o clássico *"por que apagar uma linha leva quatro minutos"*, e
a resposta nunca está no `DELETE`.

**E o `ON DELETE CASCADE`**, que é o mesmo trabalho com mais linhas no fim.

O MySQL evita o problema inteiro recusando-se a tê-lo: o InnoDB cria um índice nas colunas que
referenciam se não houver um. É uma coisa pequena que previne uma classe grande de incidente, e o
PostgreSQL deixa para você.

Então: **indexe as suas chaves estrangeiras**, a menos que tenha razão para não. Achar as que você
não indexou:

```sql
SELECT c.conrelid::regclass AS "table", c.conname AS "constraint"
FROM   pg_constraint c
WHERE  c.contype = 'f'
AND    NOT EXISTS (
           SELECT 1 FROM pg_index i
           WHERE i.indrelid = c.conrelid
           AND   (i.indkey::smallint[])[0:array_length(c.conkey,1)-1] @> c.conkey
       );
```

Rode isso em qualquer banco PostgreSQL que esteja vivo há um ano e ele vai achar algo.

## Restrição ou índice

No PostgreSQL os dois não são bem intercambiáveis:

| | restrição `UNIQUE` | índice único |
|---|---|---|
| pode ser alvo de uma chave estrangeira | sim | não |
| aparece como restrição no catálogo | sim | não |
| pode ser parcial (`WHERE …`) | não | **sim** |
| pode ser sobre uma expressão | não | **sim** |

O que decide na prática. Use uma restrição para unicidade simples numa coluna, porque ela diz o que
quer dizer e outras tabelas podem referenciá-la. Use um índice único quando precisar das duas
últimas linhas daquela tabela — *"único entre as linhas não excluídas"*, *"único ignorando a caixa"*
— que é o material da seção anterior.

Um índice construído antes pode ser promovido depois, que é como se acrescenta uma restrição de
unicidade a uma tabela viva sem segurar um bloqueio enquanto ele é construído:

```sql
CREATE UNIQUE INDEX CONCURRENTLY customers_email_key ON customers (email);
ALTER TABLE customers ADD CONSTRAINT customers_email_key UNIQUE USING INDEX customers_email_key;
```

## Duas quinas afiadas

**Construir um índice único sobre dado que tem duplicatas falha.** Está correto, e significa que a
instrução que você ensaiou num banco de testes vazio pode falhar em produção. Ache as duplicatas
antes — o `GROUP BY … HAVING count(*) > 1` da aula 6 — e decida o que fazer com elas antes da
migração, e não durante.

**Uma troca viola a unicidade no meio do caminho.** Trocar os valores de `position` de duas linhas
quebra a regra entre o primeiro update e o segundo, e a instrução é rejeitada mesmo com o estado
final estando bem. A resposta é adiar a conferência para o fim da transação:

```sql
ALTER TABLE items ADD CONSTRAINT items_position_key UNIQUE (position) DEFERRABLE INITIALLY IMMEDIATE;

BEGIN;
SET CONSTRAINTS items_position_key DEFERRED;
UPDATE items SET position = 2 WHERE id = 1;
UPDATE items SET position = 1 WHERE id = 2;
COMMIT;                                     -- conferido aqui, e passa
```

O que é a transação da aula 8 fazendo algo que só ela consegue: tornar o estado intermediário, que é
inválido, invisível à regra tanto quanto a todo mundo.
