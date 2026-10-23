---
title: Oito tipos primitivos, e o que cada um comporta
version: 1
---

Python e JavaScript deixam uma variável guardar qualquer coisa e descobrem o que ela é quando o
programa roda. **O Java decide o tipo de cada variável quando compila**, e o tipo fixa duas coisas de
vez: que valores a variável pode guardar, e quantos bits de memória cada um ocupa. A maioria dos tipos
em Java são classes, que a lição 12 começa. Oito não são. São os **tipos primitivos**, embutidos na
linguagem, e todo número, caractere e verdadeiro-ou-falso de um programa Java é um deles por baixo.

Um programa que pergunta a cada um o tamanho e os limites, em `~/types`:

```java
// Ranges.java
public class Ranges {
    public static void main(String[] args) {
        System.out.println("byte   " + Byte.SIZE + " bits, " + Byte.MIN_VALUE + " to " + Byte.MAX_VALUE);
        System.out.println("short  " + Short.SIZE + " bits, " + Short.MIN_VALUE + " to " + Short.MAX_VALUE);
        System.out.println("int    " + Integer.SIZE + " bits, " + Integer.MIN_VALUE + " to " + Integer.MAX_VALUE);
        System.out.println("long   " + Long.SIZE + " bits, " + Long.MIN_VALUE + " to " + Long.MAX_VALUE);
        System.out.println("float  " + Float.SIZE + " bits, largest " + Float.MAX_VALUE);
        System.out.println("double " + Double.SIZE + " bits, largest " + Double.MAX_VALUE);
        System.out.println("char   " + Character.SIZE + " bits, 0 to " + (int) Character.MAX_VALUE);
        System.out.println("boolean: true or false");
    }
}
```

```
ana@vm:~/types$ java Ranges.java
byte   8 bits, -128 to 127
short  16 bits, -32768 to 32767
int    32 bits, -2147483648 to 2147483647
long   64 bits, -9223372036854775808 to 9223372036854775807
float  32 bits, largest 3.4028235E38
double 64 bits, largest 1.7976931348623157E308
char   16 bits, 0 to 65535
boolean: true or false
```

Cada primitivo tem uma classe de nome parecido, `Integer` para `int` e `Character` para `char`, e
essas classes trazem os limites como constantes. O `(int)` antes de `Character.MAX_VALUE` transforma o
caractere no número dele, um cast (conversão explícita) que a lição 6 explica.

| tipo | bits | guarda | use para |
|---|---|---|---|
| `byte` | 8 | inteiros, de -128 a 127 | bytes crus de um arquivo ou da rede |
| `short` | 16 | inteiros, de -32.768 a 32.767 | quase nada em código novo |
| `int` | 32 | inteiros, uns ±2,1 bilhões | **o padrão para um número inteiro** |
| `long` | 64 | inteiros, uns ±9,2 × 10¹⁸ | contagens que passam de dois bilhões, carimbos de tempo |
| `float` | 32 | decimais, uns 7 dígitos significativos | arrays grandes onde a memória importa |
| `double` | 64 | decimais, uns 15 a 16 dígitos significativos | **o padrão para um decimal** |
| `char` | 16 | uma unidade de código UTF-16, de 0 a 65.535 | um único caractere |
| `boolean` | — | `true` ou `false` | condições |

**`int` e `double` são os padrões**: um número inteiro escrito no código, como `42`, é um `int`, e um
número com ponto, como `39.90`, é um `double`. Os outros são escolhidos de propósito, por um motivo
que você saberia dizer. O tamanho de um `boolean` não faz parte da linguagem, e por isso o programa
não imprimiu nenhum: quem decide como guardá-lo é a JVM.

## O que acontece no limite

Um número fixo de bits quer dizer um maior valor, e o Java não para nele. **Passar dele dá a volta
para a outra ponta, em silêncio**:

```java
// Overflow.java
public class Overflow {
    public static void main(String[] args) {
        int copies = Integer.MAX_VALUE;
        System.out.println(copies);
        System.out.println(copies + 1);
        long many = Integer.MAX_VALUE;
        System.out.println(many + 1);
        char letter = 'A';
        System.out.println(letter);
        System.out.println(letter + 0);
        letter++;
        System.out.println(letter);
    }
}
```

```
ana@vm:~/types$ java Overflow.java
2147483647
-2147483648
2147483648
A
65
B
```

`Integer.MAX_VALUE + 1` é `-2147483648`, o menor `int`, sem erro e sem aviso. A mesma soma num `long`
dá a resposta certa, `2147483648`, porque um `long` tem espaço para ela. **Escolher `int` para algo
que pode passar de dois bilhões é um bug esperando a hora**: uma contagem de visualizações, um tamanho
em bytes, os milissegundos desde 1970. A lição 8 mostra o `Math.addExact`, que lança uma exceção em
vez de dar a volta.

As três últimas linhas são sobre `char`. Ele imprime como letra, `A`, e por baixo é um número: o
`letter + 0` o transformou num `int` e imprimiu `65`, o código dele. O `letter++` somou um a esse
código, e a variável imprimiu `B`.

## Literais, e o que não cabe

Um número escrito no código é um **literal**, e o tipo dele vem do jeito como foi escrito. Um número
inteiro simples é um `int`, então um inteiro grande demais para um `int` é um erro **mesmo quando a
variável que o recebe é um `long`**:

```java
// Population.java
public class Population {
    public static void main(String[] args) {
        long people = 8_000_000_000;
        System.out.println(people);
    }
}
```

```
ana@vm:~/types$ java Population.java
Population.java:4: error: integer number too large
        long people = 8_000_000_000;
                      ^
1 error
error: compilation failed
```

O compilador lê `8_000_000_000` primeiro como `int`, e nenhum `int` é tão grande. A correção é o
sufixo `L`, `8_000_000_000L`, que faz do literal um `long`. Os sublinhados são só para pessoas: o
Java os ignora num número, e `8_000_000_000L` se lê melhor que `8000000000L`.

| escrito | tipo |
|---|---|
| `42`, `8_000` | `int` |
| `42L`, `8_000_000_000L` | `long` |
| `39.90`, `1e3` | `double` |
| `39.90f` | `float` |
| `'A'` (aspas simples) | `char` |
| `"A"` (aspas duplas) | `String`, que não é primitivo |
| `true`, `false` | `boolean` |

Use o `L` maiúsculo: um `l` minúsculo parece o dígito `1` na maioria das fontes.
