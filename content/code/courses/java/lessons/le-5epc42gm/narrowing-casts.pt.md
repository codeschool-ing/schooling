---
title: Estreitamento, e o cast que diz que você queria isso
version: 1
---

Na outra direção, de um tipo maior para um menor, o valor pode se perder inteiro. **O Java se recusa
a fazer isso em silêncio**: atribuir um `double` a um `int` é erro de compilação, mesmo quando o
número caberia.

```java
// Lossy.java
public class Lossy {
    public static void main(String[] args) {
        double price = 3.99;
        int whole = price;
        System.out.println(whole);
    }
}
```

```
ana@vm:~/convert$ javac Lossy.java
Lossy.java:5: error: incompatible types: possible lossy conversion from double to int
        int whole = price;
                    ^
1 error
```

A mensagem nomeia o risco, `possible lossy conversion` (possível conversão com perda), não uma
certeza: o compilador não olha o `3.99`, só os tipos. Para converter mesmo assim você escreve um
**cast**, o tipo de destino entre parênteses na frente do valor, `(int) price`. Um cast é você dizendo
ao compilador que sabe que um valor pode se perder e aceita isso. O que exatamente se perde depende
da conversão:

```java
// Narrow.java
public class Narrow {
    public static void main(String[] args) {
        double price = 3.99;
        System.out.println((int) price);
        System.out.println((int) -3.99);
        System.out.println((byte) 200);
        System.out.println((int) 1e20);
        System.out.println((int) Double.NaN);
        System.out.println(Math.round(3.99));
        System.out.println(Math.round(-2.5));
        System.out.println(Math.toIntExact(3_000_000_000L));
    }
}
```

```
ana@vm:~/convert$ java Narrow.java
3
-3
-56
2147483647
0
4
-2
Exception in thread "main" java.lang.ArithmeticException: integer overflow
	at java.base/java.lang.Math.toIntExact(Math.java:1375)
	at Narrow.main(Narrow.java:12)
```

Cada linha é uma regra diferente, e nenhuma delas é arredondamento:

| expressão | impresso | a regra |
|---|---|---|
| `(int) 3.99` | `3` | de decimal para inteiro **corta a fração**, em direção ao zero |
| `(int) -3.99` | `-3` | em direção ao zero, então para cima num número negativo, não para -4 |
| `(byte) 200` | `-56` | de um inteiro para um menor **guarda os bits de baixo**: 200 passa 256 do que cabe num `byte`, menos 256 dá -56 |
| `(int) 1e20` | `2147483647` | um decimal grande demais para o destino **para no maior valor dele** |
| `(int) Double.NaN` | `0` | o não-número, assunto da lição 8, vira 0 |

O cast nunca falha. **Ele sempre produz um número, e às vezes um errado**, sem nada na tela dizendo
qual. Dois métodos de `Math` dizem mais sobre o que você quer.

O `Math.round` arredonda para o inteiro mais próximo, então 3,99 virou 4. Metades sobem, em direção ao
infinito positivo, e por isso `Math.round(-2.5)` deu -2 e não -3. O `Math.round` de um `double`
devolve um `long`, então ainda precisa de um cast para caber num `int`.

O `Math.toIntExact` recebe um `long` e devolve o `int` só se couber. 3.000.000.000 não cabe, então ele
lançou `ArithmeticException: integer overflow` e o programa parou na linha 12. É o comportamento a
querer quando um número errado seria pior que nenhum: **uma exceção que você vê é melhor que um valor
errado em silêncio**.
