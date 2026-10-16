---
title: Rodando a suíte, e o build que não rodou nada
version: 1
---

**`mvn test` roda toda classe de teste que o projeto tem, e uma falha é a parte da saída que vale
ler.** Esta seção acrescenta o teste que falha, lê o que ele imprime e acha os relatórios que um
pipeline lê. Depois remove dois blocos do `pom.xml` para mostrar o resultado mais perigoso que uma
execução de testes pode dar: um sucesso que não testou nada.

## O teste que falha de propósito

A lição 1 descobriu que o boxoffice responde `HEAD` com `405`, quando o padrão diz que um servidor
tem de respondê-lo como um `GET`. Como teste, salve como `restassured/src/test/java/boxoffice/HeadTest.java`:

```java
package boxoffice;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;

import org.junit.jupiter.api.Test;

// RFC 9110, §9.1: a general-purpose server must answer HEAD like GET.
// boxoffice does not, so this test fails until the server is fixed.
class HeadTest {

    @Test
    void headAnswersLikeGet() {
        given()
            .spec(Api.ANYONE)
        .when()
            .head("/v1/shows/{id}", "sh-103")
        .then()
            .statusCode(200)
            .header("content-type", equalTo("application/json"));
    }
}
```

O comentário no topo diz por que o teste existe e por que falha, para que a próxima pessoa que o vir
vermelho não o "conserte" esperando `405`. Agora rode tudo, e depois peça o código de saída:

```
ana@laptop:~/boxoffice/restassured$ mvn -q test
Request method:	HEAD
Request URI:	http://localhost:8080/v1/shows/sh-103
Proxy:			<none>
Request params:	<none>
Query params:	<none>
Form params:	<none>
Path params:	<none>
Headers:		Accept=*/*
Cookies:		<none>
Multiparts:		<none>
Body:			<none>

HTTP/1.1 405 Method Not Allowed
content-type: application/problem+json
allow: GET
Date: Sat, 10 Oct 2026 19:45:07 GMT
Connection: keep-alive
Keep-Alive: timeout=5
[ERROR] Tests run: 1, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 1.730 s <<< FAILURE! -- in boxoffice.HeadTest
[ERROR] boxoffice.HeadTest.headAnswersLikeGet -- Time elapsed: 1.694 s <<< FAILURE!
java.lang.AssertionError: 
1 expectation failed.
Expected status code <200> but was <405>.

	at org.codehaus.groovy.vmplugin.v8.IndyInterface.fromCache(IndyInterface.java:344)
	at io.restassured.internal.ResponseSpecificationImpl$HamcrestAssertionClosure.validate(ResponseSpecificationImpl.groovy:516)
	at org.codehaus.groovy.vmplugin.v8.IndyInterface.fromCache(IndyInterface.java:344)
	at io.restassured.internal.ResponseSpecificationImpl.validateResponseIfRequired(ResponseSpecificationImpl.groovy:714)
	at org.codehaus.groovy.vmplugin.v8.IndyInterface.fromCache(IndyInterface.java:344)
	at io.restassured.internal.ResponseSpecificationImpl.statusCode(ResponseSpecificationImpl.groovy:139)
	at org.codehaus.groovy.vmplugin.v8.IndyInterface.fromCache(IndyInterface.java:344)
	at io.restassured.internal.ResponseSpecificationImpl.statusCode(ResponseSpecificationImpl.groovy:147)
	at io.restassured.internal.ValidatableResponseOptionsImpl.statusCode(ValidatableResponseOptionsImpl.java:89)
	at boxoffice.HeadTest.headAnswersLikeGet(HeadTest.java:19)

[ERROR] Failures: 
[ERROR]   HeadTest.headAnswersLikeGet:19 1 expectation failed.
Expected status code <200> but was <405>.

[ERROR] Tests run: 11, Failures: 1, Errors: 0, Skipped: 0
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-surefire-plugin:3.6.0:test (default-test) on project boxoffice-api-tests: There are test failures.
[ERROR] 
[ERROR] See /home/ana/boxoffice/restassured/target/surefire-reports for the individual test results.
[ERROR] See dump files (if any exist) [date].dump, [date]-jvmRun[N].dump and [date].dumpstream.
[ERROR] -> [Help 1]
[ERROR] 
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR] 
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoFailureException
ana@laptop:~/boxoffice/restassured$ echo $?
1
```

