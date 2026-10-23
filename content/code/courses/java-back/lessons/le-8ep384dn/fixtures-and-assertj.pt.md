---
title: Fixtures, classes aninhadas e AssertJ
version: 1
---

`Isbn` não tem estado, então os testes dele não precisam de nada preparado. Um `Book` tem um estoque
que `take` altera, e um `Order` soma as suas linhas. Testá-los levanta duas perguntas novas: de onde
vem o objeto do qual um teste parte (a **fixture**), e como dizer mais numa asserção do que
verdadeiro ou falso.

## BookTest

Crie `src/test/java/com/example/bookshop/catalogue/BookTest.java`:

```schooling-example
{
  "language": "java",
  "file": "BookTest.java",
  "parts": [
    {
      "code": "package com.example.bookshop.catalogue;\n\nimport static org.junit.jupiter.api.Assertions.assertEquals;\nimport static org.junit.jupiter.api.Assertions.assertThrows;\n\nimport org.junit.jupiter.api.BeforeEach;\nimport org.junit.jupiter.api.DisplayName;\nimport org.junit.jupiter.api.Nested;\nimport org.junit.jupiter.api.Test;\n",
      "note": "`assertThrows` é a única asserção nova. `@BeforeEach`, `@Nested` e `@DisplayName` tratam de como os testes se organizam, não do que verificam."
    },
    {
      "code": "class BookTest {\n\n    private Book book;\n\n    @BeforeEach\n    void aBookWithTwoCopies() {\n        book = new Book(\"9786500000016\", \"Dom Casmurro\", new Author(\"Machado de Assis\"), 3990, 2);\n    }\n",
      "note": "**`@BeforeEach` roda antes de cada teste desta classe, inclusive os das classes aninhadas.** Todo teste muda o livro, então todo teste precisa de um livro novo com dois exemplares. Escrever `new Book(...)` na declaração do campo também funcionaria, porque a própria instância é nova a cada teste (a figura abaixo mostra); `@BeforeEach` é o lugar de costume, e o que continua servindo quando a preparação tem mais de um comando."
    },
    {
      "code": "    @Nested\n    @DisplayName(\"take\")\n    class Take {\n",
      "note": "Uma **classe aninhada** agrupa os testes de um método, `take`. É uma classe interna, não `static`, para que os testes vejam o `book` da instância de fora. `@DisplayName(\"take\")` é o nome que o JUnit dá ao grupo no lugar de `Take`."
    },
    {
      "code": "        @Test\n        void lowersTheStock() {\n            book.take(2);\n            assertEquals(0, book.getStock());\n        }\n",
      "note": "A afirmação simples: tirar dois de dois, e não sobra nenhum."
    },
    {
      "code": "        @Test\n        void refusesMoreThanThereIs() {\n            OutOfStockException e = assertThrows(OutOfStockException.class, () -> book.take(3));\n            assertEquals(\"Only 2 of 'Dom Casmurro' left, 3 wanted\", e.getMessage());\n        }\n",
      "note": "`assertThrows` roda o lambda e só passa se ele lançar aquele tipo de exceção, ou uma subclasse dele. Ele devolve a exceção, então o teste pode seguir e conferir a mensagem."
    },
    {
      "code": "        @Test\n        void leavesTheStockAloneWhenItRefuses() {\n            assertThrows(OutOfStockException.class, () -> book.take(3));\n            assertEquals(2, book.getStock());\n        }",
      "note": "A afirmação que ninguém lembra de escrever: um `take` recusado não muda nada. O desvio abaixo é sobre este teste."
    },
    {
      "code": "    }\n}"
    }
  ]
}
```

A imagem errada de uma classe de teste é a que o Java comum sugere: um objeto, os métodos chamados um
depois do outro, cada um vendo o que o anterior deixou. **O JUnit cria uma instância nova da classe
de teste para cada método de teste**, roda nela os métodos `@BeforeEach`, roda o único teste e joga a
instância fora. Com uma classe aninhada, ele cria uma instância nova da classe de fora e outra da de
dentro:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 290\" role=\"img\" aria-label=\"Três linhas, uma por teste da classe aninhada Take. Em cada linha o JUnit cria um BookTest novo, numerados 1, 2 e 3, depois um Take novo dentro dele, depois roda o método @BeforeEach aBookWithTwoCopies, que monta um livro com dois exemplares, e então roda um teste: lowersTheStock tira 2 e deixa o estoque em 0; refusesMoreThanThereIs pede 3 e é recusado; leavesTheStockAloneWhenItRefuses pede 3 e encontra o estoque ainda em 2. Nada que um teste muda chega ao próximo.\"><text x=\"66.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a classe de fora</text><text x=\"196.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a classe aninhada</text><text x=\"355.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">@BeforeEach</text><text x=\"578.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um @Test</text><rect x=\"6\" y=\"44\" width=\"120\" height=\"52\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"66\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">new BookTest()</text><text x=\"66\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">#1</text><rect x=\"144\" y=\"44\" width=\"104\" height=\"52\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"196\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">new Take()</text><text x=\"196\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dentro do #1</text><rect x=\"266\" y=\"44\" width=\"178\" height=\"52\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">aBookWithTwoCopies()</text><text x=\"355\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um livro com 2 exemplares</text><rect x=\"462\" y=\"44\" width=\"232\" height=\"52\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"578\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">lowersTheStock()</text><text x=\"578\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tira 2: o estoque fica 0</text><line x1=\"126\" y1=\"70\" x2=\"137\" y2=\"70\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><polygon points=\"144,70 136,66 136,74\" fill=\"var(--phosphor-dim)\"></polygon><line x1=\"248\" y1=\"70\" x2=\"259\" y2=\"70\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><polygon points=\"266,70 258,66 258,74\" fill=\"var(--phosphor-dim)\"></polygon><line x1=\"444\" y1=\"70\" x2=\"455\" y2=\"70\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><polygon points=\"462,70 454,66 454,74\" fill=\"var(--phosphor-dim)\"></polygon><rect x=\"6\" y=\"118\" width=\"120\" height=\"52\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"66\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">new BookTest()</text><text x=\"66\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">#2</text><rect x=\"144\" y=\"118\" width=\"104\" height=\"52\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"196\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">new Take()</text><text x=\"196\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dentro do #2</text><rect x=\"266\" y=\"118\" width=\"178\" height=\"52\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">aBookWithTwoCopies()</text><text x=\"355\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um livro com 2 exemplares</text><rect x=\"462\" y=\"118\" width=\"232\" height=\"52\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"578\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">refusesMoreThanThereIs()</text><text x=\"578\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pede 3: recusado</text><line x1=\"126\" y1=\"144\" x2=\"137\" y2=\"144\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><polygon points=\"144,144 136,140 136,148\" fill=\"var(--phosphor-dim)\"></polygon><line x1=\"248\" y1=\"144\" x2=\"259\" y2=\"144\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><polygon points=\"266,144 258,140 258,148\" fill=\"var(--phosphor-dim)\"></polygon><line x1=\"444\" y1=\"144\" x2=\"455\" y2=\"144\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><polygon points=\"462,144 454,140 454,148\" fill=\"var(--phosphor-dim)\"></polygon><rect x=\"6\" y=\"192\" width=\"120\" height=\"52\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"66\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">new BookTest()</text><text x=\"66\" y=\"229\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">#3</text><rect x=\"144\" y=\"192\" width=\"104\" height=\"52\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"196\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">new Take()</text><text x=\"196\" y=\"229\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dentro do #3</text><rect x=\"266\" y=\"192\" width=\"178\" height=\"52\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">aBookWithTwoCopies()</text><text x=\"355\" y=\"229\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um livro com 2 exemplares</text><rect x=\"462\" y=\"192\" width=\"232\" height=\"52\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"578\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">leavesTheStockAloneWhenItRefuses()</text><text x=\"578\" y=\"229\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pede 3: continua 2</text><line x1=\"126\" y1=\"218\" x2=\"137\" y2=\"218\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><polygon points=\"144,218 136,214 136,222\" fill=\"var(--phosphor-dim)\"></polygon><line x1=\"248\" y1=\"218\" x2=\"259\" y2=\"218\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><polygon points=\"266,218 258,214 258,222\" fill=\"var(--phosphor-dim)\"></polygon><line x1=\"444\" y1=\"218\" x2=\"455\" y2=\"218\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><polygon points=\"462,218 454,214 454,222\" fill=\"var(--phosphor-dim)\"></polygon><text x=\"350\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">Nada que um teste muda chega ao próximo: cada um começa do mesmo livro.</text></svg>", "caption": "Como o JUnit roda os três testes de BookTest.Take: um par novo de instâncias e um livro novo para cada teste, na ordem que ele escolher.", "same": ["@BeforeEach"]}
```

