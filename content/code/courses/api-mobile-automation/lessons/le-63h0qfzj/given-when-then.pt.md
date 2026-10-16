---
title: Given, when, then
version: 1
---

**Um teste do REST Assured é uma frase em três partes, e cada parte é uma parte de uma troca HTTP.**
`given()` descreve a requisição: para onde vai, os cabeçalhos, os parâmetros, o corpo. `when()` diz
o método e o caminho, e a envia. `then()` lista como a resposta tem de ser. As palavras vêm do jeito
como testadores escreviam comportamento muito antes desta biblioteca existir. O REST Assured as
pegou emprestadas para que um teste se leia na ordem em que uma pessoa pensa nele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Um teste do REST Assured tem três partes. given() descreve a requisição e when() a envia, como GET /v1/shows?date=… ao boxoffice. O boxoffice responde com um status, cabeçalhos e JSON, e then() confere essa resposta.\"><defs><marker id=\"f07chain-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"95\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">no teste</text><text x=\"330\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">na rede</text><rect x=\"20\" y=\"30\" width=\"150\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">given()</text><text x=\"95\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">descreve a requisição</text><rect x=\"20\" y=\"100\" width=\"150\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">when()</text><text x=\"95\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">método, caminho: envia</text><rect x=\"20\" y=\"170\" width=\"150\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">then()</text><text x=\"95\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">confere a resposta</text><rect x=\"230\" y=\"46\" width=\"200\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"330\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a requisição</text><text x=\"330\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">GET /v1/shows?date=…</text><rect x=\"230\" y=\"150\" width=\"200\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"330\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a resposta</text><text x=\"330\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">200 · headers · JSON</text><rect x=\"530\" y=\"98\" width=\"150\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"605\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">servidor</text><text x=\"605\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">boxoffice</text><line x1=\"170\" y1=\"53\" x2=\"228\" y2=\"66\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f07chain-ah)\"></line><line x1=\"170\" y1=\"123\" x2=\"228\" y2=\"86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f07chain-ah)\"></line><line x1=\"430\" y1=\"73\" x2=\"528\" y2=\"112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f07chain-ah)\"></line><line x1=\"528\" y1=\"138\" x2=\"432\" y2=\"177\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f07chain-ah)\"></line><line x1=\"228\" y1=\"182\" x2=\"172\" y2=\"192\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f07chain-ah)\"></line><text x=\"330\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma verificação que falha para o teste naquela linha</text></svg>", "caption": "given() e when() montam e enviam a requisição; then() confere o que voltou."}
```

## Uma classe de testes para os espetáculos

Cinco testes da parte pública do boxoffice, a parte que a lição 1 leu com o curl. Salve como `restassured/src/test/java/boxoffice/ShowsTest.java`:

```java
package boxoffice;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.everyItem;
import static org.hamcrest.Matchers.greaterThan;
import static org.hamcrest.Matchers.hasItems;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.matchesPattern;

import io.restassured.http.ContentType;
import org.junit.jupiter.api.Test;

class ShowsTest {

    static final String BASE = "http://localhost:8080";

    @Test
    void theListHasThreeShows() {
        given()
            .baseUri(BASE)
        .when()
            .get("/v1/shows")
        .then()
            .statusCode(200)
            .contentType(ContentType.JSON)
            .header("cache-control", "max-age=60")
            .body("shows", hasSize(3))
            .body("shows.id", hasItems("sh-101", "sh-102", "sh-103"))
            .body("shows.price_cents", everyItem(greaterThan(0)));
    }

    @Test
    void aDateNarrowsTheList() {
        given()
            .baseUri(BASE)
            .queryParam("date", "2026-11-08")
        .when()
            .get("/v1/shows")
        .then()
            .statusCode(200)
            .body("shows.id", contains("sh-103"));
    }

    @Test
    void oneShowByItsId() {
        given()
            .baseUri(BASE)
        .when()
            .get("/v1/shows/{id}", "sh-103")
        .then()
            .statusCode(200)
            .header("etag", matchesPattern("\"[0-9a-f]{16}\""))
            .body("title", equalTo("O Pagador de Promessas"))
            .body("starts_at", equalTo("2026-11-08T18:00:00-03:00"))
            .body("price_cents", equalTo(6500));
    }

    @Test
    void theCheapestShowIsFoundWithGPath() {
        given()
            .baseUri(BASE)
        .when()
            .get("/v1/shows")
        .then()
            .body("shows.findAll { it.price_cents < 7000 }.id", contains("sh-103"))
            .body("shows.min { it.price_cents }.title", equalTo("O Pagador de Promessas"));
    }

