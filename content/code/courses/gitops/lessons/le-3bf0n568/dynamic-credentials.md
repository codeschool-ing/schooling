---
title: A password that lives an hour
version: 1
---

**The credential nobody has to rotate is the one that did not exist yesterday.** Vault's database
secrets engine holds one powerful account on a database and uses it to create a new account each
time somebody with the right policy asks: its own name, a random password, a lifetime. When the
lifetime ends, or when somebody revokes it, Vault drops the account. There is no shared password for
the team, no password in a Secret that is the same for a year, and every login in the database's log
names which request it came from.

A database first. PostgreSQL runs in a container beside Vault, on the same `kind` network, so that
Vault reaches it as `postgres`:

```
ana@laptop:~$ docker run -d --name postgres --network kind -e POSTGRES_PASSWORD=initial-password -e POSTGRES_DB=bulletin postgres:17-alpine
394aae6dbc7f3d8b4af41535ccf5f219e0011381ad7b3474d1d1494ff714136d
ana@laptop:~$ docker exec postgres pg_isready
/var/run/postgresql:5432 - accepting connections
```

`initial-password` is the password the database starts with, and the only one a person ever types.
Vault is given it once, with the address and the roles allowed to use this connection:

```
ana@laptop:~$ vault secrets enable database
Success! Enabled the database secrets engine at: database/
ana@laptop:~$ vault write database/config/bulletin plugin_name=postgresql-database-plugin connection_url='postgresql://{{username}}:{{password}}@postgres:5432/bulletin?sslmode=disable' allowed_roles=bulletin-readonly username=postgres password=initial-password
Success! Data written to: database/config/bulletin
```

A **role** is a recipe for an account: the SQL that creates it, and how long it lives. Vault fills
in the name, the password and the expiry. This is `~/vault/readonly.sql`:

```sql
CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "{{name}}";
```

and the role that uses it may read every table, and lives an hour, renewable up to a day:

```
ana@laptop:~$ cat ~/vault/readonly.sql
CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "{{name}}";
ana@laptop:~$ vault write database/roles/bulletin-readonly db_name=bulletin creation_statements=@$HOME/vault/readonly.sql default_ttl=1h max_ttl=24h
Success! Data written to: database/roles/bulletin-readonly
```

Asking for credentials is reading a path:

```
ana@laptop:~$ CREDS=$(vault read -format=json database/creds/bulletin-readonly)
ana@laptop:~$ echo "$CREDS" | jq '{lease_id, lease_duration, renewable, username: .data.username}'
{
  "lease_id": "database/creds/bulletin-readonly/3lDiRxEaNPCCS3HsIaq47m57",
  "lease_duration": 3600,
  "renewable": true,
  "username": "v-root-bulletin-w3GAeOLcZSVDkSCJiQSK-1792125774"
}
```

A lease of 3600 seconds, renewable, and a username Vault made up: `v-`, the name of the token that
asked (`root`, because this terminal uses the root token), the role's name cut to eight letters, a
random part and the time. The password is in `$CREDS` too, and is not printed here, which is the
habit to keep.

The account exists in PostgreSQL now, with its expiry written into it:

```
ana@laptop:~$ DBUSER=$(echo "$CREDS" | jq -r .data.username) PASS=$(echo "$CREDS" | jq -r .data.password)
ana@laptop:~$ docker run --rm --network kind -e PGPASSWORD=$PASS postgres:17-alpine psql -h postgres -U $DBUSER -d bulletin -tAc "select current_user"
v-root-bulletin-w3GAeOLcZSVDkSCJiQSK-1792125774
ana@laptop:~$ docker exec postgres psql -U postgres -tAc "select rolname, rolvaliduntil from pg_roles where rolname like 'v-%'"
v-root-bulletin-w3GAeOLcZSVDkSCJiQSK-1792125774|2026-10-16 05:42:59+00
```

## Ending it early

A lease is Vault's record of something it handed out. Revoking it runs the cleanup at once rather
than at the end of the hour, which is what an incident wants:

```
ana@laptop:~$ vault lease revoke $(echo "$CREDS" | jq -r .lease_id)
All revocation operations queued successfully!
ana@laptop:~$ docker run --rm --network kind -e PGPASSWORD=$PASS postgres:17-alpine psql -h postgres -U $DBUSER -d bulletin -tAc "select current_user"
psql: error: connection to server at "postgres" (172.18.0.6), port 5432 failed: FATAL:  password authentication failed for user "v-root-bulletin-w3GAeOLcZSVDkSCJiQSK-1792125774"
```

`password authentication failed`: the account is gone from PostgreSQL, an hour early, with the same
password that worked a minute before.

## And the one password Vault was given

`initial-password` is now the weakest thing here: a person typed it, it is in a shell history, and
it opens every table as a superuser. Vault can change it to a value nobody knows:

```
ana@laptop:~$ vault write -f database/rotate-root/bulletin
Success! Data written to: database/rotate-root/bulletin
ana@laptop:~$ docker run --rm --network kind -e PGPASSWORD=initial-password postgres:17-alpine psql -h postgres -U postgres -d bulletin -tAc "select 1"
psql: error: connection to server at "postgres" (172.18.0.6), port 5432 failed: FATAL:  password authentication failed for user "postgres"
ana@laptop:~$ vault read -format=json database/creds/bulletin-readonly | jq -r .data.username
v-root-bulletin-iURmahrqOsV1XKIETyTG-1792125776
```

The password a person typed no longer opens the database, and Vault still hands out accounts: it
logged in with the new administrator password, which it chose and kept.

**After this, no person knows a password to the database**, and that includes you. Getting in is
asking Vault, under a policy, which is logged. The escape hatch for the day Vault is down is the
database's own administration path, through the container or the cloud console, and that is a
deliberate, audited act rather than a password in a drawer.
