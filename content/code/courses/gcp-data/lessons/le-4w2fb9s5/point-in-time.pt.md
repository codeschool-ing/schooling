---
title: Recuperação a um ponto no tempo, praticada no PostgreSQL
version: 1
---

**Recuperação a um ponto no tempo é um backup base e toda mudança desde então, reaplicada até um
momento que você escolhe.** Um backup tirado ontem à noite guarda o banco como estava ontem à noite. O
write-ahead log guarda toda mudança feita depois dele, em ordem, com a hora em que cada transação foi
confirmada. Restaure o backup, reaplique o log, e pare logo antes do engano: o banco como estava às
15:46:55 de uma sexta-feira, com todo pedido até aquele segundo e nada do estrago depois dele.

**O Cloud SQL faz exatamente isso quando a recuperação a um ponto no tempo está ligada**, com os
backups da próxima seção e o log que ele guarda ao lado deles, e o resultado é sempre uma **instância
nova**. O comando é um clone:

```sh
gcloud sql instances clone quitanda-orders quitanda-orders-before-delete \
  --point-in-time='2026-10-30T18:46:55Z'
```

Ele não foi executado. A referência diz como escrever a hora, e é o detalhe que as pessoas erram:

```
ana@laptop:~/gcp$ gcloud sql instances clone --help | sed -n '/^       --point-in-time=/,/^$/p'
       --point-in-time=POINT_IN_TIME
          Represents the state of an instance at any given point in time inside
          a transaction log file. For MySQL, the binary log file is used for
          transaction logs. For PostgreSQL, the write-ahead log file is used
          for transaction logs. For SQL Server, the log backup file is used for
          such purpose. To create a transaction log, enable point-in-time
          recovery on the source instance. Instance should have transaction
          logs accumulated up to the point in time they want to restore up to.
          Uses RFC 3339 format in UTC timezone. If specified, defines a past
          state of the instance to clone. For example,
          '2012-11-15T16:19:00.094Z'.
```

**RFC 3339, em UTC.** 15:46:55 em São Paulo é `18:46:55Z`. E quanto o momento pode ficar para trás é a
retenção do log da tabela de edições da aula 6, que a referência dá para a flag que a define:

```
ana@laptop:~/gcp$ gcloud sql instances create --help | sed -n '/^     --retained-backups-count=/,/^$/p;/^     --retained-transaction-log-days=/,/^$/p'
     --retained-backups-count=RETAINED_BACKUPS_COUNT
        How many backups to keep. The valid range is between 1 and 365. Default
        value is 7 for Enterprise edition instances. For Enterprise_Plus,
        default value is 15. Applicable only if --no-backups is not specified.

     --retained-transaction-log-days=RETAINED_TRANSACTION_LOG_DAYS
        How many days of transaction logs to keep. The valid range is between 1
        and 35. Only use this option when point-in-time recovery is enabled. If
        logs are stored on disk, storage size for transaction logs could
        increase when the number of days for log retention increases. For
        Enterprise, default and max retention values are 7 and 7 respectively.
        For Enterprise_Plus, default and max retention values are 14 and 35.
```

**Sete dias no Enterprise, e sete também é o máximo; até 35 no Enterprise Plus.** Um engano descoberto
no dia oito numa instância Enterprise está fora do alcance do log, e só um backup de antes dele ajuda,
no momento daquele backup e não no segundo que você queria.

O resto desta seção é **PostgreSQL no notebook**: o arquivo que o Cloud SQL guarda por você, montado à
mão, e uma recuperação a um momento, feita à mão. Os dois servidores da seção anterior continuam no ar.

## Arquivando o log

**O PostgreSQL recicla os arquivos de log quando um checkpoint não precisa mais deles**, então
guardá-los para recuperação é uma configuração: `archive_mode` liga o arquivamento, e `archive_command`
é o comando de shell que o servidor roda para cada segmento terminado, com `%p` o caminho dele e `%f` o
nome do arquivo. O comando aqui copia para `~/gcp/pg/archive`, que é `../archive` a partir do diretório
de dados em que o servidor roda, e se recusa a sobrescrever um segmento que já está lá:

```
ana@laptop:~/gcp$ mkdir -p ~/gcp/pg/archive
ana@laptop:~/gcp$ psql -c 'ALTER SYSTEM SET archive_mode = on' -c "ALTER SYSTEM SET archive_command = 'test ! -f ../archive/%f && cp %p ../archive/%f'"
ALTER SYSTEM
ALTER SYSTEM
ana@laptop:~/gcp$ pg_ctl -D ~/gcp/pg/orders -l ~/gcp/pg/orders.log restart -m fast
waiting for server to shut down.... done
server stopped
waiting for server to start.... done
server started
ana@laptop:~/gcp$ psql -Atc 'SHOW archive_mode'
on
ana@laptop:~/gcp$ psql -Atc 'SELECT state FROM pg_stat_replication'
streaming
```

**`archive_mode` é uma configuração `postmaster`**, a coluna de contexto da aula 6 de novo, então
precisou do reinício. A réplica reconectou sozinha depois dele; `streaming` diz isso.

