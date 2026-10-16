---
title: Uma primeira feature
version: 1
---

**Um arquivo de feature é uma lista de cenários, e um cenário é uma lista de passos, cada um uma
palavra-chave e o seu argumento.** O Karate roda os passos de cima para baixo, e o primeiro que
falha encerra o cenário. Salve como `karate/src/test/java/boxoffice/shows.feature`:

```
Feature: The shows boxoffice lists

  Background:
    * url baseUrl

  Scenario: the list has three shows
    Given path 'v1', 'shows'
    When method get
    Then status 200
    And match header cache-control == 'max-age=60'
    And match response.shows == '#[3]'
    And match response.shows[*].id contains ['sh-101', 'sh-103']

  Scenario: one show by its id
    Given path 'v1', 'shows', 'sh-103'
    When method get
    Then status 200
    And match response.title == 'O Pagador de Promessas'
    And match response.price_cents == 6500

  Scenario: an unknown show is 404
    Given path 'v1', 'shows', 'sh-999'
    When method get
    Then status 404
    And match response.detail == 'there is no show sh-999'
```

Leia o primeiro cenário linha a linha:

| passo | o que o Karate faz |
|---|---|
| `Feature: …` | dá nome ao assunto do arquivo; o relatório o imprime |
| `Background:` | seus passos rodam de novo antes de cada cenário do arquivo |
| `* url baseUrl` | define o endereço, a partir da variável que o `karate-config.js` devolveu |
| `Scenario: …` | começa um teste; o nome dele é o que uma falha cita |
| `Given path 'v1', 'shows'` | acrescenta `/v1/shows` ao endereço, um segmento por argumento |
| `When method get` | manda a requisição; nada sai antes desta linha |
| `Then status 200` | reprova o cenário a não ser que o status seja `200` |
| `And match header cache-control == …` | compara um cabeçalho da resposta |
| `And match response.shows == '#[3]'` | `response` é o corpo, já interpretado; `#[3]` quer dizer um array de três |
| `And match … contains [ … ]` | os ids incluem estes dois, em qualquer ordem |

**`Given`, `When`, `Then` e `And` não fazem nada.** O Karate trata cada um exatamente como trata o
`*`, o marcador que o passo do `Background` usa. Eles estão ali para quem lê o cenário, então use-os
onde ajudam uma pessoa a acompanhá-lo e `*` onde um passo é encanamento, como definir o endereço. Os
segmentos de `path` vêm separados porque o Karate codifica cada um, então um id com um espaço ou uma
barra não consegue quebrar o endereço.

## Rodando

A esta altura o projeto tem quatro arquivos, e o boxoffice roda no próprio terminal como na lição 1:

```
ana@laptop:~/boxoffice$ find karate -type f | sort
karate/pom.xml
karate/src/test/java/boxoffice/BoxofficeTest.java
karate/src/test/java/boxoffice/shows.feature
karate/src/test/java/karate-config.js
```

```
ana@laptop:~/boxoffice$ cd karate
ana@laptop:~/boxoffice/karate$ mvn test
[INFO] Scanning for projects...
[INFO] 
[INFO] ---------------------< boxoffice:boxoffice-karate >---------------------
[INFO] Building boxoffice-karate 1.0
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-resources-plugin:2.6:resources (default-resources) @ boxoffice-karate ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] skip non existing resourceDirectory /home/ana/boxoffice/karate/src/main/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:compile (default-compile) @ boxoffice-karate ---
[INFO] No sources to compile
[INFO] 
[INFO] --- maven-resources-plugin:2.6:testResources (default-testResources) @ boxoffice-karate ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] Copying 2 resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:testCompile (default-testCompile) @ boxoffice-karate ---
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 1 source file with javac [debug release 21] to target/test-classes
[INFO] 
[INFO] --- maven-surefire-plugin:3.6.0:test (default-test) @ boxoffice-karate ---
[INFO] Using auto detected provider org.apache.maven.surefire.junitplatform.JUnitPlatformProvider
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running boxoffice.BoxofficeTest
SLF4J(W): No SLF4J providers were found.
SLF4J(W): Defaulting to no-operation (NOP) logger implementation
SLF4J(W): See https://www.slf4j.org/codes.html#noProviders for further details.
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.465 s -- in boxoffice.BoxofficeTest
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  2.287 s
[INFO] Finished at: 2026-10-10T22:48:42-03:00
[INFO] ------------------------------------------------------------------------
```

A parte do Maven é a da lição 7: recursos, o compilador, o Surefire. Duas linhas são novas. `Copying
2 resources` é o bloco `testResources` trabalhando, pondo no classpath a feature e a configuração,
os dois arquivos que não são Java; sem ele, o Karate não acharia feature nenhuma e não rodaria nada.
E as três linhas `SLF4J(W)` são um aviso da biblioteca de log pela qual o Karate escreve: não há
nenhum destino de log instalado, então o log do próprio Karate não vai a lugar nenhum. Isso não muda
nada nos resultados, e o relatório da seção 07 registra cada requisição de qualquer jeito.

**Uma classe JUnit, três testes.** O Surefire conta cada cenário como um teste do `BoxofficeTest`,
porque o método `@TestFactory` entregou ao JUnit um teste por cenário. Uma feature com dez cenários
soma dez a esse número, e uma feature que o Karate nunca encontrou não soma nada, que é o zero de
que a lição 7 avisou.
