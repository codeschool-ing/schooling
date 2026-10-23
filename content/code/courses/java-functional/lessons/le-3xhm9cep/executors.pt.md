---
title: Executors
version: 1
---

**Um `ExecutorService` separa o trabalho das threads que o fazem.** Você submete tarefas; o executor
decide que thread roda cada uma. O tipo mais comum mantém um conjunto fixo de threads vivas e as
alimenta com tarefas de uma fila, então uma thread é criada uma vez e reaproveitada para milhares de
tarefas, o que tira o custo que a seção 04 da aula 11 mediu.

```java
// Pool.java: ten tasks on a pool of four threads
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class Pool {
    public static void main(String[] args) {
        try (ExecutorService pool = Executors.newFixedThreadPool(4)) {
            for (int n = 1; n <= 10; n++) {
                int order = n;
                pool.submit(() -> {
                    sleep(100);
                    System.out.println("order " + order + " on " + Thread.currentThread().getName());
                });
            }
            System.out.println("main: all ten submitted");
        }
        System.out.println("main: the pool has finished and shut down");
    }

    static void sleep(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
```

```
ana@vm:~/fp/executors$ java Pool.java
main: all ten submitted
order 4 on pool-1-thread-4
order 2 on pool-1-thread-2
order 3 on pool-1-thread-3
order 1 on pool-1-thread-1
order 5 on pool-1-thread-4
order 8 on pool-1-thread-1
order 7 on pool-1-thread-3
order 6 on pool-1-thread-2
order 9 on pool-1-thread-4
order 10 on pool-1-thread-1
main: the pool has finished and shut down
```

## O que aconteceu

A `main` submeteu as dez tarefas de uma vez e seguiu; o `submit` não espera. **Só quatro rodaram ao mesmo
tempo**, em quatro threads chamadas de `pool-1-thread-1` a `pool-1-thread-4`, e os mesmos quatro nomes
atenderam os dez pedidos. As outras seis esperaram na fila do executor até uma thread ficar livre. Os
pedidos terminaram em lotes de quatro, com cerca de 100 ms entre eles, que é a cara de quatro
trabalhadores com 100 ms de trabalho cada.

`int order = n;` está lá pela regra da seção 06 da aula 1: `n` muda a cada volta do laço, então o lambda
não pode capturá-lo, e `order` é uma variável nova e efetivamente final a cada vez.

## Desligando

As threads de um executor mantêm a JVM viva até ele ser desligado. Desde o Java 19, o `ExecutorService`
é `AutoCloseable`, e **fechá-lo num try-with-resources** (aula 37 do `java`) faz a coisa certa: para de
aceitar tarefas novas, espera as submetidas terminarem e então deixa as threads acabarem. É por isso que
a última linha só saiu depois de todos os pedidos. Antes do Java 19, o mesmo exigia `shutdown()` seguido
de `awaitTermination(...)`, e esquecê-los é como um programa que imprimiu a última linha continua rodando
sem motivo visível.

| fábrica | dá | para |
|---|---|---|
| `newFixedThreadPool(n)` | n threads, uma fila sem limite | uma quantidade conhecida de trabalho paralelo |
| `newSingleThreadExecutor()` | uma thread, tarefas em ordem | trabalho que não pode se sobrepor |
| `newScheduledThreadPool(n)` | tarefas rodadas depois ou repetidamente | temporizadores, consultas periódicas |
| `newVirtualThreadPerTaskExecutor()` | uma thread virtual nova por tarefa | trabalho que espera; aula 17 |
