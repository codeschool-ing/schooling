---
title: O mesmo schema no Postman e no REST Assured
version: 1
---

**Um arquivo de schema foi feito para ser compartilhado: a conferência em Node, a coleção do Postman e
os testes em Java podem ler o mesmo.** O que eles não conseguem todos é entendê-lo do mesmo jeito,
porque cada ferramenta traz o próprio validador e cada validador implementa o próprio draft de JSON
Schema. Vale descobrir isso de propósito, porque uma das duas ferramentas abaixo falha alto e a outra
não.

## Postman e Newman

Os scripts de teste do Postman afirmam um schema numa linha, `pm.response.to.have.jsonSchema(schema)`.
Um script não lê arquivo do disco, nem no app nem no Newman, então o schema viaja dentro da coleção,
como texto de uma variável de coleção. Esta coleção guarda o `schemas/show.json` na variável
`showSchema`, e duas requisições que conferem contra ele.
Salve como `postman/schemas.postman_collection.json`:

```json
{
  "info": {
    "name": "boxoffice schemas",
    "description": "The JSON schemas of lesson 10, checked inside Postman and Newman.",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "One show",
      "event": [
        {
          "listen": "test",
          "script": {
            "type": "text/javascript",
            "exec": [
              "const show = JSON.parse(pm.collectionVariables.get('showSchema'));",
              "pm.test('the show matches schemas/show.json', () => {",
              "  pm.response.to.have.jsonSchema(show);",
              "});"
            ]
          }
        }
      ],
      "request": {
        "method": "GET",
        "url": "{{baseUrl}}/v1/shows/sh-103"
      }
    },
    {
      "name": "List shows",
      "event": [
        {
          "listen": "test",
          "script": {
            "type": "text/javascript",
            "exec": [
              "const show = JSON.parse(pm.collectionVariables.get('showSchema'));",
              "pm.test('every show in the list matches schemas/show.json', () => {",
              "  pm.response.to.have.jsonSchema({",
              "    type: 'object', required: ['shows'],",
              "    properties: { shows: { type: 'array', items: show } },",
              "  });",
              "});"
            ]
          }
        }
      ],
      "request": {
        "method": "GET",
        "url": "{{baseUrl}}/v1/shows"
      }
    }
  ],
  "variable": [
    {
      "key": "showSchema",
      "value": "{\"$schema\":\"https://json-schema.org/draft/2020-12/schema\",\"$id\":\"https://boxoffice.example/schemas/show.json\",\"title\":\"Show\",\"description\":\"One show, as GET /v1/shows/{id} answers it.\",\"type\":\"object\",\"required\":[\"id\",\"title\",\"starts_at\",\"price_cents\",\"seats_left\"],\"additionalProperties\":false,\"properties\":{\"id\":{\"type\":\"string\",\"pattern\":\"^sh-[0-9]+$\"},\"title\":{\"type\":\"string\",\"minLength\":1},\"starts_at\":{\"type\":\"string\",\"format\":\"date-time\"},\"price_cents\":{\"type\":\"integer\",\"minimum\":0},\"seats_left\":{\"type\":\"integer\",\"minimum\":0}}}"
    }
  ]
}
```

No app do Postman ela é importada como a coleção da lição 4, e a variável fica na aba *Variables* da
coleção. O app não foi rodado para este curso. Rode com o Newman que a lição 6 instalou, contra o
ambiente do laboratório:

```
ana@laptop:~/boxoffice$ npx newman run postman/schemas.postman_collection.json -e postman/lab.postman_environment.json --disable-unicode
newman

boxoffice schemas

Root One show
  GET http://localhost:8080/v1/shows/sh-103 [200 OK, 312B, 26ms]
  1. the show matches schemas/show.json

Root List shows
  GET http://localhost:8080/v1/shows [200 OK, 569B, 4ms]
  Pass  every show in the list matches schemas/show.json

-----------------------------------------------------------------
|                         |         executed |           failed |
--------------------------+------------------+-------------------
|              iterations |                1 |                0 |
--------------------------+------------------+-------------------
|                requests |                2 |                0 |
--------------------------+------------------+-------------------
|            test-scripts |                2 |                0 |
--------------------------+------------------+-------------------
|      prerequest-scripts |                0 |                0 |
--------------------------+------------------+-------------------
|              assertions |                2 |                1 |
-----------------------------------------------------------------
| total run duration: 137ms                                     |
-----------------------------------------------------------------
| total data received: 502B (approx)                            |
-----------------------------------------------------------------
| average response time: 15ms [min: 4ms, max: 26ms, s.d.: 11ms] |
-----------------------------------------------------------------

  #  failure  detail                                                                   
                                                                                       
 1.  Error    the show matches schemas/show.json                                       
              no schema with key or ref "https://json-schema.org/draft/2020-12/schema" 
              at assertion:0 in test-script                                            
              inside "One show"                                                        
ana@laptop:~/boxoffice$ echo $?
1
```

