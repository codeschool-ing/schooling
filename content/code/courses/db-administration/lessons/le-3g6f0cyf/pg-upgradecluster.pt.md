---
title: O pg_upgrade, pelo pg_upgradecluster
version: 1
---

## Obtendo o PostgreSQL 17

O arquivo do Ubuntu 24.04 para no 16, então o 17 vem do repositório apt do próprio projeto
PostgreSQL, **apt.postgresql.org**, que publica toda versão maior com suporte para todo Ubuntu atual.
O postgresql-common traz um script que o adiciona, com a chave de assinatura:

```sh
sudo apt install -y postgresql-common
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
sudo apt install -y postgresql-17
```

**A máquina da gravação não conseguiu alcançar esse repositório**, e o servidor dentro dela não tem
rede nenhuma. O 17 dela foi compilado a partir do código-fonte da mesma versão, 17.10, e instalado
nos mesmos lugares que o pacote usa — `/usr/lib/postgresql/17` para os programas,
`/usr/share/postgresql/17` para o resto —, onde o postgresql-common o encontra exatamente como
encontra o pacote. A única diferença visível é a string de versão: a sua traz o empacotamento do
repositório entre parênteses depois de `17.10`, e a da gravação não tem nada depois.

```
ana@db:~$ pg_lsclusters 17
Ver Cluster Port Status Owner    Data directory              Log file
17  main    5434 online postgres /var/lib/postgresql/17/main /var/log/postgresql/postgresql-17-main.log
ana@db:~$ psql --version
psql (PostgreSQL) 17.10
```

**Instalar o pacote criou um cluster.** Na primeira vez que uma versão maior é instalada, o
postgresql-common cria um cluster `main` para ela e o sobe, na próxima porta livre — aqui a 5434,
porque o ensaio ocupa a 5433. O `17/main` está vazio, e a próxima seção o põe para trabalhar.

A outra mudança é mais discreta: o `psql` agora diz 17.10, embora o `main` continue no 16. O comando
`psql` é um wrapper do postgresql-common, e para o `psql` ele sempre roda a versão mais nova
instalada, porque um `psql` mais novo conversa com servidores mais antigos. A maioria das outras
ferramentas, o `pg_dump` entre elas, segue a versão do cluster para onde aponta, e isso importa na
próxima seção.

## Por que o servidor novo não pode simplesmente subir

O próprio servidor do 17, recebendo o diretório de dados do ensaio, se recusa antes de tocar em
qualquer coisa:

```
ana@db:~$ sudo -u postgres /usr/lib/postgresql/17/bin/postgres -D /var/lib/postgresql/16/rehearsal -c config_file=/etc/postgresql/16/rehearsal/postgresql.conf
2026-10-10 16:40:48.813 -03 [4434] FATAL:  database files are incompatible with server
2026-10-10 16:40:48.813 -03 [4434] DETAIL:  The data directory was initialized by PostgreSQL version 16, which is not compatible with this version 17.10.
```

É por isso que upgrades maiores são um projeto. O resto desta seção é o `pg_upgrade`, o mais rápido
dos três caminhos.

## O pg_upgrade, e o wrapper em volta dele

O `pg_upgrade` é a ferramenta do próprio PostgreSQL. Ele tira o esquema do cluster antigo com o
`pg_dump`, cria esse esquema num cluster novo da versão nova e então **leva os arquivos de dados sem
lê-los**: o formato das páginas de uma tabela não mudou entre o 16 e o 17, só o catálogo que as
descreve. No Ubuntu você raramente o chama direto. O **`pg_upgradecluster`** do postgresql-common
cria o cluster novo, copia a configuração, roda o `pg_upgrade` com os caminhos certos, troca as
portas e roda depois um passo que a seção 08 explica.

Duas das opções dele decidem tudo. **`-m upgrade` escolhe o pg_upgrade**; sem ela, o
`pg_upgradecluster` volta ao padrão dele, um dump e restore, que é correto mas demora tanto quanto
os dados são grandes. **`--link`** faz o pg_upgrade criar hard links dos arquivos de dados no cluster
novo em vez de copiá-los, e essa escolha tem um preço que o fim desta seção mostra.

## A primeira tentativa, recusada

