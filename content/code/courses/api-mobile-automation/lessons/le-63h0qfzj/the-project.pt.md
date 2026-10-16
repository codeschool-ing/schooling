---
title: Um projeto Maven e o primeiro teste
version: 1
---

**Um projeto Maven é um diretório com um `pom.xml` no topo e o código embaixo, onde o Maven
espera encontrá-lo.** Os testes desta lição moram em `~/boxoffice/restassured`, ao lado do
boxoffice e separados da coleção das lições 4 a 6, para que cada ferramenta fique com os próprios
arquivos. Crie os diretórios de que o primeiro teste precisa:

```sh
cd ~/boxoffice
mkdir -p restassured/src/test/java/boxoffice
```

## O `pom.xml`

O POM, o modelo de objeto do projeto, diz como o projeto se chama, do que depende e como é
construído. Salve como `restassured/pom.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>boxoffice</groupId>
  <artifactId>boxoffice-api-tests</artifactId>
  <version>1.0</version>

  <properties>
    <maven.compiler.release>21</maven.compiler.release>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>

  <dependencies>
    <dependency>
      <groupId>io.rest-assured</groupId>
      <artifactId>rest-assured</artifactId>
      <version>6.0.1</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter</artifactId>
      <version>6.1.3</version>
      <scope>test</scope>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>3.15.0</version>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>3.6.0</version>
      </plugin>
    </plugins>
  </build>
</project>
```

Leia de cima para baixo:

- **as coordenadas**, `groupId`, `artifactId` e `version`, dão nome a este projeto do mesmo jeito
  que as dependências abaixo têm nome. Ninguém o baixa; elas só precisam estar ali.
- **as propriedades** dizem que o código é Java 21 e os arquivos são UTF-8, para que `São Paulo`
  num teste signifique o mesmo em qualquer máquina.
- **as dependências** são as duas bibliotecas que os testes usam. O REST Assured manda as
  requisições e confere as respostas; o JUnit Jupiter é o framework de testes, que acha os métodos
  marcados como teste e os roda. `<scope>test</scope>` diz que elas existem só para os testes, que
  neste projeto são tudo o que há.
- **os plugins** fixam as versões dos dois plugins que compilam e rodam os testes. A seção 07 os
  remove e mostra o que dá errado.

| o quê | versão | o que faz aqui |
|---|---|---|
| `io.rest-assured:rest-assured` | 6.0.1 | manda uma requisição, confere a resposta |
| `org.junit.jupiter:junit-jupiter` | 6.1.3 | acha e roda os métodos de teste |
| `maven-compiler-plugin` | 3.15.0 | compila os testes como Java 21 |
| `maven-surefire-plugin` | 3.6.0 | roda os testes, escreve os relatórios |

Toda versão foi resolvida no Maven Central quando as transcrições foram gravadas, em outubro de
2026, e elas estão escritas por inteiro de propósito. **Uma versão escrita por inteiro é um build
que faz a mesma coisa no ano que vem**; uma versão deixada como "a mais nova que houver" é um build
que muda quando outra pessoa publica algo. O REST Assured 6.1.0 saiu na véspera da gravação e não
foi testado.

## O primeiro teste

Um teste, o menor que prova que a corrente funciona: o boxoffice está no ar e diz isso. Escreva no
seu editor e salve como `restassured/src/test/java/boxoffice/HealthTest.java`:

```java
package boxoffice;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;

import org.junit.jupiter.api.Test;

class HealthTest {

    @Test
    void healthAnswersOk() {
        given()
            .baseUri("http://localhost:8080")
        .when()
            .get("/health")
        .then()
            .statusCode(200)
            .body("status", equalTo("ok"));
    }
}
```

**O caminho segue uma convenção de que toda ferramenta Java depende.** O arquivo começa com
`package boxoffice;`, então fica num diretório chamado `boxoffice`, embaixo de `src/test/java`
porque é um teste, e tem o nome da classe que contém. O Surefire então roda as classes cujo nome
termina em `Test`, entre alguns outros padrões. Uma classe de teste chamada `HealthCheck` compila e
nunca roda, e nada imprime um erro sobre isso.

## Lendo como Java

Você precisa de muito pouco Java para ler um teste, e está tudo naquele arquivo:

| no arquivo | o que é |
|---|---|
| `package boxoffice;` | o grupo a que esta classe pertence, igual ao diretório |
| `import static io.restassured.RestAssured.given;` | deixa o arquivo escrever `given()` em vez de `RestAssured.given()` |
| `class HealthTest { … }` | a classe, um recipiente para os testes; as chaves marcam onde começa e termina |
| `@Test` | uma anotação: diz ao JUnit que o método abaixo é um teste |
| `void healthAnswersOk() { … }` | um método que não devolve nada; o nome é o que um relatório imprime, então diz o que é conferido |
| `"http://localhost:8080"` | uma `String`, texto entre aspas duplas |
| `.when()`, `.get(…)` em linhas novas | uma expressão longa, cada chamada trabalhando sobre o que a de cima devolveu |
| `;` | o fim da instrução, depois da última chamada |

As chamadas dispostas uma por linha, recuadas conforme aquilo a que pertencem, são o estilo da casa
do REST Assured, e a próxima seção as lê. Por ora, confira que a corrente roda. O boxoffice roda no
próprio terminal, como na lição 1; no seu primeiro terminal, a partir de `~/boxoffice`:

```
ana@laptop:~/boxoffice$ find restassured -type f
restassured/src/test/java/boxoffice/HealthTest.java
restassured/pom.xml
```

```
ana@laptop:~/boxoffice$ cd restassured
ana@laptop:~/boxoffice/restassured$ mvn test
[INFO] Scanning for projects...
[INFO] 
[INFO] -------------------< boxoffice:boxoffice-api-tests >--------------------
[INFO] Building boxoffice-api-tests 1.0
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-resources-plugin:2.6:resources (default-resources) @ boxoffice-api-tests ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] skip non existing resourceDirectory /home/ana/boxoffice/restassured/src/main/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:compile (default-compile) @ boxoffice-api-tests ---
[INFO] No sources to compile
[INFO] 
[INFO] --- maven-resources-plugin:2.6:testResources (default-testResources) @ boxoffice-api-tests ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] skip non existing resourceDirectory /home/ana/boxoffice/restassured/src/test/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:testCompile (default-testCompile) @ boxoffice-api-tests ---
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 1 source file with javac [debug release 21] to target/test-classes
[INFO] 
[INFO] --- maven-surefire-plugin:3.6.0:test (default-test) @ boxoffice-api-tests ---
[INFO] Using auto detected provider org.apache.maven.surefire.junitplatform.JUnitPlatformProvider
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running boxoffice.HealthTest
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 1.878 s -- in boxoffice.HealthTest
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  4.098 s
[INFO] Finished at: 2026-10-10T16:44:37-03:00
[INFO] ------------------------------------------------------------------------
```

O primeiro `mvn test` numa máquina nova **baixa o REST Assured, o JUnit, os dois plugins e tudo de
que eles dependem**, o que enche a tela de linhas `Downloading from central` e demora um pouco. A transcrição foi gravada com tudo isso já em `~/.m2`, então mostra o que toda execução
seguinte imprime. Leia pelo meio: os plugins rodam na ordem em que as fases precisam deles,
recursos, depois o compilador, depois o Surefire, e embaixo de `T E S T S` uma classe rodou um
teste sem falhas. `BUILD SUCCESS` é o veredito do Maven sobre a execução inteira.
