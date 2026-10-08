---
title: Funções, e as concessões que ninguém quis
version: 1
---

Todo controle desta aula pode ser desfeito por um objeto que lê dado em nome de alguém. A view da
seção 8 foi um. Uma função é o outro, e vem com um padrão que surpreende quase todo mundo.

Ana escreve uma pequena ajuda para o site — dado o id de um cliente, devolver o e-mail — e a
marca `SECURITY DEFINER`, para que rode com os privilégios do dono e o site não precise de
`SELECT` na tabela:

```sql
SET ROLE ipe_owner;
CREATE FUNCTION sales.customer_email(id integer) RETURNS text
LANGUAGE sql SECURITY DEFINER SET search_path = sales, pg_temp
AS $$ SELECT email FROM sales.customers WHERE customer_id = id $$;
```

```
ana@lab:~/gov$ psql -f fn.sql
SET
CREATE FUNCTION
ana@lab:~/gov$ psql service=bruno -c "SELECT sales.customer_email(1)"
        customer_email        
------------------------------
 paula.cavalcanti@example.com
(1 row)

ana@lab:~/gov$ psql -c "\df+ sales.customer_email"
                                                                                  List of functions
 Schema |      Name      | Result data type | Argument data types | Type | Volatility | Parallel |   Owner   | Security | Access privileges | Language | Internal name | Description 
--------+----------------+------------------+---------------------+------+------------+----------+-----------+----------+-------------------+----------+---------------+-------------
 sales  | customer_email | text             | id integer          | func | volatile   | unsafe   | ipe_owner | definer  |                   | sql      |               | 
(1 row)

ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "REVOKE EXECUTE ON FUNCTION sales.customer_email(integer) FROM PUBLIC"
SET
REVOKE
ana@lab:~/gov$ psql service=bruno -c "SELECT sales.customer_email(1)"
ERROR:  permission denied for function customer_email
```

O Bruno não tem direito a e-mail nenhum, e **a função entregou um a ele**. Dois fatos se combinam:

- **`SECURITY DEFINER` roda o corpo como o dono da função**, `ipe_owner`, que lê toda coluna e é
  isento das políticas da tabela.
- **Uma função nova é executável por `PUBLIC`.** Esse é o padrão do PostgreSQL para funções, o
  oposto do padrão para tabelas, e o `\df+` o mostra do mesmo jeito que o `\dp` mostrou o banco na
  aula 1: uma coluna **Access privileges** vazia, que quer dizer o padrão.

Revogar `EXECUTE` de `PUBLIC` fecha a porta, e o passo seguinte seria concedê-lo só a `app_web`. O
hábito mais seguro é tornar isso o padrão antes de escrever qualquer função, com o mesmo
mecanismo que a seção 4 usou para tabelas:

```
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC"
SET
ALTER DEFAULT PRIVILEGES
ana@lab:~/gov$ psql -c "\ddp"
               Default access privileges
   Owner   | Schema |   Type   |   Access privileges   
-----------+--------+----------+-----------------------
 ipe_owner | sales  | table    | analyst=r/ipe_owner
 ipe_owner |        | function | ipe_owner=X/ipe_owner
(2 rows)
```

O `\ddp` agora tem uma segunda linha para `ipe_owner`: funções, com a coluna de acesso dizendo
`ipe_owner=X/ipe_owner` e nada para `PUBLIC`. Toda função que o dono criar daqui em diante nasce
fechada.

O arquivo acima também faz uma coisa certa que vale copiar: `SET search_path = sales, pg_temp`.
Uma função definer que procurasse `customers` pelo search path de quem a chama poderia ser
apontada para uma tabela criada por quem chama; fixar o caminho na definição da função é o que a
documentação do PostgreSQL recomenda para toda função `SECURITY DEFINER`.

## As concessões que ninguém quis

As outras falhas desta aula têm uma forma em comum: uma concessão mais larga que a decisão por
trás dela. Quatro são comuns o bastante para procurar pelo nome.

| padrão | o que faz | em vez disso |
|---|---|---|
| `GRANT ALL ON … TO …` | todo verbo, inclusive `TRUNCATE` e `TRIGGER`, para resolver um `permission denied` | o único verbo que o erro nomeou |
| `… WITH GRANT OPTION` | quem recebe pode repassar o privilégio, e as concessões dele ficam no nome dele | concessões feitas pelo dono, a cargos |
| uma concessão a `PUBLIC` | todo papel, inclusive os criados no ano que vem | uma concessão a um cargo |
| uma função ou view definer que ninguém revisou | lê como o dono, por cima de concessões de coluna e políticas de linha | views `security_invoker`; funções definer com `EXECUTE` concedido por nome |

Nenhum deles é erro quando é uma decisão. Cada um é erro quando foi o jeito mais rápido de fazer
uma mensagem de erro sumir — e é por isso que uma revisão pergunta não só *quem tem isso*, mas
*por quê*.