```
ana@db:~$ sudo pg_upgradecluster -m upgrade --link 16 rehearsal
Stopping old cluster...
Creating new PostgreSQL cluster 17/rehearsal ...
/usr/lib/postgresql/17/bin/initdb -D /var/lib/postgresql/17/rehearsal --auth-local peer --auth-host scram-sha-256 --no-instructions --encoding UTF8 --lc-collate C.UTF-8 --lc-ctype C.UTF-8 --locale-provider libc
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

The database cluster will be initialized with locale "C.UTF-8".
The default text search configuration will be set to "english".

Data page checksums are disabled.

fixing permissions on existing directory /var/lib/postgresql/17/rehearsal ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... posix
selecting default "max_connections" ... 100
selecting default "shared_buffers" ... 128MB
selecting default time zone ... America/Sao_Paulo
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok

Copying old configuration files...
Copying old start.conf...
Copying old pg_ctl.conf...
Running init phase upgrade hook scripts ...

/usr/lib/postgresql/17/bin/pg_upgrade -b /usr/lib/postgresql/16/bin -B /usr/lib/postgresql/17/bin -p 5433 -P 5435 -d /etc/postgresql/16/rehearsal -D /etc/postgresql/17/rehearsal --link
Finding the real data directory for the source cluster        ok
Finding the real data directory for the target cluster        ok
Performing Consistency Checks
-----------------------------
Checking cluster versions                                     ok
Checking database user is the install user                    ok
Checking database connection settings                         ok
Checking for prepared transactions                            ok
Checking for contrib/isn with bigint-passing mismatch         ok
Checking data type usage                                      ok
Checking for not-null constraint inconsistencies              ok
Creating dump of global objects                               ok
Creating dump of database schemas                             ok
Checking for presence of required libraries                   fatal

Your installation references loadable libraries that are missing from the
new installation.  You can add these libraries to the new installation,
or remove the functions using them from the old installation.  A list of
problem libraries is in the file:
    /var/lib/postgresql/17/rehearsal/pg_upgrade_output.d/20261010T164052.366/loadable_libraries.txt
Failure, exiting
pg_upgradecluster: pg_upgrade output scripts are in /var/log/postgresql/pg_upgradecluster-16-17-rehearsal.XsrL
Error during cluster dumping, removing new cluster

Cluster is not running.
Starting old cluster again ...
```

Leia na ordem. O cluster antigo foi **parado** — um upgrade de verdade começa a parada na primeira
linha. O cluster novo `17/rehearsal` foi criado e recebeu a configuração antiga. O `pg_upgrade` fez
as verificações de consistência, gerou o dump dos esquemas e falhou em **`Checking for presence of
required libraries`**. Então o `pg_upgradecluster` removeu o cluster feito pela metade e subiu o
antigo de novo.

Nada se perdeu, porque nada tinha sido movido: toda verificação roda antes de qualquer arquivo de
dados ser tocado. O arquivo que ele cita, guardado no diretório de log, diz o que está faltando:

```
ana@db:~$ sudo find /var/log/postgresql -name loadable_libraries.txt -exec cat {} +
could not load library "$libdir/pg_repack": ERROR:  could not access file "$libdir/pg_repack": No such file or directory
In database: shop
```

A biblioteca da pg_repack existe para o 16 e não para o 17. Um servidor real tem duas saídas.
Instalar a versão da extensão para a versão nova — o repositório do PostgreSQL tem o
`postgresql-17-repack`, e numa máquina que o alcança, `sudo apt install postgresql-17-repack` é a
correção. Ou, quando a extensão não é necessária, removê-la antes do upgrade. A pg_repack é uma
ferramenta e não um lugar onde moram dados, então removê-la não perde nada, e foi o que a máquina da
gravação fez:

```
ana@db:~$ psql -p 5433 shop
shop=# DROP EXTENSION pg_repack;
DROP EXTENSION

shop=# \q
```

**Essa recusa é o ensaio se pagando.** No `main`, na noite marcada, teria sido a mesma saída com
gente esperando.

## A segunda tentativa

