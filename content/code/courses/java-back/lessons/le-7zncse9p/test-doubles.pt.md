---
title: Dublês de teste, e um mock para cada repositório
version: 1
---

A aula 18 testou `Order` e `Book`, que são objetos simples: cria-se um, chama-se um método, confere-se
a resposta. `OrderService` não é assim. Fazer um pedido trava uma linha no PostgreSQL, tira estoque de
uma entidade que o Hibernate carregou e salva um pedido novo pelo Spring Data. **A ideia comum é que,
por isso, testá-lo exige o banco.** Ele só exige o banco para testar o banco. As decisões do próprio
serviço — de qual livro tirar estoque, quando recusar, quanto o pedido soma — podem ser conferidas com
substitutos dos repositórios, num teste que roda em cerca de um segundo.

## Um dublê toma o lugar de um colaborador

Um **dublê de teste** é qualquer objeto que um teste põe onde estaria o colaborador real, como o dublê
que substitui o ator na cena perigosa. O vocabulário tem cinco palavras, do livro *xUnit Test
Patterns*, de Gerard Meszaros, e a aula 2 de `testing-cicd` dá a cada uma um exemplo próprio. Em
resumo:

| dublê | o que faz |
| --- | --- |
| dummy | preenche um parâmetro e nunca é usado |
| stub | devolve respostas que o teste escolheu de antemão |
| fake | uma implementação que funciona, mais simples, como um repositório sobre um `HashMap` |
| spy | um objeto real que também registra como foi chamado |
| mock | recebe o que esperar, ou é consultado depois sobre o que aconteceu com ele |

A aula 5 já escreveu um fake sem usar a palavra: o `InMemoryBookRepository` guardava três livros num
mapa, e a aula 9 o trocou pelo de JDBC. Escrever um fake do `BookRepository` de hoje seria outra
história, porque desde a aula 11 ele estende `JpaRepository`, e um fake teria de implementar dezenas de
métodos herdados para que um teste usasse dois.

