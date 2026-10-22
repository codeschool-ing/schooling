---
title: Rodando as features com JUnit e Spring
version: 1
---

O Cucumber lê os arquivos de *feature* e chama a *glue*, mas alguém precisa dar a partida nele, e
neste projeto quem faz isso são os plugins de teste do Maven, que já sabem rodar JUnit. Então o
Cucumber roda como um **motor da JUnit Platform** (*engine*): a plataforma que roda os testes
Jupiter da aula 18, com um segundo motor encaixado ao lado do Jupiter. Três arquivos ligam os dois:
o pom, uma classe de suíte e uma configuração do Spring para a *glue*.

## As dependências

Substitua o `pom.xml` por este:

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
    <cucumber.version>8.0.4</cucumber.version>
  </properties>

  <dependencyManagement>
    <dependencies>
      <dependency>
        <groupId>io.cucumber</groupId>
        <artifactId>cucumber-bom</artifactId>
        <version>${cucumber.version}</version>
        <type>pom</type>
        <scope>import</scope>
      </dependency>
    </dependencies>
  </dependencyManagement>

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
      <groupId>io.cucumber</groupId>
      <artifactId>cucumber-java</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>io.cucumber</groupId>
      <artifactId>cucumber-spring</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>io.cucumber</groupId>
      <artifactId>cucumber-junit-platform-engine</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.junit.platform</groupId>
      <artifactId>junit-platform-suite</artifactId>
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

O pai do Spring Boot gerencia as versões de centenas de bibliotecas, e o Cucumber não está entre
elas. Um **BOM**, uma *bill of materials* (lista de materiais), é um pom que só guarda versões.
Importar o `cucumber-bom` em `<dependencyManagement>` dá a todo módulo do Cucumber a versão de
`cucumber.version`, de modo que os módulos, que são lançados juntos, sempre concordam entre si, e
as entradas abaixo não levam versão nenhuma. As quatro dependências de teste novas:

| dependência | o que ela traz |
|---|---|
| `cucumber-java` | as anotações: `@Given`, `@When`, `@Then`, os hooks |
| `cucumber-spring` | a *glue* criada como beans do Spring, dentro de um contexto de teste do Spring |
| `cucumber-junit-platform-engine` | o motor que acha os arquivos `.feature` e roda cada cenário como um teste |
| `junit-platform-suite` | `@Suite`, a classe que diz à plataforma o que rodar; a versão dela vem do Spring Boot |

```
ana@vm:~/bookshop$ PENDING
```

## A suíte

Crie `src/test/java/com/example/bookshop/acceptance/CucumberIT.java`:

```java
package com.example.bookshop.acceptance;

import static io.cucumber.junit.platform.engine.Constants.ANSI_COLORS_DISABLED_PROPERTY_NAME;
import static io.cucumber.junit.platform.engine.Constants.GLUE_PROPERTY_NAME;
import static io.cucumber.junit.platform.engine.Constants.PLUGIN_PROPERTY_NAME;

import org.junit.platform.suite.api.ConfigurationParameter;
import org.junit.platform.suite.api.IncludeEngines;
import org.junit.platform.suite.api.SelectPackages;
import org.junit.platform.suite.api.Suite;

@Suite
@IncludeEngines("cucumber")
@SelectPackages("features")
@ConfigurationParameter(key = GLUE_PROPERTY_NAME, value = "com.example.bookshop.acceptance")
@ConfigurationParameter(key = PLUGIN_PROPERTY_NAME, value = "pretty")
@ConfigurationParameter(key = ANSI_COLORS_DISABLED_PROPERTY_NAME, value = "true")
class CucumberIT {
}
```

Uma **suíte** é uma classe sem métodos de teste que só diz o que rodar, e cada anotação responde a
uma pergunta. `@IncludeEngines("cucumber")` diz qual motor, para o Jupiter não vir procurar aqui
também. `@SelectPackages("features")` diz onde estão as *features*: um pacote no classpath de
teste, que é onde `src/test/resources/features/` vai parar depois do build. O primeiro
`@ConfigurationParameter` é a *glue*, `cucumber.glue`, com o pacote das definições de passos. O
segundo é `cucumber.plugin`, o relatório a imprimir, e `pretty` é o que você vai ver daqui a pouco.

O nome termina em `IT` de propósito. A aula 19 dividiu os testes em dois: o Surefire roda as classes
`*Test` no `mvn test`, e o Failsafe roda as classes `*IT` no `mvn verify`, porque elas sobem a
aplicação inteira e um banco de dados. Estes cenários fazem as duas coisas, então ficam com o
segundo tipo.

## Spring para a glue

Crie `src/test/java/com/example/bookshop/acceptance/CucumberSpringConfiguration.java`:

```java
package com.example.bookshop.acceptance;

import io.cucumber.spring.CucumberContextConfiguration;

import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;

import com.example.bookshop.TestcontainersConfiguration;

@CucumberContextConfiguration
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Import(TestcontainersConfiguration.class)
public class CucumberSpringConfiguration {
}
```

**`@CucumberContextConfiguration`** marca a única classe cujas anotações o cucumber-spring lê para
montar o contexto de teste do Spring. Tem de haver exatamente uma na *glue*. As outras três são as
anotações do `BooksApiIT` da aula 20, pelos mesmos motivos: a aplicação inteira numa porta
aleatória, o perfil `test` e o PostgreSQL do Testcontainers. A classe tem o corpo vazio porque é só
um lugar para pendurar anotações; os passos moram em outro lugar e recebem os beans pelo
construtor.

