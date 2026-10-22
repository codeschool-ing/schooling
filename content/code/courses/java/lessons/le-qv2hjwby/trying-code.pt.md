---
title: Experimentando uma linha, e o menor programa que o Java aceita
version: 1
---

Uma classe, um `main` e um arquivo são muita cerimônia para descobrir quanto dá `7 / 2`. O JDK tem
duas respostas para isso, e elas servem para momentos diferentes. **O `jshell` executa Java uma linha
por vez**, para perguntas que cabem numa linha. **Um arquivo-fonte compacto** é um programa inteiro sem
a classe em volta, que o Java 25 permite e o Java 21 não.

## O `jshell`

Digite `jshell` e você ganha um prompt `jshell>`. Cada linha digitada é compilada e executada na hora,
e o `jshell` responde com o valor que ela produziu. Para esta transcrição ficar exata, as linhas foram
salvas antes num arquivo e entregues ao `jshell` pela entrada, o que imprime as mesmas respostas sem
ecoar o que foi digitado. Digitada à mão, cada linha aparece depois do seu `jshell>`:

```
ana@vm:~/syntax$ cat try.jsh
int pages = 7 / 2
pages * 3.0
String name = "Ana"
name.length()
name.toUpperCase()
/vars
/exit
ana@vm:~/syntax$ jshell --feedback normal < try.jsh
|  Welcome to JShell -- Version 25.0.4.1
|  For an introduction type: /help intro

jshell> pages ==> 3

jshell> $2 ==> 9.0

jshell> name ==> "Ana"

jshell> $4 ==> 3

jshell> $5 ==> "ANA"

jshell> |    int pages = 3
|    double $2 = 9.0
|    String name = "Ana"
|    int $4 = 3
|    String $5 = "ANA"

jshell> |  Goodbye
```

Cada linha ganhou uma resposta na forma `nome ==> valor`:

- `int pages = 7 / 2` declarou uma variável, e o valor dela é **3, não 3,5**: dividir um número
  inteiro por outro dá um número inteiro em Java, e a lição 6 mostra por quê.
- `pages * 3.0` era uma expressão sem variável para guardá-la, então o `jshell` inventou uma, `$2`, e
  o valor é `9.0` porque `3.0` é um número decimal.
- `name.length()` e `name.toUpperCase()` chamaram métodos de uma `String`, assunto da lição 7.
- `/vars` é um comando do `jshell`, não Java. Comandos começam com `/`, e este lista cada variável com
  o tipo dela. `/exit` sai, e `/help` lista o resto.

Duas coisas que o `jshell` perdoa e um arquivo `.java` não: **uma instrução não precisa de ponto e
vírgula**, e nada precisa estar dentro de uma classe. Isso o torna o lugar certo para conferir o que
uma expressão faz antes de pô-la num programa, e o lugar errado para escrever o programa.

## Arquivos-fonte compactos

O Java 25 deixa um arquivo-fonte conter um método sem declarar uma classe em volta:

```java
// Hi.java
void main() {
    IO.println("Hello from a compact source file");
}
```

```
ana@vm:~/syntax$ java Hi.java
Hello from a compact source file
ana@vm:~/syntax$ javac Hi.java && javap Hi.class
Compiled from "Hi.java"
final class Hi {
  Hi();
  void main();
}
ana@vm:~/syntax$ javac --release 21 Hi.java
Hi.java:2: error: implicitly declared classes are not supported in -source 21
void main() {
^
  (use -source 25 or higher to enable implicitly declared classes)
1 error
```

Três coisas mudam em relação ao `Hello.java`, e o `javap` mostra para onde a classe foi. **O
compilador declarou uma por você**, com o nome do arquivo, `final class Hi`, então a regra da seção 03
continua valendo numa forma nova. O `main` agora pode dispensar `public`, `static` e o parâmetro. E o
`IO.println` é um jeito mais curto de imprimir, de uma classe `IO` que o Java 25 acrescentou
exatamente para esse tipo de arquivo.

O último comando mostra a outra metade da história. Compilado para o Java 21, o mesmo arquivo é
recusado: **arquivos-fonte compactos são novos no Java 25**, e a mensagem diz qual versão pedir.

Este curso escreve os programas do jeito longo, com a classe, `public static void main(String[]
args)` e `System.out.println`, daqui até a lição 40. Não é nostalgia. Todo código Java que alguém vai
lhe pagar para ler está escrito assim, toda biblioteca se documenta assim, e os cursos
`java-functional` e `java-back`, depois deste, constroem classes que outras classes usam, onde a forma
compacta não se aplica. Use arquivos compactos para scripts e experimentos, e saiba a forma longa de
cor.
