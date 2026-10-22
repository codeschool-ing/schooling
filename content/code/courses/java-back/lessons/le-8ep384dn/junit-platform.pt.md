---
title: O JUnit, a Platform e o que o mvn test roda
version: 1
---

Um **teste de unidade**, aqui, é um método que chama uma parte da livraria com uma entrada escolhida
por você e falha quando a resposta não é a que você deixou escrita. Nenhum servidor sobe, nenhum
banco de dados é acessado e o Spring não participa. `Isbn` é uma classe de métodos estáticos, e
`Book` e `Order` só são entidades até onde vão as anotações: um teste cria um deles com `new` e lhe
faz uma pergunta em poucos microssegundos. A lição 19 acrescenta o outro tipo, testes que sobem a
aplicação contra um PostgreSQL de verdade; esta lição fica abaixo dessa linha de propósito, porque
testes tão baratos assim podem rodar em todo build.

## JUnit 5, JUnit 6 e o nome no jar

O framework é o **JUnit**, e a versão que este curso usa é a 6.0.3. A maioria dos livros, artigos e
vagas de emprego diz "JUnit 5", e para o que você escreve as duas coisas são a mesma. O JUnit 5,
lançado em 2017, introduziu o modelo de programação **Jupiter**: as anotações e asserções de
`org.junit.jupiter.api`. O JUnit 6, lançado em 2025, manteve esse modelo, os mesmos pacotes e as
mesmas anotações, subiu o mínimo para o Java 17 e deu um só número de versão a todas as suas partes.
Um teste escrito para o JUnit 5 é, em tudo o que esta lição mostra, um teste para o JUnit 6. O título
da lição fica com o nome que as pessoas procuram.

O JUnit 4, de 2006, é outra API (`org.junit.Test`, rules, runners) e não é nada disto.

## Três camadas, não um jar

A imagem comum é a de que o JUnit é uma biblioteca que roda testes. Ele é três coisas, e o Maven só
conversa com uma delas:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 272\" role=\"img\" aria-label=\"mvn test roda o maven-surefire-plugin, que acha as classes de teste, roda as classes numa JVM própria e escreve os relatórios. Ele as entrega à JUnit Platform, que descobre os testes e dá cada um a um engine: o engine Jupiter roda IsbnTest, BookTest e OrderTest, escritos com @Test, @ParameterizedTest e @Nested. Um engine do Cucumber entra na lição 21; o engine Vintage roda testes de JUnit 3 e 4 e não está neste projeto.\"><rect x=\"10\" y=\"112\" width=\"96\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"58\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">mvn test</text><line x1=\"106\" y1=\"134\" x2=\"131\" y2=\"134\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><polygon points=\"138,134 130,130 130,138\" fill=\"var(--phosphor-dim)\"></polygon><rect x=\"138\" y=\"92\" width=\"170\" height=\"84\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"223\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">maven-surefire-plugin</text><text x=\"223\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">acha as classes chamadas *Test</text><text x=\"223\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">roda as classes numa JVM própria</text><text x=\"223\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">e escreve os relatórios</text><line x1=\"308\" y1=\"134\" x2=\"331\" y2=\"134\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><polygon points=\"338,134 330,130 330,138\" fill=\"var(--phosphor-dim)\"></polygon><rect x=\"338\" y=\"14\" width=\"352\" height=\"244\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"514\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">JUnit Platform</text><text x=\"514\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">descobre os testes e entrega cada um ao seu engine</text><rect x=\"356\" y=\"66\" width=\"316\" height=\"64\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"514\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">engine Jupiter: os testes que esta lição escreve</text><text x=\"514\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">@Test  @ParameterizedTest  @Nested</text><text x=\"514\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">IsbnTest  BookTest  OrderTest</text><rect x=\"356\" y=\"140\" width=\"316\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"514\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">engine do Cucumber</text><text x=\"514\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a lição 21 o acrescenta, e nada acima dele muda</text><rect x=\"356\" y=\"198\" width=\"316\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"514\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">engine Vintage</text><text x=\"514\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">roda testes de JUnit 3 e 4, para código antigo; fora deste projeto</text></svg>", "caption": "Três camadas entre mvn test e um método de teste. O Maven conhece o surefire, o surefire conhece a Platform, e só um engine sabe o que @Test quer dizer.", "same": ["JUnit Platform"]}
```

- **O surefire** é o plugin do Maven ligado à fase `test`. Ele reconhece as classes de teste pelo
  nome e sobe uma JVM separada para elas.
- **A JUnit Platform** é quem lança: descobre os testes e entrega cada um ao engine que é dono dele.
  Ela não sabe nada de `@Test`.
- **Um engine** é o que dá sentido a uma anotação. O engine do Jupiter roda os testes desta lição.
  Outros frameworks entram como engines próprios, e é assim que a lição 21 roda cenários do Cucumber
  na mesma Platform, sem um runner só dele.

## O que o projeto tinha antes

No fim da lição 17 a livraria não tinha nenhum teste, e o `mvn test` disse isso sem reclamar:

```
ana@vm:~/bookshop$ mvn test | tail -n 8
[INFO] --- maven-surefire-plugin:3.5.6:test (default-test) @ bookshop ---
[INFO] No tests to run.
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  3.187 s
[INFO] Finished at: 2026-10-22T20:20:02-03:00
[INFO] ------------------------------------------------------------------------
```

`No tests to run.` junto com `BUILD SUCCESS` vale guardar: para o Maven, uma rodada de testes vazia
é um sucesso, e a próxima seção reencontra isso numa forma pior.

## O starter

O Spring Boot junta as bibliotecas de teste num starter. Substitua o `pom.xml` por esta versão, que
acrescenta `spring-boot-starter-test` no escopo `test`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>4.1.1</version>
    <relativePath/>
  </parent>

  <groupId>com.example</groupId>
  <artifactId>bookshop</artifactId>
  <version>0.1.0</version>

  <properties>
    <java.version>25</java.version>
    <springdoc.version>3.1.1</springdoc.version>
  </properties>

  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-webmvc</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-flyway</artifactId>
    </dependency>
    <dependency>
      <groupId>org.flywaydb</groupId>
      <artifactId>flyway-database-postgresql</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-security-oauth2-resource-server</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springdoc</groupId>
      <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
      <version>${springdoc.version}</version>
    </dependency>

    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-test</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.postgresql</groupId>
      <artifactId>postgresql</artifactId>
      <scope>runtime</scope>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-javadoc-plugin</artifactId>
        <configuration>
          <show>public</show>
          <doclint>all,-missing</doclint>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>
```

