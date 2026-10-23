---
title: Uma classe descreve, um objeto existe
version: 1
---

Todo programa das lições 1 a 11 foi uma classe com um `main` dentro, e a classe não fazia nada além
de guardar esse método. É um uso estreito da palavra. **Uma classe é a descrição de um tipo de
coisa**: os dados que cada uma delas carrega e, a partir da lição 13, o que cada uma sabe fazer. Um
**objeto** é uma dessas coisas, criada enquanto o programa roda. A classe é escrita uma vez; os
objetos são criados tantas vezes quantas o programa pedir.

Crie um diretório para esta lição, `~/objects`, e salve isto como `Book.java`:

```java
// Book.java
class Book {
    String isbn;
    String title;
    int year;
}
```

Três **atributos** (fields): variáveis declaradas dentro da classe e fora de qualquer método. Cada
`Book` vai ter o seu próprio `isbn`, o seu próprio `title` e o seu próprio `year`. Não há `main`,
então esta classe não é um programa, e `java Book` não teria o que iniciar. A classe também não é
`public`, o que a lição 14 explica; por enquanto isso só quer dizer que qualquer classe do mesmo
diretório pode usá-la.

Um segundo arquivo a usa:

```schooling-example
{
  "language": "java",
  "file": "Main.java",
  "parts": [
    {
      "code": "// Main.java\npublic class Main {\n    public static void main(String[] args) {",
      "note": "Um programa comum, como os das lições 1 a 11."
    },
    {
      "code": "        Book first = new Book();",
      "note": "**`new Book()` cria um objeto** e devolve um jeito de alcançá-lo, que vai para a variável `first`. O tipo da variável é a classe, `Book`."
    },
    {
      "code": "        first.title = \"Dom Casmurro\";\n        first.year = 1899;",
      "note": "Um ponto entra no objeto: `first.title` é o atributo `title` daquele livro."
    },
    {
      "code": "\n        Book second = new Book();\n        second.title = \"Vidas Secas\";\n        second.year = 1938;",
      "note": "Um segundo `new`, um segundo objeto. Os atributos são dele, e defini-los não muda nada em `first`."
    },
    {
      "code": "\n        System.out.println(first.title + \", \" + first.year);\n        System.out.println(second.title + \", \" + second.year);\n        System.out.println(first.isbn);",
      "note": "Ninguém definiu `first.isbn`. **Um atributo que ninguém atribuiu tem um valor padrão**: `null` para uma referência como uma `String`, `0` para um `int`."
    },
    {
      "code": "        System.out.println(first);\n        System.out.println(second);\n    }\n}",
      "note": "Imprimindo o próprio objeto, em vez de um dos atributos."
    }
  ]
}
```

Compile os dois e execute o que tem o `main`:

```
ana@vm:~/objects$ javac Book.java Main.java
ana@vm:~/objects$ ls
Book.class
Book.java
Main.class
Main.java
ana@vm:~/objects$ java Main
Dom Casmurro, 1899
Vidas Secas, 1938
null
Book@251a69d7
Book@7344699f
```

**Uma classe, dois objetos, cada um com o seu título e o seu ano.** A terceira linha é o `isbn` que
ninguém definiu, e ele imprimiu `null` em vez de falhar: um atributo sempre tem valor, e o compilador
fornece um se você não fornecer. Uma variável local não tem esse padrão, o que a lição 5 mostrou como
erro de compilação.

As duas últimas linhas são o que o Java imprime para um objeto quando a classe não disse como se
descrever: o nome da classe, um `@` e um número em hexadecimal. **O número é um hash code, não um
endereço**, e muda a cada execução; o seu não vai bater com estes. O que ele mostra é que os dois
objetos são dois, mesmo tendo vindo da mesma classe. A lição 20 ensina uma classe a imprimir algo
mais útil, escrevendo o seu próprio `toString`.

## O que o compilador fez da classe

```
ana@vm:~/objects$ javap -p Book
Compiled from "Book.java"
class Book {
  java.lang.String isbn;
  java.lang.String title;
  int year;
  Book();
}
```

Os três atributos, como declarados, e uma coisa que ninguém escreveu: `Book()`, um construtor. É o
mesmo construtor escrito pelo compilador que a lição 1 encontrou em `Hello`, e é ele que
`new Book()` chama. A lição 13 escreve construtores próprios e mostra o que acontece com este quando
você faz isso.

**O arquivo `.class` guarda a descrição e nada mais.** Nenhum livro existe até um programa rodar e
dizer `new`, e quando esse programa termina, os livros dele vão junto. A seção 04 olha para eles
enquanto existem.
