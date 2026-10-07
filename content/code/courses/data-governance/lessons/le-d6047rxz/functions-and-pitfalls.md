---
title: Functions, and the grants nobody meant
version: 1
---

Every control in this lesson can be undone by an object that reads data on somebody's behalf. The
view in section 8 was one. A function is the other, and it comes with a default that surprises
almost everybody.

Ana writes a small helper for the website — given a customer's id, return their e-mail — and
marks it `SECURITY DEFINER`, so that it runs with the owner's privileges and the website does not
need `SELECT` on the table:

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

Bruno has no right to any e-mail address, and **the function handed him one**. Two facts combine:

- **`SECURITY DEFINER` runs the body as the function's owner**, `ipe_owner`, who can read every
  column and is exempt from the table's policies.
- **A new function is executable by `PUBLIC`.** That is PostgreSQL's default for functions, the
  opposite of its default for tables, and `\df+` shows it the same way `\dp` showed the database
  in lesson 1: an empty **Access privileges** column, which means the default.

Revoking `EXECUTE` from `PUBLIC` closes it, and the next step would be to grant it to `app_web`
alone. The safer habit is to make that the default before writing any function, with the same
mechanism section 4 used for tables:

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

`\ddp` now carries a second line for `ipe_owner`: functions, with the access column reading
`ipe_owner=X/ipe_owner` and nothing for `PUBLIC`. Every function the owner creates from here on
starts closed.

The file above also does one thing right that is worth copying: `SET search_path = sales,
pg_temp`. A definer function that looked up `customers` through the caller's search path could be
pointed at a table of the caller's own making; fixing the path in the function's definition is
what the PostgreSQL documentation recommends for every `SECURITY DEFINER` function.

## The grants nobody meant

The rest of this lesson's failures share one shape: a grant wider than the decision behind it.
Four of them are common enough to look for by name.

| pattern | what it does | instead |
|---|---|---|
| `GRANT ALL ON … TO …` | every verb, including `TRUNCATE` and `TRIGGER`, to fix one `permission denied` | the one verb the error named |
| `… WITH GRANT OPTION` | the grantee may pass the privilege on, and their grants survive in their name | grants made by the owner, to jobs |
| a grant to `PUBLIC` | every role, including ones created next year | a grant to a job |
| a definer function or view nobody reviewed | reads as its owner, past column grants and row policies | `security_invoker` views; definer functions with `EXECUTE` granted by name |

None of these is a mistake when it is a decision. Each is a mistake when it was the quickest way to
make an error message go away — which is why a review asks not only *who has this* but *why*.
