---
title: A fachada e o backend
version: 1
---

A imagem comum de logging em Java é uma biblioteca que o seu código importa e que escreve as linhas.
**São duas metades, e o seu código só encontra uma delas.** A metade que o seu código chama é uma
**fachada**: uma interface com métodos como `info` e `warn` e nenhuma opinião sobre para onde vai uma
linha. A metade que formata a linha e a escreve em algum lugar é o **backend**. Neste curso a fachada
é o **SLF4J**, a Simple Logging Facade for Java, e o backend é o **Logback**, porque é o que o Spring
Boot traz.

A divisão existe porque uma aplicação Java é, em boa parte, código dos outros. Spring, Hibernate,
HikariCP e Tomcat registram logs, foram escritos por equipes diferentes em anos diferentes, e escolheram
APIs de logging diferentes. Se cada um trouxesse o seu backend, um programa escreveria em quatro
formatos, em quatro lugares, com quatro conjuntos de níveis. A fachada deixa toda biblioteca registrar
por uma interface só e deixa a escolha do backend para quem monta a aplicação, que é você.

## O que a livraria já carrega

A aula 4 encontrou o `spring-boot-starter-logging` na árvore de dependências do starter. Pedir ao
Maven só as bibliotecas de logging mostra de onde vem cada uma:

```
ana@vm:~/bookshop$ mvn dependency:tree -Dincludes=org.slf4j,ch.qos.logback,org.apache.logging.log4j,commons-logging,org.jboss.logging
[INFO] Scanning for projects...
[INFO] 
[INFO] ------------------------< com.example:bookshop >------------------------
[INFO] Building bookshop 0.1.0
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-dependency-plugin:3.10.0:tree (default-cli) @ bookshop ---
[INFO] com.example:bookshop:jar:0.1.0
[INFO] +- org.springframework.boot:spring-boot-starter-webmvc:jar:4.1.1:compile
[INFO] |  +- org.springframework.boot:spring-boot-starter:jar:4.1.1:compile
[INFO] |  |  \- org.springframework.boot:spring-boot-starter-logging:jar:4.1.1:compile
[INFO] |  |     +- ch.qos.logback:logback-classic:jar:1.5.38:compile
[INFO] |  |     |  \- ch.qos.logback:logback-core:jar:1.5.38:compile
[INFO] |  |     +- org.apache.logging.log4j:log4j-to-slf4j:jar:2.25.5:compile
[INFO] |  |     |  \- org.apache.logging.log4j:log4j-api:jar:2.25.5:compile
[INFO] |  |     \- org.slf4j:jul-to-slf4j:jar:2.0.18:compile
[INFO] |  \- org.springframework.boot:spring-boot-http-converter:jar:4.1.1:compile
[INFO] |     \- org.springframework.boot:spring-boot:jar:4.1.1:compile
[INFO] |        \- org.springframework:spring-core:jar:7.0.9:compile
[INFO] |           \- commons-logging:commons-logging:jar:1.3.6:compile
[INFO] +- org.springframework.boot:spring-boot-starter-validation:jar:4.1.1:compile
[INFO] |  \- org.springframework.boot:spring-boot-validation:jar:4.1.1:compile
[INFO] |     \- org.hibernate.validator:hibernate-validator:jar:9.1.3.Final:compile
[INFO] |        \- org.jboss.logging:jboss-logging:jar:3.6.3.Final:compile
[INFO] \- org.springframework.boot:spring-boot-starter-data-jpa:jar:4.1.1:compile
[INFO]    \- org.springframework.boot:spring-boot-starter-jdbc:jar:4.1.1:compile
[INFO]       \- com.zaxxer:HikariCP:jar:7.0.2:compile
[INFO]          \- org.slf4j:slf4j-api:jar:2.0.18:compile
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  0.761 s
[INFO] Finished at: 2026-10-22T19:30:34-03:00
[INFO] ------------------------------------------------------------------------
```