## Um backup base, e depois o engano

```
ana@laptop:~/gcp$ pg_basebackup -D ~/gcp/pg/base -c fast && ls ~/gcp/pg/archive
000000010000000000000003
000000010000000000000004
000000010000000000000004.00000028.backup
```

O backup base é o mesmo comando da réplica, sem `-R`, para `~/gcp/pg/base`. O arquivo agora guarda os
segmentos escritos até aqui, e um pequeno arquivo `.backup` que marca onde, no log, o backup começou.
Agora anote a hora, e depois cometa o engano que todo banco de dados encontra um dia:

```
ana@laptop:~/gcp$ psql -Atc 'SELECT now()'
2026-10-30 15:46:55.877432-03
ana@laptop:~/gcp$ psql -c 'DELETE FROM orders' -c 'SELECT pg_switch_wal()' > /dev/null && sleep 1 && psql -Atc 'SELECT count(*) FROM orders' && psql -p 5434 -Atc 'SELECT count(*) FROM orders'
0
0
ana@laptop:~/gcp$ ls ~/gcp/pg/archive
000000010000000000000003
000000010000000000000004
000000010000000000000004.00000028.backup
000000010000000000000005
```

**Zero no primário e zero na réplica.** O `DELETE` sem `WHERE` chegou à réplica dentro do segundo, como
as seções anteriores disseram que chegaria. O `pg_switch_wal()` fechou o segmento de log atual para
que o servidor o arquivasse na hora, em vez de quando enchesse. No Cloud SQL o log chega ao arquivo num
ritmo do Google, e é por isso que o momento mais recente para o qual dá para recuperar fica um pouco
atrás do presente.

## Recuperando ao momento de antes

**A recuperação parte do backup base, nunca do diretório danificado.** Copie-o, e marque a cópia para
recuperação com `recovery.signal`, o irmão do `standby.signal` da réplica: recupere, depois pare e vire
um servidor próprio. Três configurações dizem onde está o log, até onde reaplicar, e o que fazer ao
chegar:

```
ana@laptop:~/gcp$ cp -a ~/gcp/pg/base ~/gcp/pg/restored && touch ~/gcp/pg/restored/recovery.signal
ana@laptop:~/gcp$ printf "restore_command = 'cp ../archive/%%f %%p'\nrecovery_target_time = '2026-10-30 15:46:55.877432-03'\nrecovery_target_action = 'promote'\n" >> ~/gcp/pg/restored/postgresql.auto.conf && tail -3 ~/gcp/pg/restored/postgresql.auto.conf
restore_command = 'cp ../archive/%f %p'
recovery_target_time = '2026-10-30 15:46:55.877432-03'
recovery_target_action = 'promote'
```

**A hora é a que o `SELECT now()` imprimiu**, com o deslocamento, `-03`, que é o que permite ao
PostgreSQL ler corretamente a hora de São Paulo. Inicie a cópia numa porta própria, 5435, e leia o que
ela fez:

```
ana@laptop:~/gcp$ pg_ctl -D ~/gcp/pg/restored -o "-p 5435 -k $HOME/gcp/pg" -l ~/gcp/pg/restored.log start
waiting for server to start.... done
server started
ana@laptop:~/gcp$ sleep 2 && grep -E 'starting point-in-time|recovery stopping|selected new timeline' ~/gcp/pg/restored.log | cut -d' ' -f4-
[28834] LOG:  starting point-in-time recovery to 2026-10-30 15:46:55.877432-03
[28834] LOG:  recovery stopping before commit of transaction 733, time 2026-10-30 15:46:56.905418-03
[28834] LOG:  selected new timeline ID: 2
ana@laptop:~/gcp$ psql -p 5435 -Atc 'SELECT count(*), max(id) FROM orders'
1100|1100
```

**`recovery stopping before commit of transaction 733`** é o `DELETE`, confirmado um segundo depois do
alvo, e o servidor parou logo antes dele. **`selected new timeline ID: 2`** é o servidor restaurado
começando uma história própria, ramificada da original no alvo; é isso que permite ao mesmo arquivo
guardar as duas. E **1.100 pedidos, o último o 1.100**: tudo até o momento, inclusive os cem escritos
enquanto a réplica estava pausada, e nada do estrago.

```
ana@laptop:~/gcp$ pg_ctl -D ~/gcp/pg/restored stop && pg_ctl -D ~/gcp/pg/reports stop && pg_ctl -D ~/gcp/pg/orders stop
waiting for server to shut down.... done
server stopped
waiting for server to shut down.... done
server stopped
waiting for server to shut down.... done
server stopped
```

**A original não foi tocada.** Ela continua sem pedidos, e a cópia restaurada fica ao lado dela em
outra porta. Essa é exatamente a forma do clone do Cloud SQL: uma instância nova, com endereço novo, ao
lado da antiga. Alguém então decide se aponta a aplicação para o clone ou se copia as linhas que faltam
de volta para a original, e essa decisão é de uma pessoa, não de um comando.
