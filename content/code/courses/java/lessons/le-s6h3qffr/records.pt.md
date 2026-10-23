---
title: Uma classe que é só os seus dados
version: 1
---

Uma classe escrita do jeito longo tem campos privados, um construtor que os define, um acessor para
cada um (lição 22), e depois `equals`, `hashCode` e `toString`, que a lição 24 mostrou serem fáceis
de errar de forma sutil. **Para uma classe cujo trabalho inteiro é carregar alguns valores, isso é uma
página de código que diz uma coisa só**, e cada linha dela é uma linha que alguém pode quebrar numa
edição. Desde o Java 16 há um jeito mais curto de dizer isso.

Um **record** declara os campos no cabeçalho, como **componentes**, e o compilador escreve todo o
resto. Dois deles, em `~/records`. O ISBN foi inventado para a lição:

```java
// Records.java
record Isbn(String value) {
}

record Book(Isbn isbn, String title, int year) {
}

public class Records {
    public static void main(String[] args) {
        Book a = new Book(new Isbn("9788535902771"), "Dom Casmurro", 1899);
        Book b = new Book(new Isbn("9788535902771"), "Dom Casmurro", 1899);

        System.out.println(a);
        System.out.println(a.title() + ", " + a.year());
        System.out.println(a == b);
        System.out.println(a.equals(b));
        System.out.println(a.hashCode() == b.hashCode());
    }
}
```

```
ana@vm:~/records$ javac Records.java && java Records
Book[isbn=Isbn[value=9788535902771], title=Dom Casmurro, year=1899]
Dom Casmurro, 1899
false
true
true
```

Cinco linhas de saída, cinco coisas que o compilador escreveu:

- **O `toString` imprime o nome do record e todos os componentes**, e o `Isbn` lá dentro se imprime do
  mesmo jeito. Nada de `Book@` e um hash code, que é o que a classe da lição 12 imprimia.
- **Os acessores têm o nome dos componentes, sem `get`**: `a.title()`, e não `a.getTitle()`.
- `a == b` é `false`, porque o `new` rodou duas vezes e fez dois objetos. **O `equals` é `true`,
  porque o `equals` de um record compara todos os componentes**, e os dois livros guardam valores
  iguais. Os hash codes também coincidem, como o `HashSet` e o `HashMap` da lição 32 exigem.

## O que o compilador escreveu

```
ana@vm:~/records$ javap -p Book
Compiled from "Records.java"
final class Book extends java.lang.Record {
  private final Isbn isbn;
  private final java.lang.String title;
  private final int year;
  Book(Isbn, java.lang.String, int);
  public final java.lang.String toString();
  public final int hashCode();
  public final boolean equals(java.lang.Object);
  public Isbn isbn();
  public java.lang.String title();
  public int year();
}
```

Leia comparando com aquela lista:

- **`final class Book extends java.lang.Record`.** Um record não pode ser estendido, e estende
  `Record` do jeito que um enum estende `Enum` (lição 28).
- **Cada componente é um campo `private final`.** Não há setter nem pode haver, então um record fica
  fixo a partir do momento em que é construído. É isso que "imutável" quer dizer no título desta
  lição: os campos não podem ser reatribuídos.
- **Um construtor que recebe todos os componentes, em ordem**, chamado de construtor *canônico*. A
  seção 03 é onde você acrescenta o seu próprio código a ele.
- `toString`, `hashCode` e `equals`, todos gerados a partir dos componentes, e um acessor por
  componente.

Tudo o que estava na lista está lá, e nada disso consegue sair de compasso com os campos. Acrescente
um componente ao cabeçalho e o construtor, o acessor, o `equals`, o `hashCode` e o `toString` o
incluem na próxima compilação. **Dois records com componentes iguais são intercambiáveis**, que é a
definição de um valor, e é por isso que um record é a forma natural de um ISBN, de um intervalo de
datas, de um ponto num mapa ou de uma linha lida de um arquivo.