Leia em quatro blocos, de cima para baixo:

1. A requisição e a resposta, impressas porque o `HeadTest` usa `Api.ANYONE` e uma verificação
   falhou. `Request method: HEAD` e o URI são o que foi mandado; `HTTP/1.1 405 Method Not Allowed`
   com `allow: GET` é o que voltou. É a evidência de que um relatório de defeito precisa, produzida
   pela própria execução que falhou.
2. A falha: `Expected status code <200> but was <405>`, e embaixo o stack trace. Procure a única
   linha que cita o seu arquivo, `HeadTest.java:19`, e pule o resto.
3. O resumo: `Tests run: 11, Failures: 1`. Onze são um no `HealthTest`, cinco no `ShowsTest`, quatro
   no `OrdersTest` e este.
4. O código de saída, `1`. Um pipeline lê esse número e mais nada, e é assim que um teste vermelho
   barra um merge, como a lição 6 fez com o Newman.

Uma **failure** é uma verificação que não se confirmou. O Maven também conta **errors**, um teste
que nem conseguiu terminar, como um cujo servidor não estava rodando: a requisição lança uma exceção
antes de qualquer verificação. Os dois deixam o build vermelho, e apontam para lugares diferentes:
uma failure para a resposta do servidor, um error em geral para o laboratório.

## Os relatórios

O Surefire escreve dois arquivos por classe em `target/surefire-reports`:

```
ana@laptop:~/boxoffice/restassured$ ls target/surefire-reports
TEST-boxoffice.HeadTest.xml    boxoffice.HeadTest.txt
TEST-boxoffice.HealthTest.xml  boxoffice.HealthTest.txt
TEST-boxoffice.OrdersTest.xml  boxoffice.OrdersTest.txt
TEST-boxoffice.ShowsTest.xml   boxoffice.ShowsTest.txt
ana@laptop:~/boxoffice/restassured$ grep '<testcase' target/surefire-reports/TEST-boxoffice.OrdersTest.xml
  <testcase name="theAuditorMayReadButNotBuy" classname="boxoffice.OrdersTest" time="0.067"/>
  <testcase name="noTokenIs401AndSaysWhy" classname="boxoffice.OrdersTest" time="0.039"/>
  <testcase name="sevenSeatsAreRefused" classname="boxoffice.OrdersTest" time="0.061"/>
  <testcase name="anOrderCanBeReadBack" classname="boxoffice.OrdersTest" time="0.118"/>
```

Os arquivos `.txt` são o resumo que você leu acima. Os arquivos `TEST-….xml` estão no formato JUnit
XML, o mesmo que a lição 6 pediu ao Newman. Um servidor de CI o lê para desenhar a lista de testes:
um `<testcase>` por método, com um `<failure>` dentro dos que falharam. A ordem deles aqui é a ordem
em que os testes rodaram, que de novo não é a ordem do arquivo.

Para rodar menos que tudo, `-Dtest` aceita uma classe, ou uma classe e um método depois de `#`:

```
ana@laptop:~/boxoffice/restassured$ mvn -q test -Dtest='OrdersTest#sevenSeatsAreRefused'
ana@laptop:~/boxoffice/restassured$ echo $?
0
```

## Um build verde que não rodou nada

Os dois blocos `<plugin>` do `pom.xml` parecem enfeite, e a arrumação óbvia é apagá-los. Isto é o
que o Maven do Ubuntu faz com este projeto quando o bloco do Surefire some:

```
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
[INFO] Nothing to compile - all classes are up to date.
[INFO] 
[INFO] --- maven-surefire-plugin:2.12.4:test (default-test) @ boxoffice-api-tests ---
[INFO] Surefire report directory: /home/ana/boxoffice/restassured/target/surefire-reports

-------------------------------------------------------
 T E S T S
-------------------------------------------------------

Results :

Tests run: 0, Failures: 0, Errors: 0, Skipped: 0

[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.083 s
[INFO] Finished at: 2026-10-10T16:45:16-03:00
[INFO] ------------------------------------------------------------------------
ana@laptop:~/boxoffice/restassured$ echo $?
0
```

