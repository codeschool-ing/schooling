---
title: pgcrypto, and how a password is kept
version: 1
---

**pgcrypto puts hash functions and encryption inside the database.** The case a DBA meets most is
a table of users with passwords in it, and the question is what that column should hold. The wrong
answers are the password itself, which anybody with a backup can read, and a plain hash of it,
which looks safe and is not. This section shows why, with the extension installed in `ana` in the
first section of this lesson.

## A hash is the same every time

`digest` computes a cryptographic hash: a fixed-length fingerprint that cannot be turned back into
its input. Here is SHA-256 of a password, twice:

```
ana=# SELECT encode(digest('correct horse battery', 'sha256'), 'hex');
                              encode                              
------------------------------------------------------------------
 9028ea0d15decaa35b2da21c0290af3b1a5ba0a30a591906f89b5074e209ea72
(1 row)

ana=# SELECT encode(digest('correct horse battery', 'sha256'), 'hex');
                              encode                              
------------------------------------------------------------------
 9028ea0d15decaa35b2da21c0290af3b1a5ba0a30a591906f89b5074e209ea72
(1 row)
```

The same input gives the same output, which is the whole point of a hash and the whole problem with
storing passwords this way. **Two users with the same password have the same value in the column**,
so learning one teaches the other. And the function is built to be fast, which helps anybody who
has stolen the table and is trying candidate passwords one after another:

```
ana=# \timing on
Timing is on.

ana=# SELECT count(digest(i::text, 'sha256')) FROM generate_series(1, 100000) AS i;
 count  
--------
 100000
(1 row)

Time: 149.499 ms

ana=# \timing off
Timing is off.
```

A hundred thousand SHA-256 hashes took 149.499 ms on the recording machine, roughly two thirds of a
million a second from one SQL statement on one core. That speed is why a table of plain hashes is not
safe: whoever copies it can test candidates just as fast.

## crypt and gen_salt

`digest` is the right tool for checking that a file has not changed. For a password, pgcrypto has
**`crypt`**, which hashes with a **salt** and a deliberately slow algorithm. `gen_salt('bf')` makes
a random salt for **bcrypt** (the `bf` is Blowfish, the cipher it is built on), and `crypt` stores
the salt inside the result:

```
ana=# CREATE TABLE app_users (
ana(#     email         text PRIMARY KEY,
ana(#     password_hash text NOT NULL
ana(# );
CREATE TABLE

ana=# INSERT INTO app_users VALUES
ana-#     ('ana@example.com', crypt('correct horse battery', gen_salt('bf'))),
ana-#     ('rui@example.com', crypt('correct horse battery', gen_salt('bf')));
INSERT 0 2

ana=# SELECT * FROM app_users;
      email      |                        password_hash                         
-----------------+--------------------------------------------------------------
 ana@example.com | $2a$06$f5boI99NkExsvSRJ89EdVOF/rWxffy2LsNdlC3rsP4Onbx0T6HXSK
 rui@example.com | $2a$06$Oe/6dSvGLIDc6ZRb7oK3gOY19iFXt4tRamiIjmhHHx13aowXsh7UG
(2 rows)
```

**The same password, two different values**, because each got its own salt. The value reads in
parts: `$2a$` names bcrypt, `06` is the cost, and the next 22 characters are the salt. The cost is
a power of two: each step up doubles the work. One hash at the default cost and one at 12:

```
ana=# \timing on
Timing is on.

ana=# SELECT crypt('correct horse battery', gen_salt('bf')) IS NOT NULL;
 ?column? 
----------
 t
(1 row)

Time: 5.993 ms

ana=# SELECT crypt('correct horse battery', gen_salt('bf', 12)) IS NOT NULL;
 ?column? 
----------
 t
(1 row)

Time: 259.907 ms

ana=# \timing off
Timing is off.
```

5.993 ms at the default cost, 259.907 ms at 12, on the same machine. **One bcrypt hash at cost 12
took longer than the hundred thousand SHA-256 hashes above.** Slow is the point: a login waits that
fraction of a second once, and anybody testing guesses against a stolen copy waits it for every
guess. Choose the highest cost your login rate can afford.

To check a password at login, hash what was typed **with the stored value as the salt**. `crypt`
finds the salt and the cost inside it, so the result equals the stored value exactly when the
password is the same:

```
ana=# SELECT email FROM app_users
ana-#  WHERE email = 'ana@example.com'
ana-#    AND password_hash = crypt('correct horse battery', password_hash);
      email      
-----------------
 ana@example.com
(1 row)

ana=# SELECT email FROM app_users
ana-#  WHERE email = 'ana@example.com'
ana-#    AND password_hash = crypt('correct horse batery', password_hash);
 email 
-------
(0 rows)
```

One letter missing, no row. Nothing in the table can be decoded back into a password, and the
column is useless to anybody who copies it except as a slow, per-user guessing exercise.

## Where the hashing should happen

There is a catch that belongs to this course rather than to cryptography. With `crypt` in SQL, **the
password travels to the server in plain text inside the statement**, and anything that records
statements records it: `log_statement = 'all'` writes it to the server log in full, and lesson 19
is about that log. Most applications therefore hash in their own code, with their language's bcrypt or Argon2 library, and
send the database only the result. pgcrypto is the right tool when the database itself has to do
it: a migration that converts old plain-text passwords in place, or a system with no application
layer in front.

## gen_random_uuid is not pgcrypto's any more

Older guides install pgcrypto for one function, `gen_random_uuid()`, which makes a random UUID for
a primary key. Since PostgreSQL 13 it is part of the core server, and `shop`, which has no pgcrypto,
has it:

```
shop=# SELECT gen_random_uuid();
           gen_random_uuid            
--------------------------------------
 47a194b3-214f-4601-8c1b-48945f44af34
(1 row)

shop=# \df gen_random_uuid
                              List of functions
   Schema   |      Name       | Result data type | Argument data types | Type 
------------+-----------------+------------------+---------------------+------
 pg_catalog | gen_random_uuid | uuid             |                     | func
(1 row)
```

Schema `pg_catalog` is the server's own. **An application that needs only UUIDs needs no
extension**, and one fewer extension is one fewer thing to carry through every upgrade.
