---
title: O tipo da variável e a classe do objeto
version: 1
---

Uma variável em Java tem um tipo que está escrito no código e nunca muda: `Item item` é uma variável
`Item` enquanto existir. O objeto ao qual ela se refere tem uma classe, fixada quando o `new` rodou,
e pode ser qualquer subclasse de `Item`. **São dois tipos diferentes, e cada um decide uma coisa
diferente.** A maior parte da confusão com polimorfismo vem de tratá-los como um só.

| | de onde vem | conhecido quando | decide |
|---|---|---|---|
| **tipo declarado** | a declaração da variável, `Item item` | na compilação | quais métodos podem ser chamados |
| **classe real** | o `new` que construiu o objeto | na execução | qual corpo de um método sobrescrito roda |

## Três objetos atrás de um tipo

Em `~/binding`, um pai e duas subclasses que sobrescrevem o seu único método:

```java
// Item.java
public class Item {
    public String describe() {
        return "an item";
    }
}
```

```java
// Book.java
public class Book extends Item {
    private final String isbn;

    public Book(String isbn) {
        this.isbn = isbn;
    }

    @Override
    public String describe() {
        return "a book";
    }

    public String isbn() {
        return isbn;
    }
}
```

```java
// Dvd.java
public class Dvd extends Item {
    @Override
    public String describe() {
        return "a DVD";
    }
}
```

```java
// Desk.java
public class Desk {
    public static void main(String[] args) {
        Item[] items = { new Book("978-85-359-0277-2"), new Dvd(), new Item() };
        for (Item item : items) {
            System.out.println(item.describe());
        }
    }
}
```

```
ana@vm:~/binding$ javac *.java && java Desk
a book
a DVD
an item
```

Três elementos, todos declarados `Item`, e três respostas diferentes. **O laço chamou `describe()`
num `Item` toda vez, e cada objeto rodou a sua própria sobrescrita**: a do livro, a do DVD, e para o
`Item` simples, a original. Nada no `Desk` menciona `Book` ou `Dvd` depois de o array ser montado.

## O tipo declarado limita o que se pode pedir

`Book` tem um método que `Item` não tem. Por uma variável `Item` ele fica fora de alcance, mesmo
quando o objeto é um livro:

```java
// Visible.java
public class Visible {
    public static void main(String[] args) {
        Item item = new Book("978-85-359-0277-2");
        System.out.println(item.isbn());
    }
}
```

```
ana@vm:~/binding$ javac Visible.java
Visible.java:5: error: cannot find symbol
        System.out.println(item.isbn());
                               ^
  symbol:   method isbn()
  location: variable item of type Item
1 error
```

A mensagem diz exatamente o que o compilador olhou: `variable item of type Item`. **O compilador
nunca vê objetos, só declarações**, e `Item` não declara nenhum `isbn()`. Que o objeto construído na
linha de cima seja um `Book` é um fato do tempo de execução, e o compilador não raciocina sobre ele.

## Um cast é uma promessa que a JVM confere

```java
// Casts.java
public class Casts {
    public static void main(String[] args) {
        Item[] items = { new Book("978-85-359-0277-2"), new Dvd() };
        for (Item item : items) {
            if (item instanceof Book book) {
                System.out.println("checked: " + book.isbn());
            }
        }
        Book forced = (Book) items[1];
        System.out.println(forced.isbn());
    }
}
```

```
ana@vm:~/binding$ javac Casts.java && java Casts
checked: 978-85-359-0277-2
Exception in thread "main" java.lang.ClassCastException: class Dvd cannot be cast to class Book (Dvd and Book are in unnamed module of loader 'app')
	at Casts.main(Casts.java:10)
```

O padrão `instanceof` perguntou primeiro, então o livro imprimiu o ISBN e o DVD foi pulado. **O cast
simples `(Book) items[1]` não perguntou**: ele disse ao compilador "confie em mim, isto é um
`Book`", e o compilador aceitou, porque um `Item` poderia ser um. A JVM não confiou. Ela conferiu a
classe real no momento do cast, encontrou um `Dvd`, e lançou `ClassCastException` na linha 10,
nomeando as duas classes. Então um cast leva a conferência da compilação para a execução; nunca a
pula. Prefira a forma com `instanceof`, que transforma uma queda num desvio.
