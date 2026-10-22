---
title: Conjuntos, e a ordem que cada um guarda
version: 1
---

Um `Set` guarda cada elemento uma vez. Acrescente algo que ele já tem e nada muda; o `add` responde
`false` para avisar. **O que surpreende não é a unicidade, e sim a ordem**, porque as três classes de
`Set` do dia a dia guardam três ordens diferentes, e um programa que imprime um `HashSet` e parece
certo hoje fez uma promessa que a classe nunca fez.

```java
// Orders.java
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;

public class Orders {
    public static void main(String[] args) {
        List<String> borrowed = List.of("Dune", "Emma", "Ulysses", "Beloved", "Dune", "Emma", "Middlemarch");

        Set<String> hash = new HashSet<>(borrowed);
        Set<String> linked = new LinkedHashSet<>(borrowed);
        Set<String> tree = new TreeSet<>(borrowed);

        System.out.println("list          " + borrowed);
        System.out.println("HashSet       " + hash);
        System.out.println("LinkedHashSet " + linked);
        System.out.println("TreeSet       " + tree);
        System.out.println("add Dune again? " + tree.add("Dune"));
    }
}
```

```
ana@vm:~/colls$ java Orders.java
list          [Dune, Emma, Ulysses, Beloved, Dune, Emma, Middlemarch]
HashSet       [Beloved, Dune, Ulysses, Middlemarch, Emma]
LinkedHashSet [Dune, Emma, Ulysses, Beloved, Middlemarch]
TreeSet       [Beloved, Dune, Emma, Middlemarch, Ulysses]
add Dune again? false
```

Sete títulos entraram e cinco saíram de cada conjunto: o segundo `Dune` e o segundo `Emma` foram
descartados. Depois, as três ordens:

| classe | ordem | como encontra um elemento | o que exige do elemento |
|---|---|---|---|
| `HashSet` | nenhuma em que se possa confiar | pelo `hashCode`, depois pelo `equals` | `equals` e `hashCode` que concordem |
| `LinkedHashSet` | a ordem da primeira inserção | igual, mais uma lista passando pelas entradas | o mesmo |
| `TreeSet` | ordenada | comparando, descendo uma árvore balanceada | `Comparable`, ou um `Comparator` |

**A ordem do `HashSet` é a que os seus baldes produzirem**, aqui `Beloved, Dune, Ulysses,
Middlemarch, Emma`. Ela é a mesma em toda execução deste programa, porque o hash code de uma `String`
é calculado a partir dos caracteres, e essa constância é a armadilha. Acrescente mais elementos e o
conjunto aumenta a tabela e a ordem se embaralha; troque a classe dos elementos e ela muda de novo. Um
teste que compara um `HashSet` impresso com uma string fixa passa até o dia em que não passa.

Quando a ordem importa, diga isso com a classe. O `LinkedHashSet` gasta um pouco de memória com a
lista que passa pelas entradas e lhe devolve a ordem de inserção. O `TreeSet` mantém os elementos
ordenados, em ordem alfabética para strings, e acrescenta alguns métodos de navegação como `first()`
e `ceiling(x)`.

## O contrato que um hash exige

`HashSet` e `HashMap` encontram um elemento em dois passos. O hash code escolhe um balde, e o
`equals` compara dentro dele. **Dois objetos que são `equals` precisam ter o mesmo `hashCode`**, senão
o primeiro passo os manda para baldes diferentes e o segundo nunca roda. A lição 24 sobrescreveu o
`equals` corretamente; aqui está uma classe que o sobrescreve e esquece a outra metade:

```java
// BrokenKey.java
import java.util.HashSet;
import java.util.Objects;
import java.util.Set;

public class BrokenKey {
    static class Book {
        final String isbn;
        Book(String isbn) { this.isbn = isbn; }

        @Override
        public boolean equals(Object o) {
            return o instanceof Book b && b.isbn.equals(isbn);
        }
        // no hashCode: Object's is used, one per object
    }

    public static void main(String[] args) {
        Set<Book> shelf = new HashSet<>();
        shelf.add(new Book("978-0441013593"));
        shelf.add(new Book("978-0441013593"));
        System.out.println("size " + shelf.size());
        System.out.println("contains " + shelf.contains(new Book("978-0441013593")));
        System.out.println("equal? " + new Book("978-0441013593").equals(new Book("978-0441013593")));
    }
}
```

```
ana@vm:~/colls$ java BrokenKey.java
size 2
contains false
equal? true
```

Três linhas, cada uma verdadeira e juntas absurdas. Os dois livros são iguais, o conjunto guarda os
dois, e não consegue encontrar um terceiro igual. **Sem `hashCode`, vale a versão de `Object`, que dá
a cada objeto um número próprio**, e livros iguais caem em baldes diferentes. Nada falhou e nada
avisou: o conjunto simplesmente está errado.

O conserto é um método ao lado do `equals`, feito dos mesmos campos:

```java
@Override
public int hashCode() {
    return Objects.hash(isbn);
}
```

Ponha-o no `BrokenKey.java` no lugar do comentário que diz `no hashCode`, e execute o arquivo de novo:

```
ana@vm:~/colls$ java BrokenKey.java
size 1
contains true
equal? true
```

O `import java.util.Objects;` no topo do arquivo estava lá para esta linha. Os records da lição 29
escrevem os dois métodos para você, a partir dos componentes, e nunca esquecem um dos dois.
