---
title: Testando pela porta
version: 1
---

A lição 19 deixou a livraria com três tipos de teste. O `OrderServiceTest` roda o serviço com o
Mockito no lugar dos repositórios, o `BookRepositoryIT` roda o repositório contra um PostgreSQL num
contêiner, e o `BookshopApplicationIT` sobe o contexto inteiro da aplicação contra o mesmo tipo de
contêiner. **Nenhum deles envia uma requisição HTTP.** Então ninguém conferiu ainda que
`GET /books/1` responde 200 com JSON, que um livro que a loja não tem volta como o problem detail da
lição 7, ou que `POST /books` sem token é recusado com o 401 da lição 15. Tudo isso mora entre o
socket e o serviço, num código que nenhum teste executou.

Uma primeira ideia comum é testar o controller chamando-o: construir um `BookController`, chamar
`get(1)`, olhar o que ele devolve. Isso confere um método. Pula o mapeamento do caminho para o
método, a conversão de `"1"` em `long`, os filtros de segurança, o Jackson e o tratador de erros,
que juntos são o que um cliente de fato encontra. **Um teste de API é um cliente.** Ele envia uma
requisição a um servidor rodando e julga a resposta pelo que atravessou a rede: o status, os
cabeçalhos e o corpo.

## Dois jeitos de subir a aplicação num teste

`@SpringBootTest` sobe o contexto da aplicação, e o atributo `webEnvironment` diz se um servidor
vem junto:

| `webEnvironment` | o que sobe | como uma requisição chega ao controller |
|---|---|---|
| `MOCK`, o padrão | o contexto, com um ambiente de servlet simulado e nenhum servidor | na mesma thread, pelo `MockMvc` do Spring, sem socket |
| `RANDOM_PORT` | o contexto e o Tomcat embutido, numa porta livre | por uma conexão HTTP de verdade |
| `DEFINED_PORT` | o mesmo, na `server.port`, aqui 8080 | por uma conexão HTTP de verdade, se nada mais ocupar a 8080 |
| `NONE` | o contexto, sem camada web nenhuma | não chega |

