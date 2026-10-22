---
title: O `for` aprimorado, e o que ele não consegue fazer
version: 1
---

A lição 9 encontrou o `for (int n : stock)`, o laço sobre cada elemento de um array. O nome dele é
**`for` aprimorado** (enhanced `for`), e as pessoas o chamam de for-each, que o descreve melhor. Ele
funciona com arrays e com toda coleção da biblioteca, `List` incluída, que a lição 31 apresenta:

```java
// Each.java
import java.util.Arrays;
import java.util.List;

public class Each {
    public static void main(String[] args) {
        String[] titles = {"Dom Casmurro", "Iracema", "Macunaíma"};
        for (String t : titles) {
            System.out.println(t.length() + " " + t);
        }

        List<String> shelf = List.of("O Guarani", "Senhora");
        for (String t : shelf) {
            System.out.println("on the shelf: " + t);
        }

        int[] fines = {10, 20, 30};
        for (int f : fines) {
            f = f * 2;
        }
        System.out.println(Arrays.toString(fines));

        for (int i = 0; i < fines.length; i++) {
            fines[i] = fines[i] * 2;
        }
        System.out.println(Arrays.toString(fines));
    }
}
```

```
ana@vm:~/loops$ java Each.java
12 Dom Casmurro
7 Iracema
9 Macunaíma
on the shelf: O Guarani
on the shelf: Senhora
[10, 20, 30]
[20, 40, 60]
```

**Leia os dois-pontos como "em"**: para cada `String t` em `titles`. O laço cuida da posição, do teste
e do passo, o que remove todo lugar onde um erro de um a mais poderia se esconder. Na `List` ele
funciona igual e não precisa de nada diferente, porque o laço pede à coleção os elementos dela um por
vez; a lição 34 mostra o objeto a quem ele pede, o `Iterator`.

## Ele entrega uma cópia de cada valor

O terceiro laço tentou dobrar todas as multas e **não mudou nada**: o array imprimiu `[10, 20, 30]`
depois. A variável `f` guarda uma cópia do elemento atual, e `f = f * 2` mudou a cópia. O array nem
foi tocado, e o compilador não reclamou, porque atribuir a uma variável local é legal.

Para mudar elementos no lugar você precisa das posições deles, e o laço que tem posições é o `for`
que conta. O quarto laço escreveu por meio de `fines[i]` e imprimiu `[20, 40, 60]`. Então a regra
para escolher entre os dois é curta: **for-each para ler, o `for` que conta para escrever**, ou sempre
que a própria posição importar, como para imprimir `lugar 3 de 5`.

Com um array de objetos a mesma regra vale, com um detalhe: `t = "x"` dentro do laço trocaria só a
cópia da referência, mas chamar um método que altera o objeto alteraria o de verdade. A lição 30 é
sobre essa diferença.
