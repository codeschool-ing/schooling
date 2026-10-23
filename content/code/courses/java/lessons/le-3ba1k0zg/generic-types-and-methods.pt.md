---
title: Escrever uma classe genérica e um método genérico
version: 1
---

`List<E>` não é mágica reservada ao JDK. **Qualquer classe pode receber um parâmetro de tipo**, um
nome entre colchetes angulares depois do nome da própria classe, e usá-lo onde caberia um tipo. A
convenção é uma única letra maiúscula: `T` para um tipo, `E` para um elemento, `K` e `V` para uma
chave e um valor.

O menor exemplo útil é uma caixa que guarda uma coisa de um tipo escolhido por quem a usa:

```java
// Box.java
public class Box<T> {
    private T item;

    public void put(T item) {
        this.item = item;
    }

    public T take() {
        return item;
    }
}
```

Dentro da classe, `T` representa um tipo que ninguém escolheu ainda. **Cada uso de `Box` o escolhe**:
`Box<String>` é uma caixa de strings, `Box<Book>` uma caixa de livros, e o compilador confere cada
`put` e cada `take` contra a escolha. A classe foi escrita uma vez.

Um método pode ter parâmetros de tipo próprios, e o `UseBox` declara um que também diz o que precisa
do tipo:

```schooling-example
{
  "language": "java",
  "file": "UseBox.java",
  "parts": [
    {
      "code": "import java.util.List;\n\npublic class UseBox {\n    static <T extends Comparable<T>> T max(List<T> items) {",
      "note": "**Um método genérico declara o seu próprio parâmetro de tipo**, entre colchetes angulares antes do tipo de retorno. `T extends Comparable<T>` é um **limite** (bound): `T` pode ser qualquer tipo cujos objetos possam ser comparados entre si."
    },
    {
      "code": "        T best = items.get(0);\n        for (T item : items) {\n            if (item.compareTo(best) > 0) {\n                best = item;\n            }\n        }\n        return best;\n    }",
      "note": "**É o limite que torna o `compareTo` chamável.** Sem ele, `T` poderia ser qualquer coisa e o compilador só permitiria os métodos de `Object` em `item`."
    },
    {
      "code": "\n    public static void main(String[] args) {\n        Box<String> box = new Box<>();\n        box.put(\"Dune\");\n        String title = box.take();\n        System.out.println(title.length());",
      "note": "**`Box<String>` fixa `T` como `String` para esta caixa.** O `take()` então devolve uma `String`, sem conversão escrita, e o `length()` está disponível nela. O `<>` à direita é o diamante: o compilador copia o tipo da esquerda."
    },
    {
      "code": "\n        System.out.println(max(List.of(\"Dune\", \"Ulysses\", \"Emma\")));\n        System.out.println(max(List.of(1965, 1815, 1922)));\n    }\n}",
      "note": "**A cada chamada o compilador infere `T`**: `String` na primeira, `Integer` na segunda. Os dois são `Comparable` consigo mesmos, então as duas chamadas compilam, e um método serve aos dois tipos."
    }
  ]
}
```

```
ana@vm:~/generics$ javac Box.java UseBox.java && java UseBox
4
Ulysses
1965
```

`4` é o tamanho de `Dune`, `Ulysses` vem por último na ordem alfabética, e `1965` é o maior ano.
**Um `max`, dois tipos de elemento, e nenhuma conversão em lugar nenhum.**

## Um limite é uma exigência que o compilador cobra

O limite `T extends Comparable<T>` é uma promessa que quem chama precisa cumprir. Um record de sócios
que não podem ser comparados não cumpre:

```java
// NoOrder.java
import java.util.List;

public class NoOrder {
    record Member(String name) {}

    static <T extends Comparable<T>> T max(List<T> items) {
        return items.get(0);
    }

    public static void main(String[] args) {
        System.out.println(max(List.of(new Member("Ana"), new Member("Bruno"))));
    }
}
```

```
ana@vm:~/generics$ javac NoOrder.java
NoOrder.java:12: error: method max in class NoOrder cannot be applied to given types;
        System.out.println(max(List.of(new Member("Ana"), new Member("Bruno"))));
                           ^
  required: List<T>
  found:    List<Member>
  reason: inference variable E has incompatible bounds
    upper bounds: Comparable<T>,Object
    lower bounds: Member
  where T,E are type-variables:
    T extends Comparable<T> declared in method <T>max(List<T>)
    E extends Object declared in method <E>of(E,E)
1 error
```

A mensagem é longa porque relata uma inferência que falhou, e se lê de baixo para cima. **`Member` foi
o tipo encontrado, e ele não é um `Comparable`**, então nenhum `T` satisfaz ao mesmo tempo o que o
`List.of` produziu e o que o `max` exige. A correção pertence a `Member`: implementar
`Comparable<Member>`, como a lição 23 fez com `Book`, ou passar um `Comparator` a uma versão de `max`
que receba um. O `extends` num limite quer dizer "é subtipo de", e se escreve `extends` mesmo quando
o limite é uma interface.
