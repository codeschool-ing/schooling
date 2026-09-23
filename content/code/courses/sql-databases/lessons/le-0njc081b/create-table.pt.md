---
title: O comando, e os hábitos que vão nele
version: 2
---

Duas aulas de projeto, e agora você escreve.

```sql
CREATE TABLE invoices (
    id          integer       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id integer       NOT NULL REFERENCES customers (id) ON DELETE RESTRICT,
    number      text          NOT NULL UNIQUE,
    issued_on   date          NOT NULL DEFAULT current_date,
    total       numeric(12,2) NOT NULL CHECK (total >= 0),
    paid_at     timestamptz,
    CONSTRAINT invoices_paid_after_issue
        CHECK (paid_at IS NULL OR paid_at::date >= issued_on)
);
```

Cada parte disso apareceu nas duas últimas aulas, exceto o formato do próprio comando, que é o
assunto desta seção. Leia como três tipos de linha:

- **definições de coluna** — um nome, um tipo, e as restrições que valem só para aquela coluna;
- **restrições de tabela** — no fim, para o que abrange mais de uma coluna;
- **mais nada.** Não há lugar no `CREATE TABLE` para um comentário sobre intenção, que é por que a
  última seção desta aula é sobre nomear.

## `IF NOT EXISTS` e por que normalmente é errado

```sql
CREATE TABLE IF NOT EXISTS invoices ( … );
```

Parece defensivo e é perigoso, porque **não confere se a tabela existente combina**. Se `invoices`
já está lá com outro formato, isso passa em silêncio e o seu programa agora roda contra uma tabela
que você não escreveu.

Tem um uso honesto: um script genuinamente idempotente cuja definição de tabela é a única que já
existiu. Num sistema com migrações — aula 11 — cada migração roda uma vez, e o `IF NOT EXISTS`
esconde o fato de que uma rodou duas, que é coisa sobre a qual você quer ser avisado.

## Nomes, com que você vai conviver mais tempo que com o código

Não há padrão universal, e há um comum que vale seguir se seu time ainda não tem outro:

| | |
|---|---|
| **`snake_case`**, minúsculo | `issued_on`, não `issuedOn` nem `IssuedOn` |
| **tabelas no plural** | `invoices`, porque a tabela guarda muitas |
| **colunas no singular** | `total`, porque a coluna guarda uma por linha |
| **chave estrangeira é `<tabela-singular>_id`** | `customer_id` aponta para `customers.id` |
| **datas terminam em `_on`, momentos em `_at`** | `issued_on` é data, `paid_at` é timestamp |

A regra de caixa não é preferência no PostgreSQL, é armadilha. **Identificadores sem aspas são
rebaixados para minúsculas**, então `CREATE TABLE Invoices` cria uma tabela chamada `invoices` e
tudo funciona — até alguém escrever `CREATE TABLE "Invoices"` com aspas, o que cria uma tabela
*diferente* que só pode ser referida com aspas. Um par de aspas acidental produz um esquema em que
metade das tabelas precisa delas e metade não.

A convenção `_on` / `_at` se paga na primeira vez que você lê o esquema de outra pessoa: dá para
distinguir uma data de um timestamp sem consultar, e a diferença importa mais do que se espera,
como a seção sobre tempo explica.

## Ordene as colunas para quem lê

O banco não liga. Uma pessoa lendo `\d invoices` às três da manhã liga:

1. a chave,
2. as chaves estrangeiras — porque dizem a que esta linha está presa,
3. o que a identifica para um humano — um número, um nome, um código,
4. o resto,
5. os timestamps por último, porque estão em quase toda tabela e carregam o menor significado.

## Uma tabela por comando, e a transação em volta

DDL no PostgreSQL é **transacional**, o que não é verdade em todo banco e vale saber:

```sql
BEGIN;
CREATE TABLE customers ( … );
CREATE TABLE invoices  ( … );
COMMIT;
```

Ou as duas tabelas existem ou nenhuma existe. Uma migração que falha no meio não deixa nada para
trás — nenhum meio-esquema para a próxima pessoa reconciliar à mão. **MySQL não faz isso**: cada
comando DDL comita implicitamente, então uma migração que falha deixa o que rodou antes da falha.
A aula 12 tem as diferenças; importa aqui porque muda o cuidado com que uma migração é escrita.

## O que o comando não consegue dizer

Três coisas pertencem a uma tabela e não estão no `CREATE TABLE`, então são comandos separados e
fáceis de esquecer:

```sql
COMMENT ON TABLE invoices IS 'One row per invoice issued. Never deleted; cancelled is a status.';
COMMENT ON COLUMN invoices.total IS 'Sum of the lines at the moment of issue. Not recomputed.';

CREATE INDEX invoices_customer_id_idx ON invoices (customer_id);

GRANT SELECT ON invoices TO reporting;
```

**`COMMENT ON` é subutilizado e não custa nada.** Fica guardado no banco, aparece no `\d+`, e
sobrevive a toda pessoa que trabalhou aqui. O segundo acima é a regra do instantâneo da aula 2,
escrita onde alguém vai encontrar.

O índice é assunto da aula 9, e é mencionado aqui por uma razão: **uma chave estrangeira não cria
índice em si mesma.** A referência é uma regra sobre o que pode ser guardado; achar rápido as
faturas de um cliente é outra coisa, que você tem que pedir.
