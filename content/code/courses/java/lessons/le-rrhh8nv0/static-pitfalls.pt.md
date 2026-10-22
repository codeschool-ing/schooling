---
title: O que dá errado com static
version: 1
---

O `static` é fácil de acrescentar e difícil de tirar, porque tudo o que toca um membro estático passa
a contar com a existência de exatamente um. Três coisas dão errado com frequência suficiente para
valer a pena vê-las uma vez.

## Compartilhado por engano

Uma biblioteca com duas filiais quer saber quantos livros cada uma tem emprestados:

```java
// Branch.java
class Branch {
    static int booksOnLoan = 0;
    String name;

    Branch(String name) {
        this.name = name;
    }

    void lend() {
        booksOnLoan = booksOnLoan + 1;
    }
}
```

```java
// Branches.java
public class Branches {
    public static void main(String[] args) {
        Branch centro = new Branch("Centro");
        Branch norte = new Branch("Norte");
        centro.lend();
        centro.lend();
        norte.lend();
        System.out.println(centro.name + ": " + centro.booksOnLoan);
        System.out.println(norte.name + ": " + norte.booksOnLoan);
    }
}
```

```
ana@vm:~/static$ javac Branches.java && java Branches
Centro: 3
Norte: 3
```

O Centro emprestou dois e o Norte um, e os dois dizem 3. **Uma palavra, `static`, transformou uma
contagem por filial numa contagem da biblioteca**, e nada falhou: os números são plausíveis e
errados. Ler o atributo por `centro.` e `norte.` escondeu isso, que é o hábito contra o qual a seção
02 alertou; `Branch.booksOnLoan` teria parecido o que é. Tirar o `static` dá a cada filial a sua
contagem.

Estado estático mutável tem um segundo custo que um programa pequeno não mostra. O programa inteiro o
compartilha, então qualquer código em qualquer lugar pode alterá-lo, e um teste de uma classe pode
deixar para trás um valor que muda o teste seguinte. Contadores compartilhados existem, e
`Member.created` é um razoável, mas **um atributo estático que muda é o primeiro suspeito quando duas
partes de um programa discordam.**

## Constantes, e a cópia que o compilador guarda

Um valor que nunca muda é o uso seguro de static: `static final`, uma cópia, inalterável. O `final` é
a lição 16, e aqui basta saber que o atributo não pode ser atribuído de novo. Constantes têm nome em
maiúsculas por convenção, como a lição 3 disse:

```java
// Limits.java
class Limits {
    static final int MAX_LOANS = 3;
}
```

```java
// LimitMain.java
public class LimitMain {
    public static void main(String[] args) {
        System.out.println("A member may borrow " + Limits.MAX_LOANS + " books");
    }
}
```

A biblioteca sobe o limite para 5, e alguém edita o `Limits.java` e compila só esse arquivo:

```java
// Limits.java
class Limits {
    static final int MAX_LOANS = 5;
}
```

```
ana@vm:~/static$ javac LimitMain.java Limits.java && java LimitMain
A member may borrow 3 books
ana@vm:~/static$ javac Limits.java && java LimitMain
A member may borrow 3 books
ana@vm:~/static$ javap -c LimitMain | grep -A4 "main("
  public static void main(java.lang.String[]);
    Code:
         0: getstatic     #7                  // Field java/lang/System.out:Ljava/io/PrintStream;
         3: ldc           #15                 // String A member may borrow 3 books
         5: invokevirtual #17                 // Method java/io/PrintStream.println:(Ljava/lang/String;)V
ana@vm:~/static$ javac LimitMain.java Limits.java && java LimitMain
A member may borrow 5 books
```

O `Limits.class` agora diz 5, e o `LimitMain` continuou imprimindo 3. O `javap` mostra por quê: o
`LimitMain` nunca lê `Limits.MAX_LOANS`. **Um atributo `static final` de tipo primitivo ou `String`,
com um valor que o compilador consegue calcular, é uma constante de compilação.** O `javac` copia o
valor dela para toda classe que a usa. Aqui ele foi além e montou a frase inteira na compilação, com
o `3` dentro. Só compilar o `LimitMain` de novo pegou o 5. O Maven, a partir da lição 18, recompila o
que depende de um arquivo alterado, o que é um dos motivos de projetos serem construídos por uma
ferramenta e não com um `javac` de cada vez.

## Imports estáticos

O `import static` deixa um arquivo usar os membros estáticos de outra classe sem o nome da classe:

```java
// Imports.java
import static java.lang.Math.PI;
import static java.lang.Math.max;

public class Imports {
    public static void main(String[] args) {
        System.out.println(max(3, 7));
        System.out.println(PI);
    }
}
```

```
ana@vm:~/static$ javac Imports.java && java Imports
7
3.141592653589793
```

Economiza digitação, e custa a quem lê a única pista que o `Math.` dava sobre onde o `max` mora. Use
para alguns nomes lidos o tempo todo e reconhecidos na hora, e escreva a classe por extenso no resto.
