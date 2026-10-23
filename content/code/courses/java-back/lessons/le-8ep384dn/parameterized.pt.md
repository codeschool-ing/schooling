---
title: Um teste, muitas entradas
version: 1
---

O primeiro `IsbnTest` confere um ISBN válido e um errado. A regra tem mais jeitos de dar errado do
que isso: doze dígitos, catorze, um hífen, uma letra. Copiar um método cinco vezes para trocar uma
string é como classes de teste crescem até mil linhas que ninguém lê. Um **teste parametrizado** é um
método que o JUnit roda uma vez por argumento, e relata uma vez por argumento.

Substitua `IsbnTest.java` pela versão final:

```schooling-example
{
  "language": "java",
  "file": "IsbnTest.java",
  "parts": [
    {
      "code": "package com.example.bookshop.catalogue;\n\nimport static org.junit.jupiter.api.Assertions.assertFalse;\nimport static org.junit.jupiter.api.Assertions.assertTrue;\n\nimport org.junit.jupiter.api.Test;\nimport org.junit.jupiter.params.ParameterizedTest;\nimport org.junit.jupiter.params.provider.CsvSource;\nimport org.junit.jupiter.params.provider.ValueSource;\n",
      "note": "Três imports novos, de `junit-jupiter-params`: a anotação que torna um método parametrizado e duas **fontes** que lhe dão argumentos. `@Test` continua para o único caso sem entrada para variar."
    },
    {
      "code": "class IsbnTest {\n\n    @ParameterizedTest\n    @ValueSource(strings = {\"9786500000016\", \"9786500000023\", \"9786500000030\", \"9780306406157\"})\n    void acceptsAValidIsbn13(String isbn) {\n        assertTrue(Isbn.isValid(isbn));\n    }\n",
      "note": "`@ValueSource` dá um argumento por invocação, aqui quatro strings, então o método roda quatro vezes, com `isbn` valendo cada uma. O `9786500000030` de Frankenstein é o único cujo dígito verificador é 0, e a próxima seção mostra quanto isso vale."
    },
    {
      "code": "    @ParameterizedTest(name = \"{1}: {0}\")\n    @CsvSource({\n            \"9786500000017, wrong check digit\",\n            \"978650000001, twelve digits\",\n            \"97865000000160, fourteen digits\",\n            \"978-6500000016, a hyphen\",\n            \"97865000000X6, a letter\"\n    })\n    void refusesAnythingElse(String isbn, String reason) {\n        assertFalse(Isbn.isValid(isbn));\n    }\n",
      "note": "`@CsvSource` dá uma linha por invocação, quebrada nas vírgulas entre os parâmetros do método: o ISBN e umas palavras sobre o que há de errado com ele. A asserção nunca lê `reason`. Ele está ali pelo nome: `\"{1}: {0}\"` nomeia cada invocação pelo segundo argumento e depois pelo primeiro."
    },
    {
      "code": "    @Test\n    void refusesNull() {\n        assertFalse(Isbn.isValid(null));\n    }",
      "note": "`null` não pode ser escrito num `@ValueSource` de strings, então fica com um teste simples só dele. O Jupiter também tem `@NullSource` para isso; um método separado deixa o caso visível pelo nome."
    },
    {
      "code": "}"
    }
  ]
}
```

Rode só esta classe com `-Dtest`, e fique com as linhas que contam:

```
ana@vm:~/bookshop$ mvn test -Dtest=IsbnTest | grep -E "Running|Tests run|BUILD"
[INFO] Running com.example.bookshop.catalogue.IsbnTest
[INFO] Tests run: 10, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.152 s -- in com.example.bookshop.catalogue.IsbnTest
[INFO] Tests run: 10, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

**Dez testes vindos de três métodos**: quatro invocações do primeiro, cinco do segundo e um teste
simples. O surefire conta cada invocação como um teste, e uma falha numa delas derruba só aquela; as
outras nove continuam rodando e relatando.

## Os nomes, e quem os imprime

O relatório do surefire chama uma invocação pela assinatura do método e pelo índice:

```
ana@vm:~/bookshop$ grep -o "testcase name=\"[^\"]*\"" target/surefire-reports/TEST-com.example.bookshop.catalogue.IsbnTest.xml
testcase name="refusesNull"
testcase name="acceptsAValidIsbn13(String)[1]"
testcase name="acceptsAValidIsbn13(String)[2]"
testcase name="acceptsAValidIsbn13(String)[3]"
testcase name="acceptsAValidIsbn13(String)[4]"
testcase name="refusesAnythingElse(String, String)[1]"
testcase name="refusesAnythingElse(String, String)[2]"
testcase name="refusesAnythingElse(String, String)[3]"
testcase name="refusesAnythingElse(String, String)[4]"
testcase name="refusesAnythingElse(String, String)[5]"
```

