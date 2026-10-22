---
title: Uma classe, um jar, um servidor no ar
version: 1
---

Uma aplicação Spring Boot precisa de uma classe sua antes de poder subir, e a da livraria tem três
linhas que fazem alguma coisa. Crie
`src/main/java/com/example/bookshop/BookshopApplication.java`:

```schooling-example
{
  "language": "java",
  "file": "src/main/java/com/example/bookshop/BookshopApplication.java",
  "parts": [
    {
      "code": "package com.example.bookshop;\n\nimport org.springframework.boot.SpringApplication;\nimport org.springframework.boot.autoconfigure.SpringBootApplication;\n",
      "note": "**O pacote é onde o Spring começa a procurar.** A varredura de componentes começa no pacote desta classe e desce, então uma classe em `com.example.bookshop.catalogue`, que a aula 5 acrescenta, é encontrada, e uma classe em `com.example.reports` não seria."
    },
    {
      "code": "@SpringBootApplication\npublic class BookshopApplication {\n",
      "note": "**`@SpringBootApplication` são três anotações numa só**, lidas na classe compilada logo abaixo. A classe não tem corpo: nada nela é fiação escrita à mão."
    },
    {
      "code": "    public static void main(String[] args) {\n        SpringApplication.run(BookshopApplication.class, args);\n    }\n}",
      "note": "**`SpringApplication.run` monta a aplicação e a inicia.** Ele lê as propriedades, decide qual autoconfiguração se aplica, cria os beans e, como há um servidor web no classpath, o sobe. O `args` é repassado, e é assim que `--debug` ou `--server.port=9091` na linha de comando chegam ao Spring mais adiante nesta aula."
    }
  ]
}
```

Uma anotação em Java é um tipo de interface, então as anotações dela estão na classe compilada,
e o `javap` as lê do jar que o Maven baixou. O `sed` guarda a lista da classe, e o `grep` guarda um
nome por entrada:

```
ana@vm:~/bookshop$ javap -v -cp ~/.m2/repository/org/springframework/boot/spring-boot-autoconfigure/4.1.1/spring-boot-autoconfigure-4.1.1.jar org.springframework.boot.autoconfigure.SpringBootApplication | sed -n '/^RuntimeVisibleAnnotations:/,/^InnerClasses:/p' | grep -E '^    [a-z]'
    java.lang.annotation.Target(
    java.lang.annotation.Retention(
    java.lang.annotation.Documented
    java.lang.annotation.Inherited
    org.springframework.boot.SpringBootConfiguration
    org.springframework.boot.autoconfigure.EnableAutoConfiguration
    org.springframework.context.annotation.ComponentScan(
```

Sete. As quatro primeiras são o que qualquer anotação diz sobre si mesma: onde pode ser posta,
que é mantida em tempo de execução, que aparece no Javadoc e que subclasses a herdam. As três
últimas fazem o trabalho.
**`@SpringBootConfiguration`** marca a classe como fonte de definições de beans, os objetos que o
Spring cria e conecta, que são o assunto da aula 5. **`@EnableAutoConfiguration`** liga o mecanismo
que a próxima seção abre. **`@ComponentScan`** diz ao Spring para procurar as suas classes neste
pacote e em todo pacote abaixo dele, e é por isso que a classe principal fica no topo da árvore
de pacotes, e nunca num subpacote próprio.

Mais um arquivo, `src/main/resources/application.properties`, com uma linha:

```properties
spring.application.name=bookshop
```

Ela dá nome à aplicação, e o log abaixo mostra onde esse nome aparece.

## O jar executável

Faça o build. O `-B` é o modo batch, como na aula 1, e o `tail` guarda as últimas linhas:

