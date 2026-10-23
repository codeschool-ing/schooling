---
title: Um método que devolve this
version: 1
---

Uma **interface fluente** é uma classe desenhada para que as chamadas a ela possam ser encadeadas
numa expressão só, que se lê quase como uma frase. Não há sintaxe especial por trás. **Cada método
devolve um objeto, e a próxima chamada é feita no que voltou.** Quando o objeto que volta é o mesmo,
a cadeia continua trabalhando nele.

## O que você já conhece

O `StringBuilder.append` devolve o builder em que foi chamado, então em `~/fluent`:

```java
// Chains.java
public class Chains {
    public static void main(String[] args) {
        StringBuilder note = new StringBuilder()
                .append("loan ")
                .append(42)
                .append(": due ")
                .append("2026-10-12");
        System.out.println(note);
    }
}
```

```
ana@vm:~/fluent$ javac Chains.java && java Chains
loan 42: due 2026-10-12
```

Quatro chamadas, um objeto. Cada `append` acrescentou o seu pedaço e devolveu `this`, e o `append`
seguinte foi chamado nele. Dividido em instruções separadas, o mesmo código repetiria o nome da
variável quatro vezes sem dizer nada a mais.

## Escrevendo um

O recibo da biblioteca acrescenta linhas, guarda um total e devolve a si mesmo em `line`:

```java
// Receipt.java
import java.util.ArrayList;
import java.util.List;

public class Receipt {
    private final List<String> lines = new ArrayList<>();
    private long totalCents;

    public Receipt line(String what, long cents) {
        lines.add(what + ": " + cents + " cents");
        totalCents += cents;
        return this;
    }

    public String print() {
        return String.join("\n", lines) + "\ntotal: " + totalCents + " cents";
    }
}
```

```java
// ReceiptDemo.java
public class ReceiptDemo {
    public static void main(String[] args) {
        String text = new Receipt()
                .line("late fee, Iracema", 150)
                .line("replacement card", 500)
                .print();
        System.out.println(text);
    }
}
```

```
ana@vm:~/fluent$ javac Receipt.java ReceiptDemo.java && java ReceiptDemo
late fee, Iracema: 150 cents
replacement card: 500 cents
total: 650 cents
```

**`return this;` é a técnica inteira.** O `line` altera o recibo e devolve o mesmo recibo, então o
`ReceiptDemo` pode chamar `line` de novo, e depois `print`, que encerra a cadeia devolvendo uma
`String`. O recibo nunca tem nome no `ReceiptDemo`: é criado, preenchido e impresso dentro de uma
expressão só.

## Onde a cadeia quebra

Um setter no estilo JavaBeans da lição 22 devolve `void`, e não há em que chamar o próximo método:

```java
// Card.java
public class Card {
    private String name;
    private int number;

    public void setName(String name) {
        this.name = name;
    }

    public void setNumber(int number) {
        this.number = number;
    }
}
```

```java
// CardDemo.java
public class CardDemo {
    public static void main(String[] args) {
        Card card = new Card();
        card.setName("Ana").setNumber(1042);
    }
}
```

```
ana@vm:~/fluent$ javac Card.java CardDemo.java
CardDemo.java:5: error: void cannot be dereferenced
        card.setName("Ana").setNumber(1042);
                           ^
1 error
```

`void cannot be dereferenced` quer dizer "a expressão à esquerda deste ponto não tem valor". A
correção não é fazer todo setter devolver `this`: a introspecção `java.beans` do próprio JDK só
reconhece um setter quando ele devolve `void`, e as ferramentas construídas sobre ela não enxergam os
outros. **Encadear é um desenho para uma classe cujo propósito inteiro é ser configurada de uma vez**,
como um recibo ou uma consulta, e o desenho mais claro desse tipo é o builder da seção 03.
