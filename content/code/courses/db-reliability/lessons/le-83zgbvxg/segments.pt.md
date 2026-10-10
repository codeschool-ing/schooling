---
title: O write-ahead log, visto como arquivos
version: 1
---

As lições 2 e 3 terminaram no mesmo limite: um backup é um momento, e tudo o que é escrito depois
dele fica fora do backup. O caminho para passar desse limite já rodava no seu servidor antes de
você instalar qualquer coisa. Toda mudança que o PostgreSQL faz é escrita primeiro no
**write-ahead log**, um registro sequencial do que está para acontecer com os arquivos de dados, e
a lição 7 do curso de administração explicou por quê: depois de uma queda, é com o log que o
servidor conserta os arquivos. Esta lição guarda esse log. Um base backup mais todo registro de log
escrito desde então é o banco em qualquer momento que você quiser.

## Segmentos

Em disco, o log é um diretório de arquivos de exatamente 16 MB cada, chamados **segmentos**:

```
ana@vm:~$ sudo ls -l /var/lib/postgresql/16/main/pg_wal
total 32772
-rw------- 1 postgres postgres 16777216 Oct 10 04:33 000000010000000000000001
-rw------- 1 postgres postgres 16777216 Oct 10 04:33 000000010000000000000002
drwx------ 2 postgres postgres     4096 Oct 10 04:33 archive_status
shop=# SELECT pg_current_wal_lsn(), pg_walfile_name(pg_current_wal_lsn());
 pg_current_wal_lsn |     pg_walfile_name      
--------------------+--------------------------
 0/212D3E8          | 000000010000000000000002
(1 row)
```

Os nomes não são arbitrários. `000000010000000000000002` são três números de oito dígitos
hexadecimais: a **timeline** (`00000001`, que a lição 6 explica) e depois onde no log o segmento
fica. Os segmentos são escritos em ordem e nomeados em ordem, e um arquivo deles se ordena do jeito
que a história aconteceu.

Uma posição dentro do log é um **log sequence number**, um LSN, escrito como dois números
hexadecimais separados por uma barra. `0/212D3E8` é uma posição em bytes, e o `pg_walfile_name` diz
qual segmento a contém. Dois LSNs podem ser subtraídos, e a resposta é quantos bytes de log foram
escritos entre eles, que é a medida mais honesta que existe de quanto uma instrução mudou:

```
shop=# SELECT pg_current_wal_lsn() AS before \gset
shop=# UPDATE orders SET total_cents = total_cents + 1;
UPDATE 50000

shop=# SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before'));
 pg_size_pretty 
----------------
 15 MB
(1 row)
```

O `\gset` guardou a primeira resposta numa variável do `psql` chamada `before`, e a última consulta
a subtraiu da nova posição. **Atualizar cinquenta mil linhas escreveu 15 MB de log**, quase um
segmento inteiro, para uma tabela cujos dados têm uns 3 MB. Cada linha atualizada é uma nova versão
da linha, registrada no log junto com as entradas de índice que apontam para ela, e a primeira
mudança em cada página de 8 kB depois de um checkpoint registra a página inteira, para que uma
queda no meio da escrita dela possa ser consertada. Lembre dessa proporção quando a lição 8
perguntar quanto log um dia de um banco de verdade produz.

## Um segmento termina quando enche, ou quando pedem

O servidor escreve num segmento até usar os 16 MB dele, e então passa para o próximo. Um segmento
terminado é a unidade com que tudo nesta lição trabalha, então importa que um segmento também possa
ser terminado antes, a pedido:

```
shop=# SELECT pg_walfile_name(pg_current_wal_lsn());
     pg_walfile_name      
--------------------------
 000000010000000000000003
(1 row)

shop=# SELECT pg_switch_wal();
 pg_switch_wal 
---------------
 0/302B1C8
(1 row)
```

O `pg_switch_wal()` fecha o segmento atual onde ele está e começa o próximo, e responde com a
posição em que o antigo terminou. O segmento 3 foi terminado naquele momento, uns 170 kB dentro dos
seus 16 MB, e o resto do arquivo nunca é usado. Você vai usar essa função a lição inteira para
fazer o servidor entregar um segmento agora, em vez de quando ele encher.