É por isso que `leavesTheStockAloneWhenItRefuses` pode esperar dois exemplares mesmo que
`lowersTheStock`, que tirou os dois, tenha rodado antes. Os testes não sabem uns dos outros, e **a
ordem em que o JUnit os roda é fixa, mas de propósito não está amarrada à ordem do arquivo**: nada
deve depender dela.

## Um desvio: um livro para os três

`@BeforeAll` roda uma vez por classe, antes de qualquer teste, e precisa ser `static` porque ainda
não existe instância. É o lugar para uma preparação cara que nenhum teste altera, como subir um
servidor que os testes só leem. Use-o aqui para o livro, que todo teste altera, e veja o que
acontece:

```
ana@vm:~/bookshop$ sed -i 's/import org.junit.jupiter.api.BeforeEach;/import org.junit.jupiter.api.BeforeAll;/; s/    private Book book;/    private static Book book;/; s/    @BeforeEach/    @BeforeAll/; s/    void aBookWithTwoCopies/    static void aBookWithTwoCopies/' src/test/java/com/example/bookshop/catalogue/BookTest.java && sed -n '11,18p' src/test/java/com/example/bookshop/catalogue/BookTest.java
class BookTest {

    private static Book book;

    @BeforeAll
    static void aBookWithTwoCopies() {
        book = new Book("9786500000016", "Dom Casmurro", new Author("Machado de Assis"), 3990, 2);
    }
```