De novo sem versão: o parent cuida dela, como cuida dos outros starters. Pergunte ao Maven o que o
starter trouxe, filtrando as bibliotecas que importam aqui:

```
ana@vm:~/bookshop$ mvn -q dependency:tree -DoutputFile=/tmp/tree.txt && grep -E "junit|assertj|mockito|hamcrest|jsonpath|xmlunit|awaitility|starter-test|spring-test|boot-test" /tmp/tree.txt
+- org.springframework.boot:spring-boot-starter-test:jar:4.1.1:test
|  +- org.springframework.boot:spring-boot-test:jar:4.1.1:test
|  +- org.springframework.boot:spring-boot-test-autoconfigure:jar:4.1.1:test
|  +- com.jayway.jsonpath:json-path:jar:2.10.0:test
|  +- org.assertj:assertj-core:jar:3.27.7:test
|  +- org.awaitility:awaitility:jar:4.3.0:test
|  +- org.hamcrest:hamcrest:jar:3.0:test
|  +- org.junit.jupiter:junit-jupiter:jar:6.0.3:test
|  |  +- org.junit.jupiter:junit-jupiter-api:jar:6.0.3:test
|  |  |  +- org.junit.platform:junit-platform-commons:jar:6.0.3:test
|  |  +- org.junit.jupiter:junit-jupiter-params:jar:6.0.3:test
|  |  \- org.junit.jupiter:junit-jupiter-engine:jar:6.0.3:test
|  |     \- org.junit.platform:junit-platform-engine:jar:6.0.3:test
|  +- org.mockito:mockito-core:jar:5.23.0:test
|  +- org.mockito:mockito-junit-jupiter:jar:5.23.0:test
|  +- org.springframework:spring-test:jar:7.0.9:test
|  \- org.xmlunit:xmlunit-core:jar:2.11.0:test
```

Lendo de cima para baixo:

- `junit-jupiter` é a API contra a qual você escreve (`-api`), os testes parametrizados (`-params`) e
  o engine (`-engine`), todos na 6.0.3, com duas peças da Platform por baixo. O lançador da
  Platform quem traz é o próprio surefire, e por isso ele não aparece nesta lista.
- `assertj-core` é uma segunda forma de escrever asserções, que o `OrderTest` da livraria usa.
- `mockito-core` e `mockito-junit-jupiter` são da lição 19.
- `spring-test` e os dois jars `spring-boot-test` são o que um teste precisa para subir um contexto
  da aplicação. Nada nesta lição os usa.
- `json-path`, `hamcrest`, `awaitility` e `xmlunit-core` são matchers e utilitários para testes que
  conferem JSON, esperam algo assíncrono ou comparam XML.

Todas as linhas da lista terminam em `:test`. Como a lição 1 mostrou, o escopo é herdado para baixo,
então nenhum desses jars chega a `src/main/java` nem ao jar executável.

A versão do surefire também é escolha do parent, e é a mesma 3.5.6 que a lição 1 fixou à mão:

```
ana@vm:~/bookshop$ mvn help:effective-pom | grep -A1 "<artifactId>maven-surefire-plugin"
          <artifactId>maven-surefire-plugin</artifactId>
          <version>3.5.6</version>
--
        <artifactId>maven-surefire-plugin</artifactId>
        <version>3.5.6</version>
```