O **Mockito** elimina esse custo. Dada uma interface ou uma classe, ele cria um objeto que implementa
todos os métodos e responde a cada um com um valor vazio — `null`, `0`, `false`, uma lista vazia, um
`Optional` vazio — até o teste dizer outra coisa. O que o Mockito chama de mock pode fazer o papel de
stub (`when`) e de mock no sentido de Meszaros (`verify`) no mesmo teste, e é por isso que a maior parte
do código Java diz "mock" para os dois.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 330\" role=\"img\" aria-label=\"Dois painéis. Na aplicação rodando, OrderService chama BookRepository e OrderRepository, dois proxies do Spring Data que mandam SQL ao PostgreSQL, e um Clock que lê o relógio do sistema. Em OrderServiceTest, o mesmo OrderService chama dois mocks do Mockito, um que responde como foi programado e outro que registra cada chamada, e um relógio parado; não há banco nem rede.\"><defs><marker id=\"f19a-ad\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"f19a-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"360\" height=\"310\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"190\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">na aplicação rodando</text><rect x=\"25\" y=\"48\" width=\"160\" height=\"38\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">OrderService</text><line x1=\"45\" y1=\"86\" x2=\"45\" y2=\"236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"45\" y1=\"126\" x2=\"58\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"60\" y=\"108\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"122.5\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Clock</text><line x1=\"185\" y1=\"126\" x2=\"208\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"210\" y=\"108\" width=\"148\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"284.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Clock.system(...)</text><text x=\"284.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a hora real</text><line x1=\"45\" y1=\"181\" x2=\"58\" y2=\"181\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"60\" y=\"163\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"122.5\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">BookRepository</text><line x1=\"185\" y1=\"181\" x2=\"208\" y2=\"181\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"210\" y=\"163\" width=\"148\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"284.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">proxy do Spring Data</text><text x=\"284.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">manda SQL</text><line x1=\"45\" y1=\"236\" x2=\"58\" y2=\"236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"60\" y=\"218\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"122.5\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">OrderRepository</text><line x1=\"185\" y1=\"236\" x2=\"208\" y2=\"236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"210\" y=\"218\" width=\"148\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"284.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">proxy do Spring Data</text><text x=\"284.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">manda SQL</text><line x1=\"284\" y1=\"254\" x2=\"284\" y2=\"268\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><path d=\"M 358 181 L 366 181 L 366 288\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></path><line x1=\"366\" y1=\"288\" x2=\"360\" y2=\"288\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"210\" y=\"270\" width=\"148\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"284.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">PostgreSQL</text><text x=\"284.0\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">outro processo</text><rect x=\"390\" y=\"10\" width=\"360\" height=\"310\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"570\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">em OrderServiceTest</text><rect x=\"405\" y=\"48\" width=\"160\" height=\"38\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"485.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">OrderService</text><line x1=\"425\" y1=\"86\" x2=\"425\" y2=\"236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"425\" y1=\"126\" x2=\"438\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"440\" y=\"108\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"502.5\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Clock</text><line x1=\"565\" y1=\"126\" x2=\"588\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"590\" y=\"108\" width=\"148\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"664.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Clock.fixed(...)</text><text x=\"664.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sempre 15:00 UTC</text><line x1=\"425\" y1=\"181\" x2=\"438\" y2=\"181\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"440\" y=\"163\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"502.5\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">BookRepository</text><line x1=\"565\" y1=\"181\" x2=\"588\" y2=\"181\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"590\" y=\"163\" width=\"148\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"664.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">mock</text><text x=\"664.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">responde como programado</text><line x1=\"425\" y1=\"236\" x2=\"438\" y2=\"236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"440\" y=\"218\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"502.5\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">OrderRepository</text><line x1=\"565\" y1=\"236\" x2=\"588\" y2=\"236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19a-ad)\"></line><rect x=\"590\" y=\"218\" width=\"148\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"664.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">mock</text><text x=\"664.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">registra cada chamada</text><text x=\"664\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">sem banco, sem rede</text></svg>", "caption": "O serviço é a mesma classe nos dois painéis. O que muda é o que ele alcança quando chama para fora.", "same": ["mock"]}
```

## O teste

Crie `src/test/java/com/example/bookshop/ordering/OrderServiceTest.java`:

```schooling-example
{
  "language": "java",
  "file": "OrderServiceTest.java",
  "parts": [
    {
      "code": "package com.example.bookshop.ordering;\n\nimport static org.assertj.core.api.Assertions.assertThat;\nimport static org.assertj.core.api.Assertions.assertThatThrownBy;\nimport static org.mockito.ArgumentMatchers.any;\nimport static org.mockito.Mockito.never;\nimport static org.mockito.Mockito.verify;\nimport static org.mockito.Mockito.when;\n\nimport java.time.Clock;\nimport java.time.Instant;\nimport java.time.ZoneOffset;\nimport java.util.List;\nimport java.util.Optional;\n\nimport org.junit.jupiter.api.BeforeEach;\nimport org.junit.jupiter.api.Test;\nimport org.junit.jupiter.api.extension.ExtendWith;\nimport org.mockito.Mock;\nimport org.mockito.junit.jupiter.MockitoExtension;\nimport org.springframework.test.util.ReflectionTestUtils;\n\nimport com.example.bookshop.catalogue.Author;\nimport com.example.bookshop.catalogue.Book;\nimport com.example.bookshop.catalogue.BookRepository;\nimport com.example.bookshop.catalogue.OutOfStockException;\n",
      "note": "Os imports estáticos são o vocabulário do teste. `when`, `verify`, `never` e `any` são do Mockito; `assertThat` e `assertThatThrownBy` são do AssertJ, como na aula 18. O `spring-boot-starter-test` já traz o Mockito, então o pom não muda por causa deste arquivo."
    },
    {
      "code": "@ExtendWith(MockitoExtension.class)\nclass OrderServiceTest {\n\n    @Mock\n    BookRepository books;\n\n    @Mock\n    OrderRepository orders;\n",
      "note": "A **`MockitoExtension`** cria um mock novo para cada campo `@Mock` antes de cada teste. Um mock de `BookRepository` implementa a interface inteira e responde a toda chamada com um valor vazio até o teste dizer outra coisa."
    },
    {
      "code": "    OrderService service;\n\n    Book frankenstein = new Book(\"9786500000030\", \"Frankenstein\", new Author(\"Mary Shelley\"), 3500, 1);\n",
      "note": "O serviço é a classe real, a que está sendo testada. O livro também é uma entidade real, criada pelo construtor público: um exemplar de *Frankenstein* a 3500 centavos. Nada aqui precisa de dublê, porque nenhum dos dois toca em algo fora da JVM."
    },
    {
      "code": "    @BeforeEach\n    void setUp() {\n        Clock noon = Clock.fixed(Instant.parse(\"2026-10-16T15:00:00Z\"), ZoneOffset.UTC);\n        service = new OrderService(books, orders, noon);\n        ReflectionTestUtils.setField(frankenstein, \"id\", 3L);\n    }\n",
      "note": "O serviço recebe os três colaboradores pelo construtor, como a aula 5 deixou. O relógio está parado às 15:00 UTC, meio-dia em São Paulo, e assim o horário do pedido é um valor que o teste pode verificar. `ReflectionTestUtils` dá ao livro o id que o banco teria gerado."
    },
    {
      "code": "    @Test\n    void placingAnOrderTakesTheStockAndSavesTheOrder() {\n        when(books.findByIdForUpdate(3L)).thenReturn(Optional.of(frankenstein));",
      "note": "Um **stub**: quando o serviço pede o livro 3 com trava, o mock devolve a entidade acima. Qualquer outro id continua recebendo o padrão, um `Optional` vazio."
    },
    {
      "code": "        when(orders.save(any(Order.class))).thenAnswer(call -> {\n            Order order = call.getArgument(0);\n            ReflectionTestUtils.setField(order, \"id\", 7L);\n            return order;\n        });\n",
      "note": "`thenAnswer` executa código no momento da chamada. O pedido é criado dentro de `place`, então o teste não consegue nomeá-lo de antemão; a resposta o pega dos argumentos da chamada, dá a ele o id 7 e o devolve, que é o que o `save` de verdade faz."
    },
    {
      "code": "        OrderResponse placed = service.place(\"ana\", new OrderRequest(List.of(new OrderRequest.Line(3L, 1))));\n\n        assertThat(placed.id()).isEqualTo(7);\n        assertThat(placed.totalCents()).isEqualTo(3500);\n        assertThat(placed.placedAt()).isEqualTo(Instant.parse(\"2026-10-16T15:00:00Z\"));\n        assertThat(frankenstein.getStock()).isZero();\n    }\n",
      "note": "A chamada testada, e depois o que ela devia ter produzido: o id que o `save` deu, o total, o instante fixo e o estoque que o pedido tirou do livro."
    },
    {
      "code": "    @Test\n    void anOrderForMoreThanTheStockIsNeverSaved() {\n        when(books.findByIdForUpdate(3L)).thenReturn(Optional.of(frankenstein));\n",
      "note": "O segundo teste faz o mesmo stub da busca e pede dois exemplares de um livro que tem um."
    },
    {
      "code": "        assertThatThrownBy(() -> service.place(\"ana\", new OrderRequest(List.of(new OrderRequest.Line(3L, 2)))))\n                .isInstanceOf(OutOfStockException.class);\n",
      "note": "`Book.take` lança a exceção, e ela sai de `place` antes de o pedido chegar ao `save`."
    },
    {
      "code": "        verify(orders, never()).save(any());\n    }\n}",
      "note": "**`verify`** pergunta ao mock o que aconteceu com ele. `never()` transforma a pergunta numa afirmação: `save` não foi chamado, com argumento nenhum. É a única coisa que um stub não consegue verificar, porque um stub só responde."
    }
  ]
}
```

Rode os testes. O Maven imprime uma tela de linhas `[INFO]` antes de os testes começarem, e o `sed`
guarda a parte que vai do cabeçalho dos testes até o fim. O `2>&1` manda pelo `sed` também o que a JVM
dos testes escreve na saída de erro, para que cada linha chegue na ordem em que foi impressa:

```
ana@vm:~/bookshop$ mvn test 2>&1 | sed -n '/T E S T S/,$p'
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.example.bookshop.ordering.OrderTest
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.089 s -- in com.example.bookshop.ordering.OrderTest
[INFO] Running com.example.bookshop.ordering.OrderServiceTest
Mockito is currently self-attaching to enable the inline-mock-maker. This will no longer work in future releases of the JDK. Please add Mockito as an agent to your build as described in Mockito's documentation: https://javadoc.io/doc/org.mockito/mockito-core/latest/org.mockito/org/mockito/Mockito.html#0.3
WARNING: A Java agent has been loaded dynamically (/home/ana/.m2/repository/net/bytebuddy/byte-buddy-agent/1.18.11/byte-buddy-agent-1.18.11.jar)
WARNING: If a serviceability tool is in use, please run with -XX:+EnableDynamicAgentLoading to hide this warning
WARNING: If a serviceability tool is not in use, please run with -Djdk.instrument.traceUsage for more information
WARNING: Dynamic loading of agents will be disallowed by default in a future release
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
20:28:54.044 [main] INFO com.example.bookshop.ordering.OrderService -- Order 7 placed by ana: 1 line(s), 3500 cents
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.795 s -- in com.example.bookshop.ordering.OrderServiceTest
[INFO] Running com.example.bookshop.catalogue.BookTest
[INFO] Running take
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.009 s -- in take
[INFO] Tests run: 0, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.010 s -- in com.example.bookshop.catalogue.BookTest
[INFO] Running com.example.bookshop.catalogue.IsbnTest
[INFO] Tests run: 10, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.098 s -- in com.example.bookshop.catalogue.IsbnTest
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 17, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  2.964 s
[INFO] Finished at: 2026-10-22T20:28:54-03:00
[INFO] ------------------------------------------------------------------------
```

Os dezessete testes passam, os dois novos entre eles. Duas coisas nessa saída não são resultados de
teste. A linha do `OrderService` é o log que a aula 16 acrescentou, escrito aqui no padrão de console
do Logback porque não há contexto do Spring rodando. A outra é o bloco de avisos no meio, que a próxima
seção lê linha por linha.

## O que um mock responde quando ninguém lhe disse nada

**Um mock que não foi instruído sobre o que devolver não falha. Ele devolve o valor vazio.** Tire o
stub do segundo teste para ver o que isso significa para `findByIdForUpdate`, cujo tipo de retorno é
`Optional<Book>`. O primeiro comando apaga a linha que vem depois do nome do método e imprime o método;
o segundo roda só esta classe, `-Dtest=OrderServiceTest`, e guarda a falha. **`-B`** é o modo batch do
Maven, e ele importa sempre que a saída do Maven passa por `grep` ou `sed`: sem ele, o Maven colore as
linhas mesmo dentro de um pipe, e os códigos de cor ficam entre os caracteres que um padrão procura.

```
ana@vm:~/bookshop$ sed -i '/void anOrderForMoreThanTheStockIsNeverSaved/{n;d}' src/test/java/com/example/bookshop/ordering/OrderServiceTest.java && sed -n '/void anOrderForMoreThanTheStockIsNeverSaved/,/^    }/p' src/test/java/com/example/bookshop/ordering/OrderServiceTest.java
    void anOrderForMoreThanTheStockIsNeverSaved() {

        assertThatThrownBy(() -> service.place("ana", new OrderRequest(List.of(new OrderRequest.Line(3L, 2)))))
                .isInstanceOf(OutOfStockException.class);

        verify(orders, never()).save(any());
    }
