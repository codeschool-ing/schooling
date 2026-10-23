---
title: Ligada e não ligada
version: 1
---

**`String::length` e `name::length` parecem iguais e são coisas diferentes.** A primeira é não
ligada: ainda não tem string e recebe uma como argumento, então sua forma é
`Function<String, Integer>`. A segunda é ligada: já guarda a string que está em `name`, não recebe
nada, e sua forma é `Supplier<Integer>`. Qual das duas você tem depende de haver uma classe ou um
objeto antes do `::`.

## Dois argumentos, um receptor

Uma referência não ligada usa **o primeiro argumento como objeto** e passa o resto ao método. É por
isso que `String::compareToIgnoreCase`, um método que recebe uma string, pode ser um
`Comparator<String>`, cujo `compare` recebe duas:

```java
// Unbound.java: an unbound reference takes its object from the first argument
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.function.BiPredicate;

public class Unbound {
    public static void main(String[] args) {
        BiPredicate<String, String> sameIgnoringCase = String::equalsIgnoreCase;
        System.out.println(sameIgnoringCase.test("EMMA", "emma"));

        Comparator<String> byName = String::compareToIgnoreCase;
        List<String> authors = new ArrayList<>(List.of("woolf", "Austen", "eliot", "Brontë"));
        authors.sort(byName);
        System.out.println(authors);
    }
}
```

```
ana@vm:~/fp/references$ java Unbound.java
true
[Austen, Brontë, eliot, woolf]
```

`compare(a, b)` virou `a.compareToIgnoreCase(b)`, e os autores foram ordenados sem levar em conta
maiúsculas e minúsculas.

## Quando o objeto é escolhido

Uma referência ligada **avalia o que vem antes do `::` uma vez, quando a referência é feita**. Um
lambda avalia o corpo cada vez que roda. Com um valor que muda, os dois dão respostas diferentes:

```java
// Bound.java: a bound reference fixes its receiver when it is made; a lambda reads it when it runs
import java.util.function.Supplier;

public class Bound {
    static String current = "Dune";

    public static void main(String[] args) {
        Supplier<Integer> ref = current::length;
        Supplier<Integer> lambda = () -> current.length();
        current = "One Hundred Years of Solitude";
        System.out.println("reference: " + ref.get());
        System.out.println("lambda:    " + lambda.get());

        current = null;
        Supplier<Integer> later = () -> current.length();
        System.out.println("the lambda was made without complaint");
        Supplier<Integer> now = current::length;
        System.out.println("never printed");
    }
}
```

```
ana@vm:~/fp/references$ java Bound.java
reference: 4
lambda:    29
the lambda was made without complaint
Exception in thread "main" java.lang.NullPointerException
	at java.base/java.util.Objects.requireNonNull(Objects.java:220)
	at Bound.main(Bound.java:17)
```

**A referência imprimiu 4, o tamanho de `"Dune"`**, porque tirou a string de `current` quando foi
feita, antes da atribuição. O lambda imprimiu 29, porque leu o campo quando rodou. `current` é um
campo estático aqui para que o lambda possa lê-lo depois de uma mudança; uma variável local teria
sido recusada, como a seção 06 da aula 1 mostrou.

A segunda metade é a mesma regra com um `null`. O lambda que lê um campo `null` foi feito sem
reclamação e só falharia se alguém o chamasse. **A referência ligada falhou na linha que a criou**:
o stack trace aponta para a linha 17 e para `Objects.requireNonNull`, a verificação que o compilador
pôs na frente de toda referência ligada. É um lugar melhor para falhar, já que aponta a linha em que
o `null` entrou, e não uma linha mais adiante por onde ele saiu.
