---
title: O que um lambda pode usar do que está em volta
version: 1
---

**Um lambda pode ler as variáveis visíveis onde está escrito: seus próprios parâmetros, os campos do
objeto em volta e as variáveis locais do método em que está.** A última delas vem com uma regra, e a
regra é o erro de compilação mais comum que um lambda produz.

## Capturando um valor

```java
// Capture.java: a lambda that uses a parameter, a local and a field
import java.util.function.Supplier;

public class Capture {
    private final String shop = "Livraria Lumen";

    Supplier<String> greeter(String visitor) {
        String greeting = "Welcome";
        return () -> greeting + ", " + visitor + ", to " + this.shop;
    }

    public static void main(String[] args) {
        Supplier<String> greet = new Capture().greeter("Ana");
        System.out.println(greet.get());
    }
}
```

```
ana@vm:~/fp/lambdas$ java Capture.java
Welcome, Ana, to Livraria Lumen
```

`greeter` retornou antes de `greet.get()` rodar, e com ele foram as suas variáveis locais,
`greeting` e `visitor`. O lambda imprimiu as duas mesmo assim. **Quando o lambda foi criado, ele
copiou os valores delas para dentro de si.** É isso que capturar quer dizer, e é por isso que existe
a regra abaixo.

## Efetivamente final

```java
// Counter.java: a lambda that tries to change a local variable
import java.util.List;

public class Counter {
    public static void main(String[] args) {
        int count = 0;
        List.of("a", "b", "c").forEach(s -> count++);
        System.out.println(count);
    }
}
```

```
ana@vm:~/fp/lambdas$ javac -d out Counter.java
Counter.java:7: error: local variables referenced from a lambda expression must be final or effectively final
        List.of("a", "b", "c").forEach(s -> count++);
                                            ^
1 error
```

**Uma variável local que um lambda usa nunca pode mudar, nem antes nem depois de o lambda ser
escrito.** Ela não precisa dizer `final`; precisa ser uma que poderia dizer. A especificação chama
isso de **efetivamente final**, e o compilador confere para cada variável local que um lambda lê. A
regra sai direto da cópia: o lambda guarda uma cópia de `count`, então um incremento dentro dele
mudaria a cópia e deixaria a variável como estava, e uma atribuição fora dele deixaria a cópia
desatualizada. O Java recusa as duas em vez de escolher uma.

A regra também cobre uma mudança que o lambda nunca faz:

```java
// Reassigned.java: the lambda reads, and somebody else writes
public class Reassigned {
    public static void main(String[] args) {
        String greeting = "Hi";
        greeting = "Hello";
        Runnable say = () -> System.out.println(greeting);
        say.run();
    }
}
```

```
ana@vm:~/fp/lambdas$ javac -d out Reassigned.java
Reassigned.java:6: error: local variables referenced from a lambda expression must be final or effectively final
        Runnable say = () -> System.out.println(greeting);
                                                ^
1 error
```

`greeting` recebeu duas atribuições, então não é efetivamente final, e o lambda não pode lê-la. O
conserto é dar ao lambda uma variável atribuída uma vez só, como
`String finalGreeting = greeting;` acima do lambda.

**Campos não entram na regra.** `this.shop`, lá em cima, foi lido através de `this`, e o lambda
capturou o `this`, que nunca muda; o campo em si pode mudar quantas vezes você quiser, e o lambda vê
o valor mais recente quando roda. Essa liberdade é exatamente o que torna perigoso um campo
compartilhado entre duas threads, e as aulas 11 a 14 tratam desse perigo. Contar dentro de um
`forEach` fica melhor sem um lambda mudando coisa nenhuma, que é o que o `count()` e o `reduce` da
aula 7 fazem.

## `this` é o objeto em volta do lambda

Uma classe anônima é uma classe, então dentro dela `this` é o objeto anônimo. Um lambda não é, então
`this` significa o que significa no método em volta:

```java
// WhoIsThis.java: `this` inside a lambda and inside an anonymous class
public class WhoIsThis {
    @Override
    public String toString() {
        return "the WhoIsThis object";
    }

    void show() {
        Runnable lambda = () -> System.out.println("lambda sees:    " + this);
        Runnable anonymous = new Runnable() {
            @Override
            public void run() {
                System.out.println("anonymous sees: " + this);
            }

            @Override
            public String toString() {
                return "the anonymous Runnable";
            }
        };
        lambda.run();
        anonymous.run();
    }

    public static void main(String[] args) {
        new WhoIsThis().show();
    }
}
```

```
ana@vm:~/fp/lambdas$ java WhoIsThis.java
lambda sees:    the WhoIsThis object
anonymous sees: the anonymous Runnable
```

**Dentro de um lambda, `this` é o objeto que o envolve.** O mesmo vale para nomes. O método de uma
classe anônima pode chamar seu parâmetro do que quiser, porque a classe é um escopo novo; o
parâmetro de um lambda não pode repetir o nome de uma variável local que já está visível:

```java
// Shadow.java: a lambda parameter with a name already taken
import java.util.function.Function;

public class Shadow {
    public static void main(String[] args) {
        String s = "outer";
        Function<String, Integer> length = s -> s.length();
        System.out.println(length.apply(s));
    }
}
```

```
ana@vm:~/fp/lambdas$ javac -d out Shadow.java
Shadow.java:7: error: variable s is already defined in method main(String[])
        Function<String, Integer> length = s -> s.length();
                                           ^
1 error
```

As duas regras vêm do fato que os arquivos de classe mostraram na seção 04: **um lambda não é um
escopo novo com uma classe em volta**, só um corpo que roda em outro lugar.