Leia de baixo para cima. `slf4j-api` é a fachada, e o Maven a coloca sob o HikariCP só porque foi o
primeiro lugar onde a encontrou; o Logback também depende dela. `logback-classic` é o backend. Todo o
resto é uma porta de entrada: as classes do próprio Spring registram pelo `commons-logging`, o
validador do Hibernate pelo `jboss-logging`, e duas **pontes** pegam o resto. O `log4j-to-slf4j` recebe
chamadas feitas à API do Log4j e as passa ao SLF4J, e o `jul-to-slf4j` faz o mesmo com o
`java.util.logging`, o logger que vem no JDK. Repare no que falta: `log4j-core`, o backend do Log4j. A
última seção desta aula conta por que essa ausência já importou para todo mundo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Cinco origens de chamadas de log à esquerda: o seu código pela API do SLF4J, as classes do Spring pelo commons-logging, o Hibernate pelo jboss-logging, uma biblioteca da API do Log4j pelo log4j-to-slf4j e o java.util.logging pelo jul-to-slf4j. As cinco setas chegam ao slf4j-api, que tem uma seta para o logback-classic, que escreve no console.\"><defs><marker id=\"ffb-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14\" y=\"14\" width=\"240\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"134\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o seu código</text><text x=\"134\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">LoggerFactory.getLogger</text><line x1=\"254\" y1=\"36\" x2=\"368\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ffb-ah)\"></line><rect x=\"14\" y=\"70\" width=\"240\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"134\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">as classes do Spring</text><text x=\"134\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">commons-logging</text><line x1=\"254\" y1=\"92\" x2=\"368\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ffb-ah)\"></line><rect x=\"14\" y=\"126\" width=\"240\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"134\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o Hibernate</text><text x=\"134\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">jboss-logging</text><line x1=\"254\" y1=\"148\" x2=\"368\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ffb-ah)\"></line><rect x=\"14\" y=\"182\" width=\"240\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"134\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma biblioteca na API do Log4j</text><text x=\"134\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">log4j-to-slf4j</text><line x1=\"254\" y1=\"204\" x2=\"368\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ffb-ah)\"></line><rect x=\"14\" y=\"238\" width=\"240\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"134\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma biblioteca no java.util.logging</text><text x=\"134\" y=\"269\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">jul-to-slf4j</text><line x1=\"254\" y1=\"260\" x2=\"368\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ffb-ah)\"></line><rect x=\"370\" y=\"118\" width=\"130\" height=\"64\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"435\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">slf4j-api</text><text x=\"435\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a fachada</text><line x1=\"500\" y1=\"150\" x2=\"538\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ffb-ah)\"></line><rect x=\"540\" y=\"118\" width=\"166\" height=\"64\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"623\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">logback-classic</text><text x=\"623\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o único backend</text><line x1=\"623\" y1=\"182\" x2=\"623\" y2=\"236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ffb-ah)\"></line><rect x=\"553\" y=\"238\" width=\"140\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"623\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o console</text></svg>", "caption": "Cinco entradas, uma saída. Cada biblioteca registra pela API que escolheu; as pontes do starter de logging do Boot mandam tudo para o SLF4J, e o SLF4J para o único backend do classpath.", "same": []}
```

## A fachada sozinha

O jeito mais limpo de ver as duas metades é um programa pequeno o bastante para rodar com cada backend
por vez. Crie `~/logging-look/pom.xml`. Ele não tem código para compilar: existe para o Maven montar
um classpath, e cada **perfil** acrescenta um backend à única dependência que todas as variantes
compartilham:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>com.example</groupId>
  <artifactId>logging-look</artifactId>
  <version>1.0.0</version>

  <dependencies>
    <dependency>
      <groupId>org.slf4j</groupId>
      <artifactId>slf4j-api</artifactId>
      <version>2.0.18</version>
    </dependency>
  </dependencies>

  <profiles>
    <profile>
      <id>logback</id>
      <dependencies>
        <dependency>
          <groupId>ch.qos.logback</groupId>
          <artifactId>logback-classic</artifactId>
          <version>1.5.38</version>
        </dependency>
      </dependencies>
    </profile>
    <profile>
      <id>log4j2</id>
      <dependencies>
        <dependency>
          <groupId>org.apache.logging.log4j</groupId>
          <artifactId>log4j-slf4j2-impl</artifactId>
          <version>2.25.5</version>
        </dependency>
        <dependency>
          <groupId>org.apache.logging.log4j</groupId>
          <artifactId>log4j-core</artifactId>
          <version>2.25.5</version>
        </dependency>
      </dependencies>
    </profile>
    <profile>
      <id>tinylog</id>
      <dependencies>
        <dependency>
          <groupId>org.tinylog</groupId>
          <artifactId>slf4j-tinylog</artifactId>
          <version>2.8.1</version>
        </dependency>
        <dependency>
          <groupId>org.tinylog</groupId>
          <artifactId>tinylog-impl</artifactId>
          <version>2.8.1</version>
        </dependency>
      </dependencies>
    </profile>
  </profiles>

  <build>
    <pluginManagement>
      <plugins>
        <plugin>
          <artifactId>maven-dependency-plugin</artifactId>
          <version>3.10.0</version>
        </plugin>
      </plugins>
    </pluginManagement>
  </build>
</project>
```

