---
title: Um milhão de threads
version: 1
---

**A seção 04 da aula 11 iniciou dez mil threads de plataforma que dormiam, e isso levou cinco segundos e
meio e cerca de 250 MB.** O mesmo experimento com threads virtuais, cem vezes maior:

```java
// Million.java: one million virtual threads that sleep, and the process around them
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class Million {
    static String status(String field) throws Exception {
        for (String line : Files.readAllLines(Path.of("/proc/self/status"))) {
            if (line.startsWith(field)) {
                return line.replaceAll("\\s+", " ");
            }
        }
        return field + " ?";
    }

    public static void main(String[] args) throws Exception {
        int n = 1_000_000;
        System.out.println("before:    " + status("Threads:") + ", " + status("VmRSS:"));
        long start = System.nanoTime();
        try (ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor()) {
            for (int i = 0; i < n; i++) {
                executor.submit(() -> {
                    Thread.sleep(Duration.ofSeconds(2));
                    return null;
                });
            }
            System.out.printf("submitted: %d virtual threads in %d ms%n", n, (System.nanoTime() - start) / 1_000_000);
            System.out.println("during:    " + status("Threads:") + ", " + status("VmRSS:"));
        }
        System.out.printf("finished:  all of them, %d ms after the first started%n", (System.nanoTime() - start) / 1_000_000);
    }
}
```

```
ana@vm:~/fp/virtual$ java Million.java
before:    Threads: 22, VmRSS: 127388 kB
submitted: 1000000 virtual threads in 1813 ms
during:    Threads: 27, VmRSS: 1022092 kB
finished:  all of them, 9496 ms after the first started
```

## Lendo os números

O sistema operacional contou 22 threads antes e 27 durante: **um milhão de threads virtuais acrescentou
cinco threads do sistema operacional**, as portadoras entre elas. Submeter todas levou 1,8 segundo, cerca
de um terço do que dez mil threads de plataforma levaram na aula 11, para cem vezes mais. A memória
cresceu cerca de 870 MB, **menos de um kilobyte por thread** com a pilha, a tarefa e a contabilidade do
executor, onde uma thread de plataforma custava dezenas de kilobytes.

A última thread terminou 9,5 segundos depois de a primeira começar, embora cada uma tenha dormido só
dois. Acordar e encerrar um milhão de threads é trabalho de verdade para quatro processadores, e o
programa mediu isso em vez de fingir que não existe. Um milhão de threads é barato, não de graça.

`Executors.newVirtualThreadPerTaskExecutor()` dá a cada tarefa submetida uma thread virtual nova, e
fechá-lo num try-with-resources espera todas, exatamente como os pools da aula 16. **Não existe pool de
threads virtuais, e nunca deveria existir**: um pool existe para reaproveitar algo caro, e uma thread
virtual é mais barata de criar do que de cuidar. Uma thread virtual nova por tarefa é o uso pretendido.

A tarefa é um `Callable`, por causa do `return null`: `Thread.sleep` lança `InterruptedException`, um
`Callable` pode lançá-la, e um `Runnable` não pode (aula 2, seção 05).
