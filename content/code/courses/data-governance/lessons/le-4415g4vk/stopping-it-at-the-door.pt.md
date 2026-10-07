---
title: Barrando na porta
version: 1
---

Medir acha os defeitos que já entraram. O movimento mais barato é impedir o próximo de entrar, e o
PostgreSQL tem um jeito de fazer isso sem antes ter de corrigir toda linha antiga:

```sql
-- New rows must have the shape; the old ones are checked separately.
SET ROLE ipe_owner;
ALTER TABLE sales.customers ADD CONSTRAINT email_shape
  CHECK (email ~* '^[^@ ]+@[^@ ]+\.[a-z]{2,}$' OR email LIKE 'erased-%@invalid')
  NOT VALID;
```

```
ana@lab:~/gov$ psql -f email-check.sql
SET
ALTER TABLE
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "INSERT INTO sales.customers (customer_id, full_name, email, birth_date, sex, cep, city, state, created_at, marketing_opt_in) VALUES (9001, 'Teste Novo', 'teste.novoexample.com', '1990-01-01', 'F', '01001-000', 'São Paulo', 'SP', '2026-07-01 09:00-03', false)"
SET
ERROR:  new row for relation "customers" violates check constraint "email_shape"
DETAIL:  Failing row contains (9001, Teste Novo, teste.novoexample.com, 1990-01-01, F, 01001-000, São Paulo, SP, 2026-07-01 09:00:00-03, f, null, null, null).
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "ALTER TABLE sales.customers VALIDATE CONSTRAINT email_shape"
SET
ERROR:  check constraint "email_shape" of relation "customers" is violated by some row
```

O `NOT VALID` é a chave. A restrição vale para **toda linha nova ou alterada** a partir daquele
momento — o insert de um endereço malformado é recusado na hora —, mas o PostgreSQL não confere as
linhas que já estão na tabela. O `VALIDATE CONSTRAINT` confere, e falha, porque os 23 continuam lá.
Quando o último deles for corrigido, o mesmo comando funciona, e dali em diante a restrição é uma
garantia sobre a tabela inteira.

Essa ordem de trabalho é o que a torna prática:

1. **estancar**: uma restrição `NOT VALID`, hoje, sem migração de dados;
2. **corrigir as linhas antigas** no ritmo do dono — aqui, perguntando aos clientes;
3. **validar**, e a regra em `gov.quality_rules` fica redundante para essa tabela, porque o próprio
   banco agora recusa o que ela contava.

A restrição permite uma exceção, `erased-%@invalid`, o endereço que a aula 7 pôs no lugar do e-mail de
um cliente eliminado. Uma exceção escrita na restrição é visível e revisada; uma tratada com "a gente
só pula essas linhas" é invisível e esquecida.

## O que uma restrição não consegue

Os três pedidos com data em 2027 não podem ser barrados assim. Um `CHECK` tem de dar a mesma resposta
toda vez que é perguntado sobre a mesma linha, então não pode comparar com a data atual: `now()` não é
permitido nele. Recusar uma data futura pede um gatilho, ou — melhor — uma verificação na importação
que as escreveu, que é onde o defeito foi feito. O banco é a última porta, e não a única.