```
ana@db:~$ time sudo pg_upgradecluster -m upgrade --link 16 rehearsal
Stopping old cluster...
Creating new PostgreSQL cluster 17/rehearsal ...
/usr/lib/postgresql/17/bin/initdb -D /var/lib/postgresql/17/rehearsal --auth-local peer --auth-host scram-sha-256 --no-instructions --encoding UTF8 --lc-collate C.UTF-8 --lc-ctype C.UTF-8 --locale-provider libc
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

The database cluster will be initialized with locale "C.UTF-8".
The default text search configuration will be set to "english".

Data page checksums are disabled.

fixing permissions on existing directory /var/lib/postgresql/17/rehearsal ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... posix
selecting default "max_connections" ... 100
selecting default "shared_buffers" ... 128MB
selecting default time zone ... America/Sao_Paulo
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok

Copying old configuration files...
Copying old start.conf...
Copying old pg_ctl.conf...
Running init phase upgrade hook scripts ...

/usr/lib/postgresql/17/bin/pg_upgrade -b /usr/lib/postgresql/16/bin -B /usr/lib/postgresql/17/bin -p 5433 -P 5435 -d /etc/postgresql/16/rehearsal -D /etc/postgresql/17/rehearsal --link
Finding the real data directory for the source cluster        ok
Finding the real data directory for the target cluster        ok
Performing Consistency Checks
-----------------------------
Checking cluster versions                                     ok
Checking database user is the install user                    ok
Checking database connection settings                         ok
Checking for prepared transactions                            ok
Checking for contrib/isn with bigint-passing mismatch         ok
Checking data type usage                                      ok
Checking for not-null constraint inconsistencies              ok
Creating dump of global objects                               ok
Creating dump of database schemas                             ok
Checking for presence of required libraries                   ok
Checking database user is the install user                    ok
Checking for prepared transactions                            ok
Checking for new cluster tablespace directories               ok

If pg_upgrade fails after this point, you must re-initdb the
new cluster before continuing.

Performing Upgrade
------------------
Setting locale and encoding for new cluster                   ok
Analyzing all rows in the new cluster                         ok
Freezing all rows in the new cluster                          ok
Deleting files from new pg_xact                               ok
Copying old pg_xact to new server                             ok
Setting oldest XID for new cluster                            ok
Setting next transaction ID and epoch for new cluster         ok
Deleting files from new pg_multixact/offsets                  ok
Copying old pg_multixact/offsets to new server                ok
Deleting files from new pg_multixact/members                  ok
Copying old pg_multixact/members to new server                ok
Setting next multixact ID and offset for new cluster          ok
Resetting WAL archives                                        ok
Setting frozenxid and minmxid counters in new cluster         ok
Restoring global objects in the new cluster                   ok
Restoring database schemas in the new cluster                 ok
Adding ".old" suffix to old global/pg_control                 ok

If you want to start the old cluster, you will need to remove
the ".old" suffix from /var/lib/postgresql/16/rehearsal/global/pg_control.old.
Because "link" mode was used, the old cluster cannot be safely
started once the new cluster has been started.
Linking user relation files                                   ok
Setting next OID for new cluster                              ok
Sync data directory to disk                                   ok
Creating script to delete old cluster                         ok
Checking for extension updates                                notice

Your installation contains extensions that should be updated
with the ALTER EXTENSION command.  The file
    update_extensions.sql
when executed by psql by the database superuser will update
these extensions.

Upgrade Complete
----------------
Optimizer statistics are not transferred by pg_upgrade.
Once you start the new server, consider running:
    /usr/lib/postgresql/17/bin/vacuumdb --all --analyze-in-stages
Running this script will delete the old cluster's data files:
    ./delete_old_cluster.sh
pg_upgradecluster: pg_upgrade output scripts are in /var/log/postgresql/pg_upgradecluster-16-17-rehearsal.7TJ3
Disabling automatic startup of old cluster...
Starting upgraded cluster on port 5433...
Running finish phase upgrade hook scripts ...
vacuumdb: processing database "ana": Generating minimal optimizer statistics (1 target)
vacuumdb: processing database "postgres": Generating minimal optimizer statistics (1 target)
vacuumdb: processing database "shop": Generating minimal optimizer statistics (1 target)
vacuumdb: processing database "template1": Generating minimal optimizer statistics (1 target)
vacuumdb: processing database "ana": Generating medium optimizer statistics (10 targets)
vacuumdb: processing database "postgres": Generating medium optimizer statistics (10 targets)
vacuumdb: processing database "shop": Generating medium optimizer statistics (10 targets)
vacuumdb: processing database "template1": Generating medium optimizer statistics (10 targets)
vacuumdb: processing database "ana": Generating default (full) optimizer statistics
vacuumdb: processing database "postgres": Generating default (full) optimizer statistics
vacuumdb: processing database "shop": Generating default (full) optimizer statistics
vacuumdb: processing database "template1": Generating default (full) optimizer statistics

Success. Please check that the upgraded cluster works. If it does,
you can remove the old cluster with
    pg_dropcluster 16 rehearsal

Ver Cluster   Port Status Owner    Data directory                   Log file
16  rehearsal 5435 down   postgres /var/lib/postgresql/16/rehearsal /var/log/postgresql/postgresql-16-rehearsal.log
Ver Cluster   Port Status Owner    Data directory                   Log file
17  rehearsal 5433 online postgres /var/lib/postgresql/17/rehearsal /var/log/postgresql/postgresql-17-rehearsal.log

real	0m17.706s
user	0m1.056s
sys	0m0.673s
```