O `BookshopApplicationIT` usa o padrão, e é por isso que pôde pedir uma contagem ao `BookService`
sem abrir conexão nenhuma. O teste que esta lição escreve pede **`RANDOM_PORT`**. Uma porta livre,
escolhida na subida, faz o teste nunca colidir com uma livraria que você deixou rodando em outro
terminal, nem com um segundo build na mesma máquina, que é exatamente o que o `DEFINED_PORT` faria.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"Uma JVM, iniciada pelo failsafe, contém o teste e a aplicação. O REST Assured envia HTTP de verdade pela interface de loopback ao Tomcat numa porta aleatória; a requisição passa pela cadeia de filtros de segurança, pelo controller e seu tratador de erros e pelo JPA, que fala JDBC com o PostgreSQL num contêiner fora da JVM.\"><defs><marker id=\"l20p-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"20\" width=\"490\" height=\"265\" rx=\"5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma JVM, iniciada pelo failsafe</text><rect x=\"35\" y=\"120\" width=\"135\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"102\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">REST Assured</text><text x=\"102\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o cliente</text><rect x=\"220\" y=\"50\" width=\"270\" height=\"222\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o contexto do Spring</text><rect x=\"240\" y=\"80\" width=\"230\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Tomcat, numa porta aleatória</text><rect x=\"240\" y=\"128\" width=\"230\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a cadeia de filtros de segurança</text><polyline points=\"355,116 355,127\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l20p-ah)\"></polyline><rect x=\"240\" y=\"176\" width=\"230\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">controllers e ApiErrorHandler</text><polyline points=\"355,164 355,175\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l20p-ah)\"></polyline><rect x=\"240\" y=\"224\" width=\"230\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">JPA e Hibernate</text><polyline points=\"355,212 355,223\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l20p-ah)\"></polyline><polyline points=\"170,148 200,148 200,98 238,98\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l20p-ah)\"></polyline><text x=\"196\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">HTTP de verdade</text><text x=\"196\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">pelo loopback</text><rect x=\"540\" y=\"214\" width=\"145\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"612\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">postgres:16-alpine</text><text x=\"612\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um contêiner, fora da JVM</text><polyline points=\"470,242 538,242\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l20p-ah)\"></polyline><text x=\"504\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">JDBC</text></svg>", "caption": "RANDOM_PORT sobe a aplicação inteira dentro da JVM do teste, e o REST Assured chega a ela como qualquer cliente chegaria: por um socket.", "same": ["controllers e ApiErrorHandler"]}
```

O `MockMvc` pula o socket e o Tomcat, e é uma escolha justa para testar o mapeamento de um
controller. Esta lição usa uma porta de verdade porque a pergunta dela é o que um cliente vê, e o
cliente de uma API chega por um socket.

## REST Assured

O **REST Assured** é uma biblioteca Java para testar APIs HTTP: um cliente HTTP e um conjunto de
asserções, escritos como uma frase por requisição. O parent do Spring Boot não gerencia a versão
dele, então o pom a declara numa propriedade própria, do jeito que já faz com a do springdoc.
Substitua o `pom.xml` por este. Duas coisas são novas: a propriedade `rest-assured.version` e a
dependência perto do fim de `<dependencies>`, no escopo `test`.

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
    <rest-assured.version>6.1.0</rest-assured.version>
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
      <groupId>io.rest-assured</groupId>
      <artifactId>rest-assured</artifactId>
      <version>${rest-assured.version}</version>
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
        <artifactId>maven-dependency-plugin</artifactId>
        <executions>
          <execution>
            <goals>
              <goal>properties</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-surefire-plugin</artifactId>
        <configuration>
          <argLine>-javaagent:${org.mockito:mockito-core:jar} --enable-native-access=ALL-UNNAMED</argLine>
        </configuration>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-failsafe-plugin</artifactId>
        <configuration>
          <argLine>-javaagent:${org.mockito:mockito-core:jar} --enable-native-access=ALL-UNNAMED</argLine>
        </configuration>
        <executions>
          <execution>
            <goals>
              <goal>integration-test</goal>
              <goal>verify</goal>
            </goals>
          </execution>
        </executions>
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

As dependências dele merecem uma olhada, porque duas delas surpreendem:

```
ana@vm:~/bookshop$ mvn dependency:tree -Dincludes=io.rest-assured,org.apache.groovy,org.apache.httpcomponents,org.hamcrest | grep -E 'rest-assured|groovy|httpc|hamcrest'
[INFO] |  \- org.hamcrest:hamcrest:jar:3.0:test
[INFO] \- io.rest-assured:rest-assured:jar:6.1.0:test
[INFO]    +- org.apache.groovy:groovy:jar:5.0.8:test
[INFO]    +- org.apache.groovy:groovy-xml:jar:5.0.8:test
[INFO]    +- org.apache.httpcomponents:httpclient:jar:4.5.13:test
[INFO]    |  \- org.apache.httpcomponents:httpcore:jar:4.4.16:test
[INFO]    +- org.apache.httpcomponents:httpmime:jar:4.5.13:test
[INFO]    +- io.rest-assured:json-path:jar:6.1.0:test
[INFO]    |  +- org.apache.groovy:groovy-json:jar:5.0.8:test
[INFO]    |  \- io.rest-assured:rest-assured-common:jar:6.1.0:test
[INFO]    \- io.rest-assured:xml-path:jar:6.1.0:test
```

O REST Assured envia as requisições com o **HttpClient** 4.5 da Apache, não com o cliente do
próprio JDK, e lê corpos JSON e XML com **Groovy**: o caminho que você escreve para chegar a um
campo, como `title` ou `lines.size()`, é o GPath do Groovy. Nenhum dos dois aparece no seu código
de teste. Veja também a versão do Groovy, comparada com a que o próprio pom parent do REST Assured
pede:

```
ana@vm:~/bookshop$ grep groovy.version ~/.m2/repository/io/rest-assured/rest-assured-parent/6.1.0/rest-assured-parent-6.1.0.pom
        <groovy.version>5.0.3</groovy.version>
                            <version>${groovy.version}</version>
                <version>${groovy.version}</version>
```

O REST Assured pede a 5.0.3 e o build usa a 5.0.8. O parent do Spring Boot gerencia o Groovy, e a
lista de versões que a lição 4 descreveu vale para toda biblioteca que está nela, inclusive uma que
chega pelo pom de outro.

A classe de teste vai onde o failsafe procura testes de integração, com um nome terminado em `IT`,
como a lição 19 arrumou: `src/test/java/com/example/bookshop/BooksApiIT.java`. A próxima seção a
escreve.
