---
title: Quando a instalação não funciona
version: 1
---

Todo jeito de a instalação dar errado imprime uma frase dizendo qual. Leia antes de qualquer outra
coisa: a parte depois de `FATAL:` é o servidor te dizendo exatamente o que recusou.

## `role "…" does not exist`

```
ana@vm:~$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
```

O servidor está rodando e não te conhece. O passo do `createuser` foi pulado, ou foi rodado numa
máquina diferente daquela em que você está digitando. Rode:

```sh
sudo -u postgres createuser --superuser $USER
```

## `database "…" does not exist`

Você foi mais longe: o servidor te conhece, e você pediu um banco que não existe. Sem um nome, o
`psql` pede o que tem o seu nome. Diga o que você queria, `psql shop`, e se a resposta for a mesma, o
`createdb shop` foi pulado.

## `Peer authentication failed for user "postgres"`

```
ana@vm:~$ psql -U postgres
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  Peer authentication failed for user "postgres"
```

Instruções escritas para outros sistemas mandam conectar como `postgres`, e no Ubuntu isso é
recusado de propósito. Uma conexão vinda da mesma máquina é conferida contra **quem você é no
computador**, e você não é o usuário `postgres` do computador. Conecte como você mesmo; e quando
precisar mesmo de `postgres`, vire ele antes, com `sudo -u postgres psql`.

## `No such file or directory`, e `Is the server running`

```
ana@vm:~$ sudo pg_ctlcluster 16 main stop
ana@vm:~$ psql shop
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
ana@vm:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 down   postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
ana@vm:~$ sudo pg_ctlcluster 16 main start
```

Desta vez não há `FATAL:`, porque nada respondeu. O arquivo que o `psql` procura é a porta do
servidor, um socket que só existe enquanto o servidor roda, e o `pg_lsclusters` confirma que o
servidor está `down`. Uma máquina virtual desligada em vez de encerrada, ou um disco que encheu, os
dois terminam aqui, e neste curso você também vai acabar aqui de propósito. Se o `start` falhar, o
motivo está nas últimas linhas do log indicado na coluna da direita:

```sh
sudo tail -n 20 /var/log/postgresql/postgresql-16-main.log
```

## `ERROR:` enquanto o `shop.sql` roda

O script deixa de ser inofensivo se foi copiado com uma linha faltando: o `psql` relata o número da
linha e segue para o próximo comando, então as tabelas podem ficar preenchidas pela metade. Confira
as contagens na seção que o carregou e, se forem diferentes, copie o script de novo com o botão de
copiar em vez de selecionar o texto, e rode de novo. Ele apaga as duas tabelas primeiro, então uma
segunda execução começa limpa.

## Por baixo de tudo isso: a própria máquina virtual

Se o hipervisor se recusar a ligar a máquina com uma mensagem sobre `VT-x`, `AMD-V` ou virtualização
desabilitada, **o processador consegue e o firmware do computador está com isso desligado.** É uma
configuração no menu da BIOS ou UEFI, aberto por uma tecla apertada enquanto o computador liga, e o
site do fabricante diz qual tecla. Se você não conseguir mudar isso, o caminho online não precisa de
virtualização do seu lado.

## Começando de novo

Nada aqui é precioso ainda. `dropdb shop_restored` remove um banco, e se a máquina inteira estiver
num estado que você não consegue explicar, apague-a e crie outra, ou volte ao snapshot. Este curso
vai te pedir para fazer coisa pior com ela, de propósito.
