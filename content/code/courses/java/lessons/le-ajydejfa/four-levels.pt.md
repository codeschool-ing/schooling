---
title: Quatro níveis, e o que o compilador diz em cada um
version: 1
---

Todo atributo e todo método das lições 12 e 13 podiam ser lidos e alterados por qualquer classe do
mesmo diretório, o que é tranquilo com três classes e vira problema com trezentas. **Um modificador
de acesso diz que código pode usar um membro**, e o compilador recusa qualquer uso fora disso. O Java
tem quatro níveis, e um deles se escreve não escrevendo nada.

Os níveis só se diferenciam quando há mais de um **pacote** (package), então esta seção usa um. Um
pacote é um diretório de classes com um nome, declarado na primeira linha de cada arquivo; a lição 18
trata de pacotes por inteiro, e aqui só importa o efeito deles no acesso. Num diretório novo,
`~/access`, salve uma estante num subdiretório `lib`, com um atributo em cada nível:

```java
// lib/Shelf.java
package lib;

public class Shelf {
    public String name = "Fiction";
    String code = "F-01";
    protected int capacity = 40;
    private int count = 0;

    public void add() {
        count = count + 1;
    }

    public int count() {
        return count;
    }
}
```

Um programa no próprio `~/access`, fora de `lib`, tenta ler os quatro. O `import lib.Shelf;` diz de
qual `Shelf` ele está falando:

```java
// Main.java
import lib.Shelf;

public class Main {
    public static void main(String[] args) {
        Shelf s = new Shelf();
        s.add();
        System.out.println(s.name + " " + s.count());
        System.out.println(s.code);
        System.out.println(s.capacity);
        System.out.println(s.count);
    }
}
```

```
ana@vm:~/access$ javac Main.java
Main.java:9: error: code is not public in Shelf; cannot be accessed from outside package
        System.out.println(s.code);
                            ^
Main.java:10: error: capacity has protected access in Shelf
        System.out.println(s.capacity);
                            ^
Main.java:11: error: count has private access in Shelf
        System.out.println(s.count);
                            ^
3 errors
```

Três erros, e cada mensagem nomeia o seu nível. A linha 8, com `s.name` e `s.count()`, passou: os
dois são `public`. **O atributo `count` é privado, e o método `count()` é público**, que é o arranjo
que a seção 03 defende.

Agora uma classe dentro de `lib`, no mesmo pacote que `Shelf`:

```java
// lib/Inside.java
package lib;

public class Inside {
    public static void main(String[] args) {
        Shelf s = new Shelf();
        System.out.println(s.code + " " + s.capacity);
        System.out.println(s.count);
    }
}
```

```
ana@vm:~/access$ javac lib/Inside.java
lib/Inside.java:8: error: count has private access in Shelf
        System.out.println(s.count);
                            ^
1 error
```

De dentro do pacote, `code` e `capacity` passaram e só `count` falhou. **`private` quer dizer esta
classe e mais nada**, nem uma vizinha do mesmo pacote.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Quatro regiões de acesso, uma dentro da outra. A mais interna é a própria classe, que o private alcança. Em volta dela, o pacote, que a ausência de modificador alcança. Em volta disso, subclasses em outros pacotes, que o protected acrescenta. A mais externa é toda outra classe, que só o public alcança.\"><rect x=\"16\" y=\"16\" width=\"688\" height=\"248\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"38\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">public</text><text x=\"96\" y=\"38\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">toda classe, em qualquer pacote</text><rect x=\"56\" y=\"56\" width=\"608\" height=\"192\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"76\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">protected</text><text x=\"156\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">acrescenta subclasses de outros pacotes (lição 20)</text><rect x=\"96\" y=\"96\" width=\"528\" height=\"136\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"116\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">nenhum modificador</text><text x=\"244\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">toda classe do mesmo pacote</text><rect x=\"136\" y=\"136\" width=\"448\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"156\" y=\"158\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">private</text><text x=\"222\" y=\"158\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a própria classe</text><text x=\"360\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Shelf.count</text></svg>", "caption": "Cada modificador alcança a sua região e todas as regiões dentro dela. Shelf.count é privado, então só o código escrito dentro de Shelf o alcança."}
```

| modificador | a própria classe | o pacote dela | subclasses em outro lugar | todo mundo |
|---|---|---|---|---|
| `private` | sim | não | não | não |
| nenhum, chamado *package-private* | sim | sim | não | não |
| `protected` | sim | sim | sim | não |
| `public` | sim | sim | sim | sim |

O `protected` acrescenta as subclasses, que a lição 20 apresenta, e é o menos usado dos quatro. Um
`Main` que se limita aos membros públicos compila e roda:

```java
// Main.java
import lib.Shelf;

public class Main {
    public static void main(String[] args) {
        Shelf s = new Shelf();
        s.add();
        s.add();
        System.out.println(s.name + " " + s.count());
    }
}
```

```
ana@vm:~/access$ javac Main.java && java Main
Fiction 2
ana@vm:~/access$ ls lib
Inside.java
Shelf.class
Shelf.java
```

O `javac Main.java` encontrou `lib/Shelf.java` sozinho, por meio do `import`, e o compilou ao lado do
código-fonte. `Inside` não tem `.class`, já que nunca compilou.
