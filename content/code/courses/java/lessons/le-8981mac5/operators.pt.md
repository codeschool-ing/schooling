---
title: Operadores, e os dois que surpreendem
version: 1
---

Os operadores aritméticos do Java são os da escola, `+ - * /`, mais o `%` para o resto. Dois deles
fazem algo diferente de uma calculadora, e **as duas diferenças vêm dos tipos dos operandos, não do
operador**. Crie um diretório para esta lição, `~/maths`, e salve isto como `Operators.java`:

```java
// Operators.java
public class Operators {
    public static void main(String[] args) {
        System.out.println(7 / 2);
        System.out.println(7.0 / 2);
        System.out.println(7 % 3);
        System.out.println(-7 % 3);
        System.out.println(7 % -3);

        int i = 5;
        int a = i++;
        int b = ++i;
        System.out.println(a + " " + b + " " + i);

        System.out.println(2 + 3 * 4);
        System.out.println((2 + 3) * 4);
        System.out.println(10 - 4 - 3);

        int big = Integer.MAX_VALUE;
        System.out.println(big + 1);
        System.out.println(Math.addExact(big, 1));
    }
}
```

```
ana@vm:~/maths$ java Operators.java; echo $?
3
3.5
1
-1
1
5 7 7
14
20
3
-2147483648
Exception in thread "main" java.lang.ArithmeticException: integer overflow
	at java.base/java.lang.Math.addExact(Math.java:915)
	at Operators.main(Operators.java:21)
1
```

Linha por linha, contra o que uma calculadora diria:

| expressão | imprimiu | por quê |
|---|---|---|
| `7 / 2` | `3` | **os dois operandos são `int`, então a divisão é inteira**: a fração é jogada fora |
| `7.0 / 2` | `3.5` | um operando é `double`, então o outro é alargado e a divisão mantém a fração |
| `7 % 3` | `1` | o resto de 7 dividido por 3 |
| `-7 % 3` | `-1` | **o resto leva o sinal do operando da esquerda** |
| `7 % -3` | `1` | o sinal do operando da direita não importa |
| `a`, `b`, `i` | `5 7 7` | `i++` dá o valor antigo e depois soma um; `++i` soma um e depois dá o valor novo |
| `2 + 3 * 4` | `14` | o `*` tem precedência sobre o `+` |
| `(2 + 3) * 4` | `20` | os parênteses primeiro |
| `10 - 4 - 3` | `3` | operadores de mesma precedência vão da esquerda para a direita: `(10 - 4) - 3` |
| `big + 1` | `-2147483648` | o maior `int` mais um dá a volta até o menor |

## A divisão inteira joga a fração fora

`7 / 2` dá `3` e não `3.5` porque o Java decide o tipo de divisão antes de olhar os valores. **Dois
`int` dão um `int`**, e um `int` não tem onde guardar o `.5`. Ele é truncado, ou seja, cortado em
direção ao zero, então `-7 / 2` dá `-3`, e a seção 03 mostra o método que arredonda para baixo. O bug
de sempre é uma média: `sum / count` com dois `int`, em que a correção é transformar um deles em
`double` antes de dividir, `(double) sum / count`, um cast que a lição 6 explica.

O resto segue a mesma regra. `-7 % 3` dá `-1`, porque `-7 / 3` dá `-2` e `-2 * 3 + -1` devolve o
`-7`. Um teste como `n % 2 == 1` para achar números ímpares está, portanto, **errado para números
negativos**: `-7 % 2` dá `-1`. Escreva `n % 2 != 0`.

## `i++` e `++i`

Os dois somam um a `i`. Diferem só no valor que a expressão tem, o que importa quando ela é usada
dentro de uma maior. `a = i++` copiou o 5 antigo para `a` e depois fez `i` virar 6; `b = ++i` fez `i`
virar 7 e copiou o 7. **Numa linha sozinha, `i++;` e `++i;` são a mesma instrução**, e um contador de
laço é o único lugar em que a maioria dos códigos precisa de um deles. Um código que usa o valor de
`i++` dentro de outra expressão é um código em que o próximo leitor tem de parar para pensar.

## O overflow não para o programa

`Integer.MAX_VALUE + 1` imprimiu `-2147483648`. A lição 4 explicou por quê: um `int` tem 32 bits, e
a aritmética dá a volta, do maior valor para o menor, **sem erro e sem aviso**. Um contador de
milissegundos ou uma soma de preços pode cruzar essa linha em silêncio e ficar negativo.

Quando a resposta precisa estar certa ou não existir, a classe `Math` tem versões exatas que
recusam: `Math.addExact`, `subtractExact`, `multiplyExact` e `toIntExact`. A última linha do
programa pediu uma delas e o programa parou com `ArithmeticException: integer overflow`, apontando
para a linha 21, com status de saída 1. **Uma falha que você vê é melhor que um saldo negativo que
você não vê.** O outro remédio é um tipo mais largo: o `long` guarda valores até uns nove
quintilhões, espaço para qualquer contagem de coisas numa biblioteca.
