---
title: Medindo a perda a que você está exposto agora
version: 1
---

O RPO que um esquema entrega quando um servidor se perde é simples de enunciar: **tudo o que foi
escrito desde que o último segmento chegou ao arquivo.** O `pg_stat_archiver` da lição 4 tem as duas
metades disso, a hora do último segmento arquivado e o nome dele, e uma consulta transforma isso nos
dois números que vale a pena acompanhar. Salve como `rpo.sql`:

```schooling-example
{"language": "sql", "file": "rpo.sql", "parts": [{"code": "-- rpo.sql: what this server would lose if its disk died now\nSELECT now() - last_archived_time AS since_last_archive,", "note": "Quanto tempo faz que um segmento completo chegou ao arquivo pela última vez: tudo o que foi escrito desde então só existe neste servidor."}, {"code": "       pg_size_pretty(pg_current_wal_lsn()\n         - ('0/0'::pg_lsn + ((pg_split_walfile_name(left(last_archived_wal, 24))).segment_number + 1) * 16777216))\n         AS not_yet_archived,", "note": "Quanto log foi escrito além do fim do último segmento arquivado. O nome é cortado nos primeiros 24 caracteres porque, logo depois de um backup, a última coisa arquivada é um arquivo de histórico de backup, cujo nome leva um sufixo."}, {"code": "       current_setting('archive_timeout') AS archive_timeout\nFROM pg_stat_archiver;", "note": "E a configuração que põe um limite superior no primeiro número quando o servidor está parado."}]}
```

A segunda coluna é a aritmética de LSN da lição 4: o fim do último segmento arquivado é o número dele
mais um, vezes 16 MB, e a posição atual menos isso é o log que só existe aqui.

Rode logo depois do esquema da lição 5, com um backup full recém-feito, e de novo depois de três
pedidos e quarenta segundos de calmaria:

```
ana@vm:~$ psql -X shop -f rpo.sql
 since_last_archive | not_yet_archived | archive_timeout 
--------------------+------------------+-----------------
 00:00:00.383811    | 0 bytes          | 0
(1 row)

ana@vm:~$ psql -X shop -f rpo.sql
 since_last_archive | not_yet_archived | archive_timeout 
--------------------+------------------+-----------------
 00:00:40.665245    | 1716 kB          | 0
(1 row)
```

A primeira execução é o melhor momento que um servidor chega a ter: o backup acabou de trocar de
segmento e arquivar o log, e não há nada pendente. Quarenta segundos e três pedidos depois, **1716 kB
de log e quarenta segundos de trabalho só existem nesta máquina**, e com `archive_timeout` em 0 nada
limita quanto tempo isso dura numa tarde tranquila. Esse é o RPO medido, e ele piora a cada segundo
até um segmento encher.

A configuração da lição 4 põe um teto nele:

```
shop=# ALTER SYSTEM SET archive_timeout = '60s';
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
ana@vm:~$ psql -X shop -f rpo.sql
 since_last_archive | not_yet_archived | archive_timeout 
--------------------+------------------+-----------------
 00:00:11.321607    | 0 bytes          | 1min
(1 row)
```

Onze segundos desde o último arquivamento, e a garantia de que isso não passa de mais ou menos um
minuto enquanto houver escrita. **O RPO que este esquema entrega quando o servidor se perde agora é de
mais ou menos um minuto.** Ponha o `rpo.sql` num agendamento e dispare um alerta quando
`since_last_archive` passar do dobro do `archive_timeout`: esse único alerta cobre um arquivamento
quebrado, um comando travado e um repositório cheio, porque cada um deles aparece primeiro como o
arquivo ficando para trás.
