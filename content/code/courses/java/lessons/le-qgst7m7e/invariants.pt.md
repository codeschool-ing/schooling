---
title: Cumprindo a promessa que a classe fez
version: 1
---

Um **invariante** é algo que uma classe promete ser sempre verdade sobre os seus objetos: uma
prateleira nunca guarda mais livros que a capacidade, um empréstimo sempre tem data de devolução, um
saldo nunca é negativo. Tornar os atributos privados é como a maioria dos invariantes começa. **Não é
onde eles terminam**, porque um atributo privado ainda pode ser entregue, e um atributo que guarda um
objeto mutável entrega junto o poder de alterá-lo.

## Uma prateleira para dois com três livros

```java
// Shelf.java
import java.util.ArrayList;
import java.util.List;

public class Shelf {
    private final List<String> titles = new ArrayList<>();
    private final int capacity;

    public Shelf(int capacity) {
        this.capacity = capacity;
    }

    public void add(String title) {
        if (titles.size() == capacity) {
            throw new IllegalStateException("shelf is full: " + capacity + " books");
        }
        titles.add(title);
    }

    public List<String> getTitles() {
        return titles;
    }
}
```

`add` recusa um terceiro livro, `titles` é privado e final, e a classe parece fechada. Agora um
chamador:

```java
// LeakDemo.java
public class LeakDemo {
    public static void main(String[] args) {
        Shelf shelf = new Shelf(2);
        shelf.add("Dom Casmurro");
        shelf.add("Iracema");
        shelf.getTitles().add("O Guarani");
        System.out.println(shelf.getTitles().size() + " books on a shelf for 2");
    }
}
```

```
ana@vm:~/encap$ javac Shelf.java LeakDemo.java && java LeakDemo
3 books on a shelf for 2
```

**`getTitles()` devolveu a própria lista**, não uma cópia dela. O `private` impediu que alguém desse
nome ao atributo; não fez nada quanto a uma referência ao mesmo `ArrayList` saindo por um método. O
`LeakDemo` então chamou `add` nessa lista, que é o `ArrayList.add` e não sabe nada de prateleiras nem
de capacidades. O `final` também não ajudou: ele fixa a qual lista o atributo se refere, e não diz
nada sobre o que há dentro dela. A lição 30 desenha as duas referências para um objeto; aqui basta o
resultado, que é uma promessa quebrada sem exceção e sem stack trace apontando para lugar nenhum.

## Entregando uma cópia, ou uma vista

```java
// SafeShelf.java
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class SafeShelf {
    private final List<String> titles = new ArrayList<>();
    private final int capacity;

    public SafeShelf(int capacity) {
        this.capacity = capacity;
    }

    public void add(String title) {
        if (titles.size() == capacity) {
            throw new IllegalStateException("shelf is full: " + capacity + " books");
        }
        titles.add(title);
    }

    public List<String> getTitles() {
        return List.copyOf(titles);
    }

    public List<String> view() {
        return Collections.unmodifiableList(titles);
    }
}
```

A `SafeShelf` entrega a lista de dois jeitos, e eles não são a mesma coisa:

| método | o que o chamador recebe | vê o que for acrescentado depois | o chamador pode alterá-la |
|---|---|---|---|
| `getTitles()`, com `List.copyOf` | uma lista nova, congelada no momento da chamada | não | não |
| `view()`, com `Collections.unmodifiableList` | uma janela só de leitura para a própria lista da prateleira | sim | não |

O `SafeDemo` pega uma de cada, acrescenta um livro à prateleira e depois tenta o vazamento de novo:

```java
// SafeDemo.java
import java.util.List;

public class SafeDemo {
    public static void main(String[] args) {
        SafeShelf shelf = new SafeShelf(3);
        shelf.add("Dom Casmurro");
        List<String> copy = shelf.getTitles();
        List<String> view = shelf.view();
        shelf.add("Iracema");
        System.out.println("copy: " + copy);
        System.out.println("view: " + view);
        view.add("O Guarani");
    }
}
```

```
ana@vm:~/encap$ javac SafeShelf.java SafeDemo.java && java SafeDemo
copy: [Dom Casmurro]
view: [Dom Casmurro, Iracema]
Exception in thread "main" java.lang.UnsupportedOperationException
	at java.base/java.util.Collections$UnmodifiableCollection.add(Collections.java:1093)
	at SafeDemo.main(SafeDemo.java:13)
```

**A cópia ficou com um título e a vista mostrou dois**: `Iracema` entrou depois de as duas terem
sido pegas, e só a vista enxerga a prateleira. Depois `view.add` lançou
`UnsupportedOperationException`, em `SafeDemo.java:13`, a linha que tentou. Uma lista vinda de
`List.copyOf` recusa do mesmo jeito. Qualquer uma das duas cumpre a promessa; a escolha depende de o
chamador dever ver a prateleira como ela está agora ou como estava.

## O mesmo vazamento na entrada

A imagem espelhada é um construtor que guarda uma lista recebida. Se a `Shelf` tivesse um construtor
`Shelf(List<String> titles)` que guardasse o argumento como atributo, o chamador continuaria com a
mesma lista e poderia acrescentar coisas depois, passando por cima de toda verificação. **Copie o que
você recebe tanto quanto o que você devolve**: `this.titles = new ArrayList<>(titles);` num
construtor custa uma linha e fecha a segunda porta. Uma `String`, ou um record da lição 29 feito só
de valores assim, não muda depois de construído e não precisa de cópia nenhuma, o que explica boa
parte de por que tipos imutáveis são agradáveis de usar.
