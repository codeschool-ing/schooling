---
title: Quando a instalação falha
version: 1
---

**Cada mensagem abaixo foi produzida de propósito na máquina em que este curso foi gravado, e cada
uma diz exatamente o que está errado quando você sabe onde olhar.** Estão na ordem em que você as
encontraria: o pacote, a versão e depois os primeiros arquivos. Esta seção é para o momento em que
algo não funciona, por isso mostra cada mensagem antes de explicá-la.

## `Unable to locate package openjdk-25-jdk`

O `apt` responde com essa linha num Ubuntu anterior ao 24.04, cujo repositório para num Java mais
antigo. *Este caso não foi executado para o curso, porque a máquina da gravação é 24.04.* O remédio
está no sistema, não no pacote: `cat /etc/os-release` diz qual Ubuntu você tem, e qualquer coisa
antes do 24.04 é motivo para seguir o caminho da máquina virtual da seção anterior, em vez de caçar o
Java 25 em outro lugar.

## Uma versão de arquivo de classe que o runtime não conhece

Uma máquina que já tinha o Java 21 antes deste curso tem dois JDKs lado a lado, e os comandos nem
sempre vêm do mesmo:

```
ana@vm:~/fp/lambdas$ javac -d out Hello.java
ana@vm:~/fp/lambdas$ ls /usr/lib/jvm
java-1.21.0-openjdk-amd64
java-1.25.0-openjdk-amd64
java-21-openjdk-amd64
java-25-openjdk-amd64
openjdk-21
openjdk-25
ana@vm:~/fp/lambdas$ /usr/lib/jvm/java-21-openjdk-amd64/bin/java -cp out Hello
Error: LinkageError occurred while loading main class Hello
	java.lang.UnsupportedClassVersionError: Hello has been compiled by a more recent version of the Java Runtime (class file version 69.0), this version of the Java Runtime only recognizes class file versions up to 65.0
```

O arquivo foi compilado pelo `javac` 25 e executado por um `java` da pasta do Java 21. **Cada versão
carimba seus arquivos de classe com um número**: 65 é o Java 21, 69 é o Java 25, e um runtime recusa
um número mais novo que o seu. A mensagem diz os dois números, e isso é o diagnóstico inteiro. No
Ubuntu, `sudo update-alternatives --config java` lista os Javas instalados e deixa você escolher o
25, e o mesmo comando com `javac` faz o compilador; `java -version` e `javac -version` devem então
concordar.

## O Maven no Java errado

```
ana@vm:~/fp/lambdas$ JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 mvn -B -v
Apache Maven 3.8.7
Maven home: /usr/share/maven
Java version: 21.0.12.1, vendor: Ubuntu, runtime: /usr/lib/jvm/java-21-openjdk-amd64
Default locale: en, platform encoding: UTF-8
OS name: "linux", version: "6.18.44-fc-v139", arch: "amd64", family: "unix"
```

**O Maven não usa o `java` do seu `PATH` quando `JAVA_HOME` está definida**; ele usa o Java que essa
variável aponta. Um guia de outro projeto que mandou pôr `export JAVA_HOME=...` no `~/.bashrc` deixa
exatamente isto para trás. A terceira linha diz: o Maven achou o 21. Apague essa linha do
`~/.bashrc`, ou aponte-a para `/usr/lib/jvm/java-25-openjdk-amd64`, abra um terminal novo e confira
`mvn -B -v` de novo.

## `Could not find or load main class`

```
ana@vm:~/fp/lambdas$ java Helo.java
Error: Could not find or load main class Helo.java
Caused by: java.lang.ClassNotFoundException: Helo.java
```

O arquivo é `Hello.java` e o comando disse `Helo.java`. Quando o nome depois de `java` não é um
arquivo que existe, **o lançador para de tratá-lo como arquivo e tenta usá-lo como o nome de uma
classe compilada**, e é por isso que a mensagem fala de classe e não de arquivo sumido. `ls` mostra o
que existe de verdade na pasta.

## `should be declared in a file named`

O modo de arquivo-fonte é tolerante com nomes, e o `javac` não é. Uma cópia do primeiro programa
salva como `Greeting.java`:

```
ana@vm:~/fp/lambdas$ javac Greeting.java
Greeting.java:2: error: class Hello is public, should be declared in a file named Hello.java
public class Hello {
       ^
1 error
```

**Uma classe `public` mora num arquivo de mesmo nome**, e o `javac` exige isso. O modo de
arquivo-fonte rodou o mesmo arquivo sem reclamar, porque compila na memória e nunca grava um arquivo
de classe cujo nome pudesse discordar. Renomeie o arquivo, ou a classe, antes que um projeto chegue
ao Maven, onde todo arquivo passa pelo `javac`.

## `illegal character: '“'`

Um programa colado de um editor de texto ou de uma janela de chat costuma trazer aspas tipográficas,
`“` e `”`, onde o Java quer a `"` simples:

```java
// Quotes.java: a program pasted from a chat window
public class Quotes {
    public static void main(String[] args) {
        System.out.println(“Hello”);
    }
}
```

```
ana@vm:~/fp/lambdas$ java Quotes.java
Quotes.java:4: error: illegal character: '\u201c'
        System.out.println(“Hello”);
                           ^
Quotes.java:4: error: illegal character: '\u201d'
        System.out.println(“Hello”);
                                 ^
Quotes.java:4: error: not a statement
        System.out.println(“Hello”);
                            ^
3 errors
error: compilation failed
```

Três erros, e só o primeiro é real: depois que o compilador rejeitou as duas aspas, o que sobrou
entre elas deixou de ser uma string, e o `not a statement` veio disso. **Corrija o primeiro erro que
um compilador aponta e compile de novo** antes de ler o resto. Aqui, redigite as aspas no seu editor.
