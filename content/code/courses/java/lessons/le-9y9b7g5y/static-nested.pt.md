---
title: Uma classe dentro de outra, sem amarras
version: 1
---

Até aqui toda classe teve um arquivo só seu. O Java também deixa você declarar uma classe **dentro**
de outra, e há quatro tipos, que diferem numa pergunta: **um objeto da classe de dentro pertence a um
objeto da classe de fora?** Esta seção é o tipo em que não pertence. A palavra que diz isso é
`static`, a mesma que a lição 15 usou para um atributo que pertence à classe e não a um objeto.

Um catálogo guarda entradas, e uma entrada não significa nada fora de um catálogo. Então `Entry` mora
dentro de `Catalogue`. Crie um diretório para esta lição, `~/nested`, e salve nele:

```java
// Catalogue.java
public class Catalogue {
    static class Entry {
        final String isbn;
        final String title;

        Entry(String isbn, String title) {
            this.isbn = isbn;
            this.title = title;
        }
    }

    private final Entry[] entries = new Entry[10];
    private int size;

    void add(String isbn, String title) {
        entries[size++] = new Entry(isbn, title);
    }

    public static void main(String[] args) {
        Catalogue c = new Catalogue();
        c.add("978-0134685991", "Effective Java");
        c.add("978-0596009205", "Head First Java");
        Catalogue.Entry loose = new Catalogue.Entry("978-1617293566", "Modern Java in Action");
        System.out.println(c.size + " entries; one more built on its own: " + loose.title);
        System.out.println(c.entries[0].title + ", " + c.entries[1].title);
    }
}
```

A classe aninhada é declarada como qualquer outra, com `static` na frente. O código dentro de
`Catalogue` a chama de `Entry`; o código em qualquer outro lugar a chama de **`Catalogue.Entry`**, o
nome de fora, um ponto, o nome de dentro. O `main` usa as duas grafias:

```
ana@vm:~/nested$ javac Catalogue.java && java Catalogue
2 entries; one more built on its own: Modern Java in Action
Effective Java, Head First Java
ana@vm:~/nested$ ls
Catalogue$Entry.class
Catalogue.class
Catalogue.java
```

Duas coisas nessa transcrição são a ideia inteira.

**`new Catalogue.Entry(...)` não precisou de catálogo.** A terceira entrada foi criada no `main` sem
objeto `Catalogue` nenhum por perto. Uma classe aninhada estática é uma classe comum que por acaso foi
declarada dentro de outra; o aninhamento muda o nome dela e o que ela enxerga, e nada no jeito de
criá-la.

**Um arquivo-fonte deu dois arquivos de classe.** A JVM não tem ideia de aninhamento. O compilador
escreve a classe aninhada como uma classe à parte, chamada `Catalogue$Entry`, o nome de fora e o de
dentro unidos por um cifrão. É esse o nome que você vai ver num stack trace e no `javap`, e o motivo
de um `$` num nome de classe nunca querer dizer que você o digitou.

## O que ela enxerga, e o que não enxerga

O aninhamento compra acesso. `Entry` fica dentro das chaves de `Catalogue`, então pode usar tudo o que
`Catalogue` declara, inclusive o que é `private`, e `Catalogue` pode usar os membros privados de
`Entry` em troca. A lição 14 traçou a linha em volta de uma classe; uma classe aninhada está dentro
dessa linha.

O que ela não pode usar é um atributo **de instância** da classe de fora, porque um objeto aninhado
estático não tem objeto de fora de onde lê-lo. `Shelf` tenta:

```java
// Shelf.java
public class Shelf {
    private int capacity = 40;

    static class Label {
        String text() {
            return "Shelf of " + capacity;
        }
    }
}
```
```
ana@vm:~/nested$ javac Shelf.java
Shelf.java:7: error: non-static variable capacity cannot be referenced from a static context
            return "Shelf of " + capacity;
                                 ^
1 error
```

**A capacidade de qual estante?** Um `Label` pode existir sem `Shelf` nenhum, então `capacity` não
tem objeto de onde vir, e o compilador diz isso com as palavras da lição 15: um contexto estático não
alcança um membro de instância. As duas saídas são o assunto do resto da lição. Dê à etiqueta uma
estante a quem perguntar, como parâmetro do construtor, ou tire o `static` e a transforme numa classe
interna, que é o que a seção 03 faz.

## Quando aninhar

**Aninhe uma classe quando ela faz parte da implementação de outra e mais nada a usaria.** O JDK faz
isso o tempo todo. `Map.Entry`, o par que um mapa entrega na lição 32, é uma interface aninhada
estática de `Map`. Os builders, que a lição 26 escreve, são classes aninhadas estáticas da classe que
constroem. A regra prática é começar pela estática: **uma classe aninhada deve ser `static` a menos
que precise de um objeto de fora**. Uma classe interna carrega uma referência escondida, que a seção
03 torna visível, e essa referência custa memória e pode manter vivo o objeto de fora.
