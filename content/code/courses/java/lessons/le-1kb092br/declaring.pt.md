---
title: Um array é uma fileira de caixas de um tipo só
version: 1
---

Um array guarda um número fixo de valores de um mesmo tipo, lado a lado, cada um alcançado pela sua
posição. **O tamanho dele é decidido quando ele é criado e nunca muda depois**: não existe
acrescentar um sexto elemento a um array de cinco. A lição 31 mostra a lista que cresce; esta lição é
a estrutura que fica por baixo dela. Crie um diretório para esta lição, `~/arrays`, e salve isto como
`Declaring.java`:

```java
// Declaring.java
import java.util.Arrays;

public class Declaring {
    public static void main(String[] args) {
        int[] copies = new int[5];
        String[] titles = new String[3];
        double[] fines = new double[2];
        boolean[] lent = new boolean[2];
        System.out.println(Arrays.toString(copies));
        System.out.println(Arrays.toString(titles));
        System.out.println(Arrays.toString(fines) + " " + Arrays.toString(lent));

        int[] years = {1899, 1881, 1943};
        System.out.println(years.length);
        System.out.println(years[0] + " " + years[years.length - 1]);
        System.out.println(years);

        years[1] = 1880;
        System.out.println(Arrays.toString(years));
        System.out.println(years[3]);
    }
}
```

```
ana@vm:~/arrays$ java Declaring.java
[0, 0, 0, 0, 0]
[null, null, null]
[0.0, 0.0] [false, false]
3
1899 1943
[I@25b485ba
[1899, 1880, 1943]
Exception in thread "main" java.lang.ArrayIndexOutOfBoundsException: Index 3 out of bounds for length 3
	at Declaring.main(Declaring.java:21)
```

`int[] copies` declara uma variável que pode guardar um array de `int`, e `new int[5]` cria um com
cinco posições. **Um array novo nunca está vazio no sentido de não guardar nada**: toda posição começa
com o valor padrão do seu tipo, `0` para números, `false` para `boolean`, e `null`, que quer dizer
objeto nenhum, para uma `String` ou qualquer outra classe. A segunda forma, `{1899, 1881, 1943}`, cria
o array e o preenche de uma vez, e o compilador conta o tamanho para você.

## As posições começam em 0

`years[0]` é o primeiro elemento e `years[years.length - 1]` o último, o que imprimiu `1899 1943`. O
`length` é um campo e não um método, então não leva parênteses, ao contrário do `length()` de uma
`String` na lição 7. A atribuição a `years[1]` trocou 1881 por 1880 no lugar.

Depois `years[3]` pediu um quarto elemento de um array de três, e o programa parou:
`ArrayIndexOutOfBoundsException: Index 3 out of bounds for length 3`, na linha 21. **O Java confere
todo índice em todo acesso**, então um índice errado é uma exceção na linha que errou, e não a leitura
de qualquer memória que estivesse depois do fim, como seria em C.

## Imprimindo um array

`System.out.println(years)` imprimiu `[I@25b485ba`, o que não é um bug mas não serve para ninguém. Um
array é um objeto, e um objeto impresso sem um método próprio que o descreva mostra o nome em código
do seu tipo, `[I` para um array de `int`, depois `@` e um número derivado da identidade dele. **Esse
número muda a cada execução**, e o seu não vai bater. O `Arrays.toString` é o método que imprime os
elementos, e a classe `java.util.Arrays`, a que ele pertence, é onde moram as outras ferramentas de
array da próxima seção.
