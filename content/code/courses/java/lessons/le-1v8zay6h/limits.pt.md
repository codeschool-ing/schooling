---
title: Onde a herança deixa de compensar
version: 1
---

A herança é o recurso que os iniciantes pegam primeiro, porque economiza digitação na hora. Os custos
chegam depois e de longe. **Uma subclasse depende de como a superclasse foi escrita, e não só do que
ela promete**, e esse é um laço mais forte que qualquer outro na linguagem. Três limites, um na
sintaxe e dois no projeto.

## Uma mãe só

Uma classe estende exatamente uma classe. Um audiolivro é um livro e, de certo modo, uma gravação, e
o Java não deixa uma classe dizer isso. Faça `Book` estender as duas:

```
ana@vm:~/inherit$ sed -i 's/public class Book extends Item {/public class Book extends Item, Dvd {/' Book.java && javac Book.java
Book.java:2: error: '{' expected
public class Book extends Item, Dvd {
                              ^
1 error
```

O compilador nem chega a uma explicação: depois de `extends Item` ele esperava o corpo da classe, `{`,
e encontrou uma vírgula. **A herança simples de classes é uma regra da gramática**, escolhida para que
um método nunca possa ser herdado de dois lugares com dois corpos. Uma classe pode implementar
quantas **interfaces** quiser, que prometem comportamento sem quase nada desse risco, e a lição 23 é
sobre elas. Ponha o `Book.java` de volta como a seção 02 o tem antes de seguir.

## O teste do "é um"

`extends` diz que todo objeto da subclasse **é um** objeto da superclasse, e pode ser usado onde quer
que um seja esperado. Um `Book` é um `Item`, e um `Dvd` é um `Item`: onde o programa empresta um
item, qualquer um serve. Antes de escrever `extends`, diga a frase. "Um `Loan` é um `Book`" é falsa:
um empréstimo **tem** um livro, e essa relação é um atributo, não uma superclasse. Herdar para pegar
um código que você quer, de uma classe da qual você não é um tipo, é o mau uso mais comum do recurso.

## O código da superclasse faz parte do seu

Uma estante deve contar quantos ISBNs já foram postos nela. O `HashSet` já guarda um conjunto de
strings, então o movimento óbvio é estendê-lo e contar nos dois métodos que acrescentam:

```java
// CountingSet.java
import java.util.Collection;
import java.util.HashSet;
import java.util.List;

public class CountingSet extends HashSet<String> {
    private int added;

    @Override
    public boolean add(String isbn) {
        added++;
        return super.add(isbn);
    }

    @Override
    public boolean addAll(Collection<? extends String> isbns) {
        added += isbns.size();
        return super.addAll(isbns);
    }

    public static void main(String[] args) {
        CountingSet shelf = new CountingSet();
        shelf.addAll(List.of("978-0134685991", "978-0596009205", "978-1617293566"));
        System.out.println(shelf.added + " added, " + shelf.size() + " on the shelf");
    }
}
```

(`Collection<? extends String>` é o tipo exato do parâmetro de `HashSet.addAll`, que uma sobrescrita
tem de repetir; a lição 35 explica o `?`.) Três ISBNs entram, numa chamada:

```
ana@vm:~/inherit$ java CountingSet.java
6 added, 3 on the shelf
```

**Seis acrescentados, para três ISBNs.** Nada em `CountingSet` está errado sozinho. O `addAll` somou
três, e então o `super.addAll` fez o seu trabalho chamando `add` uma vez por elemento, e o `add` está
sobrescrito, então cada um foi contado de novo. Se o `HashSet.addAll` chama ou não o `add` não está no
contrato dele; é um detalhe de como ele por acaso foi escrito, e **uma subclasse que sobrescreve
métodos depende desses detalhes**. Uma versão futura poderia mudá-los, e a contagem mudaria junto, sem
uma edição nesta classe.

A saída é parar de ser um conjunto e passar a **ter** um. `CountingShelf` guarda um `HashSet` num
atributo privado e oferece só os métodos que pretende:

```java
// CountingShelf.java
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class CountingShelf {
    private final Set<String> isbns = new HashSet<>();
    private int added;

    public void add(String isbn) {
        added++;
        isbns.add(isbn);
    }

    public void addAll(List<String> more) {
        for (String isbn : more) {
            add(isbn);
        }
    }

    public int size() {
        return isbns.size();
    }

    public static void main(String[] args) {
        CountingShelf shelf = new CountingShelf();
        shelf.addAll(List.of("978-0134685991", "978-0596009205", "978-1617293566"));
        System.out.println(shelf.added + " added, " + shelf.size() + " on the shelf");
    }
}
```
```
ana@vm:~/inherit$ java CountingShelf.java
3 added, 3 on the shelf
```

Isso é **composição**: a estante usa um conjunto do jeito que usa uma string, pelos métodos públicos
dele, e nada do que o `HashSet` faz por dentro alcança a contagem. Custa umas linhas que uma subclasse
teria herdado, `size()` aqui, e compra uma classe cujo comportamento está todo no próprio arquivo.

**Prefira composição, e estenda quando a frase do "é um" for verdadeira e a superclasse tiver sido
projetada para ser estendida.** `Item` foi: é nosso, pequeno, e cada método dele existe para ser
compartilhado ou substituído. O `HashSet` não foi projetado para isso, e não promete nada sobre como
os métodos dele chamam uns aos outros.
A lição 21 é a outra metade disto: uma superclasse escrita para ser estendida, com os lugares que uma
subclasse preenche marcados como tal.
