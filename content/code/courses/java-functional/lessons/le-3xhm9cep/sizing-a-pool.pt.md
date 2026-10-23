---
title: Dimensionando um pool, e o que acontece quando ele lota
version: 1
---

**Quantas threads um pool deve ter depende do que as tarefas fazem enquanto rodam.** Uma tarefa que
calcula mantém um processador ocupado a vida toda; uma tarefa que espera um disco, um banco de dados ou
outro serviço segura uma thread e deixa o processador ocioso.

| tarefas | threads | por quê |
|---|---|---|
| calculam: parsing, hash, matemática | mais ou menos o número de processadores, `availableProcessors()` | mais threads só se revezam nos mesmos núcleos |
| esperam a maior parte do tempo: E/S, chamadas remotas | muito mais que os processadores | cada thread passa a maior parte da vida esperando |
| uma mistura | meça | o número certo depende da proporção entre esperar e trabalhar |

Uma regra prática comum para trabalho que espera é processadores × (1 + tempo de espera / tempo de
cálculo): com 4 processadores e tarefas que esperam 90 ms para cada 10 ms de trabalho, cerca de 40
threads. É um ponto de partida para medir, não um resultado. A aula 17 faz a pergunta quase sumir para
trabalho que espera, tornando as threads tão baratas que uma por tarefa basta.

## A fila na frente do pool

O `newFixedThreadPool` põe uma fila **sem limite** na frente das threads. Se as tarefas chegam mais
rápido do que as threads as terminam, a fila cresce sem limite, cada tarefa na fila segura os seus dados
na memória, e o primeiro sinal de problema é um `OutOfMemoryError` longe do código que submeteu demais.
A seção 04 da aula 15 disse o mesmo sobre filas entre threads. Montar o pool você mesmo deixa você limitar
a fila e decidir o que acontece quando ela enche:

```java
// Bounded.java: a pool with a bounded queue, and a full queue that refuses work
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.RejectedExecutionException;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

public class Bounded {
    public static void main(String[] args) throws InterruptedException {
        ThreadPoolExecutor pool = new ThreadPoolExecutor(
                2, 2, 0, TimeUnit.SECONDS,
                new ArrayBlockingQueue<>(3),
                new ThreadPoolExecutor.AbortPolicy());
        for (int n = 1; n <= 7; n++) {
            int order = n;
            try {
                pool.execute(() -> Pool.sleep(300));
                System.out.println("order " + order + " accepted, queue holds " + pool.getQueue().size());
            } catch (RejectedExecutionException e) {
                System.out.println("order " + order + " refused: the pool and its queue are full");
            }
        }
        pool.shutdown();
        pool.awaitTermination(5, TimeUnit.SECONDS);
        System.out.println("completed: " + pool.getCompletedTaskCount());
    }
}
```

```
ana@vm:~/fp/executors$ java Bounded.java
order 1 accepted, queue holds 0
order 2 accepted, queue holds 0
order 3 accepted, queue holds 1
order 4 accepted, queue holds 2
order 5 accepted, queue holds 3
order 6 refused: the pool and its queue are full
order 7 refused: the pool and its queue are full
completed: 5
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Sete pedidos chegam pela esquerda. Dois vão direto para as duas threads do pool, três esperam na fila limitada, e os dois últimos são recusados com RejectedExecutionException.\"><defs><marker id=\"pool-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"pool-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"pool-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pedidos 1 a 7</text><rect x=\"190\" y=\"60\" width=\"230\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"305\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">fila de 3</text><rect x=\"203\" y=\"73\" width=\"60\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"233.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">3</text><rect x=\"275\" y=\"73\" width=\"60\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"305.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">4</text><rect x=\"347\" y=\"73\" width=\"60\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"377.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">5</text><rect x=\"480\" y=\"20\" width=\"220\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">thread 1: order 1</text><rect x=\"480\" y=\"76\" width=\"220\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">thread 2: order 2</text><rect x=\"190\" y=\"158\" width=\"230\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"305.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">6 e 7: recusados</text><path d=\"M140 95 L186 95\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#pool-ah-paperdim)\"></path><path d=\"M420 95 L450 95 L450 42 L476 42\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#pool-ah-phosphor)\"></path><path d=\"M450 95 L450 98 L476 98\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#pool-ah-phosphor)\"></path><path d=\"M80 120 L80 178 L186 178\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#pool-ah-amber)\"></path></svg>", "caption": "Duas threads e uma fila de três seguram cinco tarefas; a sexta e a sétima são recusadas em voz alta."}
```

Duas threads e uma fila de três seguram cinco pedidos; o sexto e o sétimo foram **recusados em voz
alta**, com `RejectedExecutionException`. Essa é a `AbortPolicy`, e é o padrão certo: quem chama descobre
que o sistema está saturado e pode dizer a quem o chamou para tentar depois. As políticas alternativas
valem ser conhecidas pelo nome: a `CallerRunsPolicy` faz a thread que submete rodar a tarefa ela mesma, o
que desacelera o produtor até o ritmo do pool; a `DiscardPolicy` descarta a tarefa em silêncio, o que
quase nunca é o que alguém quer e deveria precisar de um comentário explicando por que o silêncio é
certo.

`Bounded` usa o `Pool.sleep` do arquivo da seção 02, que está na mesma pasta.