**`Tests run: 0`, e o código de saída é `0`.** O `HeadTest` continua no projeto e deveria falhar, e
nada falhou, porque nada rodou. Sem versão citada, o Maven 3.8.7 roda o Surefire antigo com que foi
construído, que é anterior ao JUnit Jupiter e não acha nenhum destes testes. Ele não reclama disso;
informa, corretamente, que zero testes falharam.

Remova também o bloco do compilador, o `<build>` inteiro, e rode de novo:

```
ana@laptop:~/boxoffice/restassured$ mvn -q test

-------------------------------------------------------
 T E S T S
-------------------------------------------------------

Results :

Tests run: 0, Failures: 0, Errors: 0, Skipped: 0
```

O mesmo zero, e desta vez ele esconde um segundo problema. As classes compiladas nas execuções
anteriores continuam em `target`, então o plugin de compilador antigo decide que não há nada a
fazer. `clean` apaga o `target` antes, que é de onde um checkout novo na máquina do pipeline parte
de qualquer jeito:

```
ana@laptop:~/boxoffice/restassured$ mvn -q clean test
[ERROR] COMPILATION ERROR : 
[ERROR] Source option 5 is no longer supported. Use 8 or later.
[ERROR] Target option 5 is no longer supported. Use 8 or later.
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.1:testCompile (default-testCompile) on project boxoffice-api-tests: Compilation failure: Compilation failure: 
[ERROR] Source option 5 is no longer supported. Use 8 or later.
[ERROR] Target option 5 is no longer supported. Use 8 or later.
[ERROR] -> [Help 1]
[ERROR] 
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR] 
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoFailureException
ana@laptop:~/boxoffice/restassured$ echo $?
1
```

Agora falha alto: o plugin de compilador antigo pede ao Java para compilar para o Java 5, que o Java
21 não aceita mais.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 228\" role=\"img\" aria-label=\"Sem versão do Surefire no pom.xml, o Maven 3.8.7 roda o Surefire 2.12.4, que não acha nenhum teste JUnit Jupiter e informa Tests run: 0 com código de saída 0. Com a versão 3.6.0 fixada, o Surefire roda os onze testes e informa Tests run: 11 com código de saída 1, porque o HeadTest falha.\"><defs><marker id=\"f07plugins-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"350\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">os mesmos onze testes, o mesmo Maven 3.8.7</text><rect x=\"20\" y=\"40\" width=\"160\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"100\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pom.xml sem versão</text><rect x=\"250\" y=\"40\" width=\"180\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"340\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">surefire 2.12.4</text><text x=\"340\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não acha teste JUnit Jupiter</text><rect x=\"500\" y=\"40\" width=\"180\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"590\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Tests run: 0</text><text x=\"590\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">código de saída 0: verde</text><line x1=\"180\" y1=\"67\" x2=\"248\" y2=\"67\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f07plugins-ah)\"></line><line x1=\"430\" y1=\"67\" x2=\"498\" y2=\"67\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f07plugins-ah)\"></line><rect x=\"20\" y=\"130\" width=\"160\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"100\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pom.xml fixa 3.6.0</text><rect x=\"250\" y=\"130\" width=\"180\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"340\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">surefire 3.6.0</text><text x=\"340\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">roda o JUnit Jupiter</text><rect x=\"500\" y=\"130\" width=\"180\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Tests run: 11</text><text x=\"590\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">código de saída 1: vermelho</text><line x1=\"180\" y1=\"157\" x2=\"248\" y2=\"157\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f07plugins-ah)\"></line><line x1=\"430\" y1=\"157\" x2=\"498\" y2=\"157\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f07plugins-ah)\"></line><text x=\"350\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">só o segundo resultado é verdadeiro: o HeadTest deveria falhar</text></svg>", "caption": "Sem um Surefire fixado, o build fica verde porque nada rodou."}
```

Um Maven mais novo traz plugins padrão mais novos, e esses acham os testes. Isso não torna as
versões fixas desnecessárias. Quer dizer que o resultado do mesmo projeto depende de qual Maven está
instalado, no seu notebook, no de um colega e na máquina do pipeline. **Leia a contagem de testes,
nunca só a cor do build.** Uma suíte de onze testes que informa zero é uma suíte quebrada. Conferir
esse número é o hábito que a pega no dia em que alguém arruma um `pom.xml`.
