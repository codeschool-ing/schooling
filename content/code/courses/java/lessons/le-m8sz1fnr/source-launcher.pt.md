---
title: Executando um arquivo-fonte diretamente
version: 1
---

Dois comandos para um programa que você muda a cada minuto é um comando a mais, e desde o Java 11 o
`java` aceita um arquivo `.java` em vez de um nome de classe. **Ele compila o arquivo na memória, o
executa, e não grava nada no disco.** Esse é o modo de arquivo-fonte, e muitos dos programas antes da
lição 18 rodam assim, porque essas lições são sobre o programa e não sobre onde as classes dele ficam.

Num diretório novo, `~/launch`, com o mesmo `Greet.java`:

```
ana@vm:~/launch$ java Greet.java Ana
Hello, Ana
ana@vm:~/launch$ ls
Greet.java
```

O programa rodou, e o `ls` não mostra nenhum `Greet.class`. A classe compilada viveu na memória da
JVM e foi embora quando o processo terminou. O que o `java` faz aqui são os dois passos da seção 02
num processo só: chama o compilador, que também é escrito em Java e vem dentro do JDK, e depois
executa o resultado. **Nada no programa muda**: os mesmos `args`, o mesmo status de saída, a mesma
saída. O que muda é o custo de começar, que o `time` mede:

```
ana@vm:~/launch$ time java Greet.java Ana
Hello, Ana

real	0m1.093s
user	0m0.785s
sys	0m0.120s
ana@vm:~/launch$ javac Greet.java && time java Greet Ana
Hello, Ana

real	0m0.206s
user	0m0.028s
sys	0m0.009s
```

1,093 segundo a partir do fonte contra 0,206 a partir de uma classe compilada, nesta máquina e nesta
execução; os números mudam um pouco a cada vez. **A diferença é o compilador iniciando**, toda vez, o
que não é nada para um programa que você está editando e é um custo real para um que roda mil vezes
por dia.

## Um programa em vários arquivos

Até o Java 22, o modo de arquivo-fonte tinha um limite que importava: tudo tinha de estar naquele
arquivo. Hoje o `java` compila as outras classes que o programa usa, desde que os arquivos delas
estejam no mesmo diretório, com o nome das suas classes. Dois arquivos pequenos mostram isso:

```java
// Main.java
public class Main {
    public static void main(String[] args) {
        System.out.println(Shout.loud("hello from two files"));
    }
}
```

```java
// Shout.java
public class Shout {
    static String loud(String text) {
        return text.toUpperCase() + "!";
    }
}
```

```
ana@vm:~/launch$ java Main.java
HELLO FROM TWO FILES!
ana@vm:~/launch$ ls
Greet.java
Main.java
Shout.java
```

O `java Main.java` compilou o `Main`, viu que ele usa uma classe chamada `Shout`, encontrou o
`Shout.java` ao lado e compilou esse também. **Isso funciona no 25 e não no 21**: o Java 22 o
acrescentou, e no 21, que não foi testado aqui, o modo de arquivo-fonte compila só o arquivo que
você nomeia e para no `Shout`. O arquivo que você nomeia é aquele cujo `main` roda, e os outros são
encontrados conforme a necessidade. Um arquivo que ninguém usa nunca é compilado, mesmo um que não
compilaria:

```
ana@vm:~/launch$ echo 'class Broken {' > Broken.java; java Main.java
HELLO FROM TWO FILES!
ana@vm:~/launch$ rm Broken.java
```

Falta a chave de fechamento no `Broken.java`, e o `java Main.java` nem olhou para ele.

## Um programa Java como script

No Linux e no macOS, um arquivo de texto pode ser marcado como executável, e a primeira linha dele,
começando com `#!`, nomeia o programa que deve executá-lo. O `java` aceita um arquivo assim quando lhe
dizem para que versão o código foi escrito. Uma linha monta um a partir do `Greet.java`:

```
ana@vm:~/launch$ (echo '#!/usr/bin/java --source 25'; cat Greet.java) > greet
ana@vm:~/launch$ chmod +x greet && ./greet Ana
Hello, Ana
ana@vm:~/launch$ head -3 greet
#!/usr/bin/java --source 25
public class Greet {
    public static void main(String[] args) {
```

O arquivo se chama `greet`, sem `.java`, e **isso é a regra, não questão de gosto**. O
`--source 25` é o que diz ao `java` que esse arquivo sem extensão é código-fonte. Um arquivo
terminado em `.java` é compilado como Java comum, e em Java comum `#` nem é um caractere válido:

```
ana@vm:~/launch$ cp greet greet.java && java greet.java Ana
greet.java:1: error: illegal character: '#'
#!/usr/bin/java --source 25
^
greet.java:1: error: class, interface, annotation type, enum, record, method or field expected
#!/usr/bin/java --source 25
  ^
2 errors
error: compilation failed
```

Um script assim é uma boa ferramenta para algo que você roda à mão, e o formato errado para qualquer
coisa maior, porque cada execução o compila de novo.

| você tem | você digita | grava algo compilado no disco |
|---|---|---|
| uma classe em `out` | `java -cp out Greet Ana` | já gravado, pelo `javac -d out` |
| um ou mais arquivos-fonte | `java Greet.java Ana` | nada |
| um script executável | `./greet Ana` | nada |
