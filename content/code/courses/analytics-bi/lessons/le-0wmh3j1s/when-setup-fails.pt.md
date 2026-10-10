---
title: Quando a configuração não funciona
version: 1
---

Tudo nas duas últimas seções pode dar errado, e quase todo jeito de dar errado imprime uma frase
que diz qual. Leia a frase antes de qualquer outra coisa.

## `Connection refused` no `ssh`

```
$ ssh -p 2222 ana@localhost
ssh: connect to host localhost port 2222: Connection refused
```

Nada na porta 2222 do seu computador respondeu. Ou falta a regra de encaminhamento — no
VirtualBox ela é criada com a máquina desligada, e um erro de digitação em qualquer das duas
portas dá o mesmo efeito —, ou a máquina não está ligada, ou o servidor OpenSSH nunca foi
instalado. O último se resolve na janela da própria máquina: `sudo apt install -y openssh-server`.

## O script parou no meio

Uma colagem que perdeu as últimas linhas, ou uma linha quebrada em duas pelo editor, dá um script
que roda até a instrução quebrada e para ali. Com as primeiras 100 das 165 linhas:

```
ana@vm:~$ psql -q lantern -f short.sql
psql:short.sql:3: NOTICE:  drop cascades to 7 other objects
DETAIL:  drop cascades to table products
drop cascades to table customers
drop cascades to table orders
drop cascades to table order_lines
drop cascades to table web_sessions
drop cascades to table web_events
drop cascades to view order_totals
psql:short.sql:100: ERROR:  missing FROM-clause entry for table "d"
LINE 9: SELECT d.order_id, d.n AS line_no, p.product_id,
               ^
ana@vm:~$ psql -q lantern -f lantern.sql >/dev/null 2>&1
```

O `ERROR` diz a linha em que o `psql` desistiu, e a tabela de contagens nunca chega porque o
script nunca chegou nela. **A falta da tabela de contagens é o sintoma a procurar.** Abra o
arquivo de novo, apague tudo, cole o bloco inteiro mais uma vez e rode de novo: o script começa
apagando o que a execução quebrada deixou, então uma segunda execução é sempre segura.

## `database "…" does not exist`

```
ana@vm:~$ psql lantern2
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  database "lantern2" does not exist
```

O servidor está rodando, conhece você, e o nome pedido não é um dos bancos dele. Erro de
digitação é o motivo de sempre; ter pulado o `createdb lantern` é o outro. `psql -l` lista os
bancos que existem.

## `role "…" does not exist`

```
ana@vm:~$ psql lantern
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
Cluster is already running.
NOTICE:  database "lantern" does not exist, skipping
psql:/tmp/lantern.sql:3: NOTICE:  schema "shop" does not exist, skipping
```

O servidor está rodando e não conhece você: o passo do `createuser` foi pulado, ou rodou numa
máquina diferente da que você está usando. Rode:

```sh
sudo -u postgres createuser --superuser $USER
```

## `No such file or directory` — `Is the server running`

```
ana@vm:~$ sudo pg_ctlcluster 16 main stop
ana@vm:~$ psql lantern
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
ana@vm:~$ sudo pg_ctlcluster 16 main start
```

Sem `FATAL:` desta vez, porque nada respondeu: o arquivo que o `psql` procura só existe enquanto o
servidor roda. Uma máquina virtual desligada no botão em vez de encerrada, ou um disco que encheu,
acabam aqui. `sudo pg_ctlcluster 16 main start` liga o servidor, e se isso falhar, o motivo está
nas últimas linhas de `/var/log/postgresql/postgresql-16-main.log`.

## As contagens diferem das da aula

Se o script rodou até o fim e imprimiu cinco contagens que não são 12, 2650, 7102, 11362 e 108987,
o script não é o da aula — compare a primeira e a última linha do seu arquivo com o bloco — ou o
servidor não é o PostgreSQL 16. Os números vêm do gerador de números aleatórios do PostgreSQL
iniciado de uma semente fixa, e foram gravados na versão 16; `psql --version` diz qual você tem.

## Por baixo de tudo isso: a própria máquina virtual

Se o hipervisor se recusar a ligar a máquina com uma mensagem sobre `VT-x`, `AMD-V` ou
virtualização desativada, **o processador sabe fazer e o firmware do computador está com o recurso
desligado.** É uma opção no menu da BIOS ou da UEFI, aberto por uma tecla apertada enquanto o
computador liga. Se você não puder mudá-la, o caminho instalado desta aula não precisa de
virtualização nenhuma.
