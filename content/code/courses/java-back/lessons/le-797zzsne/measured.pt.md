---
title: Início e tamanho, medidos
version: 1
---

Dois números são baratos de medir, e são os que as pessoas citam quando comparam frameworks: o tamanho
do jar e quanto tempo a aplicação leva para iniciar. Os dois valem a pena, e os dois têm um jeito errado
de serem lidos. Esta seção os mede para o `javalin-hello` e para o bookshop como a aula 7 o deixou, na
mesma máquina.

Faça o build do bookshop, liste os dois jars e conte as bibliotecas empacotadas dentro do jar do bookshop:

```
ana@vm:~/bookshop$ mvn -B -q package
ana@vm:~/bookshop$ ls -l target/bookshop-0.1.0.jar ~/javalin-hello/target/javalin-hello-0.1.0.jar
-rw-r--r-- 1 ana ana  9534256 Oct 22 19:20 /home/ana/javalin-hello/target/javalin-hello-0.1.0.jar
-rw-r--r-- 1 ana ana 21580405 Oct 22 19:20 target/bookshop-0.1.0.jar
```

```
ana@vm:~/bookshop$ unzip -l target/bookshop-0.1.0.jar | grep -c "BOOT-INF/lib/.*\.jar$"
39
```

O jar do bookshop tem 21,6 MB contra 9,5 MB do Javalin, e a contagem diz onde mora a
diferença: 39 bibliotecas em `BOOT-INF/lib`, o Tomcat, o Spring, o Jackson, o Hibernate
Validator e o que cada um deles precisa. Para um serviço publicado como imagem de contêiner, alguns
megabytes raramente são o problema; o que essas bibliotecas fazem quando a aplicação inicia é.

**Cada framework imprime o próprio tempo de início, e os dois não podem ser comparados.** O `started in`
do Javalin e o `Started BookshopApplication in` do Spring disparam o cronômetro num momento que o
framework escolhe, e nenhum dos dois conta o início da própria JVM antes dele; o Spring acrescenta o
`process running for`, que conta. Então meça de fora, como mediria um usuário esperando a primeira requisição: do momento em
que o `java -jar` é lançado até a primeira resposta. Salve isto como `~/first-answer.sh`:

```sh
#!/usr/bin/env bash
# Start a jar, print how long it takes to answer its first request, and the
# line in which the framework reports its own startup time.
jar=$1
url=$2
log=$(mktemp)
java -jar "$jar" > "$log" 2>&1 &
pid=$!
start=$(date +%s%N)
until curl -s -o /dev/null "$url"; do
    sleep 0.02
done
echo "first answer after $(( ($(date +%s%N) - start) / 1000000 )) ms"
grep -E 'Javalin started in|Started [A-Za-z]+ in' "$log"
kill "$pid"
wait "$pid" 2> /dev/null
rm -f "$log"
```

Ele inicia o jar em segundo plano, guarda o log num arquivo temporário e pede a URL a cada 20
milissegundos até que algo responda. O `curl` sai com 0 para qualquer resposta HTTP, mesmo um erro, e
só falha enquanto nada está escutando, que é justamente o momento medido. Depois ele imprime a linha do
próprio framework ao lado do número medido de fora, para o processo pelo pid e apaga o log. Cada laço
`for` inicia a aplicação três vezes, porque um início só não é uma medida:

```
ana@vm:~$ for i in 1 2 3; do bash first-answer.sh javalin-hello/target/javalin-hello-0.1.0.jar localhost:7070/books; done
first answer after 4877 ms
[main] INFO io.javalin.Javalin - Javalin started in 2660ms \o/
first answer after 3270 ms
[main] INFO io.javalin.Javalin - Javalin started in 1398ms \o/
first answer after 2752 ms
[main] INFO io.javalin.Javalin - Javalin started in 2054ms \o/
ana@vm:~$ for i in 1 2 3; do bash first-answer.sh bookshop/target/bookshop-0.1.0.jar localhost:8080/books; done
first answer after 8944 ms
2026-10-22T19:20:56.233-03:00  INFO 26069 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 7.065 seconds (process running for 8.64)
first answer after 11704 ms
2026-10-22T19:21:08.196-03:00  INFO 26477 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 9.287 seconds (process running for 11.413)
first answer after 11474 ms
2026-10-22T19:21:19.841-03:00  INFO 26784 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 9.082 seconds (process running for 11.234)
```

Leia as primeiras respostas, não os relatos dos frameworks: 2752 a 4877 ms para o Javalin, 8944 a 11704
ms para o bookshop. Em média o bookshop levou cerca de 2,9 vezes o tempo do Javalin para
responder, e as linhas no meio mostram por que os relatos enganam: na primeira execução, o próprio
`Started ... in` do Spring diz 7,065 segundos para um início pelo qual um cliente esperou
8944 ms. As execuções também discordam entre si, em 2125 ms entre a mais rápida e a
mais lenta do Javalin e 2760 ms entre as do bookshop, e é por isso que uma execução só não
prova nada.

O que os números **não** dizem importa tanto quanto:

- **Nada sobre velocidade depois de rodando.** O início é pago uma vez por processo. Um serviço que
  inicia e depois responde por uma semana paga esses segundos uma vez naquela semana; quão rápido ele responde
  a cada requisição é outra medida, e a aula 20 faz uma com o JMeter.
- **Nada sobre o bookshop da aula 23.** Este bookshop não tem banco, segurança nem métricas, e cada uma
  dessas coisas acrescenta trabalho no início; um Javalin com as mesmas funções também seria maior e
  mais lento para iniciar que o `javalin-hello`.
- **Nada além desta máquina.** Quatro núcleos divididos com o que mais estivesse rodando, o cache de
  disco quente, três execuções de cada. Uma máquina mais ocupada ou um contêiner com uma fração de núcleo
  estica todos os números, mais os do Spring, porque é ele que faz mais trabalho no início.

Então quando a diferença vale uma ação? Quando os inícios são frequentes e alguém espera por cada um:
funções, serviços que escalam a partir de zero, jobs de vida curta. Ali, o Quarkus ou o Micronaut
mantêm a maior parte das conveniências do Spring e tiram o trabalho do início, e o Javalin o elimina
abrindo mão delas. Em todo o resto, que é a maioria dos serviços de back-end, os segundos são pagos na
hora de publicar, e o ecossistema do Spring é aquilo em que o resto deste curso os gasta: acesso a dados
a partir da aula 9, migrações, transações, segurança, logs, documentação, testes e métricas, a maioria
deles um starter que se configura sozinho. Da aula 9 em diante, o curso volta ao `~/bookshop`.