As versões são as que o Boot 4.1.1 gerencia para a livraria, então as duas primeiras variantes não
baixam nada novo. Ao lado dele, `~/logging-look/Hello.java`, que importa o SLF4J e mais nada:

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Hello {

    private static final Logger log = LoggerFactory.getLogger(Hello.class);

    public static void main(String[] args) {
        log.debug("Looking up book {}", 3);
        log.info("Order {} placed by {}: {} line(s)", 7, "ana", 2);
        log.warn("Only {} of '{}' left", 1, "Frankenstein");
        try {
            Integer.parseInt("two");
        } catch (NumberFormatException e) {
            log.error("Quantity '{}' is not a number", "two", e);
        }
    }
}
```

`LoggerFactory.getLogger(Hello.class)` pede um **logger**, e a classe recebida vira o **nome** do
logger: `Hello` aqui, `com.example.bookshop.ordering.OrderService` na livraria. Toda linha traz esse
nome, e a próxima seção o usa para escolher quais linhas aparecem.

`mvn dependency:build-classpath` resolve os jars de que um projeto precisa e junta os caminhos deles
com dois-pontos, exatamente o que `java -cp` recebe; `-Dmdep.outputFile=cp.txt` grava essa string num
arquivo, e `-q` deixa o Maven calado a menos que algo falhe. O `java` então roda o arquivo-fonte
direto com esse classpath. Primeiro sem perfil, com a fachada sozinha (o `cp.txt` não tem quebra de
linha no fim, daí o `echo`):

```
ana@vm:~/logging-look$ mvn -q dependency:build-classpath -Dmdep.outputFile=cp.txt
ana@vm:~/logging-look$ cat cp.txt; echo
/home/ana/.m2/repository/org/slf4j/slf4j-api/2.0.18/slf4j-api-2.0.18.jar
ana@vm:~/logging-look$ java -cp "$(cat cp.txt)" Hello.java
SLF4J(W): No SLF4J providers were found.
SLF4J(W): Defaulting to no-operation (NOP) logger implementation
SLF4J(W): See https://www.slf4j.org/codes.html#noProviders for further details.
```

O programa compilou, rodou e terminou, e **nenhuma das quatro linhas foi escrita, nem a de erro.** O
SLF4J procurou um **provider**, que é como o SLF4J chama um backend, não achou nenhum, avisou três
vezes, e trocou todo logger por um que descarta tudo. É a fachada fazendo exatamente o seu trabalho:
ela não tem ideia de como escrever uma linha. Um servidor iniciado assim rodaria por meses com um log
vazio, então vale reconhecer esses três avisos.

Agora com o Logback:

```
ana@vm:~/logging-look$ mvn -q dependency:build-classpath -Dmdep.outputFile=cp.txt -P logback
ana@vm:~/logging-look$ tr ':' '\n' < cp.txt; echo
/home/ana/.m2/repository/org/slf4j/slf4j-api/2.0.18/slf4j-api-2.0.18.jar
/home/ana/.m2/repository/ch/qos/logback/logback-classic/1.5.38/logback-classic-1.5.38.jar
/home/ana/.m2/repository/ch/qos/logback/logback-core/1.5.38/logback-core-1.5.38.jar
ana@vm:~/logging-look$ java -cp "$(cat cp.txt)" Hello.java
19:30:38.281 [main] DEBUG Hello -- Looking up book 3
19:30:38.283 [main] INFO Hello -- Order 7 placed by ana: 2 line(s)
19:30:38.284 [main] WARN Hello -- Only 1 of 'Frankenstein' left
19:30:38.284 [main] ERROR Hello -- Quantity 'two' is not a number
java.lang.NumberFormatException: For input string: "two"
	at java.base/java.lang.NumberFormatException.forInputString(NumberFormatException.java:67)
	at java.base/java.lang.Integer.parseInt(Integer.java:565)
	at java.base/java.lang.Integer.parseInt(Integer.java:662)
	at Hello.main(Hello.java:13)
	at java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(DirectMethodHandleAccessor.java:104)
	at java.base/java.lang.reflect.Method.invoke(Method.java:565)
	at jdk.compiler/com.sun.tools.javac.launcher.SourceLauncher.execute(SourceLauncher.java:258)
	at jdk.compiler/com.sun.tools.javac.launcher.SourceLauncher.run(SourceLauncher.java:138)
	at jdk.compiler/com.sun.tools.javac.launcher.SourceLauncher.main(SourceLauncher.java:76)
```

O mesmo arquivo-fonte, mais três jars, e agora toda linha chega: a hora, a thread, o nível, o nome do
logger e a mensagem, com o stack trace da exceção depois da última. Nada no `Hello.java` mudou entre as
duas execuções. **Escolher um backend é uma mudança no classpath, nunca no código**, e essa é toda a
promessa de uma fachada. O formato acima é o padrão do próprio Logback, usado quando ninguém o
configurou; as linhas da livraria são diferentes porque o Spring Boot configura o Logback antes de a
primeira ser escrita, e é daí que a próxima seção parte.
