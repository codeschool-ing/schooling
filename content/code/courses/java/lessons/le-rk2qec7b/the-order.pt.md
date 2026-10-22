---
title: Sete passos, numa ordem fixa
version: 1
---

Quando `new Book()` roda, parece um acontecimento só. **São sete, para uma classe com uma
superclasse, e a ordem deles é fixada pela linguagem**, não pelo lugar das linhas no arquivo nem pela
classe que você por acaso lê primeiro. A ordem importa no momento em que um passo usa o que outro
preparou, e a seção 04 é o que dá errado quando isso acontece.

Este programa numera cada passo e o imprime. `Item` é a superclasse e `Book` a estende, o mesmo par
que a lição 20 construiu, reduzido a nada além de anúncios. `note` é um auxiliar estático que imprime
o argumento e o devolve, para que um inicializador de campo também possa se anunciar:

```java
// Order.java
class Item {
    static {
        System.out.println("1  Item: static block");
    }

    {
        System.out.println("3  Item: instance block");
    }

    Item() {
        System.out.println("4  Item: constructor body");
    }
}

class Book extends Item {
    static {
        System.out.println("2  Book: static block");
    }

    private String title = note("5  Book: field initialiser");

    {
        System.out.println("6  Book: instance block");
    }

    Book() {
        System.out.println("7  Book: constructor body");
    }

    static String note(String step) {
        System.out.println(step);
        return step;
    }
}

public class Order {
    public static void main(String[] args) {
        System.out.println("main: before the first Book");
        new Book();
        System.out.println("main: before the second Book");
        new Book();
    }
}
```

Salve-o como `Order.java` em `~/init` e execute. As três classes estão num arquivo só, o que é
permitido porque só `Order` é `public`:

```
ana@vm:~/init$ javac Order.java && java Order
main: before the first Book
1  Item: static block
2  Book: static block
3  Item: instance block
4  Item: constructor body
5  Book: field initialiser
6  Book: instance block
7  Book: constructor body
main: before the second Book
3  Item: instance block
4  Item: constructor body
5  Book: field initialiser
6  Book: instance block
7  Book: constructor body
ana@vm:~/init$ ls *.class
Book.class
Item.class
Order.class
Shelf.class
```

Um arquivo-fonte virou três arquivos de classe, um por classe, e é por isso que a JVM consegue
inicializá-las separadamente. O `Shelf.class` é da seção 02.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"A ordem em que o Java inicializa um Book que estende Item. Uma vez, na primeira vez que Book é usado: 1, os inicializadores e blocos estáticos de Item; 2, os de Book. Depois, a cada new Book: 3, os inicializadores de campo e blocos de instância de Item; 4, o corpo do construtor de Item; 5, os inicializadores de campo de Book; 6, os blocos de instância de Book; 7, o corpo do construtor de Book. A superclasse sempre termina antes de a subclasse começar.\"><defs><marker id=\"jv27-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"200\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma vez, no primeiro uso de Book</text><text x=\"360\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a cada new Book()</text><rect x=\"20\" y=\"40\" width=\"124\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"82\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1  Item</text><text x=\"82\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">bloco estático</text><rect x=\"160\" y=\"40\" width=\"124\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"222\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2  Book</text><text x=\"222\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">bloco estático</text><path d=\"M144 68 H158\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv27-a)\"></path><rect x=\"20\" y=\"140\" width=\"124\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"82\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3  Item</text><text x=\"82\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">bloco de instância</text><path d=\"M144 168 H158\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv27-a)\"></path><rect x=\"160\" y=\"140\" width=\"124\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"222\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">4  Item</text><text x=\"222\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">corpo do construtor</text><path d=\"M284 168 H298\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv27-a)\"></path><rect x=\"300\" y=\"140\" width=\"124\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"362\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">5  Book</text><text x=\"362\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">inicializador de campo</text><path d=\"M424 168 H438\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv27-a)\"></path><rect x=\"440\" y=\"140\" width=\"124\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"502\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">6  Book</text><text x=\"502\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">bloco de instância</text><path d=\"M564 168 H578\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv27-a)\"></path><rect x=\"580\" y=\"140\" width=\"124\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"642\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">7  Book</text><text x=\"642\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">corpo do construtor</text><path d=\"M222 96 V118 H82 V138\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv27-a)\"></path><rect x=\"20\" y=\"226\" width=\"680\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a superclasse primeiro, nos dois níveis; dentro de uma classe, a ordem do código</text></svg>", "caption": "Os passos 1 e 2 acontecem uma vez por classe, qualquer que seja o número de objetos. Os passos 3 a 7 acontecem para cada objeto, e a parte da superclasse sempre termina antes de a da subclasse começar."}
```

Três regras produzem essa saída, e cada uma está visível nela.

**Uma classe é inicializada de forma preguiçosa, na primeira vez que é usada.** `main: before the
first Book` saiu antes dos dois blocos estáticos. O `Order` foi inicializado para rodar o `main`, e
`Item` e `Book` esperaram até o `new Book()` precisar deles. Uma classe que o programa nunca toca
nunca roda os seus blocos estáticos.

**A superclasse vem primeiro, nos dois níveis.** Antes de `Book` poder ser inicializada, `Item`
precisa ser, então o passo 1 é de `Item`. E antes de a parte `Book` de um objeto ser construída, a
parte `Item` termina: os passos 3 e 4 rodam antes do passo 5. Essa segunda parte é a chamada
`super()` da lição 20. Todo construtor começa chamando o da superclasse, escrito por você ou
acrescentado pelo compilador, e os inicializadores de campo, os blocos de instância e o corpo do
construtor da superclasse rodam todos dentro dessa chamada.

**Dentro de uma classe, inicializadores e blocos rodam na ordem em que estão escritos.** Em `Book` o
campo `title` está declarado acima do bloco de instância, então o passo 5 vem antes do 6. Troque os
dois de lugar no código e as duas linhas trocam de lugar na saída. Só depois de todos eles roda o
corpo do construtor, que é o passo 7.

O segundo `Book` mostra o que acontece quando a classe já está pronta: os passos 1 e 2 sumiram. **A
inicialização estática acontece uma vez por classe, e a de instância uma vez por objeto**, e essa é
toda a diferença entre os dois tipos de bloco.

O `Object`, superclasse de `Item`, também está na corrente, acima do passo 3. O construtor dele não
faz nada visível, então não imprime nada; a lição 20 mostrou que `Item` o estende, esteja isso
escrito ou não.
