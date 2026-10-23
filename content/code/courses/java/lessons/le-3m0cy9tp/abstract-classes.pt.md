---
title: Uma classe que não pode ser instanciada
version: 1
---

O `Item` da lição 20 era uma classe comum, então `new Item("Untitled", 2020)` compilava, e dava à
biblioteca um objeto que não é nem livro nem DVD, emprestado por catorze dias padrão que ninguém
escolheu. **Algumas classes existem só para serem estendidas**, e o Java deixa que digam isso: uma
classe `abstract` não pode ser instanciada, e um método `abstract` é um que ela declara e deixa para
cada subclasse escrever.

Crie um diretório para esta lição, `~/abstract`, e salve nele quatro arquivos. A superclasse, agora
abstrata, com `loanDays()` declarado e não escrito:

```java
// Item.java
public abstract class Item {
    private final String title;

    protected Item(String title) {
        this.title = title;
    }

    public String title() {
        return title;
    }

    public abstract int loanDays();

    public String describe() {
        return title + ", " + loanDays() + " days";
    }
}
```

Uma subclasse que o escreve, uma que esquece, e um programa que tenta a coisa proibida:

```java
// Book.java
public class Book extends Item {
    public Book(String title) {
        super(title);
    }

    @Override
    public int loanDays() {
        return 14;
    }
}
```
```java
// Magazine.java
public class Magazine extends Item {
    public Magazine(String title) {
        super(title);
    }
}
```
```java
// Desk.java
public class Desk {
    public static void main(String[] args) {
        Item item = new Book("Effective Java");
        System.out.println(item.describe());
        Item mystery = new Item("Untitled");
    }
}
```
```
ana@vm:~/abstract$ javac Item.java Book.java Desk.java
Desk.java:6: error: Item is abstract; cannot be instantiated
        Item mystery = new Item("Untitled");
                       ^
1 error
```

**`Item is abstract; cannot be instantiated`** (`Item` é abstrata; não pode ser instanciada). A
variável `item` tem o tipo `Item`, o que é permitido e útil, e guarda um `Book`, que é concreto. O que
não pode existir é um objeto cuja classe seja o próprio `Item`. Depois a classe que esqueceu:

```
ana@vm:~/abstract$ javac Magazine.java
Magazine.java:2: error: Magazine is not abstract and does not override abstract method loanDays() in Item
public class Magazine extends Item {
       ^
1 error
```

**`Magazine is not abstract and does not override abstract method loanDays() in Item`**: o
compilador nomeia o método que ainda falta, e as duas saídas estão na frase. Escreva o `loanDays()`,
ou declare `Magazine` abstrata também e deixe para as subclasses *dela*. Uma classe concreta tem de ter
corpo para todo método, herdado ou seu, e o compilador confere isso antes de qualquer objeto poder
ser criado.

O programa em si está certo quando a linha proibida sai. Apague-a e compile de novo:

```
ana@vm:~/abstract$ sed -i '/Item mystery/d' Desk.java && javac Item.java Book.java Desk.java && java Desk
Effective Java, 14 days
```

O `describe()` é um método concreto da classe abstrata, e chama o `loanDays()`, que `Item` nunca
escreveu. **Esse é o sentido de um método abstrato: o código da superclasse pode chamá-lo, e todo
objeto sobre o qual ele vier a rodar tem um, garantido.** Um método abstrato não tem corpo e termina
em ponto e vírgula, e uma classe que tem um precisa ser declarada `abstract`.
