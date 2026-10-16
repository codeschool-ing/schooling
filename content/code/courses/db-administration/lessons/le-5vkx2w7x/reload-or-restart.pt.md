---
title: Reload ou restart
version: 1
---

Salvar um arquivo não muda nada. O servidor lê a configuração quando sobe e quando mandam que leia
de novo, e esses são os dois jeitos de aplicar uma mudança: **um reload, a que toda conexão
sobrevive, e um restart, a que nenhuma sobrevive**. A coluna `context` da seção anterior diz de
qual o parâmetro precisa, e errar em qualquer das direções é um jeito comum de perder uma hora.

## Um arquivo no conf.d

Crie este arquivo com `sudo nano /etc/postgresql/16/main/conf.d/50-course.conf`. Ele pede duas
mudanças, uma de cada tipo. A primeira registra todo comando mais lento que um quarto de segundo,
um parâmetro `sighup` de que trata a lição 19. A segunda dobra o `shared_buffers`, um `postmaster`
de que trata a lição 6:

```ini
# /etc/postgresql/16/main/conf.d/50-course.conf
log_min_duration_statement = 250ms
shared_buffers = 256MB
```

Depois dê reload e leia o que o servidor disse:

```
ana@db:~$ cat /etc/postgresql/16/main/conf.d/50-course.conf
# /etc/postgresql/16/main/conf.d/50-course.conf
log_min_duration_statement = 250ms
shared_buffers = 256MB
ana@db:~$ sudo systemctl reload postgresql
ana@db:~$ sudo tail -n 4 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:41:48.064 -03 [101] LOG:  received SIGHUP, reloading configuration files
2026-10-10 04:41:48.065 -03 [101] LOG:  parameter "log_min_duration_statement" changed to "250ms"
2026-10-10 04:41:48.065 -03 [101] LOG:  parameter "shared_buffers" cannot be changed without restarting the server
2026-10-10 04:41:48.065 -03 [101] LOG:  configuration file "/etc/postgresql/16/main/conf.d/50-course.conf" contains errors; unaffected changes were applied
```

Um reload é um sinal, `SIGHUP`, mandado ao postmaster, que relê todos os arquivos e repassa os
novos valores a todos os processos em execução. O `systemctl reload postgresql` o manda; o
`SELECT pg_reload_conf();` no `psql` de um superusuário também, e o `sudo pg_ctlcluster 16 main
reload` também. Os três fazem a mesma coisa.

O log informa cada parâmetro. **O `log_min_duration_statement` mudou na hora**, para todas as
conexões, inclusive as que já estavam abertas. O `shared_buffers` não mudou, e a última linha
chama isso de erro, o que não é: o arquivo está certo e um valor dele está esperando. Leia as
linhas acima da palavra `errors` antes de acreditar nela.

O servidor guarda o mesmo fato no `pg_settings`. Olhe lá numa máquina cujo log você não vinha
lendo:

```
ana@db:~$ psql
ana=# SELECT name, setting, unit, pending_restart
ana-#   FROM pg_settings
ana-#  WHERE name IN ('shared_buffers', 'log_min_duration_statement');
            name            | setting | unit | pending_restart 
----------------------------+---------+------+-----------------
 log_min_duration_statement | 250     | ms   | f
 shared_buffers             | 16384   | 8kB  | t
(2 rows)

ana=# \q
ana@db:~$ sudo systemctl restart postgresql
ana@db:~$ psql
ana=# SELECT name, setting, unit, pending_restart
ana-#   FROM pg_settings
ana-#  WHERE name IN ('shared_buffers', 'log_min_duration_statement');
            name            | setting | unit | pending_restart 
----------------------------+---------+------+-----------------
 log_min_duration_statement | 250     | ms   | f
 shared_buffers             | 32768   | 8kB  | f
(2 rows)

ana=# \q
```

**`pending_restart` é verdadeiro para um valor que os arquivos pedem e o servidor ainda não usa.**
Depois do restart, o `shared_buffers` é 32768 páginas de 8 kB, os 256 MB que o arquivo pediu, e
nada está pendente. Vale rodar `SELECT name FROM pg_settings WHERE pending_restart;` em todo
servidor que você herdar: uma linha ali é uma mudança que alguém fez e não terminou, e o próximo
restart, talvez numa hora ruim, vai aplicá-la.

## O que um restart custa

