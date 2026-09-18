---
title: Defaults, e colunas que o banco preenche
version: 1
---

Dois jeitos de fazer o banco escrever um valor para ninguém precisar, e não são a mesma coisa.

## `DEFAULT`

```sql
issued_on    date        NOT NULL DEFAULT current_date,
status       text        NOT NULL DEFAULT 'draft',
created_at   timestamptz NOT NULL DEFAULT now(),
tags         text[]      NOT NULL DEFAULT '{}'
```

Um default se aplica **só quando a coluna é omitida da inserção**, e vale ser preciso nisso, porque é
a origem de uma surpresa comum:

```sql
INSERT INTO invoices (customer_id) VALUES (1);               -- status é 'draft'
INSERT INTO invoices (customer_id, status) VALUES (1, NULL); -- status é NULL
```

A segunda não recebe o default. Ela forneceu um valor, e o valor era `NULL` — então numa coluna
`NOT NULL` é recusada, e sem ela a linha é guardada com status desconhecido. Um ORM que manda toda
coluna em toda inserção nunca recebe default nenhum, que é por que o assunto da aula 11 alcança esta
aqui.

**Defaults são avaliados por linha, no momento da inserção.** `now()` é o início da transação, então
toda linha de uma inserção recebe o mesmo timestamp — coerente por projeto.

**E `DEFAULT` não é restrição.** Ele preenche um vazio e não recusa nada. `NOT NULL DEFAULT 0` são
duas afirmações separadas sobre a coluna: uma diz que ela não pode ficar vazia, a outra diz o que pôr
lá se você não disse.

## Colunas geradas

```sql
total_gross numeric(12,2) GENERATED ALWAYS AS (total * (1 + tax_rate)) STORED
```

Uma coluna gerada é **calculada a partir de outras colunas da mesma linha**, toda vez que a linha é
escrita, e não pode receber escrita direta. Uma inserção ou atualização que tente é recusada.

Este é o único lugar deste curso em que guardar um valor derivado é inequivocamente seguro, e a razão
é exatamente o quarto portão da aula 2: **o mecanismo que o mantém correto é o próprio banco, e só
existe um dele.** Nenhum gatilho para escrever, nenhum caminho de código para lembrar, nenhum jeito de
o valor desviar.

As regras, e são mais apertadas do que se espera:

- ele pode ler **só colunas da mesma linha** — sem subconsultas, sem outras tabelas;
- a expressão tem que ser determinística, então `now()` e `random()` são recusados;
- `STORED` é obrigatório no PostgreSQL; colunas geradas virtuais, calculadas na leitura, são recurso
  do MySQL e do SQLite e chegaram ao PostgreSQL 18.

**Onde ela se paga**: uma coluna de busca normalizada ao lado da real.

```sql
email        text NOT NULL,
email_folded text GENERATED ALWAYS AS (lower(email)) STORED UNIQUE
```

Agora a unicidade é insensível a caixa, há um lugar onde o rebaixamento acontece, e nenhuma inserção
pode passar por cima. Compare com fazer isso na aplicação, onde vale até o script de importação.

## `DEFAULT` contra `GENERATED`, decidido numa linha

> **`DEFAULT` define um valor uma vez e a linha passa a ser dona dele. `GENERATED` calcula o valor
> para sempre e a linha nunca é dona.**

`created_at DEFAULT now()` é certo — o momento em que foi criada é um fato sobre aquela linha e não
pode mudar quando a linha é atualizada.

`total_gross GENERATED AS (…)` é certo — não é fato sobre a linha, é aritmética sobre fatos que são.
Mude a alíquota na linha e o bruto segue, que é o que você quer, e é precisamente o que você **não**
iria querer para o `unit_price` da aula 2.

As duas seções da aula 2 continuam sendo o teste: se o valor deve seguir a origem, o banco pode
mantê-lo. Se não pode seguir — um preço do dia, um endereço para onde uma encomenda foi — é
instantâneo, e um `DEFAULT` que o captura uma vez é como você diz isso.

## `updated_at`, e por que não está nesta lista

Você vai querer um, e nenhum dos dois mecanismos te dá. Um `DEFAULT` define na inserção e nunca mais.
Uma coluna gerada não pode usar `now()`, porque isso não é determinístico.

O único jeito correto é um gatilho:

```sql
CREATE FUNCTION touch_updated_at() RETURNS trigger AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER invoices_touch
    BEFORE UPDATE ON invoices
    FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
```

Vale fazer assim em vez de na aplicação, pela razão que a aula 1 deu sobre restrições: a aplicação
nunca é uma aplicação, e um `updated_at` que alguns escritores mantêm e outros não é pior que não ter,
porque parece confiável.
