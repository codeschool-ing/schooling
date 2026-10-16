---
title: O que o servidor está usando de fato
version: 1
---

**O arquivo diz o que alguém escreveu; o servidor diz com o que está rodando**, e os dois
divergem mais do que se gostaria. Um valor num arquivo que ninguém recarregou, uma configuração
feita pelo `ALTER SYSTEM` que sobrepõe o arquivo, um parâmetro dado na linha de comando: a única
resposta confiável vem do servidor, e ela mora numa view chamada `pg_settings`.

O `SHOW` dá um valor, formatado para uma pessoa. O `pg_settings` dá uma linha por parâmetro, com
a origem do valor e o que é preciso para mudá-lo:

```
ana@db:~$ psql
ana=# SELECT name, setting, unit, source, sourceline, context
ana-#   FROM pg_settings
ana-#  WHERE name IN ('shared_buffers', 'work_mem', 'max_connections',
ana(#                 'log_min_duration_statement', 'data_directory');
            name            |           setting           | unit |       source       | sourceline |  context   
----------------------------+-----------------------------+------+--------------------+------------+------------
 data_directory             | /var/lib/postgresql/16/main |      | override           |            | postmaster
 log_min_duration_statement | -1                          | ms   | default            |            | superuser
 max_connections            | 100                         |      | configuration file |         65 | postmaster
 shared_buffers             | 16384                       | 8kB  | configuration file |        130 | postmaster
 work_mem                   | 4096                        | kB   | default            |            | user
(5 rows)

ana=# SHOW shared_buffers;
 shared_buffers 
----------------
 128MB
(1 row)

ana=# SELECT count(*) FROM pg_settings;
 count 
-------
   364
(1 row)

ana=# SELECT context, count(*) FROM pg_settings GROUP BY context ORDER BY count(*) DESC;
      context      | count 
-------------------+-------
 user              |   142
 sighup            |    95
 postmaster        |    57
 superuser         |    46
 internal          |    18
 superuser-backend |     4
 backend           |     2
(7 rows)

ana=# \q
```

Três colunas carregam quase tudo de que um administrador precisa.

## setting e unit

**`setting` é um número na unidade do próprio parâmetro**, e `unit` diz que unidade é essa. O
`shared_buffers` é `16384` em unidades de `8kB`, ou seja, 128 MB, a mesma coisa que o `SHOW`
imprimiu de um jeito mais amigável. O `work_mem` é contado em kilobytes e o
`log_min_duration_statement` em milissegundos, onde `-1` quer dizer desligado. Uma consulta que
compara ou soma configurações precisa multiplicar pela unidade antes; uma pessoa lendo um valor
pode usar o `SHOW`.

Os 8 kB não são arbitrários. São o tamanho de uma página, o bloco de que toda tabela e todo índice
são feitos, e a lição 9 os coloca ao lado dos blocos do próprio sistema de arquivos.

## source

De onde o valor veio. `default` quer dizer que ninguém o definiu e vale o valor compilado.
`configuration file` quer dizer que um arquivo definiu, e para esses `sourcefile` e `sourceline`
dizem qual arquivo e qual linha: o `shared_buffers` é a linha 130 do `postgresql.conf`, a linha
que o `sed` imprimiu na seção anterior. `override` quer dizer que o próprio servidor o definiu a
partir de como foi iniciado. A linha de comando `postgres -D …` na saída do `ps` da lição 3 é de
onde o `data_directory` vem de verdade, e a cópia no arquivo é uma anotação para pessoas.

As próximas seções encontram mais três: `database` e `user` para um valor preso a um banco ou a
um papel, e `session` para um que a conexão definiu para si mesma.

## context

**`context` responde à pergunta que sempre vem em seguida: o que é preciso para mudar isto?** São
364 parâmetros e sete respostas:

| context | quantos aqui | um novo valor passa a valer |
|---|---|---|
| `internal` | 18 | nunca; fixado quando o servidor foi compilado ou o cluster criado |
| `postmaster` | 57 | no próximo **restart** |
| `sighup` | 95 | no próximo **reload** da configuração |
| `superuser-backend`, `backend` | 4 e 2 | para conexões abertas depois de um reload |
| `superuser` | 46 | na hora, para a sessão que um superusuário muda com `SET` |
| `user` | 142 | na hora, para a sessão que qualquer um muda com `SET` |

O `shared_buffers` e o `max_connections` são `postmaster`: o servidor dimensiona a memória
compartilhada a partir deles quando sobe e não consegue redimensioná-la rodando. O `work_mem` é
`user`: toda conexão pode definir o seu, e a lição 6 trata de por que isso é útil e perigoso ao
mesmo tempo. O comentário `(change requires restart)` no arquivo é a mesma informação que
`postmaster` aqui, e a view é a que não tem como ficar desatualizada.

O `pg_settings` tem mais colunas do que a consulta pediu. `boot_val` é o padrão compilado,
`reset_val` é aquilo a que a sessão volta depois de um `RESET`, e `pending_restart` é o assunto da
próxima seção.