Isso é tudo o que o Maven imprime sobre elas, e `[3]` não diz qual ISBN era o terceiro. O padrão
`name` escrito em `refusesAnythingElse` serve para o que imprime os **nomes de exibição** do próprio
JUnit. A janela de testes de uma IDE imprime: IntelliJ IDEA, Eclipse e VS Code desenham a árvore de
testes com esses nomes. No terminal, quem imprime é o **console launcher** do JUnit, e são dois
comandos para tê-lo. O primeiro copia o launcher, um jar único no Maven Central, para `target`; o
segundo grava o classpath de teste num arquivo:

```
ana@vm:~/bookshop$ mvn -q dependency:copy -Dartifact=org.junit.platform:junit-platform-console-standalone:6.0.3 -DoutputDirectory=target
ana@vm:~/bookshop$ mvn -q dependency:build-classpath -Dmdep.outputFile=target/test.cp
```

Depois rode a classe por ele. `--details=testfeed` imprime uma linha quando cada teste começa e outra
quando termina, e `grep -v STARTED` fica com a segunda:

```
ana@vm:~/bookshop$ java -jar target/junit-platform-console-standalone-6.0.3.jar execute --disable-banner --disable-ansi-colors --details=testfeed --class-path "target/test-classes:target/classes:$(cat target/test.cp)" --select-class com.example.bookshop.catalogue.IsbnTest | grep -v STARTED
JUnit Jupiter > IsbnTest > refusesNull() :: SUCCESSFUL
JUnit Jupiter > IsbnTest > acceptsAValidIsbn13(String) > [1] isbn = "9786500000016" :: SUCCESSFUL
JUnit Jupiter > IsbnTest > acceptsAValidIsbn13(String) > [2] isbn = "9786500000023" :: SUCCESSFUL
JUnit Jupiter > IsbnTest > acceptsAValidIsbn13(String) > [3] isbn = "9786500000030" :: SUCCESSFUL
JUnit Jupiter > IsbnTest > acceptsAValidIsbn13(String) > [4] isbn = "9780306406157" :: SUCCESSFUL
JUnit Jupiter > IsbnTest > refusesAnythingElse(String, String) > "wrong check digit": "9786500000017" :: SUCCESSFUL
JUnit Jupiter > IsbnTest > refusesAnythingElse(String, String) > "twelve digits": "978650000001" :: SUCCESSFUL
JUnit Jupiter > IsbnTest > refusesAnythingElse(String, String) > "fourteen digits": "97865000000160" :: SUCCESSFUL
JUnit Jupiter > IsbnTest > refusesAnythingElse(String, String) > "a hyphen": "978-6500000016" :: SUCCESSFUL
JUnit Jupiter > IsbnTest > refusesAnythingElse(String, String) > "a letter": "97865000000X6" :: SUCCESSFUL

Test run finished after 251 ms
[         6 containers found      ]
[         0 containers skipped    ]
[         6 containers started    ]
[         0 containers aborted    ]
[         6 containers successful ]
[         0 containers failed     ]
[        10 tests found           ]
[         0 tests skipped         ]
[        10 tests started         ]
[         0 tests aborted         ]
[        10 tests successful      ]
[         0 tests failed          ]
```

Há dois tipos de nome ali. `acceptsAValidIsbn13` não tem padrão, então cada invocação recebe o nome
padrão do JUnit, `[índice] parâmetro = valor`: dá para ler o ISBN e também a posição dele na lista.
`refusesAnythingElse` tem `"{1}: {0}"`, então as invocações se chamam `"wrong check digit":
"9786500000017"` e assim por diante, o motivo primeiro. Os dois são melhores que `[3]`; o segundo se
lê como a lista dos casos que a regra recusa, que é o que um revisor quer conferir se está completo.

O resumo do próprio launcher, no fim, conta **containers** além de testes. Os seis containers são os
três engines que o jar do launcher carrega (ele traz o JUnit Vintage e um engine de suítes junto com
o Jupiter, use o projeto ou não), a classe e os dois métodos parametrizados. Os dez testes são as
invocações e o teste simples, como o surefire contou.

## Quando parar de acrescentar linhas

Um teste parametrizado deixa as linhas baratas, e linhas baratas se multiplicam. Cada linha deveria
ser um caso que a regra trata de um jeito diferente: uma linha por jeito de ser inválido, e um ISBN
válido para cada coisa que a conta faz de um jeito diferente. Mais cinco ISBNs válidos que terminam
todos num dígito verificador diferente de zero acrescentam cinco linhas ao relatório e nada ao que se
sabe. A próxima seção mostra a linha desta classe que vale mais do que todas as outras.
