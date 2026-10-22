---
title: Desmontando um record
version: 1
---

Os records chegaram junto com um segundo recurso, e os dois foram projetados como par. **Como um
record é exatamente os seus componentes, o Java consegue desmontá-lo para você**, do jeito que você
tiraria os campos à mão com acessores, e consegue fazer isso dentro de um `switch` ou de um
`instanceof`. O recurso se chama **padrão de record** (record pattern).

A biblioteca empresta livros e DVDs. A interface selada da lição 23 diz que esses são os dois únicos
tipos de item, e os dois são records:

```java
// Patterns.java
sealed interface Item permits Book, Dvd {
}

record Book(String title, int pages) implements Item {
}

record Dvd(String title, int minutes) implements Item {
}

public class Patterns {
    static String describe(Item item) {
        return switch (item) {
            case Dvd(String title, int minutes) -> title + ": " + minutes + " minutes";
            case Book(String title, int pages) when pages > 500 -> title + ": a long book";
            case Book(String title, int pages) -> title + ": " + pages + " pages";
        };
    }

    public static void main(String[] args) {
        Item[] items = {new Book("Dom Casmurro", 256), new Book("Os Sertões", 640), new Dvd("Central do Brasil", 113)};
        for (Item item : items) {
            System.out.println(describe(item));
        }

        Object first = items[0];
        if (first instanceof Book(var title, var pages)) {
            System.out.println("taken apart: " + title + " / " + pages);
        }
    }
}
```

Em `~/records/patterns`:

```
ana@vm:~/records/patterns$ javac Patterns.java && java Patterns
Dom Casmurro: 256 pages
Os Sertões: a long book
Central do Brasil: 113 minutes
taken apart: Dom Casmurro / 256
```

Cada `case` é um padrão, e um padrão faz dois trabalhos ao mesmo tempo:

- **Ele testa.** `case Book(String title, int pages)` só casa quando `item` é um `Book`.
- **Ele desmonta.** Quando casa, `title` e `pages` são variáveis novas guardando os componentes do
  record, prontas para usar à direita da seta. Nenhum cast, e nenhuma chamada a `title()`.

**Uma cláusula `when` acrescenta uma condição**, uma guarda: o primeiro caso `Book` casou só com *Os
Sertões*, cujas 640 páginas passam em `pages > 500`. A ordem dos casos importa por isso. O Java os
testa de cima para baixo, e o caso `Book` sem guarda, abaixo, pega todo livro que a guarda recusou.
Ponha o caso sem guarda primeiro e o compilador recusa o arquivo, porque o caso com guarda nunca
conseguiria casar.

**O `instanceof` também aceita um padrão.** `first instanceof Book(var title, var pages)` testou e
desmontou num passo só, e o `var` deixou o compilador fornecer os tipos dos componentes, que ele já
conhece.

## O `switch` sem `default`

Não há ramo `default` no `describe`, e o compilador o aceitou. Um `switch` sobre um valor do tipo
`Item` precisa cobrir todo `Item` possível, e **o `sealed` diz ao compilador exatamente quais são
esses**: `Book` e `Dvd`, como a cláusula `permits` os lista. Uma cobertura que se confirma na
compilação se chama exaustiva.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Uma interface selada e um switch exaustivo. A interface selada Item permite dois records, Book com title e pages, e Dvd com title e minutes. O switch de describe tem três casos: Dvd, Book com a guarda pages maior que 500, e Book. Todo record permitido chega a pelo menos um caso, então o compilador aceita o switch sem default.\"><defs><marker id=\"jv29-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"260\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sealed interface Item</text><text x=\"150\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">selada: estes dois e nenhum outro</text><rect x=\"20\" y=\"120\" width=\"120\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">record Book</text><text x=\"80\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">title, pages</text><rect x=\"160\" y=\"120\" width=\"120\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"220\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">record Dvd</text><text x=\"220\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">title, minutes</text><path d=\"M80 120 V98 H220 V120 M150 76 V98\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"380\" y=\"20\" width=\"320\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o switch de describe()</text><rect x=\"398\" y=\"58\" width=\"284\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">case Dvd(String title, int minutes)</text><rect x=\"398\" y=\"108\" width=\"284\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">case Book(…) when pages &gt; 500</text><rect x=\"398\" y=\"158\" width=\"284\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">case Book(String title, int pages)</text><text x=\"540\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">testados de cima para baixo</text><path d=\"M80 184 V212 H350 V126 H396\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv29-a)\"></path><path d=\"M350 176 H396\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv29-a)\"></path><path d=\"M280 152 H320 V76 H396\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv29-a)\"></path><rect x=\"20\" y=\"240\" width=\"680\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">todo tipo permitido tem um caso: nada de default</text></svg>", "caption": "A cláusula permits é uma lista completa, então o compilador consegue conferir o switch contra ela. Acrescente um terceiro record à lista e este switch deixa de compilar até ganhar um caso."}
```

Aí alguém acrescenta revistas à biblioteca, no `permits` e como record, e não mexe no `describe`:

```java
// Magazines.java
sealed interface Item permits Book, Dvd, Magazine {
}

record Book(String title, int pages) implements Item {
}

record Dvd(String title, int minutes) implements Item {
}

record Magazine(String title, int issue) implements Item {
}

public class Magazines {
    static String describe(Item item) {
        return switch (item) {
            case Book(String title, int pages) -> title + ": " + pages + " pages";
            case Dvd(String title, int minutes) -> title + ": " + minutes + " minutes";
        };
    }

    public static void main(String[] args) {
        System.out.println(describe(new Magazine("Piauí", 200)));
    }
}
```

```
ana@vm:~/records/magazines$ javac Magazines.java
Magazines.java:16: error: the switch expression does not cover all possible input values
        return switch (item) {
               ^
1 error
```

**A mesma recusa do `switch` sobre enum da lição 28, pelo mesmo motivo**: o compilador conhece todos
os tipos de item, e um deles não tem caso. Ele aponta o `switch` que precisa de um. Num programa
inteiro, um record novo numa interface selada quebra o build uma vez para cada `switch` que o
esqueceu, que é a lista de lugares que alguém teria de achar procurando.

## Que Java tem isso

Padrões de record e padrões no `switch` entraram na linguagem no Java 21, então funcionam no 21 e no
25. **O Java 17, a LTS anterior, não tem nenhum dos dois**, e uma equipe ainda no 17 encontra isto:

```
ana@vm:~/records/patterns$ javac --release 17 Patterns.java 2>&1 | head -4
Patterns.java:14: error: patterns in switch statements are not supported in -source 17
            case Dvd(String title, int minutes) -> title + ": " + minutes + " minutes";
                 ^
  (use -source 21 or higher to enable patterns in switch statements)
```

O `head -4` guardou o primeiro de dois erros. O segundo aponta a mesma linha e cita a outra metade,
*deconstruction patterns* (padrões de desconstrução), que é a palavra do compilador para desmontar um
record. Records e interfaces seladas, em si, compilam no 17. O que falta nele é desmontá-los.
