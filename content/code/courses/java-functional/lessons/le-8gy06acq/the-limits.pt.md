---
title: Os limites
version: 1
---

**Threads virtuais tiram o custo de uma thread. Não tiram o custo do trabalho, nem os limites das coisas
com que o trabalho conversa.** Daí saem três regras, e uma regra que deixou de valer há pouco tempo.

- **Calcular não fica mais rápido.** Uma tarefa que mantém um processador ocupado a vida toda não ganha
  nada sendo virtual, porque as portadoras são tantas quanto os processadores. A contagem de primos da
  aula 9 não rodaria mais rápido em um milhão de threads virtuais do que em quatro.
- **Nunca as ponha num pool.** A seção 03 disse; um pool fixo de threads virtuais traz de volta a fila na
  frente do pool e nenhum dos motivos para ela.
- **Um recurso escasso ainda precisa de limite.** Um milhão de threads virtuais pode chamar um banco que
  aceita vinte conexões um milhão de vezes ao mesmo tempo. A thread não limita mais você, então outra
  coisa precisa limitar: um `Semaphore` (aula 15, seção 05) em volta da chamada, ou o limite do próprio
  pool de conexões.

```java
// Limited.java: ten thousand virtual threads, at most twenty inside the service at once
import java.time.Duration;
import java.util.concurrent.Executors;
import java.util.concurrent.Semaphore;
import java.util.concurrent.atomic.AtomicInteger;

public class Limited {
    static final Semaphore connections = new Semaphore(20);
    static final AtomicInteger inside = new AtomicInteger();
    static final AtomicInteger most = new AtomicInteger();

    static void query() throws InterruptedException {
        connections.acquire();
        try {
            most.accumulateAndGet(inside.incrementAndGet(), Math::max);
            Thread.sleep(Duration.ofMillis(10));
            inside.decrementAndGet();
        } finally {
            connections.release();
        }
    }

    public static void main(String[] args) {
        long start = System.nanoTime();
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            for (int i = 0; i < 10_000; i++) {
                executor.submit(() -> {
                    query();
                    return null;
                });
            }
        }
        System.out.printf("10000 queries, at most %d at once, %d ms%n", most.get(), (System.nanoTime() - start) / 1_000_000);
    }
}
```

```
ana@vm:~/fp/virtual$ java Limited.java
10000 queries, at most 20 at once, 5212 ms
```

Dez mil threads virtuais esperaram uma permissão, e **nunca mais de vinte estiveram dentro do serviço**.
O tempo total é o que vinte conexões permitem: 10.000 consultas de 10 ms, vinte por vez, são pelo menos
cinco segundos, e a execução levou 5.212 ms.

## Pinning, e o que o Java 24 mudou

Uma thread virtual que não pode ser desmontada enquanto bloqueia está **presa** (pinned): ela segura a sua
portadora durante a espera inteira, como uma thread de plataforma. Até o Java 24, bloquear dentro de um
bloco `synchronized` a prendia, e algumas centenas de threads virtuais dormindo dentro de `synchronized`
podiam segurar todas as portadoras e parar o resto. O programa abaixo roda no Java 25 desta máquina e
depois, para mostrar o comportamento antigo, no Java 21 que esta máquina também tem (aula 1, seção 03);
você não precisa do Java 21 para acompanhar o curso.

```java
// Pinning.java: a thousand virtual threads each sleeping inside synchronized
import java.util.concurrent.Executors;

public class Pinning {
    public static void main(String[] args) {
        long start = System.nanoTime();
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            for (int i = 0; i < 1000; i++) {
                Object lock = new Object();
                executor.submit(() -> {
                    synchronized (lock) {
                        try {
                            Thread.sleep(100);
                        } catch (InterruptedException e) {
                            Thread.currentThread().interrupt();
                        }
                    }
                });
            }
        }
        System.out.printf("Java %d: %d ms%n", Runtime.version().feature(), (System.nanoTime() - start) / 1_000_000);
    }
}
```

```
ana@vm:~/fp/virtual$ java Pinning.java
Java 25: 120 ms
ana@vm:~/fp/virtual$ /usr/lib/jvm/java-21-openjdk-amd64/bin/java Pinning.java
Java 21: 25057 ms
```

No Java 25, os mil sonos se sobrepuseram e a execução levou 120 ms. **No Java 21, o mesmo programa levou
25 segundos**: cada thread dormindo segurava uma das quatro portadoras, então os sonos rodaram quatro por
vez, 250 rodadas de 100 ms. O Java 24 tirou esse pinning do `synchronized`, e é por isso que o velho
conselho de trocar `synchronized` por `ReentrantLock` em código com threads virtuais não vale mais
(aula 14, seção 04). Bloquear em código nativo ainda prende, assim como alguns casos mais raros; o evento
`jdk.VirtualThreadPinned` do Java Flight Recorder informa cada um com a sua pilha.
