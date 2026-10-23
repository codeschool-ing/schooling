---
title: Um stream se usa uma vez, e deixa a fonte em paz
version: 1
---

**Um stream pode ser consumido uma vez.** Depois da operação terminal ele está terminado, e pedir
qualquer outra coisa a ele é erro. Ele também nunca muda a coleção de onde veio, e a lista que o
`toList()` devolve também não pode ser mudada. Três programas curtos, três exceções:

```java
// Once.java: three things a stream will not do
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Stream;

public class Once {
    public static void main(String[] args) {
        Stream<Book> classics = Shelf.BOOKS.stream().filter(b -> b.genre().equals("classic"));
        System.out.println(classics.count() + " classics");
        try {
            System.out.println(classics.count() + " classics, again");
        } catch (IllegalStateException e) {
            System.out.println("second use: " + e.getMessage());
        }

        List<String> titles = Shelf.BOOKS.stream().map(Book::title).toList();
        try {
            titles.add("Moby-Dick");
        } catch (UnsupportedOperationException e) {
            System.out.println("toList() is read-only: " + e);
        }

        List<String> mutable = new ArrayList<>(List.of("Emma", "Dune"));
        try {
            mutable.stream().forEach(t -> mutable.add(t + " (copy)"));
        } catch (java.util.ConcurrentModificationException e) {
            System.out.println("changing the source mid-stream: " + e);
        }
    }
}
```

```
ana@vm:~/fp/streams$ java Once.java
6 classics
second use: stream has already been operated upon or closed
toList() is read-only: java.lang.UnsupportedOperationException
changing the source mid-stream: java.util.ConcurrentModificationException
```

## Um stream é um percurso

A primeira exceção é a que todo mundo encontra. **Um stream está mais perto de um iterador que de uma
lista**: uma passada única pela fonte, que se gasta conforme anda. Guardar um stream numa variável
para usar duas vezes é, portanto, um erro de projeto, não de sintaxe. O conserto é guardar a
**fonte**, ou um `Supplier<Stream<Book>>` que monta um stream novo a cada vez, e começar um pipeline
novo para cada pergunta.

## Os resultados são só de leitura

O `toList()`, que chegou no Java 16, devolve uma lista imutável, e o `add` lançou
`UnsupportedOperationException`. Isso é de propósito: o resultado de uma consulta é um valor, e o
código que quer editá-lo deve dizer isso com `new ArrayList<>(stream.toList())`. Código mais antigo
usa `collect(Collectors.toList())`, que devolve uma lista que pode ser mudada; a aula 8 explica os
coletores.

## Deixe a fonte em paz

O último caso mudou a lista de dentro do próprio stream dela, e o stream percebeu:
`ConcurrentModificationException`. **Os lambdas de um pipeline não devem mudar a fonte que estão
lendo**, nem nada mais de que o pipeline dependa. A regra tem nome na documentação, não
interferência, e é a mesma que a aula 34 do curso `java` deu para iteradores, pelo mesmo motivo: o
percurso e a mudança discordariam sobre o que está lá. Quando o resultado deve ser uma lista nova, o
stream a monta com `toList()`; a antiga fica como estava.
