---
title: Olhando o log
version: 1
---

O write-ahead log é um único fluxo de bytes que só cresce, cortado em arquivos de 16 MB para que os
pedaços antigos possam ser jogados fora. **Uma posição nesse fluxo é um log sequence number, um
LSN**, e todo registro, toda página e toda réplica no PostgreSQL é localizado por um.

## Os arquivos

`pg_wal` pertence ao `postgres`, como o resto do diretório de dados, então listar precisa de `sudo`.
As últimas entradas bastam:

```
ana@db:~$ sudo ls -l /var/lib/postgresql/16/main/pg_wal | tail -n 4
-rw------- 1 postgres postgres 16777216 Oct 10 04:26 000000010000000000000013
-rw------- 1 postgres postgres 16777216 Oct 10 04:26 000000010000000000000014
-rw------- 1 postgres postgres 16777216 Oct 10 04:26 000000010000000000000015
drwx------ 2 postgres postgres     4096 Oct 10 03:18 archive_status
ana@db:~$ sudo du -sh /var/lib/postgresql/16/main/pg_wal
337M	/var/lib/postgresql/16/main/pg_wal
```

**Todo segmento tem exatamente 16777216 bytes**, cheio ou não: um novo é criado já no tamanho final
e preenchido do começo. O nome tem 24 dígitos hexadecimais em três grupos de oito. O primeiro,
`00000001`, é a **timeline**, que só muda quando um servidor é recuperado para um ponto anterior ou
uma réplica é promovida, e as duas coisas pertencem ao db-reliability. Os outros dois juntos são o
número do segmento, contado desde o começo da história do cluster, então os nomes ficam em ordem
de escrita. `archive_status` é um diretório, usado quando os segmentos são copiados para um backup.

## Onde o servidor está agora

Duas funções respondem até onde o log chegou e que arquivo é esse:

```
shop=# SELECT pg_current_wal_lsn(), pg_walfile_name(pg_current_wal_lsn());
 pg_current_wal_lsn |     pg_walfile_name      
--------------------+--------------------------
 0/1584F1C0         | 000000010000000000000015
(1 row)
```

**Um LSN é um deslocamento em bytes escrito em hexadecimal**, em duas metades separadas por uma
barra. `0/1584F1C0` fica a uns 361 milhões de bytes do começo da história do cluster, quase tudo
da carga do `shop`. Com segmentos de 16 MB, os dígitos antes dos seis últimos dão o segmento, `15`,
e os seis últimos dão o deslocamento dentro dele — por isso o arquivo é `…15`. Você nunca faz essa
conta à mão; o `pg_walfile_name` faz, e o `pg_wal_lsn_diff`, na próxima seção, subtrai duas posições
e dá bytes.

## Um INSERT, decodificado

O log é binário, e o PostgreSQL traz um leitor para ele, o `pg_waldump`. O Ubuntu não o coloca no
seu `PATH`, porque os comandos que estão lá são invólucros que escolhem uma versão; ele mora com os
programas do próprio servidor em `/usr/lib/postgresql/16/bin`. Anote a posição, faça uma alteração
pequena e anote a posição de novo:

```
shop=# SELECT pg_current_wal_lsn();
 pg_current_wal_lsn 
--------------------
 0/1584F1C0
(1 row)

shop=# INSERT INTO notes VALUES (2, 'and this one');
INSERT 0 1

shop=# SELECT pg_current_wal_lsn();
 pg_current_wal_lsn 
--------------------
 0/1584F270
(1 row)
```

Depois passe as duas posições ao `pg_waldump` com `-s` (início) e `-e` (fim), e aponte o diretório
com `-p`. Use os números que o seu próprio `psql` mostrou:

```
ana@db:~$ sudo /usr/lib/postgresql/16/bin/pg_waldump -p /var/lib/postgresql/16/main/pg_wal -s 0/1584F1C0 -e 0/1584F270
rmgr: Heap        len (rec/tot):     72/    72, tx:        784, lsn: 0/1584F1C0, prev 0/1584F198, desc: INSERT off: 2, flags: 0x00, blkref #0: rel 1663/16386/16420 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:        784, lsn: 0/1584F208, prev 0/1584F1C0, desc: INSERT_LEAF off: 2, blkref #0: rel 1663/16386/16425 blk 1
rmgr: Transaction len (rec/tot):     34/    34, tx:        784, lsn: 0/1584F248, prev 0/1584F208, desc: COMMIT 2026-10-10 04:26:32.265684 -03
```

**Um `INSERT` de uma linha são três registros.** Leia cada linha pelos campos:

| campo | o que diz |
| --- | --- |
| `rmgr` | a parte do servidor que sabe refazer o registro: `Heap` para linhas de tabela, `Btree` para índices, `Transaction` para commits |
| `len (rec/tot)` | o tamanho do próprio registro, e o total com o que estiver anexado a ele; aqui os dois são iguais |
| `tx` | a transação que o escreveu: os três pertencem à transação 784 |
| `lsn`, `prev` | onde o registro começa, e onde começa o anterior |
| `desc` | o que aconteceu: a linha entrou na posição 2 da página |
| `blkref` | a página que ele alterou: tablespace, banco e arquivo, e depois o número do bloco |

`rel 1663/16386/16420 blk 0` é o bloco 0 do arquivo `base/16386/16420`, a tabela `notes` — o mesmo
caminho que o `pg_relation_filepath` deu acima, com `1663`, o tablespace padrão, na frente. O
segundo registro pôs a nova chave no índice da chave primária, outro arquivo. O terceiro é o próprio
commit, e **esse registro chegar ao disco foi o que tornou a transação durável**. Nada no arquivo da
tabela precisou mudar para isso ser verdade.

Repare também no que os registros não levam: uma cópia da página inteira. Eles descrevem uma
alteração numa página que o servidor espera encontrar intacta. A próxima seção mede o que acontece
quando o servidor não pode contar com isso.
