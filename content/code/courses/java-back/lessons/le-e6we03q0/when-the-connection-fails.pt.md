---
title: Quando a conexão falha
version: 1
---

Todo jeito de uma conexão falhar imprime uma frase dizendo qual, e a frase está sempre no mesmo
lugar. O difícil é achá-la. Com a senha trocada na linha de comando, do jeito que a aula 4 sobrepõe
uma propriedade, a livraria se recusa a subir e escreve isto tudo:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.datasource.password=wrong 2>&1 | wc -l
140
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.datasource.password=wrong 2>&1 | grep -E "ERROR|Caused by" | cut -c1-110
2026-10-22T19:16:10.152-03:00 ERROR 15645 --- [bookshop] [           main] o.s.boot.SpringApplication         
Caused by: org.springframework.beans.factory.UnsatisfiedDependencyException: Error creating bean with name 'bo
Caused by: org.springframework.beans.factory.UnsatisfiedDependencyException: Error creating bean with name 'jd
Caused by: org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'jdbcClient'
Caused by: org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'dataSourceS
Caused by: org.springframework.jdbc.datasource.init.UncategorizedScriptException: Failed to execute database s
Caused by: org.springframework.jdbc.CannotGetJdbcConnectionException: Failed to obtain JDBC Connection
Caused by: org.postgresql.util.PSQLException: FATAL: password authentication failed for user "bookshop"
```

Cento e quarenta linhas, e o `cut` guardou só os primeiros 110 caracteres das que o `grep` separou.
Cada `Caused by` é uma camada explicando a camada de cima: um bean não pôde ser criado porque a
dependência dele não pôde, porque o script não pôde rodar, porque não se conseguiu uma conexão.
**O último `Caused by` é o motivo; tudo acima dele é o caminho que a falha percorreu.** Ele é
sempre a exceção do próprio driver, `org.postgresql.util.PSQLException`, e o resto desta seção
procura direto por ela. Cada caso quebra uma linha do `application.properties` pela linha de
comando.

## Ninguém escutando

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.datasource.url=jdbc:postgresql://localhost:5433/bookshop 2>&1 | grep "Caused by: org.postgresql"
Caused by: org.postgresql.util.PSQLException: Connection to localhost:5433 refused. Check that the hostname and port are correct and that the postmaster is accepting TCP/IP connections.
```

`refused` quer dizer que a máquina naquele endereço respondeu, e nada escutava naquela porta. Aqui é
a porta errada, 5433. A mesma mensagem aparece quando a porta está certa e o servidor não está
rodando, então pergunte ao servidor:

```sh
pg_lsclusters
```

Se a coluna de status disser `down` em vez de `online`, suba-o com
`sudo pg_ctlcluster 16 main start`, e se ele não subir, o motivo está no arquivo de log da última
coluna. Uma máquina virtual desligada em vez de encerrada, e um disco cheio, terminam os dois aqui.

## A senha, e o papel que não existe

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.datasource.password=wrong 2>&1 | grep "Caused by: org.postgresql"
Caused by: org.postgresql.util.PSQLException: FATAL: password authentication failed for user "bookshop"
```

A senha está errada, e a mensagem diz isso. A próxima parece igual e é outro problema:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.datasource.username=bookshp 2>&1 | grep "Caused by: org.postgresql"
Caused by: org.postgresql.util.PSQLException: FATAL: password authentication failed for user "bookshp"
```

O papel está escrito errado, `bookshp`, e o servidor **continua dizendo que a senha falhou**. É de
propósito. Se um nome de usuário errado desse uma resposta diferente de uma senha errada, qualquer
um que alcance a porta descobriria quais nomes de papel existem, um palpite por vez. Então o cliente
só fica sabendo que não entrou, e o motivo verdadeiro vai para o log do servidor, que só um
administrador lê:

```
ana@vm:~/bookshop$ sudo grep bookshp /var/log/postgresql/postgresql-16-main.log | tail -n 3
2026-10-22 22:16:00.354 UTC [15519] bookshp@bookshop FATAL:  password authentication failed for user "bookshp"
2026-10-22 22:16:00.354 UTC [15519] bookshp@bookshop DETAIL:  Role "bookshp" does not exist.
2026-10-22 22:16:03.277 UTC [15570] bookshop@bookshp FATAL:  database "bookshp" does not exist
```

`DETAIL:  Role "bookshp" does not exist.` é a linha que o cliente nunca viu. Quando a senha está
certamente correta e o servidor continua a recusando, leia este log antes de redefinir qualquer
coisa.

## Logado, em lugar nenhum

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.datasource.url=jdbc:postgresql://localhost:5432/bookshp 2>&1 | grep "Caused by: org.postgresql"
Caused by: org.postgresql.util.PSQLException: FATAL: database "bookshp" does not exist
```

Esta foi mais longe. O login deu certo, então usuário e senha estão corretos, e o banco nomeado no
fim da URL não existe. Confira a grafia em `spring.datasource.url`, e se estiver certa, o passo do
`createdb` foi pulado ou rodado em outra máquina.

## Todas de uma vez

| o que diz | o que quer dizer | onde olhar |
|---|---|---|
| `No suitable driver found` | nenhum driver no class path aceita a URL | o class path, ou o prefixo `jdbc:postgresql:` |
| `Connection to … refused` | nada escuta naquele host e porta | a porta na URL, depois `pg_lsclusters` |
| `password authentication failed` | a senha está errada, ou o papel não existe | o log do servidor, que diz qual |
| `database "…" does not exist` | o login funcionou; falta o banco | a última parte da URL, depois `createdb` |
| `Peer authentication failed` | o `psql` entrou pelo socket como outra pessoa | conecte em `localhost` |
| `role "…" does not exist` | um login pelo socket com um papel que o servidor não tem | crie o papel, ou nomeie o certo |

As duas últimas vêm do `psql` pelo socket, e a aplicação nunca as encontra, porque o JDBC sempre se
conecta por TCP. A aula 14 acrescenta a falha que esta tabela não tem: um servidor que está lá e um
pool com todas as conexões já emprestadas.
