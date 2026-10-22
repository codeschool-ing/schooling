---
title: JSON vindo de fora
version: 1
---

**JSON de outro programa é entrada, e entrada é o que quer que o autor tenha mandado.** Um campo pode
faltar, um a mais pode chegar, um número pode vir por extenso, e o texto pode parar no meio. O programa
abaixo lê cinco entradas assim com dois mappers: o padrão da seção anterior, e um mandado recusar mais.
Salve-o como `src/main/java/com/example/catalogue/Input.java`, ao lado do `App`:

```java
// src/main/java/com/example/catalogue/Input.java
package com.example.catalogue;

import tools.jackson.core.JacksonException;
import tools.jackson.databind.DeserializationFeature;
import tools.jackson.databind.json.JsonMapper;

public class Input {
    public static void main(String[] args) {
        JsonMapper lenient = JsonMapper.builder().build();
        JsonMapper strict = JsonMapper.builder()
                .enable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES)
                .enable(DeserializationFeature.FAIL_ON_MISSING_CREATOR_PROPERTIES)
                .build();
        String[] inputs = {
            "{\"title\":\"Dune\",\"author\":\"Frank Herbert\",\"year\":1965}",
            "{\"title\":\"Dune\",\"author\":\"Frank Herbert\",\"year\":1965,\"isbn\":\"0441013597\"}",
            "{\"title\":\"Dune\"}",
            "{\"title\":\"Dune\",\"author\":\"Frank Herbert\",\"year\":\"nineteen sixty-five\"}",
            "{\"title\":\"Dune\",",
        };
        for (String in : inputs) {
            System.out.println(in);
            System.out.println("  lenient: " + read(lenient, in));
            System.out.println("  strict:  " + read(strict, in));
        }
    }

    static String read(JsonMapper mapper, String json) {
        try {
            return mapper.readValue(json, Book.class).toString();
        } catch (JacksonException e) {
            return e.getClass().getSimpleName() + ": " + e.getOriginalMessage();
        }
    }
}
```

O `-Dexec.mainClass` troca a classe indicada no `pom.xml` por uma execução:

```
ana@vm:~/catalogue$ mvn -q compile exec:java -Dexec.mainClass=com.example.catalogue.Input
WARNING: A terminally deprecated method in sun.misc.Unsafe has been called
WARNING: sun.misc.Unsafe::objectFieldOffset has been called by com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper (file:/usr/share/maven/lib/guava.jar)
WARNING: Please consider reporting this to the maintainers of class com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper
WARNING: sun.misc.Unsafe::objectFieldOffset will be removed in a future release
{"title":"Dune","author":"Frank Herbert","year":1965}
  lenient: Book[title=Dune, author=Frank Herbert, year=1965]
  strict:  Book[title=Dune, author=Frank Herbert, year=1965]
{"title":"Dune","author":"Frank Herbert","year":1965,"isbn":"0441013597"}
  lenient: Book[title=Dune, author=Frank Herbert, year=1965]
  strict:  UnrecognizedPropertyException: Unrecognized property "isbn" (class com.example.catalogue.Book), not marked as ignorable
{"title":"Dune"}
  lenient: Book[title=Dune, author=null, year=0]
  strict:  MismatchedInputException: Missing creator property 'author' (index 1); `DeserializationFeature.FAIL_ON_MISSING_CREATOR_PROPERTIES` enabled
{"title":"Dune","author":"Frank Herbert","year":"nineteen sixty-five"}
  lenient: InvalidFormatException: Cannot deserialize value of type `int` from String "nineteen sixty-five": not a valid `int` value
  strict:  InvalidFormatException: Cannot deserialize value of type `int` from String "nineteen sixty-five": not a valid `int` value
{"title":"Dune",
  lenient: StreamReadException: Unexpected end-of-input within/between Object entries
  strict:  StreamReadException: Unexpected end-of-input within/between Object entries
```

## Cinco entradas, dois mappers

A primeira entrada é a certa, e os dois a leram. As duas últimas falharam nos dois: **um ano escrito por
extenso e um texto que para no meio não são um `Book` em leitura nenhuma**, e o Jackson disse isso com uma
exceção que nomeia o tipo e o valor. Todas as exceções dele são `JacksonException`, que no Jackson 3 é não
verificada, então um lambda pode chamar o `readValue` sem embrulho nenhum, ao contrário do `Files.size` da
aula 20.

As duas do meio são as que merecem atenção. **O mapper padrão aceitou as duas sem dizer nada.** Ele pulou o
`isbn` para o qual não tinha componente, e montou um `Book` sem autor e com o ano 0 a partir de um objeto
que não tinha nenhum dos dois: um livro publicado no ano 0, por ninguém, está agora no programa, e nada vai
perceber até uma página mostrá-lo. O mapper rigoroso recusou cada uma, dizendo o campo.

| recurso | recusa | padrão no Jackson 3 |
|---|---|---|
| `FAIL_ON_UNKNOWN_PROPERTIES` | um campo para o qual a classe não tem lugar | desligado |
| `FAIL_ON_MISSING_CREATOR_PROPERTIES` | um argumento do construtor que o JSON deixou de fora | desligado |

Qual ligar depende de quem escreve o JSON. Aceitar campos desconhecidos deixa o outro lado acrescentar um
sem quebrar todos os leitores; recusar os que faltam está quase sempre certo para dados em que o programa
vai confiar. De todo jeito, **as verificações que são dos dados pertencem ao record**: um construtor
compacto que recusa um título em branco ou um ano no futuro roda quando o Jackson monta o record, porque o
Jackson o monta por esse construtor, então nenhum JSON consegue fazer um `Book` inválido.

## O único ajuste que traz o perigo de volta

O Jackson pode ser mandado gravar nomes de classe no JSON e montar a classe que encontrar lá, o que se
chama tipagem polimórfica ou **default typing**. Ela vem desligada, e ligada para entrada de fora, o JSON
vira de novo o problema da seção 03: quem envia escolhe as classes. Deixe-a desligada; onde um campo pode
mesmo guardar vários tipos, nomeie os subtipos permitidos no tipo base com `@JsonSubTypes`, que é uma lista
de permissão escrita no código.
