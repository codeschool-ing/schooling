---
title: O ponto limpo fica antes do intruso, não antes do dano
version: 1
---

Uma restauração até logo antes do dano traz de volta o que o banco tinha naquele momento, **incluindo
tudo o que o intruso já tinha mudado**. Para saber o que é isso, você precisa de um registro de como o
banco estava num dia em que você confia. Salve isto como `inventory.sql`:

```schooling-example
{"language": "sql", "file": "inventory.sql", "parts": [{"code": "-- inventory.sql: who may log in and with what power, and every function anyone added\nSELECT 'role', rolname, rolsuper, rolcanlogin, rolreplication\nFROM pg_roles WHERE rolname !~ '^pg_' ORDER BY rolname;", "note": "Todo papel que não é um dos do próprio PostgreSQL, com os três poderes que mais importam."}, {"code": "SELECT 'function', n.nspname || '.' || p.proname\nFROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace\nWHERE n.nspname NOT IN ('pg_catalog', 'information_schema')\nORDER BY 2;", "note": "E toda função fora dos schemas do sistema, porque uma função pode carregar código que roda com os direitos do dono dela."}]}
```

Tire o inventário num dia bom e guarde-o, como você guardaria o arquivo de globais da lição 2:

```
ana@vm:~$ psql -X -A -t shop -f inventory.sql > inventory-known.txt
ana@vm:~$ cat inventory-known.txt
role|ana|t|t|f
role|postgres|t|t|t
```

Dois papéis, você e o `postgres`, ambos superusuários, e nenhuma função no shop.

## O ponto de apoio

Agora, fazendo as vezes do dwell time, o laboratório faz o papel do intruso por mais um comando: um
superusuário novo que pode fazer login, criado dias antes de qualquer coisa visível acontecer. Rode-o,
e depois deixe chegarem alguns pedidos comuns:

```
shop=# CREATE ROLE maint_svc LOGIN SUPERUSER PASSWORD 'not-a-real-secret';
CREATE ROLE
```

Esse papel é toda a preparação do intruso neste laboratório. Num ataque de verdade, seria uma entre
várias coisas, e algumas delas nem estariam no banco.

## A restauração, e o que voltou com ela

O alerta acima deu o horário do dano. Restaure até dez segundos antes dele, dois intervalos do
vigia, no segundo servidor, em pausa:

```
ana@vm:~$ sudo pg_ctlcluster 16 restore stop
ana@vm:~$ sudo rm -rf /var/lib/postgresql/16/restore
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --pg1-path=/var/lib/postgresql/16/restore --archive-mode=off --type=time "--target=2026-10-15 21:54:12-03" --target-action=pause restore
ana@vm:~$ sudo pg_ctlcluster 16 restore start
shop=# SELECT name, city FROM customers ORDER BY id LIMIT 3;
    name    |     city     
------------+--------------
 customer 1 | Porto Alegre
 customer 2 | Belém
 customer 3 | Curitiba
(3 rows)

shop=# SELECT count(*), sum(total_cents) FROM orders;
 count |    sum    
-------+-----------
 50003 | 524990400
(1 row)
```

Os nomes voltaram a ser nomes, os totais voltaram a ser totais, e os três pedidos que chegaram depois
que o papel foi criado estão lá: **50003 pedidos**, como o shop ao vivo tinha antes do dano. Por toda
medida que os dados mostram, esta é uma boa recuperação. Agora compare a cópia restaurada com o
inventário do dia bom:

```
ana@vm:~$ psql -X -A -t -p 5433 shop -f inventory.sql > inventory-restored.txt
ana@vm:~$ diff inventory-known.txt inventory-restored.txt
1a2
> role|maint_svc|t|t|f
```

**O `maint_svc`, um superusuário que pode fazer login, voltou junto com os dados.** Ele foi criado
antes do alvo, então a restauração o restaurou fielmente, e uma aplicação apontada para esta cópia
devolveria ao intruso o seu caminho de volta já no primeiro dia.

É por isso que o ponto limpo é definido pelo intruso e não pelo dano, e por isso que a recuperação de
um ataque de ransomware nunca é só uma restauração:

- **Restaurar até antes do dano, e depois auditar tudo o que dá acesso**: papéis, senhas, funções,
  extensões, os arquivos de configuração, o `pg_hba.conf` que diz quem pode conectar. Comparar com um
  inventário de antes da intrusão, se existir um.
- **Ou restaurar até antes da intrusão**, se a data dela for conhecida e a perda de tudo desde então
  for aceitável. Raramente ela é conhecida; os dwell times são longos.
- **Em todo caso, trocar todas as credenciais**: a senha de cada papel, as chaves do repositório de
  backup, a passphrase, as contas do sistema operacional. O intruso pode ter lido qualquer uma delas.