Um restart para o servidor e o sobe de novo. **Toda conexão é cortada**, e toda transação em
andamento é desfeita; as aplicações veem um erro e precisam reconectar. A memória compartilhada é
liberada e alocada de novo, então tudo que o servidor tinha em cache nela se perde, e as primeiras
consultas depois disso leem do disco. Num servidor movimentado isso é um evento agendado, com
aviso para quem o usa, e é por isso que os parâmetros `postmaster` são os que se deve acertar
antes de o servidor receber tráfego.

## Quando o arquivo está errado

Cometa de propósito um erro de digitação, daqueles que todo mundo comete uma vez: uma unidade em
minúsculas.

```
ana@db:~$ echo 'work_mem = 64mb' | sudo tee -a /etc/postgresql/16/main/conf.d/50-course.conf
work_mem = 64mb
ana@db:~$ sudo systemctl reload postgresql
ana@db:~$ sudo tail -n 4 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:41:55.113 -03 [247] LOG:  received SIGHUP, reloading configuration files
2026-10-10 04:41:55.114 -03 [247] LOG:  invalid value for parameter "work_mem": "64mb"
2026-10-10 04:41:55.114 -03 [247] HINT:  Valid units for this parameter are "B", "kB", "MB", "GB", and "TB".
2026-10-10 04:41:55.114 -03 [247] LOG:  configuration file "/etc/postgresql/16/main/conf.d/50-course.conf" contains errors; unaffected changes were applied
ana@db:~$ psql
ana=# SHOW work_mem;
 work_mem 
----------
 4MB
(1 row)

ana=# SELECT sourcefile, sourceline, name, setting, error
ana-#   FROM pg_file_settings
ana-#  WHERE error IS NOT NULL;
                  sourcefile                   | sourceline |   name   | setting |            error             
-----------------------------------------------+------------+----------+---------+------------------------------
 /etc/postgresql/16/main/conf.d/50-course.conf |          4 | work_mem | 64mb    | setting could not be applied
(1 row)

ana=# \q
```

Um reload com um valor ruim é inofensivo: **o servidor em execução fica com o valor que tinha** e
diz isso no log. O `systemctl reload` em si não imprimiu nada e deu certo, então os únicos lugares
em que o erro aparece são o log e o `pg_file_settings`, uma view que lê os arquivos como estão no
disco agora, linha por linha, com uma coluna `error`.

Um restart com o mesmo arquivo não é inofensivo. O servidor lê o arquivo na partida, encontra a
linha ruim e se recusa a subir, e uma mudança rápida virou uma queda. Na máquina de gravação, o
`sudo systemctl restart postgresql` com esse arquivo no lugar não voltou. A unidade que o Ubuntu
traz espera sem limite de tempo por um servidor que não vem, e o motivo estava no log: as mesmas
linhas de cima, com `FATAL` no lugar do último `LOG`.

Então **confira os arquivos antes de um restart**. O binário do servidor consegue ler a
configuração e imprimir um parâmetro sem subir nada, e lê todos os arquivos para isso:

```
ana@db:~$ sudo -u postgres /usr/lib/postgresql/16/bin/postgres -C work_mem -c config_file=/etc/postgresql/16/main/postgresql.conf
2026-10-10 04:41:57.969 -03 [302] LOG:  invalid value for parameter "work_mem": "64mb"
2026-10-10 04:41:57.969 -03 [302] HINT:  Valid units for this parameter are "B", "kB", "MB", "GB", and "TB".
2026-10-10 04:41:57.969 -03 [302] FATAL:  configuration file "/etc/postgresql/16/main/conf.d/50-course.conf" contains errors
ana@db:~$ sudo sed -i '/^work_mem/d' /etc/postgresql/16/main/conf.d/50-course.conf
ana@db:~$ sudo -u postgres /usr/lib/postgresql/16/bin/postgres -C work_mem -c config_file=/etc/postgresql/16/main/postgresql.conf
4096
```

O `FATAL` é a linha em que um restart teria morrido, impressa enquanto o servidor de verdade
continuava rodando. O `sed -i '/^work_mem/d'` apagou a linha ruim, e a segunda execução imprimiu o
valor que os arquivos dão agora, `4096` em kilobytes, o padrão. Use isso, ou a consulta ao
`pg_file_settings`, toda vez que um restart vier depois de uma edição.
