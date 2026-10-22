---
title: Quatro gêneros e nenhum quinto
version: 1
---

O primeiro jeito que as pessoas usam para escrever um conjunto fixo de valores é como constantes:
`static final int FICTION = 0`, `HISTORY = 1`, e assim por diante, ou como strings, `"fiction"` e
`"history"`. Os dois compilam, e os dois deixam um método que recebe um gênero receber `7`, ou
`"histroy"`, sem uma palavra do compilador. **Um `enum` é um tipo cujos valores são listados uma vez
e nunca podem ser outra coisa**, então o compilador confere cada gênero do programa do jeito que
confere cada `int`.

Eis um, com o que todo enum ganha de graça, em `~/enums`:

```java
// Basics.java
enum Genre {
    FICTION, HISTORY, SCIENCE, POETRY
}

public class Basics {
    public static void main(String[] args) {
        for (Genre g : Genre.values()) {
            System.out.println(g.ordinal() + " " + g.name());
        }

        Genre picked = Genre.valueOf("HISTORY");
        System.out.println(picked == Genre.HISTORY);

        String floor = switch (picked) {
            case FICTION, POETRY -> "ground floor";
            case HISTORY, SCIENCE -> "first floor";
        };
        System.out.println(floor);

        System.out.println(Genre.valueOf("history"));
    }
}
```

```
ana@vm:~/enums$ javac Basics.java && java Basics
0 FICTION
1 HISTORY
2 SCIENCE
3 POETRY
true
first floor
Exception in thread "main" java.lang.IllegalArgumentException: No enum constant Genre.history
	at java.base/java.lang.Enum.valueOf(Enum.java:293)
	at Genre.valueOf(Basics.java:2)
	at Basics.main(Basics.java:21)
```

Linha por linha, comparando com o programa:

- **O `values()` devolve todas as constantes, na ordem em que estão escritas**, e o `ordinal()` é a
  posição de uma constante nessa ordem, a partir de 0. O `name()` é o nome da constante exatamente
  como foi escrito.
- **O `valueOf("HISTORY")` transforma um nome de volta na constante**, e a constante devolvida é o
  mesmo objeto que `Genre.HISTORY`, então o `==` imprimiu `true`. Existe exatamente um objeto
  `HISTORY` num programa em execução, o que faz do `==` a comparação certa para enums, onde a lição 7
  o desaconselhou para strings.
- **O `switch` cita as constantes sem o prefixo `Genre.`**, e agrupa duas por caso. A lição 10
  mostrou a forma com seta; com um enum ela ganha algo, que o próximo programa mostra.
- **O `valueOf` é exato.** `"history"` em minúsculas não é um nome que o enum tem, e o programa
  terminou numa `IllegalArgumentException` dizendo isso. Entrada vinda de uma pessoa precisa ser
  convertida antes, com o `toUpperCase(Locale.ROOT)` da lição 7, e de um plano para texto que não é
  gênero nenhum.

## Um enum é uma classe

O `javap` mostra o que o compilador fez com quatro palavras:

```
ana@vm:~/enums$ javap Genre
Compiled from "Basics.java"
final class Genre extends java.lang.Enum<Genre> {
  public static final Genre FICTION;
  public static final Genre HISTORY;
  public static final Genre SCIENCE;
  public static final Genre POETRY;
  public static Genre[] values();
  public static Genre valueOf(java.lang.String);
  static {};
}
```

**`Genre` é uma classe `final` que estende `java.lang.Enum`, e cada constante é um campo `public
static final` que guarda um objeto dela.** O `values()` e o `valueOf` foram escritos pelo compilador,
e o `static {}` é o inicializador de classe da lição 27, que cria os quatro objetos na primeira vez
que `Genre` é usado. Ninguém mais consegue criar um quinto: o construtor de um enum é privado, esteja
isso escrito ou não, e `new Genre()` não compila. Essa é a garantia em que o tipo inteiro se apoia.

## O `switch` que não consegue esquecer

O `Floors` usa o mesmo enum, e o `switch` dele trata três dos quatro gêneros:

```java
// Floors.java
enum Genre {
    FICTION, HISTORY, SCIENCE, POETRY
}

public class Floors {
    static String floor(Genre g) {
        return switch (g) {
            case FICTION -> "ground floor";
            case HISTORY, SCIENCE -> "first floor";
        };
    }

    public static void main(String[] args) {
        System.out.println(floor(Genre.POETRY));
    }
}
```

```
ana@vm:~/enums/floors$ javac Floors.java
Floors.java:8: error: the switch expression does not cover all possible input values
        return switch (g) {
               ^
1 error
```

**Uma expressão `switch` tem de produzir um valor para cada entrada possível, e o compilador conhece
todo `Genre` possível.** `POETRY` não tem caso, então ele recusa o arquivo. Com strings ou constantes
`int` o compilador não teria como saber, e o gênero que falta seria descoberto por um leitor na
estante. Ponha `POETRY` num caso, ou acrescente um quinto gênero ao enum sem atualizar este `switch`,
e o compilador diz exatamente onde olhar, uma vez para cada `switch` do programa.

Um ramo `default ->` também satisfaz o compilador, e custa esta verificação: um gênero acrescentado
no ano que vem cairia no `default` em silêncio. **Quando toda constante tem uma resposta de verdade,
liste todas e deixe o `default` de fora.**
