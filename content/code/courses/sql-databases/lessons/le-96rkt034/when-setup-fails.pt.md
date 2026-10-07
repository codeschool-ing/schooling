---
title: Quando a instalação não funciona
version: 1
---

Tudo na etapa anterior pode dar errado, e cada jeito de dar errado imprime uma frase que diz qual.
Leia a frase antes de qualquer outra coisa: a parte depois de `FATAL:` é o servidor dizendo
exatamente o que recusou.

## `role "…" does not exist`

```
ana@vm:~$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
```

O servidor está rodando e não conhece você. O passo do `createuser` foi pulado, ou foi rodado numa
máquina diferente daquela em que você está digitando. Rode-o:

```sh
sudo -u postgres createuser --superuser $USER
```

## `database "…" does not exist`

```
ana@vm:~$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  database "ana" does not exist
```

Você foi mais longe: o servidor conhece você, e você pediu um banco que não está lá. Sem um nome, o
`psql` pede o que se chama igual a você. Diga o que você queria — `psql shop` — e, se a resposta for
a mesma, o `createdb shop` foi pulado.

## `Peer authentication failed for user "postgres"`

```
ana@vm:~$ psql -U postgres
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  Peer authentication failed for user "postgres"
```

Instruções escritas para outro sistema mandam conectar como `postgres`, e no Ubuntu isso é recusado
de propósito. Uma conexão a partir da mesma máquina é conferida contra **quem você é no
computador**, e você não é o usuário `postgres` do computador. Conecte-se como você mesmo, o que a
etapa anterior tornou possível; e quando precisar mesmo do `postgres`, vire ele antes, com
`sudo -u postgres psql`.

## `No such file or directory` — `Is the server running`

```
ana@vm:~$ psql shop
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
```

Nada de `FATAL:` desta vez, porque ninguém respondeu. O arquivo que o `psql` procura é a porta do
servidor, e só existe enquanto o servidor roda. Pergunte, e ligue-o:

```
ana@vm:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 down   postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
ana@vm:~$ sudo pg_ctlcluster 16 main start
```

`down` era a resposta. Uma máquina virtual desligada no botão em vez de desligada direito, ou um
disco que encheu, terminam os dois aqui. Se o `start` falhar, o motivo está nas últimas linhas do
log da coluna da direita — `sudo tail /var/log/postgresql/postgresql-16-main.log` —, e um disco
cheio diz isso com todas as letras.

## `psql: command not found`

O cliente não está instalado, ou esta não é a máquina em que você o instalou. Dentro da máquina
virtual, é `sudo apt install -y postgresql` de novo. Num computador com o PostgreSQL instalado de
outro jeito, o instalador pôs o `psql` num diretório em que o shell não procura, e as instruções
dele dizem qual acrescentar.

## Por baixo de tudo isso: a própria máquina virtual

Se o hipervisor se recusar a ligar a máquina com uma mensagem sobre **VT-x**, **AMD-V** ou
**virtualização desativada**, o processador é capaz e o firmware do computador está com o recurso
desligado. É uma opção no menu da BIOS ou UEFI, aberto com uma tecla apertada enquanto o computador
liga, e o site do fabricante diz qual. Se você não puder mudá-la, o caminho instalado ou o online da
primeira etapa não precisam de virtualização nenhuma.

## Começando de novo

Nada aqui é precioso ainda. Um banco se apaga com `dropdb shop` e se cria de novo com
`createdb shop`; e se a máquina em si estiver num estado que você não consegue explicar, apague-a
no hipervisor e faça outra. É para isso que serve uma máquina virtual, e uma segunda instalação é
um preço pequeno por saber exatamente em cima do que você está.
