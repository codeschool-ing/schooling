---
title: Restaurando um base backup
version: 1
---

Restaurar um backup físico tem quatro passos, e nenhum envolve SQL: parar o servidor que vai
recebê-lo, pôr os arquivos onde fica o diretório de dados dele, entregá-los ao usuário com que o
servidor roda e subi-lo. O destino é o segundo servidor da lição 2, na porta 5433, cujos dados
estão prestes a ser substituídos por inteiro.

```
ana@vm:~$ sudo pg_ctlcluster 16 restore stop
ana@vm:~$ sudo rm -rf /var/lib/postgresql/16/restore
ana@vm:~$ sudo cp -a base /var/lib/postgresql/16/restore
ana@vm:~$ sudo chown -R postgres:postgres /var/lib/postgresql/16/restore
ana@vm:~$ sudo chmod 700 /var/lib/postgresql/16/restore
ana@vm:~$ sudo pg_ctlcluster 16 restore start
ana@vm:~$ sudo tail -n 6 /var/log/postgresql/postgresql-16-restore.log
2026-10-10 04:14:59.318 -03 [4295] LOG:  completed backup recovery with redo LSN 0/2D000028 and end LSN 0/2D000100
2026-10-10 04:14:59.318 -03 [4295] LOG:  consistent recovery state reached at 0/2D000100
2026-10-10 04:14:59.318 -03 [4295] LOG:  redo done at 0/2D000100 system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
2026-10-10 04:14:59.410 -03 [4293] LOG:  checkpoint starting: end-of-recovery immediate wait
2026-10-10 04:14:59.416 -03 [4293] LOG:  checkpoint complete: wrote 3 buffers (0.0%); 0 WAL file(s) added, 0 removed, 1 recycled; write=0.002 s, sync=0.001 s, total=0.007 s; sync files=2, longest=0.001 s, average=0.001 s; distance=16384 kB, estimate=16384 kB; lsn=0/2E000028, redo lsn=0/2E000028
2026-10-10 04:14:59.421 -03 [4292] LOG:  database system is ready to accept connections
```

O `cp -a` preserva os horários e as permissões dos arquivos, e as duas linhas seguintes cuidam do
resto: o backup foi escrito por você, e um servidor PostgreSQL se recusa a subir num diretório que
qualquer um além do próprio usuário dele consegue ler. O `chmod 700` não é formalidade, e
esquecê-lo é o jeito mais comum de essa restauração falhar, com uma mensagem no log dizendo
exatamente isso.

O log é onde dá para acompanhar a restauração. As posições estão um segmento adiante do label mostrado duas seções atrás, `0/2D…` em vez de `0/2C…`, porque este é o backup tirado de novo depois da adulteração. O servidor encontrou o `backup_label`, reaplicou o
write-ahead log do ponto de início do backup até o ponto final (`completed backup recovery`) e
informou **`consistent recovery state reached`**: a cópia agora é um único momento, o momento em
que o backup terminou. Depois ele rodou um checkpoint e abriu. Essas linhas são o equivalente físico
do `pg_restore` saindo com 0, e merecem a mesma desconfiança:

```
ana@vm:~$ psql -X -A -t shop -f verify.sql > live.txt
ana@vm:~$ psql -X -A -t -p 5433 shop -f verify.sql > restored.txt
ana@vm:~$ diff live.txt restored.txt && echo identical
identical
ana@vm:~$ psql -p 5433 -l
                                                   List of databases
   Name    |  Owner   | Encoding | Locale Provider | Collate |  Ctype  | ICU Locale | ICU Rules |   Access privileges   
-----------+----------+----------+-----------------+---------+---------+------------+-----------+-----------------------
 bigshop   | ana      | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 postgres  | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 shop      | ana      | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 template0 | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | =c/postgres          +
           |          |          |                 |         |         |            |           | postgres=CTc/postgres
 template1 | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | =c/postgres          +
           |          |          |                 |         |         |            |           | postgres=CTc/postgres
(5 rows)
```

O relatório bate, e a lista de bancos mostra num relance a diferença em relação à lição 2:
**o servidor inteiro voltou**, `bigshop` incluído, sem ninguém precisar nomeá-lo. Não houve
`createdb`, nem arquivo de globais, nem papel para criar antes, porque os papéis ficam no diretório
de dados como todo o resto e foram copiados junto.

Esse é o formato de toda restauração física deste curso. A ferramenta da lição 5 automatiza a
cópia, e a lição 6 acrescenta uma configuração que diz ao servidor para continuar reaplicando depois
do fim do backup, até um momento que você escolhe.