Rode a classe. O padrão é `BookTest*`, com asterisco, para cobrir também a classe aninhada, cujo nome
compilado é `BookTest$Take`:

```
ana@vm:~/bookshop$ mvn test -Dtest='BookTest*'
[INFO] Scanning for projects...
[INFO] 
[INFO] ------------------------< com.example:bookshop >------------------------
[INFO] Building bookshop 0.1.0
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-resources-plugin:3.5.0:resources (default-resources) @ bookshop ---
[INFO] Copying 4 resources from src/main/resources to target/classes
[INFO] Copying 3 resources from src/main/resources to target/classes
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:compile (default-compile) @ bookshop ---
[INFO] Nothing to compile - all classes are up to date.
[INFO] 
[INFO] --- maven-resources-plugin:3.5.0:testResources (default-testResources) @ bookshop ---
[INFO] skip non existing resourceDirectory /home/ana/bookshop/src/test/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:testCompile (default-testCompile) @ bookshop ---
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 2 source files with javac [debug parameters release 25] to target/test-classes
[INFO] 
[INFO] --- maven-surefire-plugin:3.5.6:test (default-test) @ bookshop ---
[INFO] Using auto detected provider org.apache.maven.surefire.junitplatform.JUnitPlatformProvider
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.example.bookshop.catalogue.BookTest
[INFO] Running take
[ERROR] Tests run: 3, Failures: 2, Errors: 0, Skipped: 0, Time elapsed: 0.071 s <<< FAILURE! -- in take
[ERROR] com.example.bookshop.catalogue.BookTest.refusesMoreThanThereIs -- Time elapsed: 0.010 s <<< FAILURE!
org.opentest4j.AssertionFailedError: expected: <Only 2 of 'Dom Casmurro' left, 3 wanted> but was: <Only 0 of 'Dom Casmurro' left, 3 wanted>
	at org.junit.jupiter.api.AssertionFailureBuilder.build(AssertionFailureBuilder.java:158)
	at org.junit.jupiter.api.AssertionFailureBuilder.buildAndThrow(AssertionFailureBuilder.java:139)
	at org.junit.jupiter.api.AssertEquals.failNotEqual(AssertEquals.java:201)
	at org.junit.jupiter.api.AssertEquals.assertEquals(AssertEquals.java:184)
	at org.junit.jupiter.api.AssertEquals.assertEquals(AssertEquals.java:179)
	at org.junit.jupiter.api.Assertions.assertEquals(Assertions.java:1188)
	at com.example.bookshop.catalogue.BookTest$Take.refusesMoreThanThereIs(BookTest.java:33)

[ERROR] com.example.bookshop.catalogue.BookTest.leavesTheStockAloneWhenItRefuses -- Time elapsed: 0.002 s <<< FAILURE!
org.opentest4j.AssertionFailedError: expected: <2> but was: <0>
	at org.junit.jupiter.api.AssertionFailureBuilder.build(AssertionFailureBuilder.java:158)
	at org.junit.jupiter.api.AssertionFailureBuilder.buildAndThrow(AssertionFailureBuilder.java:139)
	at org.junit.jupiter.api.AssertEquals.failNotEqual(AssertEquals.java:201)
	at org.junit.jupiter.api.AssertEquals.assertEquals(AssertEquals.java:152)
	at org.junit.jupiter.api.AssertEquals.assertEquals(AssertEquals.java:147)
	at org.junit.jupiter.api.Assertions.assertEquals(Assertions.java:558)
	at com.example.bookshop.catalogue.BookTest$Take.leavesTheStockAloneWhenItRefuses(BookTest.java:39)

[INFO] Tests run: 0, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.101 s -- in com.example.bookshop.catalogue.BookTest
[INFO] 
[INFO] Results:
[INFO] 
[ERROR] Failures: 
[ERROR]   BookTest.leavesTheStockAloneWhenItRefuses expected: <2> but was: <0>
[ERROR]   BookTest.refusesMoreThanThereIs expected: <Only 2 of 'Dom Casmurro' left, 3 wanted> but was: <Only 0 of 'Dom Casmurro' left, 3 wanted>
[INFO] 
[ERROR] Tests run: 3, Failures: 2, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  2.625 s
[INFO] Finished at: 2026-10-22T20:20:48-03:00
[INFO] ------------------------------------------------------------------------
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-surefire-plugin:3.5.6:test (default-test) on project bookshop: There are test failures.
[ERROR] 
[ERROR] See /home/ana/bookshop/target/surefire-reports for the individual test results.
[ERROR] See dump files (if any exist) [date].dump, [date]-jvmRun[N].dump and [date].dumpstream.
[ERROR] -> [Help 1]
[ERROR] 
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR] 
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoFailureException
```

