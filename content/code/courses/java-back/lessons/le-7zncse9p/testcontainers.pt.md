---
title: Testcontainers, um PostgreSQL de verdade a cada execução
version: 1
---

O **Testcontainers** é uma biblioteca Java que comanda o engine de dentro de um teste: pede um
contêiner, espera o programa dentro dele ficar pronto, entrega ao teste o endereço e o remove quando a
execução termina. Com o PostgreSQL num contêiner, um teste de integração confere o bookshop contra o
mesmo banco em que ele roda em produção, com um esquema que o Flyway construiu do zero segundos antes.

A outra resposta comum é um banco em memória, como o H2, no lugar do PostgreSQL. Ele sobe mais rápido,
e é outro banco, com o próprio dialeto SQL, os próprios tipos e o próprio jeito de travar. Uma migração
com um tipo que só o PostgreSQL tem, ou uma consulta cujo comportamento depende do PostgreSQL, passa ou
falha ali pelos motivos do H2. A coluna `isbn` do bookshop é `char(13)`, e a aula 13 encontrou uma falha que dependia
exatamente desse tipo.

## As dependências

Substitua o elemento `<dependencies>` inteiro do `pom.xml` por este. As quatro últimas entradas antes
do driver do PostgreSQL são novas, todas com escopo `test` e sem versão, porque o parent do Boot
gerencia o Testcontainers como tudo o mais:

```xml
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
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-data-jpa-test</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-testcontainers</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.testcontainers</groupId>
      <artifactId>testcontainers-junit-jupiter</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.testcontainers</groupId>
      <artifactId>testcontainers-postgresql</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.postgresql</groupId>
      <artifactId>postgresql</artifactId>
      <scope>runtime</scope>
    </dependency>
  </dependencies>
```

| artefato | o que traz |
| --- | --- |
| `spring-boot-starter-data-jpa-test` | `@DataJpaTest`, um teste que sobe só a metade de persistência da aplicação |
| `spring-boot-testcontainers` | `@ServiceConnection`, que aponta o Spring para um contêiner |
| `testcontainers-junit-jupiter` | `@Testcontainers` e `@Container`, um contêiner cuja vida fica presa a uma classe de teste |
| `testcontainers-postgresql` | `PostgreSQLContainer`, que sabe subir o PostgreSQL e dizer quando ele está pronto |

O Testcontainers 2 deu aos módulos o prefixo `testcontainers-` e moveu o `PostgreSQLContainer` para o
pacote `org.testcontainers.postgresql`. Exemplos escritos para a versão 1, que são a maior parte do que
uma busca encontra, o importam de `org.testcontainers.containers` e escrevem `PostgreSQLContainer<?>`;
nenhuma das duas formas compila com a versão 2.

## A aplicação inteira contra um contêiner

Crie `src/test/java/com/example/bookshop/TestcontainersConfiguration.java`:

```java
package com.example.bookshop;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.testcontainers.postgresql.PostgreSQLContainer;

@TestConfiguration(proxyBeanMethods = false)
public class TestcontainersConfiguration {

    @Bean
    @ServiceConnection
    PostgreSQLContainer postgres() {
        return new PostgreSQLContainer("postgres:16-alpine");
    }
}
```

O contêiner é um **bean**. O Spring o inicia quando o contexto precisa dele, antes dos beans que usam o
banco, e o para quando o contexto fecha. **`@ServiceConnection`** é a ligação: o Spring Boot lê o
endereço, o nome do banco, o usuário e a senha do contêiner em execução e os usa no lugar das
propriedades `spring.datasource.*` do `application.properties`. Nada no teste cita uma porta, e isso
importa, porque o Docker publica a 5432 do contêiner em qualquer porta da máquina que esteja livre.

A aplicação também precisa do segredo JWT que a aula 15 lê de uma variável de ambiente. Um teste não
deve depender de uma variável que alguém precisa lembrar de definir, então um perfil chamado `test` lhe
dá um valor. Crie `src/test/resources/application-test.properties`:

```properties
bookshop.jwt.secret=a-secret-for-tests-only-at-least-32-bytes
```

Esse valor não é segredo e nunca deve ser: ele fica no repositório e só assina tokens dentro de um
teste. Depois, o primeiro teste de integração, em
`src/test/java/com/example/bookshop/BookshopApplicationIT.java`:

```java
package com.example.bookshop;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;

import com.example.bookshop.catalogue.BookService;

@SpringBootTest
@ActiveProfiles("test")
@Import(TestcontainersConfiguration.class)
class BookshopApplicationIT {

    @Autowired
    BookService books;

    @Test
    void startsAgainstARealDatabaseWithTheMigrationsApplied() {
        assertThat(books.count()).isEqualTo(6);
    }
}
```

`@SpringBootTest` sobe a aplicação inteira, como o `java -jar` faria, sem um servidor web escutando;
`@ActiveProfiles("test")` lê o arquivo acima; `@Import` acrescenta o contêiner. O teste então pergunta
ao `BookService` real quantos livros existem. Seis é o que o `V2__first_titles.sql` da aula 13 insere,
então o número só se confirma se o Flyway rodou todas as migrações no banco vazio.

## Só a metade de persistência

`BookRepositoryIT` testa duas das consultas da aula 11. Ele não precisa dos controllers, dos filtros de
segurança nem dos serviços, e o **`@DataJpaTest`** não sobe nenhum deles, só o data source, o Flyway, o
Hibernate e os repositórios. Cada método de teste roda dentro de uma transação que é desfeita quando
ele termina. Crie `src/test/java/com/example/bookshop/catalogue/BookRepositoryIT.java`:

```java
package com.example.bookshop.catalogue;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

@DataJpaTest
@Testcontainers
class BookRepositoryIT {

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres = new PostgreSQLContainer("postgres:16-alpine");

    @Autowired
    BookRepository books;

    @Test
    void findsTitlesByAuthorInTitleOrder() {
        assertThat(books.findTitlesByAuthor("H. G. Wells"))
                .extracting(TitleAndPrice::getTitle)
                .containsExactly("The Time Machine", "The War of the Worlds");
    }

    @Test
    void searchIgnoresCase() {
        assertThat(books.findByTitleContainingIgnoreCaseOrderByTitle("BORBA"))
                .extracting(Book::getIsbn)
                .containsExactly("9786500000054");
    }
}
```

Esta classe declara o contêiner do outro jeito que o Testcontainers oferece. **`@Testcontainers`** é uma
extensão do JUnit, e ela inicia cada campo `@Container` antes do primeiro teste da classe e o para
depois do último; um campo `static` é um contêiner para a classe inteira. `@ServiceConnection` funciona
num campo exatamente como funciona num bean.

Os dois estilos aparecem lado a lado de propósito, e não são equivalentes: o bean pertence a um contexto
do Spring, o campo a uma classe de teste. A próxima seção conta quanto essa diferença custa.

## O aviso que a segunda opção evita

Antes da execução de verdade, um desvio que mostra para que serve `--enable-native-access=ALL-UNNAMED`.
Tire a opção dos dois `argLine` e rode os testes de integração pela primeira vez:

