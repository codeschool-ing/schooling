---
title: Uma senha que vive uma hora
version: 1
---

**A credencial que ninguém precisa rotacionar é a que não existia ontem.** O secrets engine de banco
de dados do Vault guarda uma conta poderosa num banco e a usa para criar uma conta nova a cada vez
que alguém com a política certa pede: nome próprio, senha aleatória, prazo de vida. Quando o prazo
acaba, ou quando alguém revoga, o Vault apaga a conta. Não há senha compartilhada pelo time, nem uma
senha num Secret que fica igual por um ano, e todo login no log do banco diz de qual pedido veio.

Primeiro, um banco. O PostgreSQL roda num contêiner ao lado do Vault, na mesma rede `kind`, para que
o Vault o alcance como `postgres`:

```
ana@laptop:~$ docker run -d --name postgres --network kind -e POSTGRES_PASSWORD=initial-password -e POSTGRES_DB=bulletin postgres:17-alpine
394aae6dbc7f3d8b4af41535ccf5f219e0011381ad7b3474d1d1494ff714136d
ana@laptop:~$ docker exec postgres pg_isready
/var/run/postgresql:5432 - accepting connections
```

`initial-password` é a senha com que o banco começa, e a única que uma pessoa chega a digitar. O
Vault a recebe uma vez, junto com o endereço e os roles que podem usar esta conexão:

```
ana@laptop:~$ vault secrets enable database
Success! Enabled the database secrets engine at: database/
ana@laptop:~$ vault write database/config/bulletin plugin_name=postgresql-database-plugin connection_url='postgresql://{{username}}:{{password}}@postgres:5432/bulletin?sslmode=disable' allowed_roles=bulletin-readonly username=postgres password=initial-password
Success! Data written to: database/config/bulletin
```

Um **role** é uma receita de conta: o SQL que a cria, e quanto tempo ela vive. O Vault preenche o
nome, a senha e a expiração. Este é `~/vault/readonly.sql`:

```sql
CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "{{name}}";
```

e o role que o usa pode ler toda tabela, e vive uma hora, renovável até um dia:

```
ana@laptop:~$ cat ~/vault/readonly.sql
CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "{{name}}";
ana@laptop:~$ vault write database/roles/bulletin-readonly db_name=bulletin creation_statements=@$HOME/vault/readonly.sql default_ttl=1h max_ttl=24h
Success! Data written to: database/roles/bulletin-readonly
```

Pedir credenciais é ler um caminho:

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

Um lease de 3600 segundos, renovável, e um nome de usuário que o Vault inventou: `v-`, o nome do
token que pediu (`root`, porque este terminal usa o token root), o nome do role cortado em oito
letras, uma parte aleatória e a hora. A senha também está em `$CREDS`, e não é impressa aqui, que é
o hábito a manter.

A conta existe no PostgreSQL agora, com a expiração gravada nela:

```
ana@laptop:~$ DBUSER=$(echo "$CREDS" | jq -r .data.username) PASS=$(echo "$CREDS" | jq -r .data.password)
ana@laptop:~$ docker run --rm --network kind -e PGPASSWORD=$PASS postgres:17-alpine psql -h postgres -U $DBUSER -d bulletin -tAc "select current_user"
v-root-bulletin-w3GAeOLcZSVDkSCJiQSK-1792125774
ana@laptop:~$ docker exec postgres psql -U postgres -tAc "select rolname, rolvaliduntil from pg_roles where rolname like 'v-%'"
v-root-bulletin-w3GAeOLcZSVDkSCJiQSK-1792125774|2026-10-16 05:42:59+00
```

## Encerrando antes

Um lease é o registro do Vault de algo que ele entregou. Revogá-lo roda a limpeza na hora, em vez de
no fim da hora, que é o que um incidente pede:

```
ana@laptop:~$ vault lease revoke $(echo "$CREDS" | jq -r .lease_id)
All revocation operations queued successfully!
ana@laptop:~$ docker run --rm --network kind -e PGPASSWORD=$PASS postgres:17-alpine psql -h postgres -U $DBUSER -d bulletin -tAc "select current_user"
psql: error: connection to server at "postgres" (172.18.0.6), port 5432 failed: FATAL:  password authentication failed for user "v-root-bulletin-w3GAeOLcZSVDkSCJiQSK-1792125774"
```

`password authentication failed`: a conta sumiu do PostgreSQL, uma hora antes, com a mesma senha que
funcionava um minuto antes.

## E a única senha que o Vault recebeu

`initial-password` agora é a coisa mais fraca aqui: uma pessoa a digitou, ela está num histórico de
shell, e abre toda tabela como superusuário. O Vault pode trocá-la por um valor que ninguém conhece:

```
ana@laptop:~$ vault write -f database/rotate-root/bulletin
Success! Data written to: database/rotate-root/bulletin
ana@laptop:~$ docker run --rm --network kind -e PGPASSWORD=initial-password postgres:17-alpine psql -h postgres -U postgres -d bulletin -tAc "select 1"
psql: error: connection to server at "postgres" (172.18.0.6), port 5432 failed: FATAL:  password authentication failed for user "postgres"
ana@laptop:~$ vault read -format=json database/creds/bulletin-readonly | jq -r .data.username
v-root-bulletin-iURmahrqOsV1XKIETyTG-1792125776
```

A senha que uma pessoa digitou não abre mais o banco, e o Vault continua entregando contas: ele
entrou com a nova senha do administrador, que ele mesmo escolheu e guardou.

**Depois disso, nenhuma pessoa conhece uma senha do banco**, e isso inclui você. Entrar é pedir ao
Vault, sob uma política, e fica registrado. A saída de emergência para o dia em que o Vault estiver
fora é o caminho de administração do próprio banco, pelo contêiner ou pelo console da nuvem, e isso
é um ato deliberado e auditado, não uma senha numa gaveta.
