---
title: Três nós e um etcd
version: 1
---

Instale o Patroni e o etcd pelos pacotes do Ubuntu:

```sh
sudo apt install -y patroni etcd-server etcd-client
```

O pacote `etcd-server` inicia o etcd como serviço na mesma hora, como um membro único escutando em
`localhost:2379`. Pergunte se ele está saudável:

```
ana@vm:~$ etcdctl endpoint health
127.0.0.1:2379 is healthy: successfully committed proposal: took = 1.645217ms
```

Um etcd basta para aprender e **não** basta para operar: a última seção desta lição o para e mostra
quanto isso custa.

## A configuração

Cada nó do Patroni é um servidor PostgreSQL mais o processo do Patroni que o roda. Este curso roda
três, com o seu próprio usuário, com os diretórios de dados em `~/patroni` e as portas de 5441 a 5443,
ao lado do 16/main que o Ubuntu roda na 5432. O próprio Patroni cria e inicia esses servidores, com o
`initdb` e o `pg_ctl` do diretório do próprio PostgreSQL, então o `pg_lsclusters` nunca vai listá-los.

Salve isto como `~/patroni/pg1.yml` depois de um `mkdir -p ~/patroni`:

```schooling-example
{"language": "yaml", "file": "pg1.yml", "parts": [{"code": "scope: shop", "note": "O nome do cluster. Todo nó com o mesmo `scope` pertence ao mesmo cluster, e as chaves do cluster no etcd ficam embaixo dele."}, {"code": "name: pg1\n", "note": "O nome do próprio nó, que o `patronictl` mostra e que vira o `application_name` dele quando ele replica."}, {"code": "restapi:\n  listen: 127.0.0.1:8008\n  connect_address: 127.0.0.1:8008\n", "note": "A interface HTTP do próprio Patroni. É aqui que os outros nós, o `patronictl` e o balanceador de carga da lição 19 perguntam a cada nó sobre ele mesmo."}, {"code": "etcd3:\n  hosts: 127.0.0.1:2379\n", "note": "Onde fica o estado compartilhado: um etcd, pela interface da versão 3."}, {"code": "bootstrap:\n  dcs:\n    ttl: 30\n    loop_wait: 10\n    retry_timeout: 10\n    maximum_lag_on_failover: 1048576\n    postgresql:\n      use_pg_rewind: true\n      use_slots: true", "note": "Usado uma vez, pelo primeiro nó que iniciar, para criar o cluster. `ttl` é quanto tempo a reivindicação do líder dura sem ser renovada, `loop_wait` de quanto em quanto tempo cada nó acorda. Uma réplica mais de `maximum_lag_on_failover` bytes atrás não pode virar líder."}, {"code": "  initdb:\n  - encoding: UTF8\n  - data-checksums\n", "note": "Checksums no `initdb`, para que a recusa do `pg_rewind` da lição 15 não possa acontecer aqui."}, {"code": "postgresql:\n  listen: 127.0.0.1:5441\n  connect_address: 127.0.0.1:5441\n  data_dir: /home/ana/patroni/pg1\n  bin_dir: /usr/lib/postgresql/16/bin", "note": "O PostgreSQL que este nó roda: o endereço, o diretório de dados e os programas que o Ubuntu instalou."}, {"code": "  parameters:\n    unix_socket_directories: /home/ana/patroni", "note": "O socket vai para o seu diretório home, já que `/var/run/postgresql` pertence ao usuário `postgres` e estes servidores rodam como você."}, {"code": "  pg_hba:\n  - local all all trust\n  - host replication replicator 127.0.0.1/32 scram-sha-256\n  - host all all 127.0.0.1/32 scram-sha-256", "note": "O Patroni escreve o `pg_hba.conf` a partir desta lista. O socket não precisa de senha, porque fica no seu diretório home, onde o Ubuntu não deixa mais ninguém entrar; as conexões pela rede, inclusive as de replicação, precisam de uma."}, {"code": "  authentication:\n    replication:\n      username: replicator\n      password: replica-pass-1\n    superuser:\n      username: postgres\n      password: patroni-pass-1", "note": "Os dois papéis que o Patroni cria no bootstrap e usa depois: um para replicar, outro para administrar, inclusive para o `pg_rewind`."}]}
```

**Troque `ana` pelo seu nome de usuário** em `data_dir` e `unix_socket_directories`. Os outros dois
nós só diferem no nome, nas duas portas e no diretório, então gere-os a partir do primeiro com `sed`
em vez de escrevê-los à mão:

```
ana@vm:~$ sed -e 's/pg1/pg2/g' -e 's/8008/8009/g' -e 's/5441/5442/g' ~/patroni/pg1.yml > ~/patroni/pg2.yml
ana@vm:~$ sed -e 's/pg1/pg3/g' -e 's/8008/8010/g' -e 's/5441/5443/g' ~/patroni/pg1.yml > ~/patroni/pg3.yml
ana@vm:~$ grep -E "name:|listen:|data_dir:" ~/patroni/pg3.yml
name: pg3
  listen: 127.0.0.1:8010
  listen: 127.0.0.1:5443
  data_dir: /home/ana/patroni/pg3
      username: replicator
      username: postgres
```

## Iniciando os nós

O Patroni roda em primeiro plano e escreve o log no terminal. Uma instalação por pacote o roda como
serviço; aqui, inicie cada um em segundo plano com o log num arquivo, o primeiro sozinho, para que seja
ele quem cria o cluster. Dê vinte segundos a ele antes de iniciar os outros dois:

```
ana@vm:~$ patroni ~/patroni/pg1.yml > ~/patroni/pg1.log 2>&1 &
ana@vm:~$ patroni ~/patroni/pg2.yml > ~/patroni/pg2.log 2>&1 &
ana@vm:~$ patroni ~/patroni/pg3.yml > ~/patroni/pg3.log 2>&1 &
ana@vm:~$ patronictl -c ~/patroni/pg1.yml list
+ Cluster: shop (7697120517756803320) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Leader  | running   |  1 |           |
| pg2    | 127.0.0.1:5442 | Replica | streaming |  1 |         0 |
| pg3    | 127.0.0.1:5443 | Replica | streaming |  1 |         0 |
+--------+----------------+---------+-----------+----+-----------+
```

O `patronictl` lê o mesmo arquivo para achar o etcd, e o `list` mostra o que o etcd sabe: **um líder e
duas réplicas, todas `streaming`**, na timeline 1. O `pg2` e o `pg3` não rodaram o `initdb`; eles
acharam um líder no etcd e se tornaram réplicas dele com um base backup, como a lição 11 fez à mão.
