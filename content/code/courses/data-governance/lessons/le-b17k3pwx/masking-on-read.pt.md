---
title: Mascarando o que é mostrado
version: 1
---

A Carla atende clientes. Ela precisa ver com quem está falando — um nome, uma cidade — e conferir
que a pessoa é quem diz ser. Ela não precisa ver um CPF inteiro nem um e-mail inteiro na tela, onde
uma foto, alguém por cima do ombro ou um compartilhamento de tela conseguem copiá-los.

**Mascarar mostra parte de um valor e esconde o resto.** Feito no banco, pode ser o único jeito de
o suporte ler clientes:

```sql
-- How support sees a customer: enough to recognise them, not enough to
-- copy their documents.
SET ROLE ipe_owner;
CREATE FUNCTION support.mask_cpf(cpf text) RETURNS text
  LANGUAGE sql IMMUTABLE
  RETURN '***.' || substr(cpf, 5, 7) || '-**';
CREATE FUNCTION support.mask_email(email text) RETURNS text
  LANGUAGE sql IMMUTABLE
  RETURN left(email, 1) || '***@' || split_part(email, '@', 2);

CREATE VIEW support.customer_card WITH (security_barrier) AS
SELECT customer_id, full_name,
       support.mask_cpf(cpf)     AS cpf,
       support.mask_email(email) AS email,
       city, state
FROM sales.customers
WHERE state IN (SELECT r.state FROM support.agent_regions r
                WHERE r.agent = current_user);

GRANT SELECT ON support.customer_card TO support_agent;
REVOKE SELECT ON sales.customers FROM support_agent;
```

```
ana@lab:~/gov$ psql -f mask.sql
SET
CREATE FUNCTION
CREATE FUNCTION
CREATE VIEW
GRANT
REVOKE
ana@lab:~/gov$ psql service=carla -c "SELECT * FROM support.customer_card ORDER BY customer_id LIMIT 3"
ERROR:  permission denied for function mask_cpf
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "GRANT EXECUTE ON FUNCTION support.mask_cpf(text), support.mask_email(text) TO support_agent"
SET
GRANT
ana@lab:~/gov$ psql service=carla -c "SELECT * FROM support.customer_card ORDER BY customer_id LIMIT 3"
 customer_id |        full_name        |      cpf       |      email       |   city    | state 
-------------+-------------------------+----------------+------------------+-----------+-------
           1 | Paula Cavalcanti Silva  | ***.874.168-** | p***@example.com | São Paulo | SP
           4 | Samuel Carvalho Barbosa | ***.862.569-** | s***@example.com | Niterói   | RJ
           6 | Davi Almeida Freitas    | ***.836.173-** | d***@example.com | São Paulo | SP
(3 rows)

ana@lab:~/gov$ psql service=carla -c "SELECT count(*) FROM support.customer_card"
 count 
-------
  3386
(1 row)

ana@lab:~/gov$ psql service=carla -c "SELECT cpf FROM sales.customers LIMIT 1"
ERROR:  permission denied for table customers
```

Quatro coisas aconteceram, e a primeira é a aula 2 rendendo. **As funções foram recusadas** à
Carla: a aula 2 fez toda função nova nascer fechada a `PUBLIC`, então uma função que alguém escreve
precisa ser concedida de propósito. Uma concessão depois, o cartão funciona.

Depois, o desenho:

- **A view é uma view padrão, que roda como o dono**, porque precisa ler o CPF inteiro para
  mascará-lo. A aula 2 mostrou que uma view assim pula a política de linha da tabela — então esta
  view carrega a regra de região **ela mesma**, no `WHERE`, lendo a mesma tabela `agent_regions`. A
  Carla vê os 3.386 clientes dela, como antes.
- **`security_barrier`** impede o PostgreSQL de avaliar uma condição que a Carla escreva antes do
  `WHERE` da própria view. Sem isso, uma função escrita com esperteza na consulta dela poderia
  receber linhas de outras regiões enquanto o planejador ainda filtrava. Com isso, as condições dela
  rodam sobre o que a view já permitiu.
- **O `SELECT` do suporte na tabela é revogado.** A view deixa de ser uma conveniência ao lado da
  tabela; ela é a única porta.

## O que é mascarar, jurídica e tecnicamente

**Dado mascarado é dado pessoal**, e a tabela embaixo da view ainda guarda todo CPF em claro.
Mascarar protege contra o que é *mostrado*: telas, capturas de tela, relatórios, o atendente que
copia um número num papel. Não faz nada por um backup, uma réplica ou um papel com `SELECT` na
tabela — para isso serviram as aulas 3 e 4.

E a parte mostrada precisa ser escolhida com cuidado. `***.874.168-**` esconde os três primeiros
dígitos e os dois verificadores; quem sabe o nome e a cidade do cliente e vê sete dos onze dígitos
tem muito. A regra comum é mostrar só o que o trabalho precisa *confirmar*, não *achar*: "os quatro
últimos dígitos" quando o cliente dita o número, nada quando não dita. As próximas seções tiram o
CPF deste cartão de vez.