Dois de três falham, e as mensagens dizem por quê: `but was: <0>`, `Only 0 of 'Dom Casmurro' left`.
`lowersTheStock` rodou primeiro e tirou os dois exemplares do único livro compartilhado, e os outros
dois testes o encontraram vazio. **Nenhum dos testes que falharam está errado, e o código também não;
a fixture está.** Numa classe maior o sintoma é pior do que este, porque ele muda de lugar: um teste
que passa sozinho e falha na rodada completa, ou o contrário, conforme o que rodou antes dele. Volte
o arquivo:

```
ana@vm:~/bookshop$ sed -i 's/import org.junit.jupiter.api.BeforeAll;/import org.junit.jupiter.api.BeforeEach;/; s/    private static Book book;/    private Book book;/; s/    @BeforeAll/    @BeforeEach/; s/    static void aBookWithTwoCopies/    void aBookWithTwoCopies/' src/test/java/com/example/bookshop/catalogue/BookTest.java && sed -n '11,18p' src/test/java/com/example/bookshop/catalogue/BookTest.java
class BookTest {

    private Book book;

    @BeforeEach
    void aBookWithTwoCopies() {
        book = new Book("9786500000016", "Dom Casmurro", new Author("Machado de Assis"), 3990, 2);
    }
```

## OrderTest, com AssertJ

