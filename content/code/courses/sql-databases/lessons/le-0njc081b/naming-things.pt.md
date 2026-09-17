---
title: Nomeie suas restrições, antes que o banco as nomeie
version: 1
---

Toda restrição tem um nome. Se você não der um, o PostgreSQL inventa, e o nome inventado é a razão de
esta seção existir.

```sql
CREATE TABLE invoices (
    number text NOT NULL UNIQUE,
    total  numeric(12,2) NOT NULL CHECK (total >= 0)
);
```

```
Indexes:
    "invoices_number_key" UNIQUE CONSTRAINT, btree (number)
Check constraints:
    "invoices_total_check" CHECK (total >= 0)
```

Nomes razoáveis, e eles te custam duas vezes.

## O primeiro custo: o que uma pessoa vê

Uma aplicação captura a violação de restrição e precisa transformá-la numa frase. O que ela recebe é:

```
ERROR:  duplicate key value violates unique constraint "invoices_number_key"
```

`invoices_number_key` é um nome que um programa pode casar, então a aplicação diz *"esse número de
fatura já está em uso"* comparando com aquela string. Funciona — até uma tabela ter dois `CHECK` na
mesma coluna:

```
"invoices_total_check"    CHECK (total >= 0)
"invoices_total_check1"   CHECK (total < 1000000)
```

**O `1` é posicional.** Qual regra é qual depende da ordem em que foram declaradas, e uma migração
que derruba e recria uma pode renumerá-las. A mensagem da aplicação agora está presa a um nome que se
moveu, e ela reporta a regra errada com total confiança.

## O segundo custo: derrubar algo que você não consegue nomear

```sql
ALTER TABLE invoices DROP CONSTRAINT invoices_total_check1;
```

Tudo bem, até você ter que escrever essa migração contra um banco em que o nome gerado é diferente —
porque as restrições foram acrescentadas em outra ordem no ambiente de testes, ou porque uma versão
mais antiga do PostgreSQL numerava diferente. **A migração passa num banco e falha no outro**, que é o
pior tipo de falha que uma migração tem.

## Então nomeie

```sql
CREATE TABLE invoices (
    id          bigint GENERATED ALWAYS AS IDENTITY,
    customer_id bigint NOT NULL,
    number      text   NOT NULL,
    total       numeric(12,2) NOT NULL,
    paid_at     timestamptz,

    CONSTRAINT invoices_pk           PRIMARY KEY (id),
    CONSTRAINT invoices_number_uq    UNIQUE (number),
    CONSTRAINT invoices_customer_fk  FOREIGN KEY (customer_id)
                                     REFERENCES customers (id) ON DELETE RESTRICT,
    CONSTRAINT invoices_total_not_negative CHECK (total >= 0),
    CONSTRAINT invoices_total_sane         CHECK (total < 1000000)
);
```

Agora a mensagem de erro nomeia a regra em vez da coluna, e continua sendo aquele nome para sempre:

```
ERROR:  new row for relation "invoices" violates check constraint "invoices_total_not_negative"
```

Uma pessoa lendo isso sabe o que deu errado sem abrir o esquema. Um programa casando com isso está
casando com algo que alguém escolheu.

## Uma convenção que se sustenta

| sufixo | para |
|---|---|
| `_pk` | chave primária |
| `_uq` | unicidade |
| `_fk` | chave estrangeira |
| `_ck` ou uma frase | check |

Para checks, **uma frase ganha de um sufixo**. `invoices_total_not_negative` diz o que está errado;
`invoices_total_ck2` diz qual deles era. O nome é a mensagem de erro que o usuário do seu usuário
acaba vendo, uma camada adiante, então escreva como se alguém fosse ler — porque vai.

## O contra-argumento, dito com justiça

Nomear toda restrição é mais para digitar, e numa tabela de quatro colunas e duas regras os nomes
gerados são perfeitamente claros. Muitos esquemas bons não fazem isso.

Onde deixa de ser opcional:

- **quando mais de um `CHECK` toca uma coluna**, porque é aí que a numeração posicional começa;
- **quando a aplicação transforma violações em mensagens**, porque ela está casando com o nome;
- **quando migrações precisam rodar idênticas em vários bancos**, que é todo sistema implantado.

Se nenhuma dessas é verdade ainda, as três viram verdade depois, e acrescentar nomes mais tarde
significa uma migração por restrição. É um dos poucos hábitos desta aula que não custa nada agora e
não pode ser aplicado depois com custo baixo.

## Já que você está aqui: `COMMENT ON`

```sql
COMMENT ON CONSTRAINT invoices_total_sane ON invoices IS
    'Uma guarda contra virgula deslocada, nao um limite de negocio.';
```

Uma restrição diz o que é recusado. Um comentário diz por quê, que é o que alguém precisa quando
esbarra nela às três da manhã e está decidindo se remove.
