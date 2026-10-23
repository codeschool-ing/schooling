---
title: O que muda
version: 1
---

**Threads virtuais não deixam nenhuma tarefa isolada mais rápida. Elas tornam barato ter muitíssimas
tarefas esperando ao mesmo tempo**, e a maior parte do que um servidor faz é esperar. Dez mil
requisições, cada uma passando 100 ms esperando um banco de dados e quase nada calculando, rodam num pool
de cem threads de plataforma e numa thread virtual cada:

```java
// Throughput.java: ten thousand waiting tasks, on a pool of 100 and on virtual threads
import java.time.Duration;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class Throughput {
    static void handleRequest() {
        try {
            Thread.sleep(Duration.ofMillis(100));
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    static long run(ExecutorService executor) {
        long start = System.nanoTime();
        try (executor) {
            for (int i = 0; i < 10_000; i++) {
                executor.submit(Throughput::handleRequest);
            }
        }
        return (System.nanoTime() - start) / 1_000_000;
    }

    public static void main(String[] args) {
        System.out.println("pool of 100 platform threads: " + run(Executors.newFixedThreadPool(100)) + " ms");
        System.out.println("one virtual thread per task:  " + run(Executors.newVirtualThreadPerTaskExecutor()) + " ms");
    }
}
```

```
ana@vm:~/fp/virtual$ java Throughput.java
pool of 100 platform threads: 10027 ms
one virtual thread per task:  187 ms
```

**Dez segundos contra menos de um quinto de segundo.** O pool rodava 100 tarefas por vez, cada uma
esperando 100 ms, então dez mil levaram cem rodadas, enquanto os quatro processadores ficavam quase
parados. Com uma thread virtual por tarefa, as dez mil esperaram ao mesmo tempo, e o lote levou mais ou
menos uma espera mais o custo de iniciar as threads: 187 ms. **Cinquenta vezes mais rápido, nos mesmos
processadores, com o mesmo código dentro de `handleRequest`.** Nada na tarefa mudou; só quantas podiam
esperar de uma vez.

## O estilo que ela traz de volta

Antes das threads virtuais, um servidor que quisesse manter dez mil requisições em andamento com algumas
centenas de threads tinha de parar de bloquear: toda chamada a um banco ou a outro serviço devolvia um
future, e o código virava cadeias de `thenApply` e `thenCompose`, a seção 05 da aula 16 esticada por um
programa inteiro, com stack traces que não mostravam mais quem chamou quem. **As threads virtuais tornam
o estilo bloqueante simples viável de novo**: uma thread por requisição, código que se lê de cima para
baixo, um `try`/`catch` em volta de uma chamada que falha, e um stack trace que diz onde. É isso que "o
que muda com o Projeto Loom" quer dizer na prática, e é por isso que frameworks como Spring Boot e Helidon
oferecem rodar cada requisição numa thread virtual.
