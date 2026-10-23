---
title: Escolher por quem sai em seguida
version: 1
---

A lição 32 escolheu uma coleção pela pergunta que se faz a ela. Para tudo nesta lição a pergunta é a
mesma, *qual é o próximo?*, e as três respostas possíveis são três classes:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Três jeitos de pegar o próximo elemento. Uma fila FIFO, ArrayDeque usado com offer e poll: os elementos entram pela cauda e saem pela cabeça, o primeiro a entrar é o primeiro a sair. Uma pilha LIFO, ArrayDeque usado com push e pop: os elementos entram e saem pela mesma ponta, o último a entrar é o primeiro a sair. Uma fila de prioridade, PriorityQueue: os elementos entram em qualquer ordem e o menor pelo comparador sai primeiro.\"><defs><marker id=\"jv33-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">primeiro a entrar, primeiro a sair</text><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ArrayDeque: offer, poll</text><text x=\"20\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">último a entrar, primeiro a sair</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ArrayDeque: push, pop</text><text x=\"20\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o menor primeiro</text><text x=\"20\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">PriorityQueue: offer, poll</text><rect x=\"330\" y=\"20\" width=\"76\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"368\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ana</text><rect x=\"410\" y=\"20\" width=\"76\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"448\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bruno</text><rect x=\"490\" y=\"20\" width=\"76\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"528\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Carla</text><path d=\"M620 37 H574\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv33-a)\"></path><text x=\"660\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">offer</text><path d=\"M326 37 H280\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv33-a)\"></path><text x=\"258\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">poll</text><rect x=\"330\" y=\"110\" width=\"92\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"376\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">return Dune</text><rect x=\"426\" y=\"110\" width=\"92\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"472\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lend Emma</text><rect x=\"522\" y=\"110\" width=\"92\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"568\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lend Dune</text><path d=\"M286 120 H326\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv33-a)\"></path><text x=\"258\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">push</text><path d=\"M326 134 H286\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv33-a)\"></path><text x=\"258\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pop</text><text x=\"330\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma ponta faz os dois trabalhos: a cabeça</text><rect x=\"330\" y=\"200\" width=\"66\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"363\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bruno</text><text x=\"363\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">9 dias</text><rect x=\"400\" y=\"200\" width=\"66\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"433\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ana</text><text x=\"433\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 dias</text><rect x=\"470\" y=\"200\" width=\"66\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"503\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Davi</text><text x=\"503\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5 dias</text><rect x=\"540\" y=\"200\" width=\"66\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"573\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Carla</text><text x=\"573\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 dias</text><rect x=\"610\" y=\"200\" width=\"66\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"643\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Eva</text><text x=\"643\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 dias</text><path d=\"M326 217 H286\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv33-a)\"></path><text x=\"258\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">poll</text><text x=\"330\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">em qualquer ordem; o poll tira o de menos dias: Carla</text></svg>", "caption": "Três respostas para \"qual é o próximo?\". A classe que você escolhe é a resposta que recebe."}
```

| o que "próximo" significa | declare | crie |
|---|---|---|
| o que chegou primeiro | `Queue<E>` | `new ArrayDeque<>()` |
| o que chegou por último | `Deque<E>` | `new ArrayDeque<>()` |
| o menor, por alguma ordem | `Queue<E>` | `new PriorityQueue<>(comparator)` |

A crença comum é que o `LinkedList` pertence à primeira linha, porque ele implementa `Queue` e
`Deque` e porque a lição 32 citou uma fila como o único bom uso dele. Ele implementa as duas, sim.
**Ainda assim é mais lento que o `ArrayDeque` no trabalho de uma fila.** O motivo é a primeira figura da lição
32, de novo: cada `offer` numa lista encadeada cria um objeto nó, onde o `ArrayDeque`
escreve uma referência numa casa de um array que ele reaproveita, dando a volta do fim para o começo.

## Medido, uma vez

Este programa mantém uma fila de no máximo cem números e passa cinco milhões por ela, em cada classe,
e faz tudo duas vezes:

```java
// QueueCost.java
import java.util.ArrayDeque;
import java.util.LinkedList;
import java.util.List;
import java.util.Queue;

public class QueueCost {
    static final int ROUNDS = 5_000_000;

    public static void main(String[] args) {
        for (int run = 1; run <= 2; run++) {
            for (Queue<Integer> q : List.<Queue<Integer>>of(new ArrayDeque<>(), new LinkedList<>())) {
                long start = System.nanoTime();
                for (int i = 0; i < ROUNDS; i++) {
                    q.offer(i);
                    if (q.size() > 100) {
                        q.poll();
                    }
                }
                long ms = (System.nanoTime() - start) / 1_000_000;
                System.out.printf("run %d  %-10s %4d ms%n", run, q.getClass().getSimpleName(), ms);
            }
        }
    }
}
```

```
ana@vm:~/queues$ java QueueCost.java
run 1  ArrayDeque   59 ms
run 1  LinkedList  338 ms
run 2  ArrayDeque   30 ms
run 2  LinkedList  495 ms
```

Os tempos pulam de uma execução para outra, e estes são uma execução. **Em toda rodada o
`ArrayDeque` foi o mais rápido**, aqui por um fator entre cinco e dezesseis. A primeira rodada foi
mais lenta que a segunda para o `ArrayDeque`, que é o compilador JIT da lição 1 trabalhando: a
primeira rodada rodou em parte interpretada. A lista encadeada não acelerou na segunda rodada, porque
o que custa a ela não é o laço, e sim os cinco milhões de nós que ela aloca e o coletor de lixo que
depois precisa limpá-los.

Então a segunda e a terceira linhas da tabela não guardam surpresa, e a primeira guarda uma: **a fila
que um programa procura é um `ArrayDeque` também**. O `LinkedList` mantém uma vantagem real, que é
aceitar elementos `null`. A seção 02 explicou por que uma fila que responde `null` para "vazia" não
deveria guardar um, de qualquer jeito.

O `java.util.concurrent` tem mais filas, o `ArrayBlockingQueue` entre elas, feitas para threads que
passam trabalho umas às outras e esperam quando a fila está vazia ou cheia. Elas pertencem ao
`java-functional`, que é sobre concorrência; nada neste curso precisa de uma além dos dois lugares da
seção 02.
