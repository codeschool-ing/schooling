---
title: Duas listas que respondem a perguntas diferentes
version: 1
---

A lição 31 resolveu array contra `ArrayList`. Esta lição é sobre as interfaces `List`, `Set` e
`Map`, e as classes por trás de cada uma, e começa pela escolha que todo mundo encontra primeiro.
**`List` é uma interface, e duas classes do JDK a implementam para uso geral**: `ArrayList` e
`LinkedList`. A crença comum é que `LinkedList` é a que se usa quando uma lista muda muito. Ela
acerta sobre uma operação e erra sobre as outras.

As duas classes cumprem a mesma promessa: elementos na ordem em que você os pôs, acessíveis por
posição, repetições permitidas. O que muda é como cumprem, e isso decide o que cada uma faz barato:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas listas com os mesmos três livros. Um ArrayList guarda um array de referências lado a lado, com casas sobrando no fim; get(1) é um passo, e acrescentar no começo empurra cada casa uma posição para a direita. Um LinkedList guarda um nó por elemento, cada um apontando para o próximo e para o anterior; acrescentar no começo muda dois ponteiros, e get(1) caminha a partir de uma ponta.\"><defs><marker id=\"jv32-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"26\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ArrayList</text><text x=\"110\" y=\"26\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um array, casas lado a lado</text><rect x=\"20\" y=\"44\" width=\"80\" height=\"34\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Dune</text><rect x=\"100\" y=\"44\" width=\"80\" height=\"34\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Emma</text><rect x=\"180\" y=\"44\" width=\"80\" height=\"34\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"220\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ulysses</text><rect x=\"260\" y=\"44\" width=\"80\" height=\"34\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"340\" y=\"44\" width=\"80\" height=\"34\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"20\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">get(1): um passo, direto na casa</text><text x=\"20\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">add(0, x): cada casa anda uma posição para a direita</text><text x=\"20\" y=\"150\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">LinkedList</text><text x=\"110\" y=\"150\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um nó por elemento, ligados nos dois sentidos</text><rect x=\"20\" y=\"168\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Dune</text><rect x=\"160\" y=\"168\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Emma</text><rect x=\"300\" y=\"168\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"345\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ulysses</text><path d=\"M110 180 H158\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv32-a)\"></path><path d=\"M250 180 H298\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv32-a)\"></path><path d=\"M160 192 H112\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv32-a)\"></path><path d=\"M300 192 H252\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv32-a)\"></path><text x=\"20\" y=\"220\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">add(0, x): um nó novo, dois links alterados</text><text x=\"20\" y=\"238\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">get(1): caminhar de uma ponta, nó a nó</text></svg>", "caption": "Os mesmos três livros nas duas listas. O que é um passo para uma é uma caminhada ou um empurrão para a outra."}
```

Um `ArrayList` guarda um array de referências, lado a lado, com espaço sobrando no fim. Ler a
posição `i` é uma conta e um passo. Inserir na posição 0 significa antes empurrar cada elemento uma
casa para a direita. Um `LinkedList` guarda um nó separado por elemento, cada um apontando para o
próximo e para o anterior. Inserir no começo muda dois links, e ler a posição `i` significa caminhar
até lá a partir da ponta mais próxima.

## Medido, uma vez

Este programa faz as duas operações cem mil vezes em cada lista. Salve-o num diretório novo,
`~/colls`:

```java
// ListCost.java
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;

public class ListCost {
    static final int N = 100_000;

    public static void main(String[] args) {
        for (List<Integer> list : List.of(new ArrayList<Integer>(), new LinkedList<Integer>())) {
            String name = list.getClass().getSimpleName();

            long start = System.nanoTime();
            for (int i = 0; i < N; i++) {
                list.add(0, i);                      // insert at the front
            }
            long front = System.nanoTime() - start;

            start = System.nanoTime();
            long sum = 0;
            for (int i = 0; i < N; i++) {
                sum += list.get(i);                  // read by position
            }
            long byIndex = System.nanoTime() - start;

            System.out.printf("%-10s add at front %6d ms   get(i) %6d ms   sum %d%n",
                    name, front / 1_000_000, byIndex / 1_000_000, sum);
        }
    }
}
```

```
ana@vm:~/colls$ java ListCost.java
ArrayList  add at front    372 ms   get(i)      4 ms   sum 4999950000
LinkedList add at front      5 ms   get(i)   3947 ms   sum 4999950000
```

Os milissegundos mudam a cada execução e em cada máquina; o formato não. **Em cada operação uma
lista vence a outra por um fator de setenta ou mais**, que é a figura acima transformada em números.
Inserir no começo custou 372 ms ao `ArrayList`, porque cada inserção empurrou tudo o que já estava
lá. Ler por posição custou 3947 ms ao `LinkedList`, porque cada `get(i)` percorreu até cinquenta mil
nós.

A maioria dos programas lê uma lista muito mais vezes do que insere no começo dela. É por isso que
**o `ArrayList` é o padrão, e o `LinkedList` é uma escolha que você faz por um motivo que sabe
nomear.** Um motivo que se sustenta é o da lição 33: uma fila, em que os elementos chegam por uma
ponta e saem pela outra, e nada é lido por posição. Mesmo ali, a lição 33 entrega o trabalho ao
`ArrayDeque`.

Repare no tipo da variável no laço: `List<Integer>`. O programa não diz qual classe está medindo até
criar uma. Escrever a interface como tipo e a classe só depois do `new` é o que torna a troca de uma
implementação por outra uma mudança de uma palavra.
