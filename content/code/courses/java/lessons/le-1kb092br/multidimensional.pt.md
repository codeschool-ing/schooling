---
title: Arrays de arrays
version: 1
---

O Java não tem array de duas dimensões no sentido de uma grade de células num bloco só. **Um
`int[][]` é um array cujos elementos são, eles mesmos, arrays**, cada um um objeto separado, com o
seu próprio tamanho. Na maior parte do tempo essa diferença é invisível, e duas vezes nesta seção
ela não é:

```java
// Grid.java
import java.util.Arrays;

public class Grid {
    public static void main(String[] args) {
        int[][] grid = new int[3][4];
        grid[1][2] = 5;
        System.out.println(Arrays.deepToString(grid));
        System.out.println(grid.length + " " + grid[0].length);

        int[][] shelves = {{1, 2, 3}, {4}, {5, 6}};
        for (int[] shelf : shelves) {
            System.out.println(shelf.length + " " + Arrays.toString(shelf));
        }

        int total = 0;
        for (int[] shelf : shelves) {
            for (int n : shelf) {
                total += n;
            }
        }
        System.out.println("total " + total);

        int[][] jagged = new int[2][];
        System.out.println(Arrays.toString(jagged));
        jagged[0] = new int[3];
        System.out.println(Arrays.deepToString(jagged));
        System.out.println(jagged[1].length);
    }
}
```

```
ana@vm:~/arrays$ java Grid.java
[[0, 0, 0, 0], [0, 0, 5, 0], [0, 0, 0, 0]]
3 4
3 [1, 2, 3]
1 [4]
2 [5, 6]
total 21
[null, null]
[[0, 0, 0], null]
Exception in thread "main" java.lang.NullPointerException: Cannot read the array length because "<local4>[1]" is null
	at Grid.main(Grid.java:28)
```

`new int[3][4]` construiu um array de fora com três elementos e três arrays de dentro com quatro,
então `grid[1][2]` é a linha 1, coluna 2, e o `deepToString` imprimiu as linhas dentro de um mesmo
par de colchetes. `grid.length` é o número de linhas, 3, e `grid[0].length` o tamanho da primeira
linha, 4.

## As linhas não precisam combinar

O literal `{{1, 2, 3}, {4}, {5, 6}}` construiu três linhas de três tamanhos diferentes, o que é
perfeitamente legal e se chama array **irregular** (jagged). Os dois `for` aninhados o percorreram
sem se importar: o de dentro pede a cada linha os seus próprios valores, e o total deu 21.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Como um array de duas dimensões fica na memória. A variável shelves aponta para um array de fora com três elementos. Cada elemento é uma referência para um array de int separado: o primeiro guarda 1, 2 e 3, o segundo guarda 4, o terceiro guarda 5 e 6, então as linhas têm tamanhos 3, 1 e 2. Uma linha que nunca foi criada, como jagged[1], é null e não um array vazio.\"><defs><marker id=\"jv9-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"16\" y=\"100\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"71\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shelves</text><text x=\"71\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">int[][]</text><path d=\"M126 120 H178\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv9-a)\"></path><text x=\"215\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o array de fora</text><rect x=\"180\" y=\"54\" width=\"70\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"215\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">[0]</text><rect x=\"180\" y=\"98\" width=\"70\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"215\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">[1]</text><rect x=\"180\" y=\"142\" width=\"70\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"215\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">[2]</text><path d=\"M250 72 H318\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv9-a)\"></path><rect x=\"320\" y=\"57\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"338\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><rect x=\"360\" y=\"57\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"378\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2</text><rect x=\"400\" y=\"57\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"418\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3</text><text x=\"450\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tamanho 3</text><path d=\"M250 116 H318\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv9-a)\"></path><rect x=\"320\" y=\"101\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"338\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">4</text><text x=\"370\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tamanho 1</text><path d=\"M250 160 H318\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv9-a)\"></path><rect x=\"320\" y=\"145\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"338\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">5</text><rect x=\"360\" y=\"145\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"378\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">6</text><text x=\"410\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tamanho 2</text><text x=\"400\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">três arrays de int separados</text><rect x=\"560\" y=\"100\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">jagged[1]</text><text x=\"615\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">null</text><text x=\"615\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma linha nunca criada:</text><text x=\"615\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nenhum array</text><rect x=\"16\" y=\"206\" width=\"688\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um int[][] é um array cujos elementos são referências para arrays de int, cada um com seu tamanho</text></svg>", "caption": "O array shelves do programa acima. Nada obriga as linhas a terem o mesmo tamanho; um retângulo como o grid são só linhas que calham de ter."}
```

`new int[2][]` vai além e cria só o array de fora, com **as linhas ainda não criadas**. Elas saem
como `null`, e `jagged[0] = new int[3]` criou só a primeira. Ler `jagged[1].length` então falhou,
porque não havia array ali para ter um tamanho:

```
ana@vm:~/arrays$ javac -g Grid.java && java Grid 2>&1 | tail -2
Exception in thread "main" java.lang.NullPointerException: Cannot read the array length because "jagged[1]" is null
	at Grid.main(Grid.java:28)
```

A mensagem nomeia a expressão que era `null`, e o jeito de nomeá-la depende de como a classe foi
compilada. **Executada direto do código-fonte, ou compilada com `javac` simples, ela diz
`"<local4>[1]"`**: a quinta variável local do método, contando a partir de 0 com `args` primeiro,
porque o arquivo de classe não guardou nomes de variáveis. O `javac -g` os guarda, e a mesma falha
diz `"jagged[1]"`. A lição 12 encontra essa mensagem de novo, como a exceção que todo programador
Java mais vê.
