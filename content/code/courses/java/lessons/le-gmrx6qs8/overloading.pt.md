---
title: Sobrecarga, decidida pelo compilador
version: 1
---

**Sobrecarga (overloading) é ter vários métodos numa classe com o mesmo nome e listas de parâmetros
diferentes.** O `println` é o que todo mundo já encontrou: há um `println(int)`, um
`println(String)`, um `println(double)` e mais sete, e você nunca precisou dizer qual queria. O
compilador escolheu, pelos tipos dos argumentos, e gravou a escolha no arquivo de classe. Nada disso
acontece em tempo de execução, e é nesse fato que o resto da lição se apoia.

## Seis chamadas, seis métodos

Em `~/overload`:

```java
// Printer.java
public class Printer {
    static void show(int x) {
        System.out.println("int " + x);
    }

    static void show(long x) {
        System.out.println("long " + x);
    }

    static void show(Integer x) {
        System.out.println("Integer " + x);
    }

    static void show(Object x) {
        System.out.println("Object " + x);
    }

    static void show(int... xs) {
        System.out.println("varargs of " + xs.length);
    }

    public static void main(String[] args) {
        byte small = 5;
        show(5);
        show(5L);
        show(small);
        show(Integer.valueOf(5));
        show("five");
        show(1, 2, 3);
    }
}
```

```
ana@vm:~/overload$ javac Printer.java && java Printer
int 5
long 5
int 5
Integer 5
Object five
varargs of 3
```

Leia a saída contra os argumentos:

| chamada | tipo do argumento | método escolhido | por quê |
|---|---|---|---|
| `show(5)` | `int` | `show(int)` | correspondência exata |
| `show(5L)` | `long` | `show(long)` | correspondência exata |
| `show(small)` | `byte` | `show(int)` | não há `show(byte)`; um `byte` se alarga para `int`, o tipo mais largo mais próximo |
| `show(Integer.valueOf(5))` | `Integer` | `show(Integer)` | correspondência exata |
| `show("five")` | `String` | `show(Object)` | uma `String` é um `Object`, e não existe nada mais próximo |
| `show(1, 2, 3)` | três `int` | `show(int...)` | só o método varargs aceita três argumentos |

**Os tipos dos parâmetros são o que distingue as sobrecargas**: o nome, o número de parâmetros e os
seus tipos em ordem, que juntos se chamam a **assinatura** do método. O tipo de retorno não faz parte
dela, então dois métodos que só diferem no que devolvem não são duas sobrecargas:

```java
// Twice.java
public class Twice {
    int count() {
        return 1;
    }

    long count() {
        return 1L;
    }
}
```

```
ana@vm:~/overload$ javac Twice.java
Twice.java:7: error: method count() is already defined in class Twice
    long count() {
         ^
1 error
```

## Quando mais de um serviria

`show(5)` correspondeu exatamente a `show(int)`. Tire a correspondência exata e um `int` ainda
alcançaria três dos outros: alargado para `long`, encaixotado num `Integer`, ou empacotado num
`int...`. O compilador ordena os três, e o `Ranking` pergunta duas vezes:

```java
// Ranking.java
public class Ranking {
    static void widen(long x) {
        System.out.println("widen: long");
    }

    static void widen(Integer x) {
        System.out.println("widen: Integer");
    }

    static void box(Integer x) {
        System.out.println("box: Integer");
    }

    static void box(int... xs) {
        System.out.println("box: varargs");
    }

    public static void main(String[] args) {
        widen(5);
        box(5);
    }
}
```

```
ana@vm:~/overload$ javac Ranking.java && java Ranking
widen: long
box: Integer
```

**Alargar vence encaixotar, e encaixotar vence varargs.** `widen(5)` escolheu `long` em vez de
`Integer`, e `box(5)` escolheu `Integer` em vez de `int...`. A ordem é história, não gosto. O
autoboxing chegou no Java 5, e um programa escrito para o Java 1.4 que chamava `widen(5)` sempre
tinha caído em `widen(long)`; pôr o encaixotamento abaixo manteve esse programa fazendo o que sempre
fez. O varargs chegou na mesma versão e foi para o fim da fila pelo mesmo motivo.

## Quando dois servem igualmente bem

```java
// Ambiguous.java
public class Ambiguous {
    static void lend(Integer copies, Object note) {
    }

    static void lend(Object copies, Integer note) {
    }

    public static void main(String[] args) {
        lend(1, 2);
    }
}
```

```
ana@vm:~/overload$ javac Ambiguous.java
Ambiguous.java:10: error: reference to lend is ambiguous
        lend(1, 2);
        ^
  both method lend(Integer,Object) in Ambiguous and method lend(Object,Integer) in Ambiguous match
1 error
```

`lend(1, 2)` alcança qualquer um dos dois métodos encaixotando um argumento e alargando o outro para
`Object`, e nenhum caminho é melhor que o outro. **O compilador não tira cara ou coroa; ele recusa**,
e nomeia os dois candidatos. A correção é de quem chama: um cast como
`lend((Integer) 1, (Object) 2)` ou, mais honestamente, dois métodos com nomes diferentes. Quando
sobrecargas precisam de casts para serem chamadas, os nomes estão trabalhando de menos.