**`no schema with key or ref "https://json-schema.org/draft/2020-12/schema"`.** O validador dentro do
Postman conhece os drafts até o draft-07, e quando a linha `$schema` cita um que ele não tem, ele
recusa o schema de uma vez. A segunda requisição só passou porque o `$schema` estava dentro de um
schema aninhado, onde esse validador o ignora.

Os schemas desta lição não usam nada que falte no draft-07, então a correção é tirar a linha antes de
afirmar. Acrescente esta linha depois do `JSON.parse` em cada um dos dois scripts:

```js
delete show.$schema; // Postman's validator knows draft-07, not 2020-12
```

```
ana@laptop:~/boxoffice$ npx newman run postman/schemas.postman_collection.json -e postman/lab.postman_environment.json --disable-unicode | grep -E 'Pass|^  [0-9]+\.|assertions'
  Pass  the show matches schemas/show.json
  Pass  every show in the list matches schemas/show.json
|              assertions |               2 |               0 |
ana@laptop:~/boxoffice$ cd restassured
```

Essa correção só é segura por causa do que o schema usa. Um schema que dependesse de uma palavra-chave
do 2020-12 que o draft-07 não tem passaria a ser conferido sem ela, e a próxima ferramenta mostra como
isso fica.

## REST Assured

O REST Assured tem um módulo para schemas, o `json-schema-validator`, lançado com os mesmos números
de versão do próprio REST Assured. Acrescente-o ao projeto da lição 7. O arquivo inteiro tem uma
dependência nova, depois de `rest-assured`; salve como `restassured/pom.xml`:

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
      <groupId>io.rest-assured</groupId>
      <artifactId>json-schema-validator</artifactId>
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

Depois, uma classe de teste que lê os mesmos arquivos de `~/boxoffice/schemas`. O Maven roda os testes
a partir do diretório do projeto, `restassured`, então o caminho começa com `..`.
Salve como `restassured/src/test/java/boxoffice/SchemaTest.java`:

```java
package boxoffice;

import static io.restassured.RestAssured.given;
import static io.restassured.module.jsv.JsonSchemaValidator.matchesJsonSchema;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.not;

import java.io.File;
import org.junit.jupiter.api.Test;

// The schemas of lesson 10, the same files the Node check reads.
class SchemaTest {

    static final File SHOW = new File("../schemas/show.json");
    static final File ORDER = new File("../schemas/order.json");

    @Test
    void aShowMatchesItsSchema() {
        given()
            .spec(Api.ANYONE)
        .when()
            .get("/v1/shows/{id}", "sh-103")
        .then()
            .statusCode(200)
            .body(matchesJsonSchema(SHOW));
    }

    @Test
    void aNewOrderMatchesItsSchema() {
        given()
            .spec(Api.as("ci-tests", "ci-secret"))
            .body("{\"show_id\": \"sh-101\", \"seats\": 1}")
        .when()
            .post("/v1/orders")
        .then()
            .statusCode(201)
            .body(matchesJsonSchema(ORDER));
    }

    // A confirmed order must carry its payment: the schema's if/then says so.
    @Test
    void aConfirmedOrderWithoutPaymentBreaksTheSchema() {
        String noPayment = """
            {"id": "ord-1001", "show_id": "sh-101", "seats": 1, "total_cents": 8000, "status": "confirmed"}
            """;
        assertThat(noPayment, not(matchesJsonSchema(ORDER)));
    }
}
```

Os dois primeiros testes conferem respostas ao vivo. O terceiro confere o próprio schema: um pedido
confirmado sem `payment` *não* pode casar, por causa do `if`/`then` no fim do `order.json`. A partir de
`~/boxoffice/restassured`:

```
ana@laptop:~/boxoffice/restassured$ mvn -q test -Dtest=SchemaTest
[ERROR] Tests run: 3, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 3.725 s <<< FAILURE! -- in boxoffice.SchemaTest
[ERROR] boxoffice.SchemaTest.aConfirmedOrderWithoutPaymentBreaksTheSchema -- Time elapsed: 0.029 s <<< FAILURE!
java.lang.AssertionError: 

Expected: not The content to match the given JSON schema.
warning: the following keywords are unknown and will be ignored: [$id, if, then]
    level: "warning"
    schema: {"loadingURI":"#","pointer":""}
    domain: "syntax"
    ignored: ["$id","if","then"]

     but: was "{\"id\": \"ord-1001\", \"show_id\": \"sh-101\", \"seats\": 1, \"total_cents\": 8000, \"status\": \"confirmed\"}\n"
	at org.hamcrest.MatcherAssert.assertThat(MatcherAssert.java:20)
	at org.hamcrest.MatcherAssert.assertThat(MatcherAssert.java:6)
	at boxoffice.SchemaTest.aConfirmedOrderWithoutPaymentBreaksTheSchema(SchemaTest.java:46)

[ERROR] Failures: 
[ERROR]   SchemaTest.aConfirmedOrderWithoutPaymentBreaksTheSchema:46 
Expected: not The content to match the given JSON schema.
warning: the following keywords are unknown and will be ignored: [$id, if, then]
    level: "warning"
    schema: {"loadingURI":"#","pointer":""}
    domain: "syntax"
    ignored: ["$id","if","then"]

     but: was "{\"id\": \"ord-1001\", \"show_id\": \"sh-101\", \"seats\": 1, \"total_cents\": 8000, \"status\": \"confirmed\"}\n"
[ERROR] Tests run: 3, Failures: 1, Errors: 0, Skipped: 0
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

**O terceiro teste falhou: o REST Assured diz que o pedido sem pagamento casa com o schema.** Os
dois primeiros passaram, então nada parecia errado com as respostas ao vivo, e esse é o perigo. O
validador dele implementa o draft 4, de 2013, que não tem `if` nem `then`. Ele pula palavras-chave
que não conhece. O aviso que diz isso,
`the following keywords are unknown and will be ignored: [$id, if, then]`, só é impresso dentro de
uma mensagem de falha como esta. As duas conferências ao vivo passaram sem imprimir nada. **Uma
regra do schema deixou de ser aplicada em silêncio**, e só um teste mirado na própria regra mostrou
isso.

Quem testa tem três respostas honestas, e fingir que a regra é conferida não é uma delas. A primeira
é manter a regra do `if`/`then` na conferência em Node da seção 03, que a aplica, e dizer isso no
teste em Java. A segunda é afirmá-la em Java com uma asserção comum. A terceira é trocar o módulo
por um validador que implemente o 2020-12. Este curso fica com a primeira, e marca o teste para a
lacuna aparecer em toda execução em vez de ser apagada. Acrescente o import e a anotação:

```java
import org.junit.jupiter.api.Disabled;
```

```java
    @Disabled("REST Assured's validator implements draft 4 and ignores if/then")
```

o import junto dos outros imports, a anotação na linha acima do `@Test` do terceiro teste:

```
ana@laptop:~/boxoffice/restassured$ mvn test -Dtest=SchemaTest | grep -E 'Tests run:|BUILD'
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 1
[INFO] BUILD SUCCESS
```

`Skipped: 1`, com o motivo escrito no código, onde a próxima pessoa que mexer no arquivo vai lê-lo.

## O que as três ferramentas entenderam

| ferramenta | validador | draft que implementa | o que fez com os schemas desta lição |
|---|---|---|---|
| `schemas/check.mjs` | Ajv, `Ajv2020` com ajv-formats | 2020-12 | toda regra, com o `if`/`then` |
| Postman, Newman | o que fica dentro do sandbox do Postman | até o draft-07 | recusou o `$schema` 2020-12; funciona sem essa linha |
| REST Assured | módulo `json-schema-validator` | draft 4 | ignorou `if`, `then` e `$id`, avisando só numa falha |

**Um schema, três validadores, três respostas.** Antes de confiar numa conferência de schema em
qualquer ferramenta, dê a ela uma resposta que precisa falhar, e veja se falha.