Vale conhecer as etapas, porque uma execução real demora mais e você vai assistir a ela:

- `Performing Consistency Checks` é a parte que falhou antes, e agora passou.
- `If pg_upgrade fails after this point, you must re-initdb the new cluster` é a linha em que
  verificar acaba e fazer começa.
- `Restoring database schemas` monta o catálogo do `17/rehearsal` a partir do dump do catálogo do 16.
- `Adding ".old" suffix to old global/pg_control` desativa o cluster antigo de propósito, por um
  motivo que a próxima parte mostra.
- `Linking user relation files` são os dados, todos eles, numa linha só.
- `Checking for extension updates` e `Optimizer statistics are not transferred` são dois
  trabalhos deixados para você, e a última seção de leitura desta lição cuida deles.

Depois do `pg_upgrade`, o `pg_upgradecluster` marcou o cluster antigo para ficar parado no boot,
**deu ao cluster novo a porta antiga**, subiu-o e rodou o passo de análise: as linhas do `vacuumdb`.

```
ana@db:~$ pg_lsclusters
Ver Cluster   Port Status Owner    Data directory                   Log file
16  main      5432 online postgres /var/lib/postgresql/16/main      /var/log/postgresql/postgresql-16-main.log
16  rehearsal 5435 down   postgres /var/lib/postgresql/16/rehearsal /var/log/postgresql/postgresql-16-rehearsal.log
17  main      5434 online postgres /var/lib/postgresql/17/main      /var/log/postgresql/postgresql-17-main.log
17  rehearsal 5433 online postgres /var/lib/postgresql/17/rehearsal /var/log/postgresql/postgresql-17-rehearsal.log
```

O `17/rehearsal` atende na 5433, onde o ensaio sempre esteve, então tudo o que conectava ao cluster
antigo agora chega ao novo sem mudar nada. O cluster antigo foi para a 5435 e está parado.

