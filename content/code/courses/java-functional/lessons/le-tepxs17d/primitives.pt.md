---
title: As outras trinta e nove
version: 1
---

**O `java.util.function` tem 43 interfaces, e a maioria das que vêm depois das quatro primeiras são
as mesmas formas para `int`, `long` e `double`.** O JDK consegue listar o próprio pacote, porque
suas classes podem ser lidas como um sistema de arquivos no endereço `jrt:/`. Este programa as lê;
ele usa um stream, que a aula 6 explica, e você não precisa acompanhá-lo ainda para ler o que ele
imprimiu:

```java
// ListFunctions.java: every interface in java.util.function, read from the JDK itself
import java.net.URI;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.stream.Stream;

public class ListFunctions {
    public static void main(String[] args) throws Exception {
        Path dir = FileSystems.getFileSystem(URI.create("jrt:/"))
                .getPath("/modules/java.base/java/util/function");
        try (Stream<Path> files = Files.list(dir)) {
            List<String> names = files
                    .map(p -> p.getFileName().toString().replace(".class", ""))
                    .filter(n -> !n.contains("$"))
                    .sorted()
                    .toList();
            System.out.println(names.size() + " interfaces");
            for (int i = 0; i < names.size(); i += 4) {
                System.out.println("  " + String.join(", ", names.subList(i, Math.min(i + 4, names.size()))));
            }
        }
    }
}
```

```
ana@vm:~/fp/interfaces$ java ListFunctions.java
43 interfaces
  BiConsumer, BiFunction, BiPredicate, BinaryOperator
  BooleanSupplier, Consumer, DoubleBinaryOperator, DoubleConsumer
  DoubleFunction, DoublePredicate, DoubleSupplier, DoubleToIntFunction
  DoubleToLongFunction, DoubleUnaryOperator, Function, IntBinaryOperator
  IntConsumer, IntFunction, IntPredicate, IntSupplier
  IntToDoubleFunction, IntToLongFunction, IntUnaryOperator, LongBinaryOperator
  LongConsumer, LongFunction, LongPredicate, LongSupplier
  LongToDoubleFunction, LongToIntFunction, LongUnaryOperator, ObjDoubleConsumer
  ObjIntConsumer, ObjLongConsumer, Predicate, Supplier
  ToDoubleBiFunction, ToDoubleFunction, ToIntBiFunction, ToIntFunction
  ToLongBiFunction, ToLongFunction, UnaryOperator
```

Leia os nomes como uma gramática, não como uma lista:

| parte do nome | significado | exemplo |
|---|---|---|
| `Int`, `Long`, `Double` na frente | a **entrada** é esse primitivo | `IntPredicate` testa um `int` |
| `To...` na frente | a **saída** é esse primitivo | `ToIntFunction<T>` transforma um `T` num `int` |
| `...To...` no meio | entra um primitivo, sai outro | `IntToDoubleFunction` |
| `Obj...Consumer` | entram um objeto e um primitivo | `ObjIntConsumer<T>` |
| `BooleanSupplier` | o único `boolean` que não é `Predicate` | um fornecedor de `true` ou `false` |

## Por que existem: genéricos recebem objetos

Um argumento de tipo precisa ser uma classe, então `Function<Integer, Integer>` não recebe um `int`.
O Java tapa o buraco com **boxing**: embrulha cada `int` num objeto `Integer` na entrada e
desembrulha na saída. Cada embrulho pode ser um objeto novo no heap, e num laço sobre milhões de
números isso são milhões de objetos para criar e recolher. As interfaces primitivas pulam o
embrulho:

```java
// Primitives.java: the same test, boxed and unboxed
import java.util.function.IntPredicate;
import java.util.function.Predicate;
import java.util.function.ToIntFunction;

public class Primitives {
    public static void main(String[] args) {
        Predicate<Integer> evenBoxed = n -> n % 2 == 0;
        IntPredicate even = n -> n % 2 == 0;
        ToIntFunction<String> length = s -> s.length();

        System.out.println(evenBoxed.test(10) + " " + even.test(10));
        System.out.println(length.applyAsInt("Ulysses"));

        Integer a = 1000;
        Integer b = 1000;
        System.out.println("two boxes of 1000 are the same object: " + (a == b));
    }
}
```

```
ana@vm:~/fp/interfaces$ java Primitives.java
true true
7
two boxes of 1000 are the same object: false
```

Os dois predicados respondem igual, e `evenBoxed.test(10)` embrulhou o `10` para chamá-lo. A última
linha é a prova de que caixas são objetos: dois `Integer` de valor 1000 são **dois objetos
diferentes**, e `==` compara objetos, não números (a aula 4 do `java` mostrou a mesma armadilha). Os
nomes dos métodos também mudam, para ninguém confundir uma família com a outra: `applyAsInt`, não
`apply`.

**Use a interface primitiva quando os valores forem números num laço quente**, e não se preocupe com
isso no resto: uma chamada com boxing custa nanossegundos. A aula 6 encontra a mesma divisão nos
streams, onde o `IntStream` existe exatamente por isso.