ana@vm:~/bookshop$ mvn -B test -Dtest=OrderServiceTest 2>&1 | sed -n '/<<< FAILURE!$/,/BookNotFoundException/p'
[ERROR] com.example.bookshop.ordering.OrderServiceTest.anOrderForMoreThanTheStockIsNeverSaved -- Time elapsed: 0.012 s <<< FAILURE!
java.lang.AssertionError: 

Expecting actual throwable to be an instance of:
  com.example.bookshop.catalogue.OutOfStockException
but was:
  com.example.bookshop.catalogue.BookNotFoundException: No book has id 3
```

O teste ainda esperava `OutOfStockException` e recebeu `BookNotFoundException`. Sem stub, o mock
devolveu um `Optional` vazio, e o `orElseThrow` do serviço fez exatamente o que faz para um livro que
não existe. Um teste que esquece um stub percorre um caminho diferente do que o nome dele descreve, e
aqui uma asserção pegou isso porque a asserção nomeava a exceção.

Ponha a linha de volta. Depois troque o id no stub do primeiro teste de `3L` para `4L`, de modo que o
mock fique preparado para uma chamada que nunca chega:

```
ana@vm:~/bookshop$ sed -i '0,/findByIdForUpdate(3L)/s//findByIdForUpdate(4L)/' src/test/java/com/example/bookshop/ordering/OrderServiceTest.java && grep -n 'findByIdForUpdate' src/test/java/com/example/bookshop/ordering/OrderServiceTest.java
50:        when(books.findByIdForUpdate(4L)).thenReturn(Optional.of(frankenstein));
67:        when(books.findByIdForUpdate(3L)).thenReturn(Optional.of(frankenstein));
ana@vm:~/bookshop$ mvn -B test -Dtest=OrderServiceTest 2>&1 | sed -n '/<<< ERROR!$/,/OrderServiceTest.java:50)$/p'
[ERROR] com.example.bookshop.ordering.OrderServiceTest.placingAnOrderTakesTheStockAndSavesTheOrder -- Time elapsed: 0.742 s <<< ERROR!
org.mockito.exceptions.misusing.PotentialStubbingProblem: 

Strict stubbing argument mismatch. Please check:
 - this invocation of 'findByIdForUpdate' method:
    books.findByIdForUpdate(3L);
    -> at com.example.bookshop.ordering.OrderService.place(OrderService.java:34)
 - has following stubbing(s) with different arguments:
    1. books.findByIdForUpdate(4L); stubbed with: [Returns: Optional[com.example.bookshop.catalogue.Book@680a66dd]]
      -> at com.example.bookshop.ordering.OrderServiceTest.placingAnOrderTakesTheStockAndSavesTheOrder(OrderServiceTest.java:50)
```

Desta vez quem recusou foi o próprio Mockito, antes de qualquer asserção rodar. **A
`MockitoExtension` roda com stubs estritos**: um stub cujos argumentos não batem com a chamada que o
código fez é um `PotentialStubbingProblem`, e a mensagem aponta as duas linhas, em vez de deixar a
chamada cair numa resposta vazia. Um stub que nunca é usado também faz o teste falhar, com
`UnnecessaryStubbingException`. As duas regras empurram o teste a fazer stub exatamente do que o código
testado chama. Ponha o `3L` de volta antes de continuar.
