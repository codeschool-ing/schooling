---
title: Privilégios numa coluna
version: 1
---

Os analistas precisam de clientes para quase toda pergunta que fazem — vendas por estado,
clientes novos por mês, quantos aceitaram marketing. Nenhuma delas precisa de nome, e-mail, CPF
ou data de nascimento. Hoje eles não têm nada na tabela:

```
ana@lab:~/gov$ psql service=bruno -c "SELECT * FROM sales.customers LIMIT 1"
ERROR:  permission denied for table customers
```

Conceder `SELECT` na tabela responderia toda pergunta analítica e entregaria quatro colunas de
dado identificador a todo mundo do cargo. O PostgreSQL consegue conceder um verbo **em colunas
nomeadas**:

```sql
-- Analysts see who the customers are as a population, never as people.
SET ROLE ipe_owner;
GRANT SELECT (customer_id, sex, city, state, created_at, marketing_opt_in)
  ON sales.customers TO analyst;
```

```
ana@lab:~/gov$ psql -f columns.sql
SET
GRANT
ana@lab:~/gov$ psql service=bruno -c "SELECT * FROM sales.customers LIMIT 1"
ERROR:  permission denied for table customers
ana@lab:~/gov$ psql service=bruno -c "SELECT state, count(*) FROM sales.customers GROUP BY state ORDER BY 2 DESC LIMIT 5"
 state | count 
-------+-------
 SP    |  2322
 RJ    |  1064
 MG    |   468
 PR    |   390
 RS    |   318
(5 rows)

ana@lab:~/gov$ psql service=bruno -c "SELECT email FROM sales.customers LIMIT 1"
ERROR:  permission denied for table customers
ana@lab:~/gov$ psql -c "\dp sales.customers"
                                      Access privileges
 Schema |   Name    | Type  |      Access privileges      |   Column privileges   | Policies 
--------+-----------+-------+-----------------------------+-----------------------+----------
 sales  | customers | table | ipe_owner=arwdDxt/ipe_owner+| customer_id:         +| 
        |           |       | pipeline=r/ipe_owner       +|   analyst=r/ipe_owner+| 
        |           |       | support_agent=r/ipe_owner   | sex:                 +| 
        |           |       |                             |   analyst=r/ipe_owner+| 
        |           |       |                             | city:                +| 
        |           |       |                             |   analyst=r/ipe_owner+| 
        |           |       |                             | state:               +| 
        |           |       |                             |   analyst=r/ipe_owner+| 
        |           |       |                             | created_at:          +| 
        |           |       |                             |   analyst=r/ipe_owner+| 
        |           |       |                             | marketing_opt_in:    +| 
        |           |       |                             |   analyst=r/ipe_owner | 
(1 row)
```

Três respostas, uma regra:

- **`SELECT *` é recusado.** O asterisco pede toda coluna, inclusive as não concedidas, e o
  servidor recusa o comando inteiro em vez de devolver calado um subconjunto. É o comportamento
  certo — uma consulta que derruba colunas em silêncio seria uma consulta que mente — e é também
  a primeira coisa em que um analista tropeça. A saída é nomear as colunas.
- **Nomear colunas concedidas funciona**, e a análise de que o Bruno precisava roda: São Paulo
  tem 2.322 dos clientes da Ipê.
- **Nomear uma não concedida é recusado**, com a mesma mensagem.

`\dp` agora lista as seis colunas uma a uma em **Column privileges**, ao lado das concessões na
tabela inteira para `pipeline` e `support_agent`. Essa listagem é o documento que um auditor
pede: as colunas de `sales.customers` que um analista vê, concedidas por quem.

## Para que servem privilégios de coluna, e para que não servem

**Eles filtram o que pode ser selecionado, não o que pode ser deduzido.** O Bruno consegue contar
clientes por `state`, `city` e `sex`, e agrupá-los por mês de cadastro. A aula 5 mostra quão
poucas dessas combinações bastam para um grupo ter uma pessoa só, e aí uma consulta de
"população" descreve alguém. Privilégios de coluna mantêm o CPF fora dos resultados do Bruno. Não
tornam, sozinhos, anônimo o que sobra.

**Eles também são incômodos de conviver.** Toda coluna nova pede uma decisão, `SELECT *` falha em
toda ferramenta que o escreve, e as concessões ficam invisíveis para quem lê só o `\dp` da tabela.
A saída comum é o assunto da próxima seção: dar aos analistas uma view que já tem as colunas
certas, calculadas do jeito certo, e conceder essa view.
