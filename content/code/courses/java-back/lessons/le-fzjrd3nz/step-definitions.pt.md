---
title: Definições de passos e expressões do Cucumber
version: 1
---

Um arquivo de *feature* não faz nada sozinho. Cada passo dele roda porque um método Java o
reivindica. Uma **definição de passo** (*step definition*) é um método anotado com `@Given`, `@When`
ou `@Then` cujo argumento é um padrão, e para cada passo o Cucumber roda o único método cujo padrão
casa com a frase. As classes que guardam esses métodos se chamam **glue** (cola), porque são elas que
grudam as frases no código.

## O padrão é uma expressão do Cucumber

`"she orders {int} copies of {string}"` é uma **expressão do Cucumber** (*Cucumber expression*):
texto literal com buracos tipados entre chaves. Casada com
`When she orders 2 copies of "The War of the Worlds"`, ela rende dois valores, o número 2 e o título sem as aspas, e o Cucumber os passa ao
método na ordem em que os buracos aparecem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"O passo When she orders 2 copies of &quot;The War of the Worlds&quot; casa com a expressão she orders {int} copies of {string}. O 2 preenche {int} e o título entre aspas preenche {string}, e o Cucumber chama sheOrders com 2 e o título, sem as aspas. A palavra-chave When não participa da correspondência.\"><defs><marker id=\"f1-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20.0\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o passo</text><text x=\"20.0\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a expressão</text><text x=\"20.0\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a chamada</text><text x=\"176.0\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">When</text><text x=\"212.0\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">she orders 2 copies of &quot;The War of the Worlds&quot;</text><text x=\"176.0\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fora da correspondência</text><text x=\"176.0\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">@When(&quot;she orders {int} copies of {string}&quot;)</text><text x=\"176.0\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">sheOrders(quantity = 2, title = The War of the Worlds)</text><text x=\"176.0\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">na ordem dos buracos</text><rect x=\"289.2\" y=\"40\" width=\"11.2\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><rect x=\"303.6\" y=\"122\" width=\"40.0\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><rect x=\"325.2\" y=\"204\" width=\"11.2\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><rect x=\"375.6\" y=\"40\" width=\"169.6\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><rect x=\"418.8\" y=\"122\" width=\"61.6\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><rect x=\"404.4\" y=\"204\" width=\"155.2\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><line x1=\"294.8\" y1=\"61\" x2=\"323.6\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#f1-ah)\"></line><line x1=\"323.6\" y1=\"143\" x2=\"330.8\" y2=\"202\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#f1-ah)\"></line><line x1=\"460.4\" y1=\"61\" x2=\"449.6\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#f1-ah)\"></line><line x1=\"449.6\" y1=\"143\" x2=\"482.0\" y2=\"202\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#f1-ah)\"></line><text x=\"509.6\" y=\"175.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as aspas ficam de fora</text></svg>", "caption": "O Cucumber casa a frase que vem depois da palavra-chave, preenche cada buraco com um pedaço dela e chama o método com os valores em ordem."}
```

Os buracos que o Cucumber conhece sem ninguém precisar ensinar:

| buraco | casa com | chega como |
|---|---|---|
| `{int}`, `{long}` | um número inteiro, como `5` ou `-1` | `int`, `long` |
| `{float}`, `{double}`, `{bigdecimal}` | um número decimal, como `3.5` | `float`, `double`, `BigDecimal` |
| `{word}` | uma palavra sem espaços | `String` |
| `{string}` | um texto entre aspas duplas ou simples | `String`, sem as aspas |

Um padrão que começa com `^` ou termina com `$` é lido como expressão regular. Projetos mais
antigos estão cheios deles, `"^she orders (\\d+) copies of \"([^\"]*)\"$"` e parecidos; uma
expressão do Cucumber diz a mesma coisa de um jeito que quem escreveu a frase ainda consegue ler.

## A palavra-chave não entra na correspondência

O Cucumber casa a frase e ignora a palavra na frente dela. `Given`, `When`, `Then` e `And` são para
quem lê: um método anotado com `@Given` roda do mesmo jeito para uma linha `Then` com as mesmas
palavras. Isso quer dizer que **uma frase não consegue preparar e conferir ao mesmo tempo**, e é por
isso que o arquivo de *feature* tem duas frases sobre estoque. *The shop has 5 copies of …* define o
estoque. *… has 3 copies left* o lê. Escrita como uma frase só, usada nos dois lugares, o método por
trás dela teria de escolher. Se só conferisse, o `Given` só passaria enquanto o banco ainda tivesse
os cinco exemplares com que foi semeado; contra um banco em que outro teste já tivesse feito pedidos,
ele falharia por um motivo que não tem nada a ver com a regra. Se só definisse, o `Then` não
conferiria nada.

Cada frase tem de casar com **exatamente um** método em toda a *glue*. Dois é um erro, e o Cucumber
cita os dois métodos em vez de escolher um. Nenhum é o passo indefinido da última seção.

## A classe

Crie `src/test/java/com/example/bookshop/acceptance/OrderingSteps.java`:

```schooling-example
{
  "language": "java",
  "file": "OrderingSteps.java",
  "parts": [
    {
      "code": "package com.example.bookshop.acceptance;\n\nimport static io.restassured.RestAssured.given;\nimport static org.assertj.core.api.Assertions.assertThat;\n\nimport java.util.Map;\n\nimport io.cucumber.java.Before;\nimport io.cucumber.java.en.Given;\nimport io.cucumber.java.en.Then;\nimport io.cucumber.java.en.When;\nimport io.restassured.RestAssured;\nimport io.restassured.http.ContentType;\nimport io.restassured.response.Response;\n\nimport org.springframework.boot.test.web.server.LocalServerPort;\nimport org.springframework.jdbc.core.simple.JdbcClient;\n",
      "note": "As anotações vêm de `io.cucumber.java.en`, as palavras-chave em inglês; um pacote `pt` ao lado tem `@Dado`, `@Quando` e `@Então`. As chamadas HTTP são do REST Assured, exatamente como a aula 20 o usou, e o `JdbcClient` é o da aula 9."
    },
    {
      "code": "public class OrderingSteps {\n\n    private static final Map<String, String> PASSWORDS = Map.of(\"ana\", \"ana-reads-books\");\n\n    private final JdbcClient jdbc;\n    private final int port;\n\n    private String token;\n    private Response lastOrder;\n",
      "note": "Uma classe comum: nenhuma anotação a torna *glue*, o pacote dela é que torna. `token` e `lastOrder` carregam o que um passo deixa para o próximo, porque os passos de um cenário são chamadas de método separadas, sem mais nada em comum."
    },
    {
      "code": "    public OrderingSteps(JdbcClient jdbc, @LocalServerPort int port) {\n        this.jdbc = jdbc;\n        this.port = port;\n    }\n",
      "note": "Injeção pelo construtor, como a aula 5 defendeu. O Spring fornece os dois argumentos, porque o cucumber-spring cria cada classe de *glue* como um bean, um novo para cada cenário. `@LocalServerPort` é a porta aleatória em que o servidor de teste subiu."
    },
    {
      "code": "    @Before\n    public void pointRestAssuredAtTheServer() {\n        RestAssured.port = port;\n    }\n",
      "note": "O `@Before` do Cucumber, não o `@BeforeEach` do JUnit: um **hook**, que roda antes de cada cenário e antes do *background* dele. O REST Assured guarda a porta num campo estático, então este aponta para o servidor de hoje."
    },
    {
      "code": "    @Given(\"the customer {string} has signed in\")\n    public void theCustomerHasSignedIn(String name) {\n        token = given().auth().preemptive().basic(name, PASSWORDS.get(name))\n                .post(\"/auth/token\")\n                .then().statusCode(200)\n                .extract().path(\"accessToken\");\n    }\n",
      "note": "`{string}` casa com um texto entre aspas duplas ou simples e o entrega sem elas, então a linha do *background* chega aqui como `name` = `ana`. Ele entra pela porta da frente, autenticação Basic em `/auth/token`, e guarda o token."
    },
    {
      "code": "    @Given(\"the shop has {int} copies of {string}\")\n    public void theShopHas(int copies, String title) {\n        int rows = jdbc.sql(\"UPDATE book SET stock = ? WHERE title = ?\")\n                .params(copies, title)\n                .update();\n        assertThat(rows).as(\"books titled %s\", title).isEqualTo(1);\n    }\n",
      "note": "Um `Given` PREPARA. Ele escreve o estoque direto na tabela, porque a loja não tem tela para definir estoque e o cenário não é sobre uma. Conferir que exatamente uma linha mudou transforma um título digitado errado numa falha nesta linha, em vez de uma falha intrigante três passos depois."
    },
    {
      "code": "    @When(\"she orders {int} copies of {string}\")\n    public void sheOrders(int quantity, String title) {\n        int bookId = book(title).path(\"id\");\n        lastOrder = given().auth().oauth2(token)\n                .contentType(ContentType.JSON)\n                .body(\"{\\\"lines\\\": [{\\\"bookId\\\": \" + bookId + \", \\\"quantity\\\": \" + quantity + \"}]}\")\n                .post(\"/orders\");\n    }\n",
      "note": "A única ação, pela mesma API HTTP que um cliente usa. `{int}` chega como `int` e `{string}` como `String`, na ordem em que aparecem na frase."
    },
    {
      "code": "    @Then(\"the order is accepted with a total of {int} cents\")\n    public void theOrderIsAccepted(int total) {\n        assertThat(lastOrder.statusCode()).isEqualTo(201);\n        assertThat(lastOrder.<Integer>path(\"totalCents\")).isEqualTo(total);\n    }\n",
      "note": "Um `Then` só olha. O AssertJ lança uma exceção quando o status ou o total não são o que a frase diz, e o Cucumber aponta o passo que lançou."
    },
    {
      "code": "    @Then(\"the order is refused as out of stock\")\n    public void theOrderIsRefused() {\n        assertThat(lastOrder.statusCode()).isEqualTo(409);\n        assertThat(lastOrder.<String>path(\"title\")).isEqualTo(\"Out of stock\");\n    }\n",
      "note": "409 e o título dos *problem details* da aula 7: a recusa que quem conhece o negócio chamou de \"out of stock\", nos termos da própria API."
    },
    {
      "code": "    @Then(\"{string} has {int} copies left\")\n    public void hasCopiesLeft(String title, int copies) {\n        assertThat(book(title).<Integer>path(\"stock\")).isEqualTo(copies);\n    }\n",
      "note": "Lido de volta pela API, que é o que uma cliente conseguiria ver, e não pela tabela em que o `Given` escreveu."
    },
    {
      "code": "    private Response book(String title) {\n        Response found = given().queryParam(\"q\", title).get(\"/books/search\");\n        found.then().statusCode(200);\n        return given().get(\"/books/{id}\", found.<Integer>path(\"[0].id\"));\n    }\n}",
      "note": "Um auxiliar, não um passo: não tem anotação, então nenhuma frase chega a ele. Ele acha o id de um livro pelo título com o endpoint de busca da aula 11."
    }
  ]
}
```

Leia os métodos na ordem em que o primeiro cenário os chama e a classe conta a mesma história que o
arquivo de *feature*, um nível abaixo: fazer login, definir o estoque, fazer o pedido, olhar a
resposta e a prateleira. As frases ficam na língua da loja e os métodos falam HTTP e SQL, que é a
divisão de trabalho que a seção anterior pediu.

## A glue é achada pelo pacote

O Cucumber não procura definições de passos em todo lugar. Ele carrega a *glue* dos pacotes que lhe
indicam, aqui `com.example.bookshop.acceptance`, que o executor da próxima seção nomeia. Uma
definição de passo em outro pacote fica invisível, e para o Cucumber ela parece exatamente uma frase
para a qual ninguém escreveu código.
