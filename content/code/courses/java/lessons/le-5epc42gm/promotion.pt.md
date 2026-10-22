---
title: Que tipo uma expressão tem
version: 1
---

A seção 02 converteu valores na hora da atribuição. A mesma coisa acontece **dentro de uma
expressão**, e ali as regras surpreendem, porque decidem o tipo de um resultado antes de ele ser
guardado em lugar nenhum. Duas regras cobrem quase tudo:

1. **Aritmética nunca é feita em `byte`, `short` ou `char`.** Cada um é alargado para `int` antes,
   então o resultado é no mínimo um `int`.
2. **Se um dos lados é mais largo, o outro é alargado para igualar.** `int` com `long` dá `long`,
   qualquer coisa com `double` dá `double`.

A primeira regra faz da soma de dois `byte` um `int`, e um `int` não entra num `byte` sem cast:

```java
// SmallSum.java
public class SmallSum {
    public static void main(String[] args) {
        byte morning = 10;
        byte afternoon = 20;
        byte total = morning + afternoon;
        System.out.println(total);
    }
}
```

```
ana@vm:~/convert$ javac SmallSum.java
SmallSum.java:6: error: incompatible types: possible lossy conversion from int to byte
        byte total = morning + afternoon;
                             ^
1 error
```

10 mais 20 cabe folgado num `byte`, e o compilador recusa mesmo assim, pelo mesmo motivo da seção 03:
ele olha tipos, e `morning + afternoon` é um `int`. `byte total = (byte) (morning + afternoon);`
compila. Também compila fazer de `total` um `int`, que é a correção de costume.

## Oito resultados, oito regras

```java
// Promote.java
public class Promote {
    public static void main(String[] args) {
        byte stock = 10;
        stock += 300;
        System.out.println(stock);
        System.out.println(7 / 2);
        System.out.println(7 / 2.0);
        int pages = 7;
        double half = pages / 2;
        System.out.println(half);
        char letter = 'A';
        System.out.println(letter + 1);
        System.out.println((char) (letter + 1));
        System.out.println("total: " + 1 + 2);
        System.out.println(1 + 2 + " total");
    }
}
```

```
ana@vm:~/convert$ java Promote.java
54
3
3.5
3.0
66
B
total: 12
3 total
```

Linha a linha:

- **`stock += 300` imprimiu 54.** Os operadores compostos, `+=`, `-=` e o resto, trazem um cast
  escondido de volta ao tipo da variável. `stock + 300` é 310, um `int`, e o `(byte)` escondido guardou
  os bits de baixo, como `(byte) 200` fez na seção 03. `stock = stock + 300;` teria sido recusado; a
  forma curta compila e está errada.
- **`7 / 2` imprimiu 3.** Os dois lados são `int`, então é divisão inteira e a fração é cortada.
  `7 / 2.0` imprimiu 3.5, porque um lado é `double` e o outro foi alargado.
- **`double half = pages / 2` imprimiu 3.0**, não 3.5. O tipo da variável não entra na expressão:
  `pages / 2` é calculado como divisão de `int`, dá 3, e só então 3 é alargado para `3.0`. Escreva
  `pages / 2.0`.
- **`letter + 1` imprimiu 66**: o `char` virou `int` para a aritmética. `(char) (letter + 1)` o
  converteu de volta e imprimiu `B`.
- **`"total: " + 1 + 2` imprimiu `total: 12`**, e `1 + 2 + " total"` imprimiu `3 total`. Um `+` com
  uma `String` de qualquer lado junta texto, e o Java avalia da esquerda para a direita: no primeiro,
  `"total: " + 1` já é uma `String`, então o `2` é juntado a ela; no segundo, `1 + 2` é somado como
  números primeiro.

A maioria disso é silenciosa. **Nada avisa sobre `pages / 2` ou `stock += 300`**, então o hábito a
construir é saber o tipo de cada expressão que você escreve, e a lição 8 acrescenta os operadores que
vêm com isso.