## Uma execução

`-Dit.test=CucumberIT` diz ao Failsafe para rodar só essa classe; os testes unitários ainda rodam
antes, porque o `verify` vem depois do `test`. O relatório *pretty* divide o terminal com o log do
Spring, então o `grep` fica com as linhas que trazem os comentários de origem do Cucumber, a linha
com a contagem e o veredito:

```
ana@vm:~/bookshop$ PENDING
```

Cada cenário é impresso com o arquivo e a linha de onde veio, e cada passo com um tique e o método
que o rodou, que é a primeira coisa a ler quando uma frase vai para o método errado. O esquema
aparece duas vezes, uma por linha da tabela, com os valores já postos: as linhas 22 e 23 do arquivo
são as duas linhas de `Examples`. O JUnit vê três testes, um por cenário. Um passo não é um teste
próprio: é uma linha dentro de um.

## O que vive quanto tempo

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 320\" role=\"img\" aria-label=\"Uma barra no topo: o contexto do Spring, a livraria numa porta aleatória com o PostgreSQL num contêiner, iniciado uma vez e guardado em cache. Embaixo dela, em ordem, o BooksApiIT e depois três cenários: o cenário 1 e as duas linhas do esquema. Cada cenário ganha um OrderingSteps novo, depois roda o hook @Before, o background e os seus passos. Uma barra embaixo: o banco de dados, compartilhado por todos, com o que cada um deixou nele: o BooksApiIT pediu The Time Machine, deixando 4; o cenário 1 pôs The War of the Worlds em 5 e deixou 3; a primeira linha pôs Persuasion em 5 e deixou 5; a segunda o pôs em 0 e deixou 0.\"><rect x=\"20\" y=\"14\" width=\"660\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">contexto do Spring: a livraria numa porta aleatória, o PostgreSQL num contêiner</text><text x=\"350\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">iniciado uma vez, depois tirado do cache por toda classe com a mesma configuração</text><rect x=\"20\" y=\"70\" width=\"130\" height=\"140\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"85.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">BooksApiIT</text><text x=\"85.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4 testes</text><text x=\"85.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o Cucumber não</text><text x=\"85.0\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">participa aqui</text><rect x=\"166\" y=\"70\" width=\"160\" height=\"140\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"246.0\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cenário 1</text><rect x=\"176\" y=\"100\" width=\"140\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"246.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">new OrderingSteps</text><text x=\"246.0\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">@Before</text><text x=\"246.0\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Background</text><text x=\"246.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Given · When · Then</text><rect x=\"342\" y=\"70\" width=\"160\" height=\"140\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"422.0\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">esquema, linha 1</text><rect x=\"352\" y=\"100\" width=\"140\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"422.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">new OrderingSteps</text><text x=\"422.0\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">@Before</text><text x=\"422.0\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Background</text><text x=\"422.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Given · When · Then</text><rect x=\"518\" y=\"70\" width=\"162\" height=\"140\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"599.0\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">esquema, linha 2</text><rect x=\"528\" y=\"100\" width=\"142\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"599.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">new OrderingSteps</text><text x=\"599.0\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">@Before</text><text x=\"599.0\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Background</text><text x=\"599.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Given · When · Then</text><rect x=\"20\" y=\"226\" width=\"660\" height=\"70\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"312\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o banco de dados: um só, compartilhado, nunca desfeito entre eles</text><text x=\"85.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">pediu 1 Time Machine</text><text x=\"85.0\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">sobram 4</text><text x=\"246.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">War of the Worlds em 5</text><text x=\"246.0\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">sobram 3</text><text x=\"422.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Persuasion em 5</text><text x=\"422.0\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">sobram 5, recusado</text><text x=\"599.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Persuasion em 0</text><text x=\"599.0\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">sobram 0, recusado</text></svg>", "caption": "Um contexto e um banco para a execução inteira, e uma glue nova para cada cenário. O estoque que cada cenário encontra é o que o anterior deixou, a não ser que o Given dele diga outra coisa."}
```

As três coisas de que os passos dependem vivem por três durações diferentes. O **contexto do
Spring** é iniciado uma vez, com o Tomcat na porta aleatória e o PostgreSQL no contêiner, e o Spring
o guarda num cache para qualquer classe de teste posterior que peça a mesma configuração. A **glue**
é criada de novo para cada cenário, então `token` e `lastOrder` começam vazios toda vez e nada que
um cenário deixou num campo vaza para o próximo. O **banco de dados** não é nem uma coisa nem outra:
ele vive tanto quanto o contexto, e nada o desfaz entre os cenários, porque toda escrita, inclusive
as dos próprios passos, foi confirmada no momento em que foi feita.

O cache vai além do Cucumber. Rode o `verify` inteiro e conte os contêineres:

```
ana@vm:~/bookshop$ PENDING
```

Três classes de teste de integração sobem um contêiner do PostgreSQL e um contexto próprio. O
`CucumberIT` não sobe nenhum dos dois: a configuração dele é igual à do `BooksApiIT`, então o Spring
lhe entregou o contexto que o `BooksApiIT` tinha deixado, com banco e tudo, inclusive o exemplar de
*The Time Machine* que um dos testes dele tinha acabado de pedir. Nesta execução o `BooksApiIT`
calhou de ir primeiro, e o Maven não promete ordem nenhuma. **É por isso que os passos `Given`
escrevem o estoque em vez de supor qual é**: um cenário que depende do estado que outro deixou passa
ou falha conforme quem rodou antes dele.
