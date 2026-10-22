---
title: Pacotes, um nome com diretórios dentro
version: 1
---

Toda classe até agora morou no **pacote padrão**, o pacote sem nome a que um arquivo pertence quando
não diz nada. Isso basta para um diretório de programas, e ninguém entrega código assim. Um programa
de verdade tem centenas de classes, usa outras milhares de bibliotecas, e duas delas se chamarem
`Book` ou `Date` é certeza. **Um pacote dá a uma classe um nome completo**, e esse nome é também o
diretório onde o arquivo de classe dela tem de estar.

## A linha `package`

Crie um diretório para esta lição, `~/pkgs`, com um diretório `src` dentro, e dois arquivos debaixo
dele:

```java
// src/com/example/library/Book.java
package com.example.library;

public class Book {
    private final String title;

    public Book(String title) {
        this.title = title;
    }

    public String title() {
        return title;
    }
}
```
```java
// src/com/example/library/app/Main.java
package com.example.library.app;

import com.example.library.Book;

public class Main {
    public static void main(String[] args) {
        Book book = new Book("Effective Java");
        System.out.println(book.title());
    }
}
```

**A primeira linha de cada arquivo dá o nome do seu pacote**, e só comentários podem vir antes dela.
`Book` está em `com.example.library`, então o nome completo dele, o **nome totalmente qualificado**
(fully qualified name), é `com.example.library.Book`. `Main` está noutro pacote,
`com.example.library.app`, e para usar `Book` pelo nome curto ele o importa, que é o assunto da seção
03.

O nome é um domínio escrito de trás para a frente. Quem é dono de `example.com` pode usar todo pacote
sob `com.example`, e mais ninguém, então duas empresas não escolhem o mesmo nome por acaso. O domínio
`example.com` é reservado para documentação, e é por isso que este curso o usa. **Nomes de pacote são
todos minúsculos**, e o layout do próprio curso, que a seção 04 fixa, põe toda classe de um projeto
chamado `library` sob `com.example.library`.

## Para onde vão os arquivos de classe

`javac -d out` compila para um diretório chamado `out` em vez de ao lado do código-fonte, e cria
sozinho os diretórios do pacote:

```
ana@vm:~/pkgs$ javac -d out src/com/example/library/Book.java src/com/example/library/app/Main.java
ana@vm:~/pkgs$ find out -type f
out/com/example/library/app/Main.class
out/com/example/library/Book.class
ana@vm:~/pkgs$ java -cp out com.example.library.app.Main
Effective Java
```

Duas coisas para ler aí. **O pacote virou diretórios**: `com.example.library.app.Main` é o arquivo
`out/com/example/library/app/Main.class`, um diretório para cada parte do nome. E **o `java` recebeu
o nome completo**, e, com `-cp out`, abreviação de `--class-path`, o diretório onde a árvore de
pacotes começa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O nome de classe com.example.library.app.Main, partido nos pontos em com, example, library, app e Main, acima do arquivo out/com/example/library/app/Main.class, partido nos mesmos pedaços. Cada pedaço do nome se alinha com um diretório, e o diretório out, a raiz do class path dada com -cp out, vem primeiro.\"><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nome da classe</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">arquivo no disco</text><rect x=\"110\" y=\"128\" width=\"70\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">out/</text><text x=\"145\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">raiz do</text><text x=\"145\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">class path, -cp out</text><rect x=\"190\" y=\"28\" width=\"60\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">com</text><rect x=\"190\" y=\"128\" width=\"60\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">com/</text><path d=\"M220.0 72 V126\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"262\" y=\"28\" width=\"90\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"307.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">example</text><rect x=\"262\" y=\"128\" width=\"90\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"307.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">example/</text><path d=\"M307.0 72 V126\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"364\" y=\"28\" width=\"90\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"409.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">library</text><rect x=\"364\" y=\"128\" width=\"90\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"409.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">library/</text><path d=\"M409.0 72 V126\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"466\" y=\"28\" width=\"60\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"496.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">app</text><rect x=\"466\" y=\"128\" width=\"60\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"496.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">app/</text><path d=\"M496.0 72 V126\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"538\" y=\"28\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"598.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Main</text><rect x=\"538\" y=\"128\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"598.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Main.class</text><path d=\"M598.0 72 V126\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"455\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cada ponto do nome é um diretório sob a raiz</text></svg>", "caption": "A JVM transforma um nome de classe num caminho trocando cada ponto por uma barra, e procura esse caminho debaixo de cada raiz do class path. O pacote são os diretórios; a raiz não faz parte dele."}
```

O **class path** é a lista de lugares onde a JVM procura classes, e o nome de uma classe diz onde
procurar debaixo de cada um deles. Peça o nome curto, ou comece do diretório errado, e as duas falhas
são diferentes:

```
ana@vm:~/pkgs$ java -cp out Main
Error: Could not find or load main class Main
Caused by: java.lang.ClassNotFoundException: Main
ana@vm:~/pkgs$ cd out/com/example/library/app && java Main
Error: Could not find or load main class Main
Caused by: java.lang.NoClassDefFoundError: Main (wrong name: com/example/library/app/Main)
```

**`ClassNotFoundException: Main`**: não existe `out/Main.class`, porque nenhuma classe se chama só
`Main`. A segunda falha é a que mais ensina. De dentro do diretório que tem o `Main.class`, `java
Main` encontrou o arquivo e o abriu, e o arquivo disse que o nome dele era
`com/example/library/app/Main`, que não é o nome pedido: **`wrong name`** (nome errado). Um arquivo
de classe conhece o seu pacote, e só é válido no caminho que esse pacote soletra.

## Os arquivos-fonte seguem a mesma regra

O `javac` não exige que um arquivo-fonte esteja no diretório do seu pacote quando você dá o nome do
arquivo na linha de comando. Exige quando tem de **encontrar** um. Com `-sourcepath src`, o `javac`
compila o arquivo que recebeu e vai procurar debaixo de `src` qualquer classe que esse arquivo use:

```
ana@vm:~/pkgs$ rm -rf out && javac -d out -sourcepath src src/com/example/library/app/Main.java && find out -type f
out/com/example/library/app/Main.class
out/com/example/library/Book.class
ana@vm:~/pkgs$ mv src/com/example/library/Book.java src/Book.java
ana@vm:~/pkgs$ rm -rf out && javac -d out -sourcepath src src/com/example/library/app/Main.java
src/com/example/library/app/Main.java:4: error: cannot find symbol
import com.example.library.Book;
                          ^
  symbol:   class Book
  location: package com.example.library
src/com/example/library/app/Main.java:8: error: cannot find symbol
        Book book = new Book("Effective Java");
        ^
  symbol:   class Book
  location: class Main
src/com/example/library/app/Main.java:8: error: cannot find symbol
        Book book = new Book("Effective Java");
                        ^
  symbol:   class Book
  location: class Main
3 errors
ana@vm:~/pkgs$ mv src/Book.java src/com/example/library/Book.java
```

A primeira compilação recebeu só o `Main.java` e encontrou sozinha o `Book.java`, em
`src/com/example/library/Book.java`. Depois a Ana moveu o `Book.java` para o topo de `src`, e o mesmo
comando falhou com **`cannot find symbol`** (símbolo não encontrado) três vezes: o `javac` procurou
`Book` exatamente onde o nome dele mandava, e ele não estava lá. A última linha o pôs de volta.

Esse é o contrato inteiro. **O pacote diz onde o arquivo tem de estar, e toda ferramenta, `javac`,
`java`, o Maven e o seu editor, procura ali e em mais lugar nenhum.** Mantenha os dois em sintonia e
nenhum desses erros acontece.
