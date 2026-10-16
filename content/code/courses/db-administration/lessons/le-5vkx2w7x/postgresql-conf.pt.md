---
title: O arquivo, e o diretório ao lado dele
version: 1
---

A configuração de um servidor PostgreSQL é **um arquivo de parâmetros, lido de cima para baixo,
em que vale o último valor dado para um nome**. Todo o resto desta lição sai dessa frase: o
diretório de arquivos extras, o arquivo que o `ALTER SYSTEM` escreve, e o motivo de uma mudança
sua poder ser anulada em silêncio por outra mais abaixo.

A lição 3 perguntou ao servidor onde fica o arquivo. Pergunte sempre: no Ubuntu ele não fica
dentro do diretório de dados, onde o projeto original o guarda.

```
ana@db:~$ psql
ana=# SHOW config_file;
               config_file               
-----------------------------------------
 /etc/postgresql/16/main/postgresql.conf
(1 row)

ana=# SHOW hba_file;
              hba_file               
-------------------------------------
 /etc/postgresql/16/main/pg_hba.conf
(1 row)

ana=# SHOW work_mem;
 work_mem 
----------
 4MB
(1 row)

ana=# \q
```

`hba_file` é a outra metade da configuração, a que decide quem pode conectar, e ela tem uma seção
própria nesta lição. O `work_mem` está aqui por um motivo que aparece daqui a pouco.

## Quase tudo comentário

O arquivo parece muita coisa para ler. Não é:

```
ana@db:~$ wc -l /etc/postgresql/16/main/postgresql.conf
828 /etc/postgresql/16/main/postgresql.conf
ana@db:~$ grep -Ev '^\s*(#|$)' /etc/postgresql/16/main/postgresql.conf
data_directory = '/var/lib/postgresql/16/main'		# use data in another directory
hba_file = '/etc/postgresql/16/main/pg_hba.conf'	# host-based authentication file
ident_file = '/etc/postgresql/16/main/pg_ident.conf'	# ident configuration file
external_pid_file = '/var/run/postgresql/16-main.pid'			# write an extra PID file
port = 5432				# (change requires restart)
max_connections = 100			# (change requires restart)
unix_socket_directories = '/var/run/postgresql' # comma-separated list of directories
ssl = on
ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key'
shared_buffers = 128MB			# min 128kB
dynamic_shared_memory_type = posix	# the default is usually the first option
max_wal_size = 1GB
min_wal_size = 80MB
log_line_prefix = '%m [%p] %q%u@%d '		# special values:
log_timezone = 'America/Sao_Paulo'
cluster_name = '16/main'			# added to process titles if nonempty
datestyle = 'iso, mdy'
timezone = 'America/Sao_Paulo'
lc_messages = 'C.UTF-8'			# locale for system error message
lc_monetary = 'C.UTF-8'			# locale for monetary formatting
lc_numeric = 'C.UTF-8'			# locale for number formatting
lc_time = 'C.UTF-8'			# locale for time formatting
default_text_search_config = 'pg_catalog.english'
include_dir = 'conf.d'			# include files ending in '.conf' from
```

De 828 linhas, **25 estão ativas**, e a última delas é uma diretiva, não uma configuração. O
`grep -Ev` imprimiu toda linha que não está em branco nem é comentário, e o que sobra é o que o
instalador decidiu: os caminhos, a porta, a localidade e o fuso horário que encontrou na máquina,
um certificado para que o `ssl = on` tenha o que usar, e um prefixo de log. Todos os outros
parâmetros têm o valor compilado no servidor, e é por isso que o `work_mem` disse `4MB` acima e
não aparece em lugar nenhum desta lista.

Os comentários são a documentação dos padrões. Um parâmetro aparece comentado com o valor padrão
ao lado, e os que precisam de restart avisam:

```
ana@db:~$ sed -n 129,135p /etc/postgresql/16/main/postgresql.conf

shared_buffers = 128MB			# min 128kB
					# (change requires restart)
#huge_pages = try			# on, off, or try
					# (change requires restart)
#huge_page_size = 0			# zero for system default
					# (change requires restart)
```

Isso dá vontade de tratar as linhas comentadas como interruptores. **Pôr o `#` de volta na frente
de uma linha não restaura o padrão** até o servidor ler o arquivo de novo, e mesmo então só porque
a linha sumiu, não pelo que o comentário diz. O cabeçalho do arquivo avisa exatamente isso.

## O formato

Cada configuração é `nome = valor`, uma por linha, e o resto da linha depois de um `#` é
comentário. Três detalhes pegam as pessoas:

- **Unidades diferenciam maiúsculas.** `128MB` é 128 megabytes; `128mb` é erro. As unidades de
  memória são `B`, `kB`, `MB`, `GB` e `TB`, as de tempo `us`, `ms`, `s`, `min`, `h` e `d`, e o
  cabeçalho do arquivo as lista.
- **Texto vai entre aspas simples**, como os caminhos acima. Uma palavra solta funciona para
  valores simples como `on`, e pôr aspas em tudo que não é número é o hábito que nunca falha.
- **Um nome pode aparecer duas vezes, e vence o de baixo.** Nada avisa. Isso é um risco num
  arquivo de 828 linhas e a base do arranjo abaixo.

## conf.d: o lugar das suas mudanças

A última linha ativa é a que mais importa:

```ini
include_dir = 'conf.d'
```

Ela manda o servidor ler, depois deste arquivo, **todo arquivo terminado em `.conf` no diretório
`/etc/postgresql/16/main/conf.d`, na ordem dos nomes**. Como vêm depois, o que eles definem
sobrepõe o arquivo principal. Num servidor novo, o diretório está vazio:

```
ana@db:~$ ls -l /etc/postgresql/16/main/conf.d
total 0
```

Então há dois lugares para mudar um parâmetro, e este curso usa o segundo. Você poderia editar o
`postgresql.conf` no lugar, no meio de 800 linhas de comentários. Ou pode deixá-lo como o
instalador escreveu e **pôr suas mudanças em arquivos pequenos dentro do `conf.d`**, com nomes que
deixem a ordem óbvia: `10-memory.conf`, `20-logging.conf`, `50-course.conf`. Uma mudança vira um
arquivo que você lê inteiro, desfazê-la é apagar o arquivo, e a lição 23 põe esses arquivos sob
controle de versão. O arquivo principal fica como registro do que o pacote fez.

Edite-os com `sudo nano`, já que os arquivos pertencem ao `postgres` e o diretório não é seu. Nada
muda quando você salva: o servidor lê a configuração na partida e quando mandam, e as duas
próximas seções tratam de mandar.
