---
title: Uma interface selada nomeia quem a implementa
version: 1
---

Uma interface comum é aberta: qualquer um, em qualquer arquivo, em qualquer biblioteca compilada anos
depois, pode implementá-la. Foi isso que tornou o `Comparable` útil para `Book`. Às vezes a abertura
é o problema. A biblioteca empresta livros e DVDs, e o código que calcula um prazo de empréstimo quer
saber que tratou todo tipo de item que existe. **Uma interface `sealed` lista todas as classes que
têm permissão para implementá-la**, e o compilador faz valer a lista nos dois sentidos.

## Escrevendo a lista

Em `~/iface/sealed`:

```java
// Item.java
public sealed interface Item permits Book, Dvd {
    String title();
}
```

O `permits` nomeia as duas classes. Cada uma delas tem de dizer, na sua própria declaração, o que
acontece abaixo dela, e uma classe que esquece é recusada:

```java
// Book.java
public final class Book implements Item {
    private final String title;

    public Book(String title) {
        this.title = title;
    }

    @Override
    public String title() {
        return title;
    }
}
```

```java
// Dvd.java
public class Dvd implements Item {
    private final String title;

    public Dvd(String title) {
        this.title = title;
    }

    @Override
    public String title() {
        return title;
    }
}
```

```
ana@vm:~/iface/sealed$ javac Item.java Book.java Dvd.java
Dvd.java:2: error: sealed, non-sealed or final modifiers expected
public class Dvd implements Item {
       ^
1 error
```

**Toda classe permitida escolhe uma de três palavras.** `final` fecha a linha: nada estende `Book`.
`sealed`, com um `permits` próprio, continua a lista um nível abaixo. `non-sealed` a abre de novo
daquela classe em diante, de propósito e por escrito. `Dvd` fica com a terceira:

```java
// Dvd.java
public non-sealed class Dvd implements Item {
    private final String title;

    public Dvd(String title) {
        this.title = title;
    }

    @Override
    public String title() {
        return title;
    }
}
```

## Qualquer outra é recusada

```java
// Magazine.java
public final class Magazine implements Item {
    @Override
    public String title() {
        return "Revista Piauí";
    }
}
```

```
ana@vm:~/iface/sealed$ javac Item.java Book.java Dvd.java Magazine.java
Magazine.java:2: error: class is not allowed to extend sealed class: Item (as it is not listed in its 'permits' clause)
public final class Magazine implements Item {
             ^
1 error
```

A mensagem diz o porquê entre parênteses: `Magazine` não está na cláusula `permits`. Para acrescentar
um tipo de item, você edita o `Item.java`, e é essa a ideia: a lista de tipos mora num lugar só, e
acrescentar a ela é uma mudança que alguém revisa, e não um arquivo aparecendo em outro lugar.

## O que a lista compra

```java
// Rules.java
public class Rules {
    static int loanDays(Item item) {
        return switch (item) {
            case Book b -> 21;
            case Dvd d -> 7;
        };
    }

    public static void main(String[] args) {
        System.out.println(loanDays(new Book("Iracema")));
        System.out.println(loanDays(new Dvd("Central do Brasil")));
    }
}
```

```
ana@vm:~/iface/sealed$ javac *.java && java Rules
21
7
```

**O `switch` não tem `default`, e compila.** A lição 10 mostrou um switch de expressão recusado
quando não cobre todos os valores. Aqui o compilador leu o `permits`, viu que todo `Item` é um `Book`
ou um `Dvd`, e aceitou os dois casos como completos. Se uma terceira classe for um dia acrescentada
ao `permits`, este switch deixa de compilar até alguém decidir o prazo dessa classe, e o mesmo vale
para todo outro switch sobre `Item`. Com uma interface comum e um ramo `default`, a classe nova
ganharia em silêncio o que quer que o `default` dissesse.

Os tipos selados chegaram no Java 17 e o switch sobre eles no Java 21, então nenhum dos dois é
novidade do 25. A lição 29 os junta com records, que é onde mais se usam.