`assertEquals(2, book.getStock())` põe o valor esperado primeiro e o obtido depois, e só o hábito
impede você de escrever ao contrário. O **AssertJ** começa pelo valor obtido: `assertThat(actual)`,
e depois um método que diz o que ele deveria ser. O starter o trouxe, e o `OrderTest` o usa. Crie
`src/test/java/com/example/bookshop/ordering/OrderTest.java`:

```schooling-example
{
  "language": "java",
  "file": "OrderTest.java",
  "parts": [
    {
      "code": "package com.example.bookshop.ordering;\n\nimport static org.assertj.core.api.Assertions.assertThat;\n\nimport java.time.Instant;\n\nimport org.junit.jupiter.api.Test;\n\nimport com.example.bookshop.catalogue.Author;\nimport com.example.bookshop.catalogue.Book;\n",
      "note": "Um import estático, `assertThat`, é toda a porta de entrada do AssertJ. O resto são métodos do objeto que ele devolve."
    },
    {
      "code": "class OrderTest {\n\n    private final Author machado = new Author(\"Machado de Assis\");\n",
      "note": "Um campo compartilhado pelos testes não tem problema quando nada o altera: nenhum teste modifica um `Author`."
    },
    {
      "code": "    @Test\n    void totalIsTheSumOfQuantityTimesPrice() {\n        Order order = new Order(\"ana\", Instant.parse(\"2026-10-16T12:00:00Z\"));\n        order.add(new Book(\"9786500000016\", \"Dom Casmurro\", machado, 3990, 5), 2);\n        order.add(new Book(\"9786500000054\", \"Quincas Borba\", machado, 3690, 5), 1);\n\n        assertThat(order.totalCents()).isEqualTo(11670);\n        assertThat(order.getLines()).extracting(OrderLine::getQuantity).containsExactly(2, 1);\n    }\n",
      "note": "`assertThat(x)` escolhe um objeto de asserção pelo tipo de `x`, aqui um `int`, e **o autocompletar do editor passa a oferecer só o que faz sentido para esse tipo**. `11670` é 2 × 3990 + 3690. `extracting` transforma a lista de linhas na lista das suas quantidades, e `containsExactly` confere esses valores nessa ordem."
    },
    {
      "code": "    @Test\n    void anEmptyOrderCostsNothing() {\n        assertThat(new Order(\"ana\", Instant.EPOCH).totalCents()).isZero();\n    }",
      "note": "`isZero()` se lê melhor que `isEqualTo(0)` e falha com a mesma mensagem."
    },
    {
      "code": "}"
    }
  ]
}
```

Rode todos os testes do projeto:

```
ana@vm:~/bookshop$ mvn test
[INFO] Scanning for projects...
[INFO] 
[INFO] ------------------------< com.example:bookshop >------------------------
[INFO] Building bookshop 0.1.0
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-resources-plugin:3.5.0:resources (default-resources) @ bookshop ---
[INFO] Copying 4 resources from src/main/resources to target/classes
[INFO] Copying 3 resources from src/main/resources to target/classes
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:compile (default-compile) @ bookshop ---
[INFO] Nothing to compile - all classes are up to date.
[INFO] 
[INFO] --- maven-resources-plugin:3.5.0:testResources (default-testResources) @ bookshop ---
[INFO] skip non existing resourceDirectory /home/ana/bookshop/src/test/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:testCompile (default-testCompile) @ bookshop ---
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 3 source files with javac [debug parameters release 25] to target/test-classes
[INFO] 
[INFO] --- maven-surefire-plugin:3.5.6:test (default-test) @ bookshop ---
[INFO] Using auto detected provider org.apache.maven.surefire.junitplatform.JUnitPlatformProvider
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.example.bookshop.ordering.OrderTest
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.116 s -- in com.example.bookshop.ordering.OrderTest
[INFO] Running com.example.bookshop.catalogue.BookTest
[INFO] Running take
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.034 s -- in take
[INFO] Tests run: 0, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.040 s -- in com.example.bookshop.catalogue.BookTest
[INFO] Running com.example.bookshop.catalogue.IsbnTest
[INFO] Tests run: 10, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.138 s -- in com.example.bookshop.catalogue.IsbnTest
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 15, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  2.939 s
[INFO] Finished at: 2026-10-22T20:20:52-03:00
[INFO] ------------------------------------------------------------------------
```

Quinze testes em três classes. Uma linha é estranha: `Running take` e `Tests run: 3 ... in take`,
seguidas de `Tests run: 0 ... in com.example.bookshop.catalogue.BookTest`. **O surefire relata uma
classe aninhada como uma classe à parte, com o nome de exibição dela**, e a classe de fora, que não
tem métodos de teste diretamente, como zero. Os três testes rodaram uma vez cada. O console launcher
mostra a estrutura que o JUnit enxerga:

```
ana@vm:~/bookshop$ java -jar target/junit-platform-console-standalone-6.0.3.jar execute --disable-banner --disable-ansi-colors --details=testfeed --class-path "target/test-classes:target/classes:$(cat target/test.cp)" --select-class com.example.bookshop.catalogue.BookTest | grep -v STARTED
JUnit Jupiter > BookTest > take > lowersTheStock() :: SUCCESSFUL
JUnit Jupiter > BookTest > take > refusesMoreThanThereIs() :: SUCCESSFUL
JUnit Jupiter > BookTest > take > leavesTheStockAloneWhenItRefuses() :: SUCCESSFUL

Test run finished after 102 ms
[         5 containers found      ]
[         0 containers skipped    ]
[         5 containers started    ]
[         0 containers aborted    ]
[         5 containers successful ]
[         0 containers failed     ]
[         3 tests found           ]
[         0 tests skipped         ]
[         3 tests started         ]
[         0 tests aborted         ]
[         3 tests successful      ]
[         0 tests failed          ]
```

## O que o AssertJ diz quando falha

O motivo para preferi-lo é a mensagem. Troque as quantidades esperadas para
`containsExactly(1, 2)`, a ordem errada, e rode a classe:

