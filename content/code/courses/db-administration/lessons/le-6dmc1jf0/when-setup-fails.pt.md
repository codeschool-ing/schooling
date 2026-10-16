---
title: Quando a instalação não funciona
version: 1
---

Tudo nesta lição pode dar errado, e quase todo jeito de dar errado imprime uma frase que diz qual.
Leia a frase antes de qualquer coisa. Quando ela contém `FATAL:`, a parte depois disso é o servidor
dizendo exatamente o que recusou; quando não contém, nada respondeu.

## `psql: command not found`

```
ana@db:~$ psql --version
-bash: line 1: psql: command not found
```

O cliente não está instalado nesta máquina. Ou o `apt install postgresql` não foi rodado, ou foi
rodado em outro lugar — no seu computador em vez da máquina virtual, o que é fácil de acontecer com
dois terminais abertos. Confira o prompt e instale.

Se o `apt` parar e disser que está **esperando uma trava** (lock), outro programa está instalando
atualizações. Um servidor Ubuntu novo faz isso sozinho por um tempo depois do primeiro boot. Espere
terminar; nunca apague o arquivo de trava para passar.

## `role "…" does not exist`

```
ana@db:~$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
```

O servidor está rodando e não conhece você. O passo do `createuser` foi pulado, ou foi rodado como
outra pessoa. Rode-o, e o `createdb` depois dele:

```sh
sudo -u postgres createuser --superuser $USER
createdb $USER
```

Se a mensagem disser `database "ana" does not exist`, o primeiro comando funcionou e o segundo foi
pulado.

## `Peer authentication failed`

```
ana@db:~$ psql -U postgres
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  Peer authentication failed for user "postgres"
```

Instruções escritas para outro sistema mandam conectar como `postgres`, e no Ubuntu isso é recusado
de propósito: pelo socket local você só pode ser o papel com o nome do seu usuário do sistema.
Quando precisar mesmo do papel `postgres`, vire primeiro o usuário `postgres`, com
`sudo -u postgres psql`.

## `No such file or directory` — `Is the server running`

```
ana@db:~$ sudo systemctl stop postgresql
ana@db:~$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
ana@db:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 down   postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
ana@db:~$ sudo systemctl start postgresql
```

Desta vez não há `FATAL:`, porque nada respondeu. O arquivo do socket só existe enquanto o servidor
roda, e o `pg_lsclusters` diz `down`. Suba-o. **Se ele não subir, o motivo está no log**, o arquivo
da última coluna, e as últimas linhas dizem isso em palavras simples:

```sh
sudo tail -n 20 /var/log/postgresql/postgresql-16-main.log
```

O `systemctl status postgresql@16-main` mostra as mesmas linhas, e o
`journalctl -u postgresql@16-main` também. Um disco cheio, um arquivo de configuração mal editado e
uma porta que outro programa já ocupa são as três causas de sempre, e o log nomeia cada uma.

## Abaixo de tudo isso: a própria máquina virtual

Se o hypervisor se recusar a ligar a máquina com uma mensagem sobre `VT-x`, `AMD-V` ou
virtualização desativada, **o processador consegue e o firmware do computador está com o recurso
desligado**. É um ajuste no menu da BIOS ou UEFI, alcançado por uma tecla apertada enquanto o
computador liga, e o site do fabricante diz qual. No Windows, um hypervisor também pode recusar
porque o Hyper-V ou o WSL já ocupam a virtualização do processador; versões recentes do VirtualBox
rodam ao lado deles, mais devagar.

Se a máquina liga mas está lenta demais, provavelmente tem memória de menos. Desligue-a, dê mais
memória nos ajustes do hypervisor e ligue de novo.

## Começar de novo

Nada aqui é precioso ainda. Um cluster pode ser removido e feito de novo em dois comandos, e a
lição 4 explica o que eles fazem:

```sh
sudo pg_dropcluster --stop 16 main
sudo pg_createcluster --start 16 main
```

Depois deles você volta para onde o `apt install` deixou, sem papel para você, e o próximo passo é o
`createuser`. Se a própria máquina estiver num estado que você não consegue explicar, apague-a no
hypervisor e faça outra: é para isso que serve uma máquina virtual, e uma segunda instalação custa
menos que uma noite de adivinhação.