```
ana@vm:~/bookshop$ sed -i 's/ --enable-native-access=ALL-UNNAMED//' pom.xml && grep -c 'enable-native-access' pom.xml
0
ana@vm:~/bookshop$ mvn -B verify 2>&1 | grep -E '^WARNING|Skipped: 0$|BUILD'
[INFO] Tests run: 17, Failures: 0, Errors: 0, Skipped: 0
WARNING: A restricted method in java.lang.System has been called
WARNING: java.lang.System::load has been called by com.sun.jna.Native in an unnamed module (file:/home/ana/.m2/repository/net/java/dev/jna/jna/5.18.1/jna-5.18.1.jar)
WARNING: Use --enable-native-access=ALL-UNNAMED to avoid a warning for callers in this module
WARNING: Restricted methods will be blocked in a future release unless native access is enabled
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

Todos os testes passaram, e o fork do failsafe imprimiu quatro linhas antes. Desde o JDK 24, a JVM avisa
quando um código chama um **método restrito**, um que vai além das garantias do Java; `System::load`,
que carrega código nativo no processo, é um deles. Quem chama é o **JNA**, Java Native Access, que vem
junto com o docker-java, o cliente de Docker dentro do Testcontainers. A terceira linha dá a correção:
permitir acesso nativo ao código do class path, que a JVM chama de módulo sem nome.

O aviso não volta a cada execução. O Testcontainers grava em `~/.testcontainers.properties` o jeito de
chegar ao engine que funcionou, e uma execução que encontra esse arquivo vai direto ao socket, sem a
busca que carrega o JNA. Por isso ele aparece numa primeira execução, num servidor de build que começa
de uma máquina limpa toda vez e em cada tentativa que não encontra o engine, que são justamente as
execuções em que ninguém quer ruído a mais. Ponha a opção de volta:

```
ana@vm:~/bookshop$ sed -i 's/mockito-core:jar}</mockito-core:jar} --enable-native-access=ALL-UNNAMED</' pom.xml && grep -c 'enable-native-access' pom.xml
2
```

## Rodando os testes

O mesmo comando, com a opção no lugar. O `tee` guarda a saída inteira em `/tmp/verify.log` para os
próximos parágrafos, e o `~/.testcontainers.properties` foi apagado de novo antes, então esta também é
uma primeira execução:

```
ana@vm:~/bookshop$ mvn -B verify 2>&1 | tee /tmp/verify.log | grep -E '^WARNING|Running |Tests run:|BUILD|Total time'
[INFO] Running com.example.bookshop.ordering.OrderTest
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.079 s -- in com.example.bookshop.ordering.OrderTest
[INFO] Running com.example.bookshop.ordering.OrderServiceTest
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.527 s -- in com.example.bookshop.ordering.OrderServiceTest
[INFO] Running com.example.bookshop.catalogue.BookTest
[INFO] Running take
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.009 s -- in take
[INFO] Tests run: 0, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.015 s -- in com.example.bookshop.catalogue.BookTest
[INFO] Running com.example.bookshop.catalogue.IsbnTest
[INFO] Tests run: 10, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.082 s -- in com.example.bookshop.catalogue.IsbnTest
[INFO] Tests run: 17, Failures: 0, Errors: 0, Skipped: 0
[INFO] Running com.example.bookshop.BookshopApplicationIT
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 6.733 s -- in com.example.bookshop.BookshopApplicationIT
[INFO] Running com.example.bookshop.catalogue.BookRepositoryIT
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 3.070 s -- in com.example.bookshop.catalogue.BookRepositoryIT
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
[INFO] Total time:  14.740 s
```

Nenhum aviso desta vez. Os dezessete testes de unidade do surefire passaram primeiro, como antes.
Depois o failsafe rodou três testes em duas classes, e o build terminou com sucesso. O log em
`/tmp/verify.log` conta o que aconteceu entre uma coisa e outra, e a primeira é o Testcontainers
encontrando o engine:

```
ana@vm:~/bookshop$ grep -E 'DockerClientProviderStrategy|DockerClientFactory   : (Testcontainers|Docker host|Connected)|tc.testcontainers/ryuk|RyukResourceReaper' /tmp/verify.log
2026-10-22T20:29:33.651-03:00  INFO 30480 --- [bookshop] [           main] [] org.testcontainers.DockerClientFactory   : Testcontainers version: 2.0.5
2026-10-22T20:29:34.031-03:00  INFO 30480 --- [bookshop] [           main] [] o.t.d.DockerClientProviderStrategy       : Found Docker environment with local Unix socket (unix:///var/run/docker.sock)
2026-10-22T20:29:34.035-03:00  INFO 30480 --- [bookshop] [           main] [] org.testcontainers.DockerClientFactory   : Docker host IP address is localhost
2026-10-22T20:29:34.049-03:00  INFO 30480 --- [bookshop] [           main] [] org.testcontainers.DockerClientFactory   : Connected to docker: 
2026-10-22T20:29:34.120-03:00  INFO 30480 --- [bookshop] [           main] [] tc.testcontainers/ryuk:0.14.0            : Creating container for image: testcontainers/ryuk:0.14.0
2026-10-22T20:29:34.273-03:00  INFO 30480 --- [bookshop] [           main] [] tc.testcontainers/ryuk:0.14.0            : Container testcontainers/ryuk:0.14.0 is starting: 10b9cde176b8d7220d95e2f098467e51b85098a2cd0a81a9cc3f3a0a3da03149
2026-10-22T20:29:34.547-03:00  INFO 30480 --- [bookshop] [           main] [] tc.testcontainers/ryuk:0.14.0            : Container testcontainers/ryuk:0.14.0 started in PT0.427031218S
2026-10-22T20:29:34.552-03:00  INFO 30480 --- [bookshop] [           main] [] o.t.utility.RyukResourceReaper           : Ryuk started - will monitor and terminate Testcontainers containers on JVM exit
```

Ele procurou o socket onde os pacotes da Docker o põem, conectou e subiu um primeiro contêiner que não é
um banco. O **Ryuk** é o ceifador do Testcontainers. A JVM dos testes mantém uma conexão aberta com ele,
e essa conexão fecha quando a execução termina, ou quando a JVM quebra ou é morta. O Ryuk então espera
alguns segundos e remove todos os contêineres que aquela execução subiu, e a si mesmo. Sem
ele, uma execução de testes interrompida com Ctrl+C no meio deixaria os bancos rodando até alguém
perceber.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 380\" role=\"img\" aria-label=\"Uma sequência em quatro raias: a JVM dos testes, o Docker Engine, o contêiner Ryuk e o contêiner PostgreSQL. 1, a JVM pede ao engine para iniciar o Ryuk e mantém uma conexão aberta com ele. 2, pede o postgres:16-alpine com a porta 5432 publicada numa porta livre da máquina. 3, espera até o PostgreSQL dizer que está pronto. 4, @ServiceConnection entrega endereço, usuário e senha ao Spring; o Flyway migra e os testes rodam contra o contêiner. 5, a JVM termina, a conexão com o Ryuk fecha e o Ryuk remove os contêineres que sobraram e depois a si mesmo.\"><defs><marker id=\"f19c-ad\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"f19c-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"15\" y=\"12\" width=\"160\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">JVM dos testes</text><text x=\"95.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">failsafe</text><line x1=\"95\" y1=\"52\" x2=\"95\" y2=\"362\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 4\"></line><rect x=\"210\" y=\"12\" width=\"160\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"290.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Docker Engine</text><text x=\"290.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/var/run/docker.sock</text><line x1=\"290\" y1=\"52\" x2=\"290\" y2=\"362\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 4\"></line><rect x=\"400\" y=\"12\" width=\"160\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"480.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Ryuk</text><text x=\"480.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">testcontainers/ryuk</text><line x1=\"480\" y1=\"52\" x2=\"480\" y2=\"362\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 4\"></line><rect x=\"585\" y=\"12\" width=\"160\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"665.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">PostgreSQL</text><text x=\"665.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">postgres:16-alpine</text><line x1=\"665\" y1=\"52\" x2=\"665\" y2=\"362\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 4\"></line><line x1=\"95\" y1=\"92\" x2=\"284\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19c-ad)\"></line><text x=\"192.5\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">inicie o Ryuk</text><circle cx=\"43\" cy=\"92\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"43\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">1</text><line x1=\"290\" y1=\"104\" x2=\"474\" y2=\"104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19c-ad)\"></line><line x1=\"95\" y1=\"122\" x2=\"474\" y2=\"122\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#f19c-am)\"></line><text x=\"382.5\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">uma conexão que fica aberta</text><line x1=\"95\" y1=\"166\" x2=\"284\" y2=\"166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19c-ad)\"></line><text x=\"222.5\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">inicie o postgres, 5432 numa porta livre</text><circle cx=\"43\" cy=\"166\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"43\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">2</text><line x1=\"290\" y1=\"178\" x2=\"659\" y2=\"178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19c-ad)\"></line><line x1=\"665\" y1=\"214\" x2=\"101\" y2=\"214\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19c-ad)\"></line><text x=\"380.0\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pronto para aceitar conexões</text><circle cx=\"43\" cy=\"214\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"43\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">3</text><line x1=\"95\" y1=\"262\" x2=\"659\" y2=\"262\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19c-ad)\"></line><text x=\"380.0\" y=\"251\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">@ServiceConnection: Flyway, depois os testes</text><circle cx=\"43\" cy=\"262\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"43\" y=\"263\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">4</text><line x1=\"95\" y1=\"316\" x2=\"474\" y2=\"316\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#f19c-am)\"></line><text x=\"287.5\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a JVM termina: a conexão fecha</text><circle cx=\"43\" cy=\"316\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"43\" y=\"317\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">5</text><line x1=\"480\" y1=\"340\" x2=\"659\" y2=\"340\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19c-ad)\"></line><text x=\"572.5\" y=\"329\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">remove o que sobrou, e depois a si mesmo</text></svg>", "caption": "O Ryuk é o motivo de uma execução de testes que quebra no meio não deixar contêiner para trás: ele age sobre a conexão fechada, não sobre uma mensagem que a JVM talvez nunca envie.", "same": ["Docker Engine", "PostgreSQL", "Ryuk"]}
```

Depois, o banco:

```
ana@vm:~/bookshop$ grep -E 'FlywayExecutor|DbMigrate|Started BookshopApplicationIT|Catalogue opened' /tmp/verify.log | head -n 8
2026-10-22T20:29:36.176-03:00  INFO 30480 --- [bookshop] [           main] [] org.flywaydb.core.FlywayExecutor         : Database: jdbc:postgresql://localhost:32869/test?loggerLevel=OFF (PostgreSQL 16.15)
2026-10-22T20:29:36.270-03:00  INFO 30480 --- [bookshop] [           main] [] o.f.core.internal.command.DbMigrate      : Current version of schema "public": << Empty Schema >>
2026-10-22T20:29:36.276-03:00  INFO 30480 --- [bookshop] [           main] [] o.f.core.internal.command.DbMigrate      : Migrating schema "public" to version "1 - catalogue"
2026-10-22T20:29:36.299-03:00  INFO 30480 --- [bookshop] [           main] [] o.f.core.internal.command.DbMigrate      : Migrating schema "public" to version "2 - first titles"
2026-10-22T20:29:36.308-03:00  INFO 30480 --- [bookshop] [           main] [] o.f.core.internal.command.DbMigrate      : Migrating schema "public" to version "3 - stock and orders"
2026-10-22T20:29:36.324-03:00  INFO 30480 --- [bookshop] [           main] [] o.f.core.internal.command.DbMigrate      : Successfully applied 3 migrations to schema "public", now at version v3 (execution time 00:00.028s)
2026-10-22T20:29:38.617-03:00  INFO 30480 --- [bookshop] [           main] [] c.e.bookshop.BookshopApplicationIT       : Started BookshopApplicationIT in 6.221 seconds (process running for 7.114)
2026-10-22T20:29:38.674-03:00  INFO 30480 --- [bookshop] [           main] [] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 6 books
```

PostgreSQL 16.15 num contêiner, o banco `test`, o Flyway aplicando as três migrações das aulas 13 e 14 a
um esquema vazio, e a aplicação iniciada com os seis livros que o teste então contou. A porta na URL
JDBC é a que o Docker escolheu desta vez.

O `BookRepositoryIT` subiu um segundo contêiner, só dele, e um contexto bem menor:

```
ana@vm:~/bookshop$ grep -E 'BookRepositoryIT  : (Started|No active)|tc.postgres.*(started in|JDBC URL)|^Hibernate:' /tmp/verify.log | tail -n 6
2026-10-22T20:29:40.196-03:00  INFO 30480 --- [bookshop] [           main] [] tc.postgres:16-alpine                    : Container postgres:16-alpine started in PT1.34241367S
2026-10-22T20:29:40.196-03:00  INFO 30480 --- [bookshop] [           main] [] tc.postgres:16-alpine                    : Container is started (JDBC URL: jdbc:postgresql://localhost:32870/test?loggerLevel=OFF)
2026-10-22T20:29:40.219-03:00  INFO 30480 --- [bookshop] [           main] [] c.e.bookshop.catalogue.BookRepositoryIT  : No active profile set, falling back to 1 default profile: "default"
2026-10-22T20:29:40.575-03:00  INFO 30480 --- [bookshop] [           main] [] c.e.bookshop.catalogue.BookRepositoryIT  : Started BookRepositoryIT in 0.372 seconds (process running for 9.072)
Hibernate: select b1_0.id,b1_0.author_id,a1_0.id,a1_0.name,b1_0.isbn,b1_0.price_cents,b1_0.stock,b1_0.title from book b1_0 join author a1_0 on a1_0.id=b1_0.author_id where upper(b1_0.title) like upper(?) escape '\' order by b1_0.title
Hibernate: select b1_0.title,b1_0.price_cents from book b1_0 join author a1_0 on a1_0.id=b1_0.author_id where a1_0.name=? order by b1_0.title
```

As duas linhas `Hibernate:` são o SQL das duas consultas testadas, impresso porque o `@DataJpaTest` liga
o `spring.jpa.show-sql`. E, quando o build acaba, `docker ps -a` lista cada contêiner que leva a
etiqueta do Testcontainers, rodando ou não:

```
ana@vm:~/bookshop$ docker ps -a --filter label=org.testcontainers=true --format '{{.Image}}  {{.Status}}'
testcontainers/ryuk:0.14.0  Up 9 seconds
ana@vm:~/bookshop$ sleep 15; docker ps -a --filter label=org.testcontainers=true --format '{{.Image}}  {{.Status}}'
```

Logo depois do build, só o Ryuk sobrou. Os dois bancos já tinham ido embora, parados pelos donos quando
a execução terminou: o contexto fechou e levou o bean junto, e a extensão parou o campo da classe depois
do último teste. Quinze segundos depois o Ryuk também tinha ido, que é a espera descrita acima
seguida do último trabalho dele.