```
ana@vm:~/bookshop$ mvn -B package | tail -n 8
[INFO] Replacing main artifact /home/ana/bookshop/target/bookshop-0.1.0.jar with repackaged archive, adding nested dependencies in BOOT-INF/.
[INFO] The original artifact has been renamed to /home/ana/bookshop/target/bookshop-0.1.0.jar.original
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  26.136 s
[INFO] Finished at: 2026-10-22T19:10:48-03:00
[INFO] ------------------------------------------------------------------------
ana@vm:~/bookshop$ ls -l target/*.jar*
-rw-r--r-- 1 ana ana 19904573 Oct 22 19:10 target/bookshop-0.1.0.jar
-rw-r--r-- 1 ana ana     2766 Oct 22 19:10 target/bookshop-0.1.0.jar.original
ana@vm:~/bookshop$ jar tf target/bookshop-0.1.0.jar | grep -c '^BOOT-INF/lib/.*\.jar$'
34
ana@vm:~/bookshop$ jar tf target/bookshop-0.1.0.jar | grep -E '^BOOT-INF/lib/spring-boot-(starter|jarmode)'
BOOT-INF/lib/spring-boot-jarmode-tools-4.1.1.jar
```

O `spring-boot-maven-plugin:4.1.1:repackage` rodou depois de o jar comum ser montado e o
transformou num **jar executável**: as classes da livraria, todas as bibliotecas da árvore em
`BOOT-INF/lib` e um pequeno lançador que sabe carregar jars aninhados dentro de um jar. É por isso
que o arquivo tem cerca de 19 MB, enquanto o `.original`, o jar que o Maven montou primeiro, tem
só a classe e os arquivos de propriedades da livraria. A conta dá 34, contra 39 na árvore, porque os starters
não têm código e ficam de fora, e o Boot acrescenta um jar próprio, o `spring-boot-jarmode-tools`,
que a aula 23 usa. **Um arquivo, e nada mais para instalar além do Java**:
nenhum Tomcat no servidor, nenhum diretório de bibliotecas ao lado. A aula 23 o abre e o põe numa
imagem de contêiner.

## Subindo

Abra um segundo terminal para a aplicação, porque ela continua rodando. Nele:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v4.1.1)

2026-10-22T19:10:50.299-03:00  INFO 5395 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Starting BookshopApplication v0.1.0 using Java 25.0.4.1 with PID 5395 (/home/ana/bookshop/target/bookshop-0.1.0.jar started by ana in /home/ana/bookshop)
2026-10-22T19:10:50.317-03:00  INFO 5395 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : No active profile set, falling back to 1 default profile: "default"
2026-10-22T19:10:51.485-03:00  INFO 5395 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat initialized with port 8080 (http)
2026-10-22T19:10:51.541-03:00  INFO 5395 --- [bookshop] [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2026-10-22T19:10:51.541-03:00  INFO 5395 --- [bookshop] [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/11.0.24]
2026-10-22T19:10:51.561-03:00  INFO 5395 --- [bookshop] [           main] b.w.c.s.WebApplicationContextInitializer : Root WebApplicationContext: initialization completed in 1152 ms
2026-10-22T19:10:52.035-03:00  INFO 5395 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 8080 (http) with context path '/'
2026-10-22T19:10:52.054-03:00  INFO 5395 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 2.658 seconds (process running for 3.253)
```

Leia de cima. O banner e a versão do Boot. `Starting BookshopApplication v0.1.0 using Java
25.0.4.1 with PID …`: a versão é a do pom, e o `[bookshop]` depois do PID é o
`spring.application.name` que você acabou de escrever, em toda linha. `No active profile set` é o
assunto da seção de perfis. Depois o Tomcat 11 inicializado na **porta 8080**, a padrão, e a linha
que diz que está pronto, com quanto tempo levou. O tempo e o PID serão outros na sua máquina.

No primeiro terminal, peça alguma coisa:

```
ana@vm:~/bookshop$ curl -s localhost:8080/; echo
{"timestamp":"2026-10-22T22:10:53.029Z","status":404,"error":"Not Found","path":"/"}
```

Um `404`, e essa é a resposta certa. A requisição chegou ao Spring MVC, nada na livraria trata `/`
ainda, e **o tratamento de erro padrão do Boot escreveu o JSON** sem nenhuma linha sua. A aula 6
acrescenta o primeiro controller; a aula 7 troca esse corpo por um pensado para a livraria. Pare a
aplicação com Ctrl+C no segundo terminal.
