---
title: Dinheiro, com `BigDecimal` ou com centavos
version: 1
---

A seção 04 mostrou por que um `double` é o lugar errado para uma multa de R$ 12,30: o valor guardado
não é 12,30, e sim a fração binária mais próxima, e as somas derivam. Dinheiro precisa de aritmética
decimal exata e de uma regra de arredondamento declarada. O Java oferece dois jeitos sólidos de ter
as duas coisas: **o `BigDecimal`, um número decimal de qualquer tamanho, ou um `long` que conta
centavos.**

```java
// Money.java
import java.math.BigDecimal;
import java.math.RoundingMode;

public class Money {
    public static void main(String[] args) {
        System.out.println(new BigDecimal(0.1));
        System.out.println(new BigDecimal("0.1"));

        BigDecimal a = new BigDecimal("0.10");
        BigDecimal b = new BigDecimal("0.20");
        BigDecimal sum = a.add(b);
        System.out.println(sum);
        System.out.println(sum.equals(new BigDecimal("0.3")));
        System.out.println(sum.compareTo(new BigDecimal("0.3")) == 0);

        BigDecimal fine = new BigDecimal("2.345");
        System.out.println(fine.setScale(2, RoundingMode.HALF_UP));
        System.out.println(fine.setScale(2, RoundingMode.HALF_EVEN));

        BigDecimal ten = new BigDecimal("10.00");
        System.out.println(ten.divide(new BigDecimal("3"), 2, RoundingMode.HALF_EVEN));
        System.out.println(ten.divide(new BigDecimal("3")));
    }
}
```

```
ana@vm:~/maths$ java Money.java
0.1000000000000000055511151231257827021181583404541015625
0.1
0.30
false
true
2.35
2.34
3.33
Exception in thread "main" java.lang.ArithmeticException: Non-terminating decimal expansion; no exact representable decimal result.
	at java.base/java.math.BigDecimal.divide(BigDecimal.java:1810)
	at Money.main(Money.java:23)
```

## Construa a partir de uma string, nunca de um `double`

A primeira linha é a armadilha. O `new BigDecimal(0.1)` recebeu um `double`, então registrou com
fidelidade a fração binária que o `double` guardava, todos os 55 dígitos dela. **O
`new BigDecimal("0.1")` recebeu o texto**, e guarda exatamente um décimo. A regra vem daí: um
`BigDecimal` se constrói a partir de uma `String`, ou de um número inteiro, e o erro nunca entra.

## A escala faz parte do valor

Um `BigDecimal` é um número inteiro mais uma **escala**, a quantidade de dígitos depois do ponto.
`0.10` é 10 com escala 2, e a soma de `0.10` com `0.20` imprimiu `0.30`, mantendo a escala. É por isso
que a linha seguinte imprimiu `false`: **o `equals` compara a escala também**, e `0.30` não é `0.3`.
Quando a pergunta é "é o mesmo valor?", use `compareTo(...) == 0`, que ignora a escala e imprimiu
`true`.

## Arredondar é uma regra que você escolhe

O `setScale(2, ...)` corta um valor em duas casas, e o segundo argumento diz como. A multa de
`2.345` fica exatamente no meio do caminho entre `2.34` e `2.35`:

| regra | `2.345` virou | o que ela faz com uma metade |
|---|---|---|
| `RoundingMode.HALF_UP` | `2.35` | vai para longe do zero, a regra ensinada na escola |
| `RoundingMode.HALF_EVEN` | `2.34` | vai para o vizinho par, para as metades não empurrarem todas para o mesmo lado |

O `HALF_EVEN` se chama arredondamento bancário, e ao longo de milhares de metades ele soma viés
nenhum. Qual dos dois está certo é uma decisão de negócio, escrita num contrato ou numa lei, e **o
código tem de dizê-la em voz alta**. A divisão força a escolha: `10.00` dividido por `3` com duas
casas e `HALF_EVEN` deu `3.33`, e sem regra de arredondamento a última linha parou o programa com
`ArithmeticException: Non-terminating decimal expansion`. Um terço não tem fim em decimal, e o
`BigDecimal` se recusa a adivinhar onde cortar.

## Ou conte centavos num `long`

Quando todo valor tem as mesmas duas casas decimais, um número inteiro de centavos é exato, rápido e
simples. A soma não deriva, e a única formatação acontece na borda, quando uma pessoa lê:

```java
// Cents.java
public class Cents {
    public static void main(String[] args) {
        long fine = 1050;
        long fee = 2075;
        long total = fine + fee;
        System.out.printf("R$ %d,%02d%n", total / 100, total % 100);

        long bill = 1000;
        long share = bill / 3;
        long left = bill % 3;
        System.out.println(share + " " + share + " " + (share + left));
    }
}
```

```
ana@vm:~/maths$ java Cents.java
R$ 31,25
333 333 334
```

`1050 + 2075` dá `3125` centavos, impressos como `R$ 31,25` separando os reais, `total / 100`, e os
centavos, `total % 100`, completados para dois dígitos com `%02d`. Dividir uma conta em três mostra a
única coisa que os inteiros obrigam você a decidir: **1000 centavos não se dividem por 3**, o resto é
1, e alguma parcela tem de levar o centavo a mais. Aqui ele foi para a última, `333 333 334`, e as
três somam 1000 de volta. Descartá-lo perderia um centavo em cada conta, em silêncio.
