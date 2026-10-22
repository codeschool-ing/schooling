---
title: Métodos default, e um contrato que cresce
version: 1
---

Um contrato com cem assinaturas tem um problema no dia em que precisa de mais uma cláusula.
Acrescente um método abstrato ao `Lendable` e toda classe que o implementa deixa de compilar,
inclusive classes no código de outras pessoas que você nunca vai ver. **Até o Java 8 a resposta
honesta era "não dá"**, e a biblioteca padrão carregava interfaces que não tinha permissão de
melhorar. Um **método default** é a saída: um método na interface que já vem com corpo, e que todo
implementador herda, a menos que escreva o seu.

## Uma cláusula nova, com corpo

Em `~/iface/defaults`, com o `Book.java` e o `Dvd.java` copiados sem mudança da seção 02, eis o
`Lendable` crescido em três métodos:

```schooling-example
{
  "language": "java",
  "file": "Lendable.java",
  "parts": [
    {
      "code": "public interface Lendable {\n    String title();\n\n    int loanDays();",
      "note": "Os dois métodos abstratos da seção 02, sem mudança. Toda classe que já assinou o `Lendable` continua compilando contra este arquivo."
    },
    {
      "code": "\n    default boolean renewable() {\n        return true;\n    }",
      "note": "**Um método default tem corpo**, e uma classe que assina a interface o ganha de graça. Livros e DVDs são renováveis sem uma linha própria; uma classe que discorda escreve o seu próprio `renewable`."
    },
    {
      "code": "\n    static String describe(Lendable item) {\n        return item.title() + \": \" + days(item.loanDays())\n                + (item.renewable() ? \", renewable\" : \", not renewable\");\n    }",
      "note": "**Um método estático pertence à própria interface** e é chamado pelo nome dela, `Lendable.describe(item)`. Ele não é herdado: `Book.describe` não existe."
    },
    {
      "code": "\n    private static String days(int n) {\n        return n == 1 ? \"1 day\" : n + \" days\";\n    }\n}",
      "note": "Um método privado é um auxiliar para o código da própria interface, aqui o plural de *day*. Ele é invisível para quem implementa e para quem chama, e o `javap` não o lista."
    }
  ]
}
```

Um jogo, que a biblioteca empresta por um dia e nunca renova, sobrescreve o default:

```java
// Game.java
public class Game implements Lendable {
    private final String title;

    public Game(String title) {
        this.title = title;
    }

    @Override
    public String title() {
        return title;
    }

    @Override
    public int loanDays() {
        return 1;
    }

    @Override
    public boolean renewable() {
        return false;
    }
}
```

```java
// Shelf.java
public class Shelf {
    public static void main(String[] args) {
        Lendable[] items = { new Book("Iracema"), new Dvd("Central do Brasil"), new Game("Banco Imobiliário") };
        for (Lendable item : items) {
            System.out.println(Lendable.describe(item));
        }
    }
}
```

```
ana@vm:~/iface/defaults$ javac *.java && java Shelf
Iracema: 21 days, renewable
Central do Brasil: 7 days, renewable
Banco Imobiliário: 1 day, not renewable
ana@vm:~/iface/defaults$ javap Lendable
Compiled from "Lendable.java"
public interface Lendable {
  public abstract java.lang.String title();
  public abstract int loanDays();
  public default boolean renewable();
  public static java.lang.String describe(Lendable);
}
```

**O `Book.java` e o `Dvd.java` compilaram sem mudança** e responderam `renewable` pelo default; o
`Game` disse não com o seu próprio método. O `describe` montou cada linha a partir dos dois métodos
abstratos e do default, e o auxiliar privado dele escolheu `1 day` em vez de `1 days`. O `javap`
lista o que a interface mostra ao mundo: o par abstrato, o método `default` e o `static`. O auxiliar
privado não aparece, porque o `javap` lista só o que outro código pode chamar.

## Para que serve um default, e para que não serve

Um método default é escrito para a **evolução**: acrescentar comportamento a um contrato que já tem
implementadores, com um corpo que está certo para a maioria deles. Foi assim que a `List` ganhou o
`sort` no Java 8 sem quebrar toda classe de lista que alguém já tinha escrito, e que o `Comparator`
ganhou `reversed()` e `thenComparing`.

Não é um jeito de dar estado a uma interface. Uma interface pode declarar constantes e mais nada que
guarde um valor, então um método default só consegue chamar outros métodos, nunca manter um atributo
seu. **Se dois métodos default precisam compartilhar um contador, o desenho pede uma classe
abstrata**, que a lição 21 mostrou. A escolha entre as duas se resume a isso: uma interface quando as
classes compartilham uma promessa, uma classe abstrata quando compartilham dados e o código em volta
deles.
