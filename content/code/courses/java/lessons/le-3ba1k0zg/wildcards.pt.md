---
title: Curingas, e a lista que não é uma lista de números
version: 1
---

Um `Integer` é um `Number`, então a crença comum é que uma `List<Integer>` é uma `List<Number>`. **Não
é, e o compilador diz isso**:

```java
// Invariant.java
import java.util.List;

public class Invariant {
    static double total(List<Number> amounts) {
        double sum = 0;
        for (Number n : amounts) {
            sum += n.doubleValue();
        }
        return sum;
    }

    public static void main(String[] args) {
        List<Integer> fines = List.of(2, 5, 3);
        System.out.println(total(fines));
    }
}
```

```
ana@vm:~/generics$ javac Invariant.java
Invariant.java:15: error: incompatible types: List<Integer> cannot be converted to List<Number>
        System.out.println(total(fines));
                                 ^
Note: Some messages have been simplified; recompile with -Xdiags:verbose to get full output
1 error
```

A recusa protege alguma coisa. Se uma `List<Integer>` pudesse ser passada como `List<Number>`, o
método que a recebe poderia chamar `amounts.add(2.5)`, que é um `Number` perfeitamente válido, e a
lista de inteiros de quem chamou passaria a guardar um `Double`. **Tipos genéricos são invariantes**:
`List<Integer>` e `List<Number>` são dois tipos sem relação, qualquer que seja a relação entre
`Integer` e `Number`.

Mas o `total` nunca acrescenta nada. Ele só lê, e ler números de uma lista de inteiros é seguro. Um
**curinga** (wildcard) é como um método diz isso.

## `? extends` para ler, `? super` para escrever

```java
// Wild.java
import java.util.ArrayList;
import java.util.List;

public class Wild {
    static double total(List<? extends Number> amounts) {
        double sum = 0;
        for (Number n : amounts) {
            sum += n.doubleValue();
        }
        return sum;
    }

    static <T> void copy(List<? super T> to, List<? extends T> from) {
        for (T item : from) {
            to.add(item);
        }
    }

    public static void main(String[] args) {
        List<Integer> fines = List.of(2, 5, 3);
        List<Double> fees = List.of(1.5, 0.25);
        System.out.println(total(fines));
        System.out.println(total(fees));

        List<Number> all = new ArrayList<>();
        copy(all, fines);
        copy(all, fees);
        System.out.println(all);
    }
}
```

```
ana@vm:~/generics$ javac Wild.java && java Wild
10.0
1.75
[2, 5, 3, 1.5, 0.25]
```

**`List<? extends Number>` quer dizer "uma lista de algum tipo que é um `Number`"**, sem dizer qual. O
`total` aceitou uma `List<Integer>` e uma `List<Double>`, e conseguiu ler cada elemento como `Number`.
O que ele não consegue é acrescentar a essa lista, porque não sabe que tipo ela guarda de verdade;
`amounts.add(1)` não compilaria.

O `copy` precisa das duas direções. Ele lê `T`s de `from` e os escreve em `to`, então `from` é
`? extends T`, qualquer coisa que produza `T`s, e `to` é `? super T`, qualquer coisa que os aceite.
Com `T` inferido como `Integer` e depois `Double`, uma `List<Number>` aceitou os dois, e imprimiu
`[2, 5, 3, 1.5, 0.25]`.

A regra tem uma sigla, **PECS: producer `extends`, consumer `super`** (quem produz usa `extends`,
quem consome usa `super`). Um parâmetro de que o método lê é um produtor; um parâmetro em que ele
escreve é um consumidor. Um parâmetro com que ele faz as duas coisas não leva curinga nenhum, só
`List<T>`.

| o parâmetro é | escreva | o método pode |
|---|---|---|
| lido | `List<? extends T>` | tirar elementos como `T` |
| escrito | `List<? super T>` | pôr `T`s nele |
| lido e escrito | `List<T>` | os dois, para exatamente um `T` |
| nenhum dos dois, só contado ou esvaziado | `List<?>` | chamar `size`, `clear`, `isEmpty` |

Você encontra isso mais nas assinaturas do próprio JDK do que escrevendo: o `Collections.copy` é
declarado quase exatamente como o `copy` acima, e o `addAll` recebe uma `Collection<? extends E>`.
