---
title: Do código-fonte ao bytecode
version: 1
---

A imagem comum de um compilador é a de um programa que transforma código-fonte nas instruções do
próprio processador, como faz um compilador C. **O compilador do Java não faz isso.** O `javac`
transforma código-fonte em **bytecode**, o conjunto de instruções de um processador que só existe no
papel, a Máquina Virtual Java. O programa `java` é essa máquina, escrita em software, e é ele que
executa o seu programa. Todo programa Java que você vier a executar passa pelos dois passos.

Crie um diretório para esta lição, `~/jvm`, e salve nele este arquivo como `Hello.java`:

```java
// Hello.java
public class Hello {
    public static void main(String[] args) {
        System.out.println("Hello, Java");
    }
}
```

A lição 3 o lê linha por linha. Por enquanto basta saber que ele imprime uma linha, e que **o arquivo
tem o nome da classe que declara**, `Hello`.

## Dois passos, dois programas

```
ana@vm:~/jvm$ javac Hello.java
ana@vm:~/jvm$ ls -l
total 8
-rw-r--r-- 1 ana ana 415 Oct 16 19:23 Hello.class
-rw-r--r-- 1 ana ana 131 Oct 16 19:23 Hello.java
ana@vm:~/jvm$ java Hello
Hello, Java
```

O `javac` não imprimiu nada, e em Java é assim que o sucesso se parece. Ele deixou um arquivo ao lado
do código-fonte, `Hello.class`, com 415 bytes contra os 131 do fonte. Depois o `java Hello` o
executou. Repare no que o `java` recebeu: **o nome de uma classe, `Hello`, e não o nome de um
arquivo.** `java Hello.class` estaria pedindo uma classe chamada `Hello.class`, que não existe; a
lição 2 mostra essa mensagem e o terceiro jeito de executar, direto do código-fonte.

## O que há dentro de um arquivo de classe

O arquivo é binário, e o comando `file` do sistema o reconhece pelos primeiros bytes:

```
ana@vm:~/jvm$ file Hello.class
Hello.class: compiled Java class data, version 69.0
ana@vm:~/jvm$ od -A d -t x1 -N 8 Hello.class
0000000 ca fe ba be 00 00 00 45
0000008
```

O `od` imprimiu os oito primeiros bytes em hexadecimal. **Todo arquivo de classe já escrito começa
com `ca fe ba be`**, uma piada do começo dos anos 1990 que o formato carrega desde então, e foi assim
que o `file` soube. Os dois últimos bytes, `00 45`, são a **versão principal** (major version): 45
em hexadecimal é 69, e 69 quer dizer Java 25. A seção 04 encontrou esse número numa mensagem de erro,
e a seção 06 o altera.

O `javap`, o impressor de arquivos de classe do JDK, mostra o resto numa forma que uma pessoa
consegue ler. Com `-c` ele imprime o bytecode de cada método:

```
ana@vm:~/jvm$ javap -c Hello
Compiled from "Hello.java"
public class Hello {
  public Hello();
    Code:
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return

  public static void main(java.lang.String[]);
    Code:
         0: getstatic     #7                  // Field java/lang/System.out:Ljava/io/PrintStream;
         3: ldc           #13                 // String Hello, Java
         5: invokevirtual #15                 // Method java/io/PrintStream.println:(Ljava/lang/String;)V
         8: return
}
```

Dois métodos, e o código-fonte declarou um. O primeiro, `public Hello()`, é um **construtor** que o
compilador escreveu porque a classe não declarou nenhum; a lição 13 o explica. O segundo é o `main`,
com quatro instruções. Leia-as de cima para baixo, como a JVM faz:

1. `getstatic` busca o `System.out`, o objeto que escreve no terminal.
2. `ldc` carrega a string constante `"Hello, Java"`.
3. `invokevirtual` chama o `println` no primeiro, com o segundo como argumento.
4. `return` encerra o método, e com ele o programa.

**Nada ali é instrução de Intel ou de ARM.** Os mesmos 415 bytes rodam sem mudança no Linux, no
macOS e no Windows, em qualquer processador para o qual alguém escreveu uma JVM. Esse é o velho
slogan, *write once, run anywhere* (escreva uma vez, rode em qualquer lugar), e ele vale exatamente
por isto: o que o `javac` produz é para a máquina virtual, e só a máquina virtual muda de um
computador para outro.

## O que a JVM faz com ele

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Como um programa Java roda. Hello.java, o código-fonte que você escreve, entra no javac. O javac escreve Hello.class, bytecode que é o mesmo arquivo em qualquer computador. O comando java inicia uma JVM, que carrega a classe, interpreta o bytecode no começo, e compila em código de máquina deste processador, com o seu compilador JIT, os métodos que rodam muito. Cada sistema operacional tem a sua JVM; o arquivo de classe é compartilhado.\"><defs><marker id=\"jv1-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"16\" y=\"70\" width=\"150\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"91\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Hello.java</text><text x=\"91\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">fonte que você escreve</text><text x=\"91\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">131 bytes de texto</text><path d=\"M166 107 H222\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv1-a)\"></path><text x=\"194\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">javac</text><rect x=\"224\" y=\"70\" width=\"160\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"304\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Hello.class</text><text x=\"304\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">bytecode, versão 69</text><text x=\"304\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o mesmo em todo computador</text><path d=\"M384 107 H440\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv1-a)\"></path><text x=\"412\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">java</text><rect x=\"442\" y=\"20\" width=\"262\" height=\"190\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"573\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a JVM, um processo</text><rect x=\"462\" y=\"58\" width=\"222\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"573\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">carrega e verifica a classe</text><rect x=\"462\" y=\"98\" width=\"222\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"573\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">interpreta o bytecode no começo</text><rect x=\"462\" y=\"138\" width=\"222\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"573\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">JIT: compila os métodos quentes</text><text x=\"573\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">código de máquina deste processador</text><path d=\"M573 88 V96 M573 128 V136\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"16\" y=\"226\" width=\"688\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma JVM por sistema operacional e processador; um arquivo de classe para todos</text></svg>", "caption": "O javac roda uma vez, na sua máquina. A JVM roda toda vez, em qualquer máquina onde o arquivo de classe for parar, e só a JVM muda entre elas."}
```

Quando `java Hello` começa, a JVM **carrega** a classe e a **verifica**, conferindo que o bytecode não
pode, por exemplo, saltar para o meio de uma instrução ou ler memória que nunca lhe foi dada. Depois
ela executa o `main` **interpretando** o bytecode, uma instrução por vez, o que começa rápido e roda
devagar. Enquanto interpreta, ela conta. Um método chamado vezes suficientes é entregue ao
**compilador JIT**, *just in time* (na hora certa), que transforma o bytecode desse método nas
instruções do próprio processador, e daí em diante são elas que rodam.

É por isso que um programa Java costuma ficar mais rápido nos primeiros segundos, e por isso que um
`main` de quatro instruções nunca chega ao JIT: ele roda uma vez e o programa acaba. A lição 2 observa
a JVM fazendo isso como um processo em execução.
