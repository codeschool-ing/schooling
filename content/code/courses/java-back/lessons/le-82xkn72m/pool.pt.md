---
title: O pool de conexões, e como é ficar sem conexão
version: 1
---

Toda transação desta aula rodou numa conexão com o banco, e nenhuma delas abriu uma. A imagem com que
muita gente começa é a de uma conexão aberta a cada requisição e fechada depois dela. Abrir uma conexão
com o PostgreSQL significa um aperto de mão TCP, autenticação e um processo novo do lado do banco, o que
é lento perto de uma consulta que lê uma linha pela chave. Por isso a aplicação mantém um **pool**: um
conjunto de conexões abertas uma vez e emprestadas. Uma transação pega uma emprestada quando começa e a
devolve quando confirma ou desfaz.

O pool do Spring Boot é o **HikariCP**, que veio com o starter de JPA. As linhas dele na partida estão em
todo log desde a aula 9; com o nome que a seção 02 deu a ele, elas ficam assim:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar | grep -E 'hikari'
2026-10-22T19:38:24.890-03:00  INFO 491 --- [bookshop] [           main] com.zaxxer.hikari.HikariDataSource       : bookshop-pool - Starting...
2026-10-22T19:38:25.354-03:00  INFO 491 --- [bookshop] [           main] com.zaxxer.hikari.pool.HikariPool        : bookshop-pool - Added connection org.postgresql.jdbc.PgConnection@53d6e959
2026-10-22T19:38:25.355-03:00  INFO 491 --- [bookshop] [           main] com.zaxxer.hikari.HikariDataSource       : bookshop-pool - Start completed.
```

## As três linhas

A seção 02 acrescentou três propriedades ao `application.properties`:

```properties
spring.datasource.hikari.pool-name=bookshop-pool
spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.connection-timeout=5000
```

`pool-name` é só um rótulo, para que uma linha de log diga de qual pool está falando.
**`maximum-pool-size` é o máximo de conexões que o pool vai ter**: 10 também é o padrão do HikariCP, e a
linha está ali para que o número fique escrito onde alguém o veja. **`connection-timeout` é quanto
tempo, em milissegundos, uma requisição espera por uma conexão livre antes de desistir**. O padrão do
HikariCP é 30 segundos, e 30 segundos é mais do que alguém espera por uma página, então a livraria
desiste depois de 5.

## Ficando sem conexão

Uma transação segura a sua conexão da primeira instrução até o commit, inclusive o tempo que passa
esperando uma trava. Isso torna fácil esgotar o pool. Reinicie a aplicação no segundo terminal com um
pool de duas conexões, sobrescrevendo a propriedade pela linha de comando:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.datasource.hikari.maximum-pool-size=2 | grep -E 'hikari'
2026-10-22T19:39:27.054-03:00  INFO 2764 --- [bookshop] [           main] com.zaxxer.hikari.HikariDataSource       : bookshop-pool - Starting...
2026-10-22T19:39:27.753-03:00  INFO 2764 --- [bookshop] [           main] com.zaxxer.hikari.pool.HikariPool        : bookshop-pool - Added connection org.postgresql.jdbc.PgConnection@11e9ac24
2026-10-22T19:39:27.754-03:00  INFO 2764 --- [bookshop] [           main] com.zaxxer.hikari.HikariDataSource       : bookshop-pool - Start completed.
```

Num terceiro terminal, o `psql` trava a linha de The Time Machine por oito segundos, como faria uma
transação que chamou algo lento: `BEGIN`, uma leitura com trava, `pg_sleep(8)` e só então `COMMIT`. No
primeiro terminal, enquanto isso roda, três clientes pedem The Time Machine ao mesmo tempo:

```
ana@vm:~/bookshop$ for c in ana bia cris; do curl -s -o /dev/null -w "$c %{http_code} %{time_total}s\n" -H "Content-Type: application/json" -d "{\"customer\":\"$c\",\"lines\":[{\"bookId\":2,\"quantity\":1}]}" localhost:8080/orders & done; wait
bia 500 5.260944s
ana 201 7.127874s
cris 201 7.131366s
```

```
ana@vm:~$ psql postgresql://bookshop:bookshop@localhost/bookshop -c 'BEGIN' -c 'SELECT title, stock FROM book WHERE id = 2 FOR UPDATE' -c 'SELECT pg_sleep(8)' -c 'COMMIT'
BEGIN
      title       | stock 
------------------+-------
 The Time Machine |     3
(1 row)

 pg_sleep 
----------
 
(1 row)

COMMIT
```

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.datasource.hikari.maximum-pool-size=2 | grep -E 'Connection is not available'
2026-10-22T19:39:39.420-03:00  WARN 2764 --- [bookshop] [nio-8080-exec-2] org.hibernate.orm.jdbc.error             : bookshop-pool - Connection is not available, request timed out after 5005ms (total=2, active=2, idle=0, waiting=0)
java.sql.SQLTransientConnectionException: bookshop-pool - Connection is not available, request timed out after 5005ms (total=2, active=2, idle=0, waiting=0)
```

Leia as três respostas contra o pool. Duas das requisições, aqui as de ana e de cris, pegaram uma
conexão cada e ficaram paradas em `findByIdForUpdate`, esperando o `psql` soltar a linha: terminaram
quando os oito segundos acabaram, uns 7 segundos depois de enviadas, e fizeram os seus pedidos. A
terceira, a de bia, encontrou as duas conexões emprestadas, esperou por uma durante 5 segundos e falhou. A mensagem do HikariCP conta o pool naquele instante: duas conexões no total,
as duas ativas, nenhuma ociosa. Essa falha não tem tratamento próprio, então volta como um `500`, com o
detalhe guardado no log do servidor.

Reinicie a aplicação sem a sobrescrita antes de continuar.

## De que tamanho é um pool

A resposta tentadora é maior. Raramente ajuda, porque o pool não é onde o trabalho acontece. O
PostgreSQL roda cada conexão como um processo, e um banco com mais consultas ativas do que núcleos de CPU
passa o tempo alternando entre elas. O banco também tem o seu próprio teto, `max_connections`, que a
saída da seção 05 mostrou em 100, dividido entre todas as instâncias da aplicação e todos os outros
clientes. Três cópias da livraria com 10 cada seguram 30 deles.

A documentação do HikariCP sugere começar pelo número de núcleos do servidor do banco vezes dois, mais o
número de discos, e medir a partir daí. O que os números da livraria dizem é a parte útil: um pool que
se esgota costuma ser sintoma de transações que duram demais, como a de cima, e a correção é encurtar as
transações, não pôr mais conexões. A aula 22 mostra como acompanhar os números do pool numa aplicação
rodando.
