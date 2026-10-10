---
title: Conferindo o servidor em execução
version: 1
---

O script dizer `wrote` e `reloaded` prova que um arquivo foi copiado e um sinal foi enviado. Não
prova que o servidor aceitou os valores. **Duas views respondem isso, e respondem perguntas
diferentes.** O `pg_settings` é o que o servidor está rodando agora e, para cada valor, o arquivo e
a linha de onde ele veio. O `pg_file_settings` é o que os arquivos de configuração dizem agora,
lidos de novo do disco toda vez que você consulta, com um erro ao lado de qualquer linha que o
servidor não conseguiu usar.

## O que está rodando, e de onde

No servidor que o script montou, peça todo valor cuja origem é o arquivo do repositório. Não existe
papel para você nesta máquina, então o `psql` roda como `postgres`:

```
postgres=# SELECT name, setting, unit, sourceline, pending_restart FROM pg_settings WHERE sourcefile = '/etc/postgresql/16/main/conf.d/50-shop.conf' ORDER BY sourceline;
            name            | setting | unit | sourceline | pending_restart 
----------------------------+---------+------+------------+-----------------
 listen_addresses           | *       |      |          3 | f
 shared_buffers             | 131072  | 8kB  |          4 | f
 work_mem                   | 32768   | kB   |          5 | f
 maintenance_work_mem       | 262144  | kB   |          6 | f
 log_min_duration_statement | 500     | ms   |          7 | f
 log_lock_waits             | on      |      |          8 | f
(6 rows)
```

Seis linhas para os seis ajustes do arquivo, cada uma na sua linha. O `setting` está na unidade ao
lado, então `shared_buffers` são 131072 páginas de 8 kB, que é o 1 GB que o arquivo pediu, e
`work_mem` são os 32 MB commitados na seção anterior. **`pending_restart` é `f` em todas as
linhas**, porque o restart depois da primeira execução aplicou os dois valores que precisavam dele.
Uma linha com `t` é um valor que o arquivo tem e o servidor ainda não está rodando; qualquer
monitoramento que conheça esta view deveria procurar essas linhas.

## Uma edição à mão, com um erro de digitação

Agora o desvio de que as seções anteriores avisaram. Alguém de plantão, numa noite lenta, acrescenta
duas linhas ao arquivo instalado no servidor, faz um reload e volta para a cama. O `printf` faz o
papel do editor dessa pessoa:

```
ana@db:~$ printf 'work_mem = 64MB\nlog_min_duraton_statement = 250ms\n' | sudo tee -a /etc/postgresql/16/main/conf.d/50-shop.conf
work_mem = 64MB
log_min_duraton_statement = 250ms
ana@db:~$ sudo systemctl reload postgresql@16-main
ana@db:~$ sudo tail -n 4 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:31:27.769 -03 [2578] LOG:  parameter "work_mem" changed to "32MB"
2026-10-10 04:31:29.959 -03 [2578] LOG:  received SIGHUP, reloading configuration files
2026-10-10 04:31:29.960 -03 [2578] LOG:  unrecognized configuration parameter "log_min_duraton_statement" in file "/etc/postgresql/16/main/conf.d/50-shop.conf" line 10
2026-10-10 04:31:29.960 -03 [2578] LOG:  configuration file "/etc/postgresql/16/main/conf.d/50-shop.conf" contains errors; no changes were applied
```

**O `systemctl reload` não imprimiu nada e deu certo.** Ele envia um sinal, e entregar um sinal é
tudo o que ele relata; se o servidor gostou dos arquivos não é assunto dele. A resposta está no
log. A primeira linha é o reload da seção anterior. As três últimas são este: o parâmetro escrito
errado na linha 10, e depois a frase que importa — **no changes were applied**, nenhuma mudança foi
aplicada. Um arquivo com um erro é recusado inteiro, então o `work_mem = 64MB` correto da linha 9
foi recusado junto com o erro, e o servidor continuou rodando exatamente como antes.

Esse é o jeito seguro de falhar, e mesmo assim é uma armadilha. A pessoa de plantão acredita que o
`work_mem` está em 64 MB. O arquivo no servidor diz que está. Só o log e o servidor em execução
discordam.

## O que os arquivos dizem agora

O `pg_file_settings` lê os arquivos no momento em que você pergunta, então mostra as linhas tendo o
servidor aplicado ou não:

```
postgres=# SELECT sourceline, name, setting, applied, error FROM pg_file_settings WHERE sourcefile LIKE '%50-shop.conf' ORDER BY sourceline;
 sourceline |            name            | setting | applied |                error                 
------------+----------------------------+---------+---------+--------------------------------------
          3 | listen_addresses           | *       | f       | 
          4 | shared_buffers             | 1GB     | f       | 
          5 | work_mem                   | 32MB    | f       | 
          6 | maintenance_work_mem       | 256MB   | f       | 
          7 | log_min_duration_statement | 500ms   | f       | 
          8 | log_lock_waits             | on      | f       | 
          9 | work_mem                   | 64MB    | f       | 
         10 | log_min_duraton_statement  | 250ms   | f       | unrecognized configuration parameter
(8 rows)

postgres=# SHOW work_mem;
 work_mem 
----------
 32MB
(1 row)
```

`applied` é `f` nas oito linhas, porque o arquivo que as contém não foi aplicado. A linha 10 traz o
motivo. O `work_mem` agora aparece duas vezes, e mesmo com o erro corrigido a linha 9 venceria a
linha 5, e a linha 5 apareceria com `applied = f`; um parâmetro definido duas vezes no mesmo
arquivo é uma versão menor do mesmo desvio. O `SHOW work_mem` confirma o que o log disse: ainda 32
MB.

**Vale rodar uma consulta depois de todo reload**, à mão ou a partir do que vigia o servidor:

```sql
SELECT sourcefile, sourceline, name, error FROM pg_file_settings WHERE error IS NOT NULL;
```

Ela não devolve linha nenhuma quando os arquivos estão sãos, e devolve um arquivo e uma linha
quando não estão.

## O repositório vence

O arquivo instalado agora difere do arquivo do repositório, e o `diff` mostra em quanto. Rodar o
script é como ele volta ao lugar:

```
ana@db:~$ diff shop-db/conf.d/50-shop.conf /etc/postgresql/16/main/conf.d/50-shop.conf
8a9,10
> work_mem = 64MB
> log_min_duraton_statement = 250ms
ana@db:~$ sudo bash shop-db/provision.sh
wrote /etc/postgresql/16/main/conf.d/50-shop.conf
reloaded the configuration
```

E no `psql` do servidor:

```
postgres=# SELECT count(*) FROM pg_file_settings WHERE error IS NOT NULL;
 count 
-------
     0
(1 row)

postgres=# SHOW work_mem;
 work_mem 
----------
 32MB
(1 row)
```

O script viu que os arquivos eram diferentes, copiou o do repositório por cima do editado e fez o
reload, e o erro sumiu. **Sumiram também os 64 MB que a pessoa de plantão queria.** Se era o valor
certo, ele passa pelo repositório como um commit com um motivo, e a próxima execução o aplica.
Rodar o script com agenda — toda noite, ou depois de cada merge — transforma o desvio de algo
encontrado uma vez por ano em algo desfeito em um dia. Também desfaz toda correção de emergência
que nunca virou commit, e é exatamente essa pressão que faz as pessoas commitarem.
