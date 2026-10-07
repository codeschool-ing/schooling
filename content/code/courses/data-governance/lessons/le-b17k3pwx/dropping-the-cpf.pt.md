---
title: Apagando o CPF
version: 1
---

Todo uso do CPF em claro tem agora um substituto. O suporte o lê decifrando o `cpf_ct` pelo
OpenBao; qualquer um acha um cliente por ele via `cpf_hmac`; os analistas nunca o tiveram. Então a
coluna pode sair. A primeira tentativa:

```
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "ALTER TABLE sales.customers DROP COLUMN cpf"
SET
ERROR:  cannot drop column cpf of table sales.customers because other objects depend on it
DETAIL:  view sales.customer_profile depends on column cpf of table sales.customers
view support.customer_card depends on column cpf of table sales.customers
HINT:  Use DROP ... CASCADE to drop the dependent objects too.
```

Duas views dependem dela. `customer_card` é esperada — ela mostra o CPF mascarado.
`customer_profile` é a view dos analistas da aula 2, e nunca mostrou CPF: ela depende da coluna
porque a consulta interna diz `c.*`, e **um `*` na definição de uma view é dependência de toda
coluna, inclusive das que você pretende remover.** O conserto é nomear as colunas que a view usa:

```sql
-- The CPF in clear has a replacement for each of its uses: cpf_ct to read
-- it (support, through OpenBao) and cpf_hmac to find it. So it goes.
SET ROLE ipe_owner;
CREATE OR REPLACE VIEW sales.customer_profile AS
SELECT customer_id,
       state,
       CASE WHEN age < 18 THEN 'under 18'
            WHEN age < 30 THEN '18-29'
            WHEN age < 50 THEN '30-49'
            WHEN age < 70 THEN '50-69'
            ELSE '70+' END AS age_band,
       created_at::date AS customer_since
FROM (SELECT customer_id, state, created_at,
             extract(year FROM age(DATE '2026-07-01', birth_date))::int AS age
      FROM sales.customers) c;
DROP VIEW support.customer_card;
ALTER TABLE sales.customers DROP COLUMN cpf;
CREATE VIEW support.customer_card WITH (security_barrier) AS
SELECT customer_id, full_name, cpf_hmac, cpf_ct,
       support.mask_email(email) AS email, city, state
FROM sales.customers
WHERE state IN (SELECT r.state FROM support.agent_regions r
                WHERE r.agent = current_user);
GRANT SELECT ON support.customer_card TO support_agent;
```

```
ana@lab:~/gov$ psql -f drop-cpf.sql
SET
CREATE VIEW
DROP VIEW
ALTER TABLE
CREATE VIEW
GRANT
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "\d sales.customers"
SET
                           Table "sales.customers"
      Column      |           Type           | Collation | Nullable | Default 
------------------+--------------------------+-----------+----------+---------
 customer_id      | integer                  |           | not null | 
 full_name        | text                     |           | not null | 
 email            | text                     |           | not null | 
 birth_date       | date                     |           | not null | 
 sex              | character(1)             |           | not null | 
 cep              | text                     |           | not null | 
 city             | text                     |           | not null | 
 state            | character(2)             |           | not null | 
 created_at       | timestamp with time zone |           | not null | 
 marketing_opt_in | boolean                  |           | not null | 
 consent_at       | timestamp with time zone |           |          | 
 cpf_ct           | text                     |           |          | 
 cpf_hmac         | text                     |           |          | 
Indexes:
    "customers_pkey" PRIMARY KEY, btree (customer_id)
    "customers_cpf_hmac_idx" btree (cpf_hmac)
Check constraints:
    "customers_sex_check" CHECK (sex = ANY (ARRAY['F'::bpchar, 'M'::bpchar]))
Referenced by:
    TABLE "sales.orders" CONSTRAINT "orders_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id)
    TABLE "health.prescriptions" CONSTRAINT "prescriptions_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id)
    TABLE "support.tickets" CONSTRAINT "tickets_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id)
Policies:
    POLICY "agent_sees_own_states" FOR SELECT
      TO support_agent
      USING ((state IN ( SELECT r.state
   FROM support.agent_regions r
  WHERE (r.agent = CURRENT_USER))))
    POLICY "analysts_see_all" FOR SELECT
      TO analyst,pipeline
      USING (true)
```

`sales.customers` não tem mais coluna chamada `cpf`. Um dump, uma réplica, um `SELECT *` descuidado,
o log do servidor e o `grep` da aula 3 no arquivo de dados não acham CPF em claro em lugar nenhum da
tabela. O cartão do suporte mostra o HMAC e o texto cifrado, que nada significam para uma pessoa e
são exatamente o que a aplicação do suporte precisa.

## Achando a Paula, de novo

A política do suporte no OpenBao ganha um caminho — calcular o índice — e a aplicação do suporte
faz o que faria quando um cliente dita o número:

```hcl
# Support decrypts a CPF to read it to the customer, and computes the
# index of a CPF the customer reads out, to find them.
path "transit/decrypt/ipe-cpf" {
  capabilities = ["update"]
}
path "transit/hmac/ipe-cpf-index" {
  capabilities = ["update"]
}
```

```
ana@lab:~/gov$ bao policy write support support-hmac.hcl
Success! Uploaded policy: support
ana@lab:~/gov$ bao token create -policy=support -ttl=1h -field=token > support.token && wc -c support.token
26 support.token
ana@lab:~/gov$ BAO_TOKEN=$(cat support.token) bao write -field=hmac transit/hmac/ipe-cpf-index input=$(printf '372.874.168-09' | base64) > wanted.hmac
ana@lab:~/gov$ psql service=carla -c "SELECT customer_id, full_name, email, city FROM support.customer_card WHERE cpf_hmac = '$(cat wanted.hmac)'"
 customer_id |       full_name        |      email       |   city    
-------------+------------------------+------------------+-----------
           1 | Paula Cavalcanti Silva | p***@example.com | São Paulo
(1 row)
```

A aplicação calculou o HMAC do CPF que a cliente disse, com um token que só pode decifrar CPFs e
calcular esse índice, e a view da Carla achou a Paula por ele. Se a Carla precisasse ler o CPF de
volta para ela, o mesmo token decifraria o `cpf_ct`.

**O que o banco guarda sobre um CPF agora são dois textos que ele não consegue transformar em CPF.**
A capacidade de fazê-lo mora no OpenBao, atrás de políticas, num log de auditoria. É a posição mais
forte que este curso alcança para um valor isolado — e custou uma coluna cifrada, uma coluna
indexada, duas políticas e uma view, e é por isso que ela fica reservada aos valores que a merecem.
