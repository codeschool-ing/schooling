---
title: O objeto que percorre uma coleção
version: 1
---

As lições 32 e 33 puseram elementos em coleções, e todos saíram de novo por um laço `for-each` ou um
`toString`. Nenhum dos dois lê a coleção diretamente. **Os dois pedem à coleção um `Iterator`**, um
objeto pequeno cuja única função é entregar os elementos um por vez, e o laço conversa com esse
objeto. Vê-lo diretamente explica o erro da seção 03, e o remédio da seção 04.

## Dois métodos e uma promessa

Um `Iterator<E>` tem dois métodos que importam. O `hasNext()` responde se há outro elemento, e o
`next()` o devolve e avança. Toda lista e todo conjunto da lição 32 têm um método `iterator()` que
cria um novo, posicionado antes do primeiro elemento; um mapa não tem o seu próprio e empresta um
por `keySet()`, `values()` ou `entrySet()`. Salve isto num diretório novo, `~/iter`:

```java
// Walk.java
import java.util.Iterator;
import java.util.List;

public class Walk {
    public static void main(String[] args) {
        List<String> shelf = List.of("Dune", "Emma", "Ulysses");

        Iterator<String> it = shelf.iterator();
        while (it.hasNext()) {
            String title = it.next();
            System.out.println("next     " + title);
        }
        System.out.println("hasNext  " + it.hasNext());
        it.next();
    }
}
```

```
ana@vm:~/iter$ java Walk.java
next     Dune
next     Emma
next     Ulysses
hasNext  false
Exception in thread "main" java.util.NoSuchElementException
	at java.base/java.util.ImmutableCollections$ListItr.next(ImmutableCollections.java:401)
	at Walk.main(Walk.java:15)
```

O laço `while` é o protocolo inteiro: perguntar, pegar, repetir. Depois que o último título foi
pego, o `hasNext` respondeu `false`, e chamar `next()` mesmo assim lançou `NoSuchElementException`.
**O iterador guarda a própria posição, e nada a reinicia**; para percorrer a estante de novo, peça à
lista um iterador novo.

Repare de onde veio a exceção: `ImmutableCollections$ListItr.next`. Essa é a classe do iterador que
o `List.of` criou, uma classe que ninguém importa pelo nome. **Cada coleção fornece a sua própria
classe de iterador**, escrita para a sua estrutura, e é assim que uma única sintaxe de laço percorre
uma lista sobre array, uma corrente de nós e uma tabela hash.

## No que um laço `for-each` se transforma

A crença comum é que o `for-each` é um recurso que a JVM entende. Não é; o `javac` o reescreve no
laço acima. Este arquivo usa um, e o `javap -c` mostra o que o compilador fez dele:

```java
// Shelf.java
import java.util.List;

public class Shelf {
    static int letters(List<String> titles) {
        int n = 0;
        for (String t : titles) {
            n += t.length();
        }
        return n;
    }

    public static void main(String[] args) {
        System.out.println(letters(List.of("Dune", "Emma", "Ulysses")));
    }
}
```

```
ana@vm:~/iter$ javac Shelf.java && java Shelf
15
ana@vm:~/iter$ javap -c Shelf | grep -E "invoke(interface|virtual)"
         3: invokeinterface #7,  1            // InterfaceMethod java/util/List.iterator:()Ljava/util/Iterator;
        10: invokeinterface #13,  1           // InterfaceMethod java/util/Iterator.hasNext:()Z
        19: invokeinterface #19,  1           // InterfaceMethod java/util/Iterator.next:()Ljava/lang/Object;
        30: invokevirtual #25                 // Method java/lang/String.length:()I
        15: invokevirtual #51                 // Method java/io/PrintStream.println:(I)V
```

**Três chamadas de interface: `List.iterator`, depois `Iterator.hasNext` e `Iterator.next`**, nos
deslocamentos 3, 10 e 19 do bytecode de `letters`. A quarta linha é a chamada a `length` no corpo do
laço, e a última pertence ao `main`. Não há instrução para "for each" em lugar nenhum: a JVM viu as
chamadas comuns da lição 1.

Essa reescrita também é a regra de quais laços compilam. **Um `for-each` funciona sobre um array ou
sobre qualquer coisa que implemente `Iterable`**, a interface do único método `iterator()`. Toda
lista e todo conjunto da lição 32 a implementam, e uma classe sua também pode, que é como um laço
`for (Loan l : member)` poderia passar a funcionar.
