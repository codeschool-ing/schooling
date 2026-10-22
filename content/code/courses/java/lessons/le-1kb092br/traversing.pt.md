---
title: Percorrendo um array, e as ferramentas da `Arrays`
version: 1
---

A maior parte do trabalho com um array visita cada elemento uma vez. O Java tem dois laços para
isso, e **qual usar depende de você precisar da posição ou só do valor**. A lição 11 desmonta os
laços direito; aqui eles aparecem nas duas formas que um array pede:

```java
// Traversing.java
import java.util.Arrays;

public class Traversing {
    public static void main(String[] args) {
        int[] stock = {4, 0, 7, 2, 9};

        int total = 0;
        for (int i = 0; i < stock.length; i++) {
            total += stock[i];
        }
        System.out.println("total " + total);

        int most = stock[0];
        for (int n : stock) {
            most = Math.max(most, n);
        }
        System.out.println("most " + most);

        int[] sorted = Arrays.copyOf(stock, stock.length);
        Arrays.sort(sorted);
        System.out.println(Arrays.toString(sorted) + " " + Arrays.toString(stock));
        System.out.println(Arrays.binarySearch(sorted, 2));
        System.out.println(Arrays.binarySearch(stock, 2));

        int[] alias = stock;
        alias[0] = 100;
        System.out.println(stock[0]);

        int[] copy = Arrays.copyOf(stock, stock.length);
        System.out.println((copy == stock) + " " + Arrays.equals(copy, stock));
        Arrays.fill(copy, 1);
        System.out.println(Arrays.toString(copy));
        System.out.println(Arrays.toString(Arrays.copyOf(stock, 7)));
    }
}
```

```
ana@vm:~/arrays$ java Traversing.java
total 22
most 9
[0, 2, 4, 7, 9] [4, 0, 7, 2, 9]
1
-1
100
false true
[1, 1, 1, 1, 1]
[100, 0, 7, 2, 9, 0, 0]
```

## Dois laços

O primeiro laço conta `i` a partir de 0 enquanto ele fica abaixo de `stock.length`, e lê `stock[i]`
a cada volta: ele tem a posição e poderia escrever nela. **O segundo, `for (int n : stock)`, entrega
cada valor por vez e posição nenhuma.** Ele não consegue sair dos limites nem errar o `<`, o que o
torna a escolha certa sempre que a posição não importa, como no maior valor, `most 9`.

## A classe `Arrays`

| chamada | imprimiu | |
|---|---|---|
| `Arrays.copyOf(stock, stock.length)` | um array novo | uma cópia, então ordená-la deixou o `stock` em paz |
| `Arrays.sort(sorted)` | `[0, 2, 4, 7, 9]` | ordena no lugar, do menor para o maior |
| `Arrays.binarySearch(sorted, 2)` | `1` | a posição do 2 na cópia ordenada |
| `Arrays.binarySearch(stock, 2)` | `-1` | **uma resposta errada: o `stock` não está ordenado**, e o 2 está ali, no índice 3 |
| `Arrays.equals(copy, stock)` | `true` | mesmo tamanho, mesmos elementos na mesma ordem |
| `Arrays.fill(copy, 1)` | `[1, 1, 1, 1, 1]` | toda posição recebe um mesmo valor |
| `Arrays.copyOf(stock, 7)` | dois zeros a mais | uma cópia mais longa é completada com o valor padrão |

O `binarySearch` corta a faixa pela metade a cada passo, o que o torna rápido num array grande e
**correto só num ordenado**. Num array desordenado ele não falha, ele responde, e a resposta é um
número negativo que quer dizer "não está aqui". Nada avisa você.

## Uma segunda variável não é um segundo array

`int[] alias = stock;` não copiou nada. Criou uma segunda variável que se refere **ao mesmo array**,
então `alias[0] = 100` mudou o que `stock[0]` imprimiu. O `copyOf` faz uma cópia de verdade, e as
duas comparações nela mostram a diferença entre os operadores: `copy == stock` pergunta se são o
mesmo array e disse `false`; o `Arrays.equals` compara o conteúdo e disse `true`. É o `==` contra o
`equals` das strings da lição 7, de novo, e a lição 30 é sobre o porquê.
