---
title: Três hábitos que mantêm uma falha visível
version: 1
---

Uma exceção é o programa avisando alguém de que não conseguiu fazer o que lhe pediram. A maior parte
do estrago feito com exceções vem de código que impede essa mensagem de chegar, e **a pior falha é a
que produz uma resposta errada e plausível, sem mensagem nenhuma**. Três hábitos evitam a maior parte
disso.

## Nunca engula uma exceção

O registro abaixo lista as multas que três membros devem, em centavos. A segunda linha tem um erro de
digitação: a letra `O` onde devia haver um zero. O bloco `catch` está vazio, que é o jeito mais curto
de fazer sumir um erro de compilação sobre uma exceção verificada, e aqui ele captura uma não
verificada sem motivo nenhum:

```java
// Fines.java
import java.util.List;

public class Fines {
    public static void main(String[] args) {
        List<String> lines = List.of("ana 250", "rui 1O0", "eva 100");
        int total = 0;
        for (String line : lines) {
            try {
                total += Integer.parseInt(line.split(" ")[1]);
            } catch (NumberFormatException e) {
            }
        }
        System.out.println("fines owed, in cents: " + total);
    }
}
```

```
ana@vm:~/hierarchy$ javac Fines.java FinesLoud.java Flow.java && java Fines
fines owed, in cents: 350
```

**350 centavos, impressos com toda a confiança.** A multa do Rui sumiu, nada na tela diz isso, e o
programa terminou como se tudo estivesse bem. Quem lê o total não tem como saber que está errado, e o
próximo programa a usá-lo herda o erro. Um `catch` vazio transforma uma falha que tinha nome, mensagem
e número de linha num número errado.

Se uma falha pode mesmo ser ignorada, o bloco diz isso num comentário que dá o motivo, para o próximo
leitor poder discordar. "Não é fatal" não é motivo; o que daria errado, e por que isso é aceitável
aqui, é.

## Embrulhe com contexto, e guarde a causa

O segundo hábito é acrescentar o que só esta camada sabe. O `Integer.parseInt` conhece a string que
recebeu. Não sabe que ela veio da linha 2 de um registro de multas. O laço sabe, então o laço captura,
acrescenta isso, e lança de novo com a original como causa:

```java
// FinesLoud.java
import java.util.List;

public class FinesLoud {
    public static void main(String[] args) {
        List<String> lines = List.of("ana 250", "rui 1O0", "eva 100");
        int total = 0;
        for (int i = 0; i < lines.size(); i++) {
            String field = lines.get(i).split(" ")[1];
            try {
                total += Integer.parseInt(field);
            } catch (NumberFormatException e) {
                throw new IllegalArgumentException(
                        "line " + (i + 1) + ": the fine is not a number of cents: " + field, e);
            }
        }
        System.out.println("fines owed, in cents: " + total);
    }
}
```

```
ana@vm:~/hierarchy$ java FinesLoud
Exception in thread "main" java.lang.IllegalArgumentException: line 2: the fine is not a number of cents: 1O0
	at FinesLoud.main(FinesLoud.java:13)
Caused by: java.lang.NumberFormatException: For input string: "1O0"
	at java.base/java.lang.NumberFormatException.forInputString(NumberFormatException.java:67)
	at java.base/java.lang.Integer.parseInt(Integer.java:565)
	at java.base/java.lang.Integer.parseInt(Integer.java:662)
	at FinesLoud.main(FinesLoud.java:11)
```

A linha do topo agora basta para consertar os dados sem abrir o código: **qual linha, qual campo, o
que ele deveria conter, e o valor que estava lá**. O `Caused by:` guarda o relato do próprio JDK,
`For input string: "1O0"`, para quem precisar. Lançar interrompe o laço, então nenhum total é impresso,
o que está certo: nenhum total é melhor que um total errado.

Embrulhar serve para acrescentar informação. Um `catch` que lança uma exceção nova com a mesma
mensagem e sem causa é pior que nenhum `catch`, porque joga fora o stack trace da original.

## Exceções não são controle de fluxo

O terceiro hábito trata do erro oposto: lançar de propósito, como jeito de sair de um laço.

```java
// Flow.java
public class Flow {
    public static void main(String[] args) {
        int[] fines = {250, 100, 75};
        int total = 0;
        try {
            for (int i = 0; ; i++) {
                total += fines[i];
            }
        } catch (ArrayIndexOutOfBoundsException e) {
            System.out.println("total " + total);
        }
    }
}
```

```
ana@vm:~/hierarchy$ java Flow
total 425
```

A resposta está certa, 425. O código ainda esconde a intenção: o laço não tem condição, e quem lê
precisa achar o `catch` para saber onde ele termina. E o `catch` não distingue o fim que esperava de um
erro de verdade: se uma mudança posterior indexasse `fines[i + 1]`, a mesma exceção dispararia um
elemento antes e imprimiria um total errado sem reclamar. **Uma exceção diz que aconteceu algo
inesperado**, e um laço chegando ao fim de um array é a coisa mais esperada do programa. O
`for (int fine : fines)` da lição 11 diz isso numa linha.

O mesmo vale para usar uma exceção para responder a uma pergunta comum: se uma string é um número se
pergunta validando a entrada onde ela chega ao programa, e uma exceção é o que acontece quando algo
passa por essa conferência.
