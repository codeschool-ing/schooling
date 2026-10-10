---
title: Arquivamento: uma cópia de cada segmento, assim que ele termina
version: 1
---

Deixado por conta própria, o servidor recicla segmentos antigos: quando um checkpoint os torna
desnecessários para a sua própria recuperação de queda, os arquivos deles são renomeados e
sobrescritos. O **arquivamento contínuo** pede ao servidor que entregue antes cada segmento
terminado a um comando, e que não o recicle até esse comando ter dado certo. O comando o copia para
um lugar seguro, e a coleção de cópias é o **arquivo**.

Duas configurações o ligam. O `archive_mode` faz o servidor acompanhar quais segmentos já foram
arquivados; o `archive_command` é um comando de shell que o servidor roda uma vez por segmento
terminado, com `%p` trocado pelo caminho do segmento e `%f` pelo nome do arquivo.

O arquivo precisa de uma casa em que o usuário do servidor possa escrever. Neste lab ele é um
diretório na mesma máquina, que é o lugar errado para um arquivo de verdade e o lugar certo para
aprender o mecanismo; a lição 9 o muda de lugar.

```
ana@vm:~$ sudo -u postgres mkdir /var/lib/postgresql/wal-archive
ana@vm:~$ sudo -u postgres chmod 700 /var/lib/postgresql/wal-archive
```

Agora as configurações. O `ALTER SYSTEM` as escreve em `postgresql.auto.conf` no diretório de
dados, um arquivo que o servidor lê depois da configuração principal, e o `archive_mode` só tem
efeito num restart:

```
shop=# ALTER SYSTEM SET archive_mode = on;
ALTER SYSTEM

shop=# ALTER SYSTEM SET archive_command = 'test ! -f /var/lib/postgresql/wal-archive/%f && cp %p /var/lib/postgresql/wal-archive/%f';
ALTER SYSTEM
ana@vm:~$ sudo pg_ctlcluster 16 main restart
shop=# SHOW archive_mode;
 archive_mode 
--------------
 on
(1 row)

shop=# SELECT archived_count, last_archived_wal, failed_count FROM pg_stat_archiver;
 archived_count | last_archived_wal | failed_count 
----------------+-------------------+--------------
              0 |                   |            0
(1 row)
```

Leia o comando antes de confiar nele. O `test ! -f …/%f` só dá certo se ainda não houver no
arquivo um arquivo com esse nome, e o `&&` só roda a cópia se ele deu certo. Essa guarda não é
enfeite: **um archive_command nunca pode sobrescrever um segmento que já está arquivado**, porque
um segundo servidor configurado errado para arquivar no mesmo lugar substituiria a sua história
pela dele, em silêncio. Com a guarda, a cópia falha, a falha é contada, e alguém percebe.

O `pg_stat_archiver` é o relato do próprio servidor sobre como vai o arquivamento, e logo depois do
restart ele não tem nada a dizer. Dê um segmento a ele:

```
shop=# SELECT pg_switch_wal();
 pg_switch_wal 
---------------
 0/40000B8
(1 row)
shop=# SELECT archived_count, last_archived_wal, last_archived_time, failed_count FROM pg_stat_archiver;
 archived_count |    last_archived_wal     |      last_archived_time       | failed_count 
----------------+--------------------------+-------------------------------+--------------
              1 | 000000010000000000000004 | 2026-10-10 04:34:04.840024-03 |            0
(1 row)
ana@vm:~$ sudo ls -l /var/lib/postgresql/wal-archive
total 16384
-rw------- 1 postgres postgres 16777216 Oct 10 04:34 000000010000000000000004
```

**`archived_count` 1, `failed_count` 0**, e o segmento está no arquivo com os seus 16 MB inteiros.
Esses dois números, e o horário ao lado do último segmento arquivado, são as três coisas a vigiar em
todo servidor que arquiva. A próxima seção quebra o comando e mostra por quê.

O `cp` é o comando mais simples que funciona, e não é um bom comando para produção: ele não garante
que a cópia chegou ao disco antes de informar sucesso, e uma queda de energia logo depois pode
deixar um segmento que o servidor acredita estar seguro e que o disco nunca guardou. A ferramenta
da lição 5 o substitui por uma que garante. O mecanismo, a guarda contra sobrescrever e as
estatísticas continuam os mesmos.
