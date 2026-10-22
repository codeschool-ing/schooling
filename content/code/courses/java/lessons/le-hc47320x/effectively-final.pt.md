---
title: Efetivamente final, a regra sem palavra-chave
version: 1
---

O Java consegue pôr um pedaço de código dentro de outro e executá-lo depois. A lição 17 apresenta a
primeira forma, a **classe anônima**, e o curso `java-functional` a segunda, a **lambda**. As duas
podem ler as variáveis locais à sua volta, com uma condição, e a condição é o motivo de esta lição
mencioná-las. Num diretório novo, `~/capture`:

```java
// Capture.java
public class Capture {
    public static void main(String[] args) {
        String branch = "Centro";
        Runnable report = new Runnable() {
            public void run() {
                System.out.println("Report for " + branch);
            }
        };
        report.run();
    }
}
```

```
ana@vm:~/capture$ javac Capture.java && java Capture
Report for Centro
```

Leia `new Runnable() { ... }` como "um objeto cujo método `run` é este código". O código lá dentro lê
`branch`, uma variável local do `main`, e a imprimiu. Agora mude `branch` depois de o objeto ser
criado:

```java
// Capture.java
public class Capture {
    public static void main(String[] args) {
        String branch = "Centro";
        Runnable report = new Runnable() {
            public void run() {
                System.out.println("Report for " + branch);
            }
        };
        branch = "Norte";
        report.run();
    }
}
```

```
ana@vm:~/capture$ javac Capture.java
Capture.java:7: error: local variables referenced from an inner class must be final or effectively final
                System.out.println("Report for " + branch);
                                                   ^
1 error
```

**Uma variável é *efetivamente final* (effectively final) quando nada a atribui depois da
declaração**, mesmo que ninguém tenha escrito `final`. O primeiro `Capture` se qualificava; o segundo
atribuiu `branch` de novo e não se qualificou. Uma lambda, a forma com seta, segue exatamente a mesma
regra:

```java
// Lambda.java
public class Lambda {
    public static void main(String[] args) {
        int count = 0;
        Runnable add = () -> System.out.println(count + 1);
        count = 5;
        add.run();
    }
}
```

```
ana@vm:~/capture$ javac Lambda.java
Lambda.java:5: error: local variables referenced from a lambda expression must be final or effectively final
        Runnable add = () -> System.out.println(count + 1);
                                                ^
1 error
```

## Por que a regra existe

O código lá dentro pode rodar muito depois de o `main` ter seguido em frente, ou depois de ele ter
retornado e o seu quadro ter sumido, que a lição 12 desenhou. Por isso o objeto não guarda um vínculo
com a variável; **ele guarda uma cópia do valor, tirada quando o objeto é criado.** Se a variável
pudesse mudar depois, a cópia e a variável discordariam, e `Report for Centro` sairia impresso depois
de `branch` ter virado `Norte`. Em vez de deixar as duas se afastarem em silêncio, o compilador
proíbe a segunda atribuição.

A regra é sobre a variável, não sobre o objeto, exatamente como na seção 02. Um `StringBuilder`
`final` capturado ainda aceita `append` lá de dentro, porque a cópia é uma cópia da referência.
Quando o código lá dentro precisa de um valor que muda, dê a ele um objeto que guarde o valor, e
mantenha fixa a referência em si.
