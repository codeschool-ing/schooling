---
title: Referências a construtores
version: 1
---

**`NomeDaClasse::new` é uma referência a um construtor**, e a sua forma é escolhida pelo tipo-alvo
como a de qualquer outra referência. Uma classe com vários construtores dá várias formas, e o
compilador escolhe o construtor cujos parâmetros combinam com o método da interface:

```java
// Constructors.java: one class, three constructor references, and an array
import java.util.List;
import java.util.function.BiFunction;
import java.util.function.Function;
import java.util.function.IntFunction;

public class Constructors {
    record Book(String title, int year) {
        Book(String title) {
            this(title, 0);
        }
    }

    public static void main(String[] args) {
        Function<String, Book> undated = Book::new;
        BiFunction<String, Integer, Book> dated = Book::new;
        System.out.println(undated.apply("Beowulf"));
        System.out.println(dated.apply("Dune", 1965));

        IntFunction<String[]> slots = String[]::new;
        System.out.println(slots.apply(3).length);

        List<String> titles = List.of("Emma", "Dune", "Ulysses");
        String[] asArray = titles.toArray(String[]::new);
        System.out.println(asArray.length + " " + asArray[2]);
    }
}
```

```
ana@vm:~/fp/references$ java Constructors.java
Book[title=Beowulf, year=0]
Book[title=Dune, year=1965]
3
3 Ulysses
```

`Book::new` apareceu duas vezes e significou dois construtores. Onde se queria uma
`Function<String, Book>`, serviu o construtor de um argumento; onde se queria uma
`BiFunction<String, Integer, Book>`, serviu o de dois argumentos do próprio record. **O texto da
referência é o mesmo; o tipo-alvo escolhe o construtor.**

`String[]::new` é uma referência à construção de um array, e a sua forma é `IntFunction<String[]>`:
dê a ela um tamanho e receba um array vazio desse tamanho. Ela existe quase só para uma chamada, o
`toArray`, que a usa para montar um array do tipo e do tamanho certos. Antes do Java 11 essa chamada
se escrevia `titles.toArray(new String[0])`, e você vai ver essa forma em código mais antigo.

## Onde são usadas

Uma referência a construtor é o que você passa quando uma API precisa de **um jeito de fazer coisas,
não das coisas em si**:

| chamada | o que recebe | o que faz com isso |
|---|---|---|
| `map.computeIfAbsent(key, k -> new ArrayList<>())` | uma `Function` | monta uma lista só quando a chave é nova |
| `Collectors.toCollection(TreeSet::new)` (aula 8) | um `Supplier` | monta a coleção que um stream enche |
| `stream.toArray(String[]::new)` (aula 7) | uma `IntFunction` | monta o array onde vão os resultados |

A primeira linha está escrita como lambda de propósito. `computeIfAbsent` passa a chave para a
função, então `ArrayList::new` ali significa `k -> new ArrayList<>(k)`. Com chaves `String` isso não
compila, porque `ArrayList` não tem construtor que receba uma string. Com chaves `Integer` compila, e
usa em silêncio a chave como capacidade inicial da lista nova, o que ninguém quis dizer. A seção 05
traz mais casos em que o lambda é a melhor escolha.