## O que o --link fez

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Duas formas de o pg_upgrade levar o arquivo de uma tabela. Sem --link, 16/rehearsal e 17/rehearsal guardam cada um sua cópia de base/16386/16393: o dobro do disco e o tempo de copiar, e o 16 ainda pode subir, então o cluster antigo é o caminho de volta. Com --link, as duas entradas de diretório apontam para um só arquivo com contagem de links 2: nenhum disco a mais e segundos em qualquer tamanho, mas o 17 escreve no arquivo comum, então o caminho de volta é um backup.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"180\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">sem --link: copiado</text><text x=\"540\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">com --link: ligado</text><line x1=\"360\" y1=\"8\" x2=\"360\" y2=\"262\" stroke=\"var(--scan)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></line><rect x=\"30\" y=\"40\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">16/rehearsal/</text><text x=\"100\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">base/16386/16393</text><rect x=\"190\" y=\"40\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">17/rehearsal/</text><text x=\"260\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">base/16386/16393</text><line x1=\"100\" y1=\"80\" x2=\"100\" y2=\"128\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><line x1=\"260\" y1=\"80\" x2=\"260\" y2=\"128\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><rect x=\"30\" y=\"130\" width=\"140\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"100.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">os dados da tabela orders</text><text x=\"100.0\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma cópia em cada</text><rect x=\"190\" y=\"130\" width=\"140\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"260.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">os dados da tabela orders</text><text x=\"260.0\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma cópia em cada</text><text x=\"180\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o dobro do disco, e o tempo de copiar tudo</text><text x=\"180\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o 16 ainda pode subir:</text><text x=\"180\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">o cluster antigo é o caminho de volta</text><rect x=\"390\" y=\"40\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"460\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">16/rehearsal/</text><text x=\"460\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">base/16386/16393</text><rect x=\"550\" y=\"40\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"620\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">17/rehearsal/</text><text x=\"620\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">base/16386/16393</text><line x1=\"460\" y1=\"80\" x2=\"520\" y2=\"128\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><line x1=\"620\" y1=\"80\" x2=\"560\" y2=\"128\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><rect x=\"450\" y=\"130\" width=\"180\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"540.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">os dados da tabela orders</text><text x=\"540.0\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um arquivo, dois nomes (links: 2)</text><text x=\"540\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nenhum disco a mais, segundos em qualquer tamanho</text><text x=\"540\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o 17 escreve no arquivo comum:</text><text x=\"540\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o caminho de volta é um backup</text></svg>", "caption": "O pg_upgrade copia cada arquivo de dados ou dá a ele um segundo nome. Ligar é rápido porque nada é copiado, e pelo mesmo motivo o cluster antigo nunca mais pode rodar."}
```

Um hard link é um segundo nome para o mesmo arquivo. Peça o número de inode do arquivo da tabela
`orders` nos dois diretórios de dados:

```
ana@db:~$ sudo ls -li /var/lib/postgresql/16/rehearsal/base/16386/16393 /var/lib/postgresql/17/rehearsal/base/16386/16393
1756158 -rw------- 2 postgres postgres 68747264 Oct 10 16:40 /var/lib/postgresql/16/rehearsal/base/16386/16393
1756158 -rw------- 2 postgres postgres 68747264 Oct 10 16:40 /var/lib/postgresql/17/rehearsal/base/16386/16393
```

O mesmo número de inode nas duas linhas, e uma contagem de links **2**: um arquivo de 68.747.264
bytes com dois nomes. Nenhum byte da tabela foi copiado, e é por isso que ligar leva mais ou menos o
mesmo tempo para um banco do tamanho do `shop` e para um de 2 TB. O `du` também vê isso, porque conta
cada arquivo uma vez só por execução:

```
ana@db:~$ sudo du -sh /var/lib/postgresql/16/rehearsal /var/lib/postgresql/17/rehearsal
261M	/var/lib/postgresql/16/rehearsal
55M	/var/lib/postgresql/17/rehearsal
```

O diretório de dados novo acrescenta só 55 MB próprios: um catálogo novo e o WAL de um cluster novo.
Agora tente subir o cluster antigo:

```
ana@db:~$ sudo pg_ctlcluster 16 rehearsal start
Job for postgresql@16-rehearsal.service failed because the service did not take the steps required by its unit configuration.
See "systemctl status postgresql@16-rehearsal.service" and "journalctl -xeu postgresql@16-rehearsal.service" for details.
ana@db:~$ sudo tail -n 5 /var/log/postgresql/postgresql-16-rehearsal.log
postgres: could not find the database system
Expected to find it in the directory "/var/lib/postgresql/16/rehearsal",
but could not open file "/var/lib/postgresql/16/rehearsal/global/pg_control": No such file or directory
pg_ctl: could not start server
Examine the log output.
```

**O cluster antigo não pode mais subir**, e isso é de propósito. Os arquivos dele são os arquivos do
cluster novo, e o 17 já está escrevendo neles; um 16 subindo sobre os mesmos arquivos leria páginas
que o 17 mudou e corromperia os dois. Por isso o `pg_upgrade` renomeou o `pg_control`, e o servidor
antigo não o encontra.

O que deixa a escolha de que o `--link` trata:

- Com `--link`, o upgrade leva mais ou menos o mesmo tempo qualquer que seja o tamanho dos dados, e
  quase não precisa de disco a mais. O caminho de volta é um **backup feito antes de começar**,
  restaurado num servidor 16.
- Sem ele, cada arquivo de dados é copiado. O upgrade leva o tempo de copiar os dados uma vez,
  precisa de espaço para uma segunda cópia e deixa o cluster antigo completo: se o 17 se comportar
  mal, você o para e sobe o 16 de novo.

Num banco do tamanho do `shop` a diferença quase não importa. Num grande, ela decide quanto dura a
noite, e esse é mais um motivo para ensaiar numa cópia do tamanho da produção: os tempos que você
mede ali são os que você vai ter.

## Quando vier o upgrade de verdade

O mesmo comando faz o upgrade do `main` — `sudo pg_upgradecluster -m upgrade --link 16 main` — com
um passo antes. Ele cria o `17/main`, e **se recusa quando já existe um cluster com esse nome**, como
o vazio que o pacote criou. Então a execução real começa com `sudo pg_dropcluster --stop 17 main`,
depois de conferir que não há nada nele. Não rode nenhum dos dois no seu servidor agora: esta lição
termina com o `main` ainda no 16.
