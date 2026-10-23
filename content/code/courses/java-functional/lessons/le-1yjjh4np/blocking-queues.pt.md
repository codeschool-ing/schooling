---
title: Filas bloqueantes
version: 1
---

**Uma `BlockingQueue` é um ponto de entrega entre threads.** Um produtor põe trabalho com `put`, um
consumidor tira com `take`, e a fila faz a espera: `take` numa fila vazia espera até algo chegar, e `put`
numa fila cheia espera até haver espaço. Essa segunda espera se chama **contrapressão** (backpressure),
e é o que impede um produtor rápido de encher a memória com trabalho que um consumidor lento não
consegue acompanhar.

```java
// Handover.java: a producer, two consumers and a bounded queue between them
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;

public class Handover {
    record Order(int number, long cents) {}

    static final Order STOP = new Order(-1, 0);

    public static void main(String[] args) throws InterruptedException {
        BlockingQueue<Order> queue = new ArrayBlockingQueue<>(3);

        Runnable packer = () -> {
            try {
                while (true) {
                    Order o = queue.take();
                    if (o == STOP) {
                        System.out.println(Thread.currentThread().getName() + ": no more orders");
                        return;
                    }
                    Thread.sleep(30);
                    System.out.println(Thread.currentThread().getName() + ": packed order " + o.number());
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        };
        Thread a = Thread.ofPlatform().name("packer-a").start(packer);
        Thread b = Thread.ofPlatform().name("packer-b").start(packer);

        long start = System.nanoTime();
        for (int n = 1; n <= 8; n++) {
            queue.put(new Order(n, 1000L * n));
            System.out.printf("main: queued order %d at %d ms, %d waiting%n",
                    n, (System.nanoTime() - start) / 1_000_000, queue.size());
        }
        queue.put(STOP);
        queue.put(STOP);
        a.join();
        b.join();
    }
}
```

```
ana@vm:~/fp/concurrent$ java Handover.java
main: queued order 1 at 0 ms, 0 waiting
main: queued order 2 at 5 ms, 1 waiting
main: queued order 3 at 5 ms, 1 waiting
main: queued order 4 at 5 ms, 2 waiting
main: queued order 5 at 5 ms, 3 waiting
packer-b: packed order 1
main: queued order 6 at 32 ms, 3 waiting
packer-a: packed order 2
main: queued order 7 at 35 ms, 3 waiting
packer-b: packed order 3
main: queued order 8 at 62 ms, 3 waiting
packer-a: packed order 4
packer-b: packed order 5
packer-a: packed order 6
packer-b: packed order 7
packer-b: no more orders
packer-a: packed order 8
packer-a: no more orders
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"À esquerda, a main como produtora, chamando put. No meio, uma fila com espaço para três pedidos, os três lugares ocupados. À direita, dois consumidores, packer-a e packer-b, cada um chamando take. Uma nota abaixo da fila diz que quando ela está cheia o put espera, e quando está vazia o take espera.\"><defs><marker id=\"queue-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"60\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"76.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">main</text><text x=\"85.0\" y=\"93.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">put()</text><rect x=\"220\" y=\"50\" width=\"250\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"235\" y=\"63\" width=\"66\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"268.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pedido</text><rect x=\"313\" y=\"63\" width=\"66\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"346.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pedido</text><rect x=\"391\" y=\"63\" width=\"66\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"424.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pedido</text><rect x=\"550\" y=\"25\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"41.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">packer-a</text><text x=\"625.0\" y=\"58.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">take()</text><rect x=\"550\" y=\"100\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"116.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">packer-b</text><text x=\"625.0\" y=\"133.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">take()</text><path d=\"M150 85 L216 85\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#queue-ah-phosphor)\"></path><path d=\"M470 85 L510 85 L510 50 L546 50\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#queue-ah-phosphor)\"></path><path d=\"M510 85 L510 125 L546 125\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#queue-ah-phosphor)\"></path><text x=\"345\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">cheia: put espera</text><text x=\"345\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">vazia: take espera</text></svg>", "caption": "A fila faz a espera: cheia, ela segura o produtor; vazia, segura os consumidores."}
```

## Lendo a linha do tempo

A `main` enfileirou os primeiros pedidos na hora, até a fila ter três e os dois empacotadores estarem
ocupados com um cada. **Dali em diante o `put` esperou**, e os tempos da fila seguem o ritmo dos
empacotadores: cada pedido novo só entrou quando um empacotador tirou um. Sem o limite, a `main` teria
enfileirado os oito no primeiro milissegundo, o que é inofensivo com oito e um `OutOfMemoryError` com
oito milhões.

O pedido `STOP` é uma **pílula de veneno**: um valor combinado que diz a um consumidor que não há mais
trabalho. Uma por consumidor, porque cada um tira exatamente uma. Comparar com `==` é de propósito: é o
objeto `STOP` em si, não qualquer pedido que por acaso seja igual a ele.

A fila também é uma aresta happens-before (aula 12, seção 04): tudo o que o produtor escreveu num pedido
antes do `put` fica visível para o consumidor depois do `take`. É por isso que `Order` não precisa de
`volatile` nem de lock, e por que entregar trabalho por uma fila é mais seguro que compartilhá-lo.
