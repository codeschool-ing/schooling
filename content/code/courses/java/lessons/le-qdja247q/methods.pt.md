---
title: Métodos rodam num objeto
version: 1
---

Toda mudança num livro da lição 12 veio de fora dele: o `main` entrava pelo ponto e definia um
atributo. Isso funciona com três atributos e para de funcionar com trinta, porque toda regra sobre os
dados acaba repetida onde quer que os dados sejam mexidos. **Um método põe o comportamento ao lado dos
dados com que trabalha.** Ele é declarado dentro da classe, e roda num objeto: o que vem antes do
ponto.

Aqui está o `Book` de novo, em `~/members`, com quatro métodos:

```schooling-example
{
  "language": "java",
  "file": "Book.java",
  "parts": [
    {"code": "// Book.java\nclass Book {\n    String title;\n    int year;\n    int timesLent;", "note": "Três atributos, como na lição 12, com `timesLent` no lugar do ISBN."},
    {"code": "\n    String describe() {\n        return title + \" (\" + year + \")\";\n    }", "note": "**Um método declara o que devolve antes do nome**: `String`. O `return` entrega o valor a quem chamou. Lá dentro, `title` e `year` sem ponto querem dizer os atributos do objeto em que o método foi chamado."},
    {"code": "\n    boolean isOlderThan(int otherYear) {\n        return year < otherYear;\n    }", "note": "Um **parâmetro** entre os parênteses: quem chama tem de passar um `int`, e dentro do método ele se chama `otherYear`. O resultado é um `boolean`."},
    {"code": "\n    void lend() {\n        timesLent = timesLent + 1;\n    }", "note": "**`void` quer dizer que não devolve nada.** Ele existe pelo que muda: o `timesLent` deste livro, e de nenhum outro."},
    {"code": "\n    void rename(String title) {\n        this.title = title;\n    }\n}", "note": "O parâmetro também se chama `title`, e dentro do método esconde o atributo. **`this` é o objeto em que o método roda**, então `this.title` é o atributo e `title` sozinho é o parâmetro."}
  ]
}
```

E um programa que os chama:

```java
// UseBook.java
public class UseBook {
    public static void main(String[] args) {
        Book b = new Book();
        b.title = "Iracema";
        b.year = 1865;

        System.out.println(b.describe());
        System.out.println(b.isOlderThan(1900));

        b.lend();
        b.lend();
        System.out.println(b.timesLent);

        b.rename("Iracema: lenda do Ceará");
        System.out.println(b.describe());
    }
}
```

```
ana@vm:~/members$ javac UseBook.java && java UseBook
Iracema (1865)
true
2
Iracema: lenda do Ceará (1865)
```

`b.describe()` executou o `describe` com o livro de `b` como `this`, e montou o texto a partir dos
atributos desse livro. Duas vezes `b.lend()` levaram `timesLent` de 0 a 2. O `rename` mudou o título,
e o segundo `describe` viu a mudança, porque o método e o atributo pertencem ao mesmo objeto.

## A assinatura é um contrato que o compilador confere

O `javap` lista cada método na forma que o compilador guarda:

```
ana@vm:~/members$ javap -p Book
Compiled from "Book.java"
class Book {
  java.lang.String title;
  int year;
  int timesLent;
  Book();
  java.lang.String describe();
  boolean isOlderThan(int);
  void lend();
  void rename(java.lang.String);
}
```

**O nome de um método e os tipos dos seus parâmetros são a sua assinatura**: `isOlderThan(int)`,
`rename(java.lang.String)`. O nome do parâmetro não faz parte dela, nem o tipo de retorno. Uma
chamada tem de casar com a assinatura, e o resultado só pode ser usado como o tipo que o método
declara. Quebre uma das duas coisas e o programa não compila:

```java
// WrongCall.java
public class WrongCall {
    public static void main(String[] args) {
        Book b = new Book();
        boolean old = b.isOlderThan("1900");
        String nothing = b.lend();
    }
}
```

```
ana@vm:~/members$ javac WrongCall.java
WrongCall.java:5: error: incompatible types: String cannot be converted to int
        boolean old = b.isOlderThan("1900");
                                    ^
WrongCall.java:6: error: incompatible types: void cannot be converted to String
        String nothing = b.lend();
                               ^
Note: Some messages have been simplified; recompile with -Xdiags:verbose to get full output
2 errors
```

Dois erros, cada um com um acento circunflexo embaixo do lugar exato. `"1900"` é uma `String`, entre
aspas, e a assinatura pede um `int`. O `lend()` declarou `void`, então não tem nada para pôr em
`nothing`. Quem chama não consegue passar a coisa errada nem esperar um resultado que não existe, e
isso é conferido uma vez, na compilação, para cada chamada do programa. A lição 24 mostra o que
acontece quando dois métodos têm o mesmo nome e parâmetros diferentes.
