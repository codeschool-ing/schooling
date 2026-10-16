---
title: Quando o comando de arquivamento falha
version: 1
---

Um arquivo falha de jeitos comuns: um compartilhamento de rede some, um disco enche, uma credencial
expira, alguém muda as permissões de um diretório. Faça a última, obrigue o servidor a terminar um
segmento, e observe:

```
ana@vm:~$ sudo chmod 500 /var/lib/postgresql/wal-archive
shop=# UPDATE orders SET total_cents = total_cents + 1;
UPDATE 50000

shop=# SELECT pg_switch_wal();
 pg_switch_wal 
---------------
 0/64E8FB8
(1 row)
shop=# SELECT archived_count, last_archived_wal, failed_count, last_failed_wal FROM pg_stat_archiver;
 archived_count |    last_archived_wal     | failed_count |     last_failed_wal      
----------------+--------------------------+--------------+--------------------------
              1 | 000000010000000000000004 |            5 | 000000010000000000000005
(1 row)
ana@vm:~$ sudo tail -n 4 /var/log/postgresql/postgresql-16-main.log
cp: cannot create regular file '/var/lib/postgresql/wal-archive/000000010000000000000005': Permission denied
2026-10-10 04:34:13.007 -03 [8697] LOG:  archive command failed with exit code 1
2026-10-10 04:34:13.007 -03 [8697] DETAIL:  The failed archive command was: test ! -f /var/lib/postgresql/wal-archive/000000010000000000000005 && cp pg_wal/000000010000000000000005 /var/lib/postgresql/wal-archive/000000010000000000000005
2026-10-10 04:34:13.007 -03 [8697] WARNING:  archiving write-ahead log file "000000010000000000000005" failed too many times, will try again later
```

O `failed_count` já está em 5, para um segmento só: o servidor tenta de novo um segmento que falha
algumas vezes seguidas, desiste por um minuto e tenta outra vez, contando cada tentativa. O
`last_failed_wal` dá o nome do segmento que não sai. O log diz por quê nas palavras do próprio
comando (`cp: cannot create regular file … Permission denied`), e depois mostra o comando exato que
falhou, que é a linha que você copia para um terminal para reproduzir o problema.

Nada mais aconteceu. **Nenhuma consulta falhou, nenhum cliente foi avisado, o banco seguiu em
frente.** Esse é o comportamento certo, porque a alternativa é um banco que para sempre que os
backups dele têm um problema. É também o que torna essa falha perigosa: os únicos lugares onde ela
aparece são uma linha de log e um contador.

## O que o servidor faz com os segmentos que não consegue arquivar

Guarda. Um segmento não é reciclado até ser arquivado, então todo segmento escrito enquanto o
arquivo está quebrado fica em `pg_wal`. Cada um é marcado por um arquivo em `archive_status`,
`.ready` para os que esperam e `.done` para os arquivados:

```
ana@vm:~$ sudo ls /var/lib/postgresql/16/main/pg_wal/archive_status
000000010000000000000004.done
000000010000000000000005.ready
000000010000000000000006.ready
ana@vm:~$ for i in 1 2 3 4 5 6; do psql -q shop -c "UPDATE orders SET total_cents = total_cents + 1" -c "SELECT pg_switch_wal()" > /dev/null; done
ana@vm:~$ sudo ls /var/lib/postgresql/16/main/pg_wal/archive_status | grep -c ready
8
ana@vm:~$ sudo du -sh /var/lib/postgresql/16/main/pg_wal
145M	/var/lib/postgresql/16/main/pg_wal
```

Mais seis updates, e oito segmentos esperando, **145 MB de log que o servidor tem que guardar** e
dos quais não consegue se livrar. A aritmética de uma falha de verdade é a mesma com números
maiores: um banco que escreve 2 GB de log por hora, com um arquivo que quebrou na sexta à noite,
tem 120 GB de `pg_wal` na segunda de manhã. Quando o disco que guarda o `pg_wal` enche, o servidor
não consegue escrever o log, e um servidor que não consegue escrever o log **para de aceitar
escritas e desliga**. Um problema de backup que ninguém viu vira uma indisponibilidade que todo
mundo vê.

## Consertando, e vendo o servidor pôr em dia

Devolva a permissão, e dê um minuto ao servidor para tentar de novo:

```
ana@vm:~$ sudo chmod 700 /var/lib/postgresql/wal-archive
shop=# SELECT archived_count, last_archived_wal, failed_count FROM pg_stat_archiver;
 archived_count |    last_archived_wal     | failed_count 
----------------+--------------------------+--------------
              9 | 00000001000000000000000C |           13
(1 row)
ana@vm:~$ sudo ls /var/lib/postgresql/16/main/pg_wal/archive_status | grep -c ready
0
```

Nove arquivados, nada esperando. O servidor arquivou o acúmulo em ordem, do mais antigo para o mais
novo, e daqui em diante recicla esses segmentos normalmente. O `failed_count` fica em 13: ele conta
tentativas desde a última vez que as estatísticas foram zeradas, não problemas atuais, e é por isso
que um alerta tem que compará-lo com o valor anterior em vez de com zero.

## Sobre o que alertar

Três condições cobrem todas as formas de o arquivamento dar errado, e cada uma é uma consulta ao
`pg_stat_archiver` ou uma olhada num diretório:

- **O `failed_count` subiu** desde a última verificação. Algo falhou, mesmo que tenha se
  recuperado.
- **O `last_archived_time` está mais velho do que deveria.** Num servidor ocupado, mais de alguns
  minutos; num tranquilo, mais que o `archive_timeout`, que a próxima seção configura. Esta pega o
  comando que trava em vez de falhar.
- **O número de arquivos `.ready` não para de crescer**, ou o `pg_wal` está acima do tamanho de
  costume. Esta é a que prevê a indisponibilidade, e a que justifica acordar alguém.