```
ana@vm:~/bookshop$ sed -i 's/containsExactly(2, 1)/containsExactly(1, 2)/' src/test/java/com/example/bookshop/ordering/OrderTest.java
ana@vm:~/bookshop$ mvn test -Dtest=OrderTest
[INFO] Scanning for projects...
[INFO] 
[INFO] ------------------------< com.example:bookshop >------------------------
[INFO] Building bookshop 0.1.0
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-resources-plugin:3.5.0:resources (default-resources) @ bookshop ---
[INFO] Copying 4 resources from src/main/resources to target/classes
[INFO] Copying 3 resources from src/main/resources to target/classes
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:compile (default-compile) @ bookshop ---
[INFO] Nothing to compile - all classes are up to date.
[INFO] 
[INFO] --- maven-resources-plugin:3.5.0:testResources (default-testResources) @ bookshop ---
[INFO] skip non existing resourceDirectory /home/ana/bookshop/src/test/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:testCompile (default-testCompile) @ bookshop ---
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 3 source files with javac [debug parameters release 25] to target/test-classes
[INFO] 
[INFO] --- maven-surefire-plugin:3.5.6:test (default-test) @ bookshop ---
[INFO] Using auto detected provider org.apache.maven.surefire.junitplatform.JUnitPlatformProvider
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.example.bookshop.ordering.OrderTest
[ERROR] Tests run: 2, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 0.119 s <<< FAILURE! -- in com.example.bookshop.ordering.OrderTest
[ERROR] com.example.bookshop.ordering.OrderTest.totalIsTheSumOfQuantityTimesPrice -- Time elapsed: 0.081 s <<< FAILURE!
org.opentest4j.AssertionFailedError: 

Expecting actual:
  [2, 1]
to contain exactly (and in same order):
  [1, 2]
but there were differences at these indexes:
  - element at index 0: expected "1" but was "2"
  - element at index 1: expected "2" but was "1"

	at com.example.bookshop.ordering.OrderTest.totalIsTheSumOfQuantityTimesPrice(OrderTest.java:23)

[INFO] 
[INFO] Results:
[INFO] 
[ERROR] Failures: 
[ERROR]   OrderTest.totalIsTheSumOfQuantityTimesPrice:23 
Expecting actual:
  [2, 1]
to contain exactly (and in same order):
  [1, 2]
but there were differences at these indexes:
  - element at index 0: expected "1" but was "2"
  - element at index 1: expected "2" but was "1"

[INFO] 
[ERROR] Tests run: 2, Failures: 1, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  2.647 s
[INFO] Finished at: 2026-10-22T20:20:57-03:00
[INFO] ------------------------------------------------------------------------
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-surefire-plugin:3.5.6:test (default-test) on project bookshop: There are test failures.
[ERROR] 
[ERROR] See /home/ana/bookshop/target/surefire-reports for the individual test results.
[ERROR] See dump files (if any exist) [date].dump, [date]-jvmRun[N].dump and [date].dumpstream.
[ERROR] -> [Help 1]
[ERROR] 
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR] 
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoFailureException
```

A mensagem mostra a lista inteira que obteve, a lista inteira que esperava e **cada posição em que as
duas diferem**. Um `assertTrue(quantities.equals(List.of(1, 2)))` puro teria impresso `expected:
<true> but was: <false>`, e você estaria acrescentando um `println` para descobrir o que a lista
continha. Volte a ordem e quebre o total:

```
ana@vm:~/bookshop$ sed -i 's/containsExactly(1, 2)/containsExactly(2, 1)/; s/isEqualTo(11670)/isEqualTo(11680)/' src/test/java/com/example/bookshop/ordering/OrderTest.java
ana@vm:~/bookshop$ mvn test -Dtest=OrderTest | grep -A3 "AssertionFailedError"
org.opentest4j.AssertionFailedError: 

expected: 11680
 but was: 11670
```

`expected: 11680` e `but was: 11670`, cada um na sua linha, de modo que os dois números ficam um
embaixo do outro. Volte o arquivo e confira que os quinze passam:

```
ana@vm:~/bookshop$ sed -i 's/isEqualTo(11680)/isEqualTo(11670)/' src/test/java/com/example/bookshop/ordering/OrderTest.java
ana@vm:~/bookshop$ mvn test | grep -E "Tests run:|BUILD"
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.079 s -- in com.example.bookshop.ordering.OrderTest
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.020 s -- in take
[INFO] Tests run: 0, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.024 s -- in com.example.bookshop.catalogue.BookTest
[INFO] Tests run: 10, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.083 s -- in com.example.bookshop.catalogue.IsbnTest
[INFO] Tests run: 15, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

As duas bibliotecas estão no classpath e a livraria usa as duas, o que é comum: o `assertThrows` do
JUnit para exceções e as asserções dele para verificações de uma linha, o AssertJ onde a mensagem
precisa descrever uma coleção ou um objeto. O AssertJ tem a sua própria forma de verificar uma
exceção, `assertThatThrownBy`, para um projeto que queira um estilo só.
