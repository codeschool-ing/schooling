---
title: A tabela onde o boxoffice guarda os eventos
version: 1
---

O `Event` do boxoffice tem quatro campos, e a tabela dele tem quatro colunas. **Tudo o que o store da
aula 3 impunha em Go, a tabela agora impõe sozinha**, para que um bug num handler, um script rodado à
mão ou um segundo programa que compartilhe o banco não consiga gravar uma linha que as regras proíbem.
Salve isto em `~/boxoffice` como `schema.sql`:

```sql
-- boxoffice/schema.sql
CREATE TABLE events (
    id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name  text    NOT NULL UNIQUE CHECK (length(name) BETWEEN 1 AND 100),
    seats integer NOT NULL CHECK (seats > 0),
    sold  integer NOT NULL DEFAULT 0 CHECK (sold BETWEEN 0 AND seats)
);

INSERT INTO events (name, seats, sold) VALUES
    ('Jazz at the Docks', 120, 0),
    ('Chamber Choir', 80, 80);
```

Cada restrição é uma das regras da aula 3, descida uma camada:

| coluna | restrição | a regra |
|---|---|---|
| `id` | `GENERATED ALWAYS AS IDENTITY PRIMARY KEY` | o banco numera os eventos, e dois nunca dividem um número |
| `name` | `NOT NULL UNIQUE`, tamanho de 1 a 100 | todo evento tem nome, com o mesmo limite de tamanho do `newEvent.validate`, e dois eventos nunca dividem um |
| `seats` | `CHECK (seats > 0)` | um evento tem lugares |
| `sold` | `CHECK (sold BETWEEN 0 AND seats)` | **nenhum evento é vendido além dos seus lugares**, seja quem for que grave a linha |

A última regra é a que mais importa. Ela era uma linha de Go no `Sell`; agora é uma promessa que o banco
cumpre até contra código que a esqueceu. A aula 3 do `sql-databases` trata de tipos e restrições por
inteiro, e nada aqui vai além dela.

O `psql -f` roda o arquivo:

```
ana@vm:~/boxoffice$ psql boxoffice -f schema.sql
CREATE TABLE
INSERT 0 2
ana@vm:~/boxoffice$ psql boxoffice -c "\d events"
                         Table "public.events"
 Column |  Type   | Collation | Nullable |           Default            
--------+---------+-----------+----------+------------------------------
 id     | integer |           | not null | generated always as identity
 name   | text    |           | not null | 
 seats  | integer |           | not null | 
 sold   | integer |           | not null | 0
Indexes:
    "events_pkey" PRIMARY KEY, btree (id)
    "events_name_key" UNIQUE CONSTRAINT, btree (name)
Check constraints:
    "events_check" CHECK (sold >= 0 AND sold <= seats)
    "events_name_check" CHECK (length(name) >= 1 AND length(name) <= 100)
    "events_seats_check" CHECK (seats > 0)

ana@vm:~/boxoffice$ psql boxoffice -c "SELECT * FROM events"
 id |       name        | seats | sold 
----+-------------------+-------+------
  1 | Jazz at the Docks |   120 |    0
  2 | Chamber Choir     |    80 |   80
(2 rows)
```

O `\d events` descreve a tabela de volta, e as restrições têm nomes que o PostgreSQL escolheu:
**`events_name_key`** para a unicidade e **`events_check`** para a regra de `sold`. A seção 08
reencontra os dois nomes, em mensagens de erro. As duas linhas são os mesmos dois eventos com que o
store em memória começava, então toda transcrição das aulas 1 a 3 se leria igual contra esta tabela.

Rodar o `schema.sql` duas vezes falha no `CREATE TABLE`, porque a tabela existe. Esse é o problema que a
aula 9 resolve com migrações; até lá, o arquivo é rodado uma vez.
