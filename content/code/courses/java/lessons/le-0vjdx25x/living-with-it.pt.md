---
title: Devolva o que você quer devolver
version: 1
---

Conhecer a regra é metade. A outra metade é escrever métodos de um jeito que ninguém precise pensar
nela ao chamar um. **Dois hábitos cobrem a maioria dos casos: um método que produz algo o devolve, e
um método que muda o seu argumento diz isso no nome.** Os dois aparecem num programa, em
`~/byvalue/living`:

```java
// Returning.java
import java.util.Arrays;

record MinMax(int min, int max) {
}

public class Returning {
    static MinMax minMax(int[] values) {
        int min = values[0];
        int max = values[0];
        for (int v : values) {
            min = Math.min(min, v);
            max = Math.max(max, v);
        }
        return new MinMax(min, max);
    }

    static int[] sortedCopy(int[] values) {
        int[] copy = values.clone();
        Arrays.sort(copy);
        return copy;
    }

    static void sortInPlace(int[] values) {
        Arrays.sort(values);
    }

    public static void main(String[] args) {
        int[] pages = {256, 640, 180};
        System.out.println(minMax(pages));

        int[] sorted = sortedCopy(pages);
        System.out.println(Arrays.toString(sorted) + " " + Arrays.toString(pages));

        sortInPlace(pages);
        System.out.println(Arrays.toString(pages));
    }
}
```

```
ana@vm:~/byvalue/living$ javac Returning.java && java Returning
MinMax[min=180, max=640]
[180, 256, 640] [256, 640, 180]
[180, 256, 640]
```

**Dois resultados, um valor de retorno.** Um método Java devolve um valor, então um método que acha um
mínimo e um máximo não consegue devolvê-los por dois parâmetros, como uma linguagem com passagem por
referência faria. Ele devolve um objeto com os dois. O record da lição 29 é a forma certa para isso:
`MinMax` é uma linha, e quem chama lê `min()` e `max()` nele. A troca que a seção 02 não conseguiu
escrever fica possível do mesmo jeito: um método que recebe dois valores e devolve um record com eles
na ordem inversa.

**Dois jeitos de ordenar, com nomes que dizem o que fazem.** O `sortedCopy` clona o array, ordena o
clone e o devolve, e a segunda linha mostra `pages` intacto, `[256, 640, 180]`, ao lado da cópia
ordenada. O `sortInPlace` ordena o próprio array de quem chamou pela referência, e a terceira linha
mostra `pages` mudado. Nenhum dos dois está errado. Errado seria um método chamado `sorted` que
mudasse o argumento em silêncio, porque quem chama não tem como saber pela chamada. A biblioteca
padrão segue os mesmos nomes: o `Arrays.sort` muda o array que recebe, e o `List.copyOf` da lição 29
devolve uma lista nova.

## Um parâmetro que você não pretende reatribuir

Reatribuir um parâmetro é permitido, e é o movimento por trás de cada surpresa da seção 04: o autor
achou que a atribuição chegaria a quem chamou. **Marcar um parâmetro como `final` faz o compilador
recusar a atribuição**, o que transforma esse engano num erro na linha em que ele é cometido:

```java
// Guard.java
public class Guard {
    static void replace(final StringBuilder b) {
        b.append("!");
        b = new StringBuilder("other");
    }
}
```

```
ana@vm:~/byvalue/living$ javac Guard.java
Guard.java:5: error: final parameter b may not be assigned
        b = new StringBuilder("other");
        ^
1 error
```

O `b.append("!")` compilou: o `final` impede que o parâmetro seja apontado de novo, e não diz nada
sobre o objeto para o qual ele aponta, como a lição 16 mostrou para toda referência `final`. A
segunda linha foi recusada, pelo nome. Algumas equipes põem `final` em todo parâmetro por esse
motivo, e outras acham isso ruído e preferem uma regra de revisão de código. De um jeito ou de outro,
**um método que reatribui o próprio parâmetro é algo que um leitor precisa olhar duas vezes**, e uma
variável local com nome próprio é mais clara.