    @Test
    void anUnknownShowIs404WithAProblem() {
        given()
            .baseUri(BASE)
        .when()
            .get("/v1/shows/{id}", "sh-999")
        .then()
            .statusCode(404)
            .contentType("application/problem+json")
            .body("status", equalTo(404))
            .body("detail", equalTo("there is no show sh-999"));
    }
}
```

Aqui estão as peças que valem uma leitura devagar, com o que cada uma faz:

```schooling-example
{
 "language": "java",
 "file": "ShowsTest.java",
 "parts": [
  {
   "code": "    @Test\n    void aDateNarrowsTheList() {\n        given()\n            .baseUri(BASE)\n            .queryParam(\"date\", \"2026-11-08\")",
   "note": "`given` é a requisição antes de sair: o servidor para onde vai e, aqui, um parâmetro de consulta. O REST Assured escreve `?date=2026-11-08` no caminho por você."
  },
  {
   "code": "        .when()\n            .get(\"/v1/shows\")",
   "note": "`when` é o método e o caminho. É esta linha que manda a requisição; tudo acima dela só a descreveu."
  },
  {
   "code": "        .then()\n            .statusCode(200)\n            .body(\"shows.id\", contains(\"sh-103\"));\n    }",
   "note": "`then` é a lista de verificações sobre a resposta, em ordem. A primeira que falha para o teste, e a mensagem diz qual foi."
  },
  {
   "code": "    @Test\n    void oneShowByItsId() {\n        given()\n            .baseUri(BASE)\n        .when()\n            .get(\"/v1/shows/{id}\", \"sh-103\")",
   "note": "Um `{id}` no caminho é preenchido com o argumento que vem depois. O relatório então mostra o modelo, que é mais fácil de ler que um caminho com o id colado."
  },
  {
   "code": "        .then()\n            .statusCode(200)\n            .header(\"etag\", matchesPattern(\"\\\"[0-9a-f]{16}\\\"\"))\n            .body(\"title\", equalTo(\"O Pagador de Promessas\"))",
   "note": "`header` confere um cabeçalho pelo nome, sem ligar para maiúsculas. `body` recebe um caminho dentro do JSON e um matcher do Hamcrest que diz o que o valor ali precisa satisfazer."
  },
  {
   "code": "            .body(\"shows.findAll { it.price_cents < 7000 }.id\", contains(\"sh-103\"))\n            .body(\"shows.min { it.price_cents }.title\", equalTo(\"O Pagador de Promessas\"));",
   "note": "O caminho é GPath, a linguagem do Groovy para percorrer JSON. `findAll` mantém os itens que as chaves aceitam, `it` é o item sendo testado, e `min` escolhe o menor pelo que as chaves calculam."
  }
 ]
}
```

## Os matchers

O segundo argumento de `body` e de `header` é um **matcher** do Hamcrest, uma biblioteca pequena
que vem com o REST Assured. Um matcher é uma descrição do que um valor precisa satisfazer, e quando
o valor não satisfaz, é o matcher que escreve a mensagem. Estes são os que esta lição usa:

| matcher | passa quando o valor | falha com |
|---|---|---|
| `equalTo(6500)` | é exatamente aquele, daquele tipo | `"6500"`, um texto |
| `hasSize(3)` | é uma lista de exatamente três | quatro espetáculos |
| `hasItems("sh-101", "sh-103")` | é uma lista com pelo menos estes, em qualquer ordem | uma lista sem `sh-103` |
| `contains("sh-103")` | é uma lista exatamente destes, nesta ordem | `["sh-103", "sh-104"]` |
| `everyItem(greaterThan(0))` | é uma lista em que cada item passa no matcher de dentro | um preço `0` |
| `startsWith("/v1/orders/")` | é um texto que começa assim | `/orders/ord-1001` |
| `containsString("expired")` | é um texto com aquilo dentro | um cabeçalho vazio |
| `matchesPattern(…)` | é um texto que a expressão regular casa inteiro | um `etag` sem aspas |

**`contains` é o que as pessoas leem errado.** O nome soa como "tem isto entre outros", que é o
`hasItems`. `contains` quer dizer a lista inteira, em ordem, e nada mais, então é o estrito. É o
certo para `aDateNarrowsTheList`: um filtro de data que também devolvesse o `sh-101` seria um
defeito, e `hasItems("sh-103")` o deixaria passar.

Repare no que a classe não confere. **Nenhum teste lê o `seats_left` do `sh-101`**, porque os
testes de pedidos da seção 05 compram lugares desse espetáculo, e o que ele diz depois depende de
quais testes rodaram antes. A lição 12 trata de testes que compartilham estado assim; a defesa mais
barata é não afirmar o que outro teste muda.

## Rodando uma classe, e lendo uma falha

`-Dtest=ShowsTest` roda só aquela classe, e `-q`, de quiet, esconde o progresso do Maven para que só
os problemas apareçam:

```
ana@laptop:~/boxoffice/restassured$ mvn -q test -Dtest=ShowsTest
ana@laptop:~/boxoffice/restassured$ echo $?
0
```

**Silêncio é aprovação**, e o código de saída confirma: `0`. Um teste só vale alguma coisa se pode
falhar, então faça-o falhar uma vez de propósito. Troque `hasSize(3)` por `hasSize(4)` no primeiro
teste e rode o mesmo comando:

```
ana@laptop:~/boxoffice/restassured$ mvn -q test -Dtest=ShowsTest
[ERROR] Tests run: 5, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 2.232 s <<< FAILURE! -- in boxoffice.ShowsTest
[ERROR] boxoffice.ShowsTest.theListHasThreeShows -- Time elapsed: 0.050 s <<< FAILURE!
java.lang.AssertionError: 
1 expectation failed.
JSON path shows doesn't match.
Expected: a collection with size <4>
  Actual: <[{id=sh-101, title=Auto da Compadecida, starts_at=2026-11-06T20:00:00-03:00, price_cents=8000, seats_left=120}, {id=sh-102, title=Auto da Compadecida, starts_at=2026-11-07T20:00:00-03:00, price_cents=8000, seats_left=120}, {id=sh-103, title=O Pagador de Promessas, starts_at=2026-11-08T18:00:00-03:00, price_cents=6500, seats_left=4}]>

	at org.codehaus.groovy.vmplugin.v8.IndyInterface.fromCache(IndyInterface.java:344)
	at io.restassured.internal.ResponseSpecificationImpl$HamcrestAssertionClosure.validate(ResponseSpecificationImpl.groovy:516)
	at org.codehaus.groovy.vmplugin.v8.IndyInterface.fromCache(IndyInterface.java:344)
	at io.restassured.internal.ResponseSpecificationImpl.validateResponseIfRequired(ResponseSpecificationImpl.groovy:714)
	at org.codehaus.groovy.vmplugin.v8.IndyInterface.fromCache(IndyInterface.java:344)
	at io.restassured.internal.ResponseSpecificationImpl.body(ResponseSpecificationImpl.groovy:274)
	at org.codehaus.groovy.vmplugin.v8.IndyInterface.selectMethod(IndyInterface.java:373)
	at org.codehaus.groovy.vmplugin.v8.IndyInterface.fromCache(IndyInterface.java:344)
	at io.restassured.internal.ResponseSpecificationImpl.body(ResponseSpecificationImpl.groovy:121)
	at io.restassured.internal.ValidatableResponseOptionsImpl.body(ValidatableResponseOptionsImpl.java:244)
	at boxoffice.ShowsTest.theListHasThreeShows(ShowsTest.java:29)

[ERROR] Failures: 
[ERROR]   ShowsTest.theListHasThreeShows:29 1 expectation failed.
JSON path shows doesn't match.
Expected: a collection with size <4>
  Actual: <[{id=sh-101, title=Auto da Compadecida, starts_at=2026-11-06T20:00:00-03:00, price_cents=8000, seats_left=120}, {id=sh-102, title=Auto da Compadecida, starts_at=2026-11-07T20:00:00-03:00, price_cents=8000, seats_left=120}, {id=sh-103, title=O Pagador de Promessas, starts_at=2026-11-08T18:00:00-03:00, price_cents=6500, seats_left=4}]>

[ERROR] Tests run: 5, Failures: 1, Errors: 0, Skipped: 0
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
```

Leia a partir da linha que cita o seu arquivo. `ShowsTest.theListHasThreeShows:29` é o teste e a
linha da verificação que falhou. A mensagem acima diz o resto: o matcher esperava
`a collection with size <4>`, e o valor real é a lista dos três espetáculos. Ela vem impressa
inteira, para você ver o que voltou sem rodar mais nada. As linhas que começam com `at org.codehaus`
são a maquinaria do próprio REST Assured, e você pode pulá-las. Volte o `3` antes de continuar.
