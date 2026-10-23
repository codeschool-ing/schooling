---
title: Um método abstrato
version: 1
---

**Uma interface funcional é uma interface com exatamente um método abstrato, e qualquer interface
assim pode ser escrita como um lambda.** A definição é só isso. O `Comparator` da aula 1 se
qualificava porque tem um método a implementar, `compare`; o `Runnable` se qualifica porque tem
`run`. O Java não criou um tipo novo para lambdas em 2014. Ele concordou em aceitar um lambda onde
quer que uma dessas interfaces fosse esperada, inclusive as escritas muito antes.

As suas próprias interfaces se qualificam do mesmo jeito:

```java
// OneMethod.java: an interface of our own, written as a lambda
@FunctionalInterface
interface PriceRule {
    long apply(long cents);

    default String describe(long cents) {
        return cents + " -> " + apply(cents);
    }
}

public class OneMethod {
    public static void main(String[] args) {
        PriceRule tenOff = cents -> cents - cents / 10;
        PriceRule shipping = cents -> cents + 1500;
        System.out.println(tenOff.describe(8990));
        System.out.println(shipping.describe(8990));
    }
}
```

```
ana@vm:~/fp/interfaces$ java OneMethod.java
8990 -> 8091
8990 -> 10490
```

`PriceRule` tem um método abstrato, `apply`, então cada lambda virou um `PriceRule` cujo `apply` é o
corpo do lambda. **O método default não conta**: ele já tem corpo, então não há nada para um lambda
preencher, e todo `PriceRule` feito de lambda ganha o `describe` de graça. Os preços estão em
centavos, como `long`, pelo motivo que o curso `java` deu sobre ponto flutuante.

## A anotação é uma promessa que o compilador confere

`@FunctionalInterface` não muda nada no funcionamento da interface. Ela pede ao compilador que
**recuse a interface se um dia ela deixar de ter exatamente um método abstrato**, que é o dia em que
alguém acrescenta um segundo e todos os lambdas do código quebram de uma vez. Este é esse dia:

```java
// TwoMethods.java: a second abstract method breaks the promise
@FunctionalInterface
interface PriceRule {
    long apply(long cents);

    String label();
}

public class TwoMethods {
    public static void main(String[] args) {
        PriceRule tenOff = cents -> cents - cents / 10;
    }
}
```

```
ana@vm:~/fp/interfaces$ javac -d out TwoMethods.java
TwoMethods.java:2: error: Unexpected @FunctionalInterface annotation
@FunctionalInterface
^
  PriceRule is not a functional interface
    multiple non-overriding abstract methods found in interface PriceRule
TwoMethods.java:11: error: incompatible types: PriceRule is not a functional interface
        PriceRule tenOff = cents -> cents - cents / 10;
                           ^
    multiple non-overriding abstract methods found in interface PriceRule
2 errors
```

Dois erros, em dois lugares. O primeiro é a anotação fazendo seu trabalho, na interface, onde o
erro foi cometido. O segundo é no lambda, que não tem mais um método único em que se transformar.
**Sem a anotação, só o segundo erro aparece**, num arquivo de outra pessoa, e quem acrescentou o
`label()` nunca o vê. Esse é o argumento para escrevê-la em toda interface que você pretende usar
com lambdas.

## O que mais pode haver numa

A regra conta métodos abstratos, e três tipos de método não entram na conta:

- **métodos `default`**, que têm corpo, como o `describe` acima;
- **métodos `static`**, que pertencem à interface e não a um objeto;
- **métodos que `Object` já tem**, como `equals` e `toString`. Todo objeto herda um corpo para eles,
  então declará-los numa interface não acrescenta nada a implementar. O `Comparator` declara
  `equals` e continua funcional por esse motivo.

Então uma interface funcional pode ser grande. O `Comparator` tem um método abstrato e, no Java 25,
mais de uma dúzia de métodos default e estáticos em volta; a aula 5 usa vários deles para montar uma
ordem a partir de ordens menores.
