---
title: Quanto custa uma thread
version: 1
---

**Toda thread de plataforma é uma thread do sistema operacional**, com a sua própria pilha de memória,
a sua entrada no escalonador do kernel, e um custo para criar e para alternar entre elas. Algumas
dezenas não custam nada que valha medir. Milhares são outra história, e o jeito de saber o quanto é
iniciá-las e olhar. No Linux o kernel mantém uma contagem atualizada das threads e da memória de cada
processo em `/proc/self/status`, e este programa a lê antes e depois:

```java
// Cost.java: start N platform threads that sleep, and see what the process looks like
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

public class Cost {
    static String status(String field) throws Exception {
        for (String line : Files.readAllLines(Path.of("/proc/self/status"))) {
            if (line.startsWith(field)) {
                return line.replaceAll("\\s+", " ");
            }
        }
        return field + " ?";
    }

    public static void main(String[] args) throws Exception {
        int n = Integer.parseInt(args[0]);
        System.out.println("before:  " + status("Threads:") + ", " + status("VmRSS:"));
        long start = System.nanoTime();
        List<Thread> threads = new ArrayList<>();
        for (int i = 0; i < n; i++) {
            threads.add(Thread.ofPlatform().start(() -> {
                try {
                    Thread.sleep(10_000);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }));
        }
        System.out.printf("started: %d threads in %.0f ms%n", n, (System.nanoTime() - start) / 1e6);
        System.out.println("during:  " + status("Threads:") + ", " + status("VmRSS:"));
        for (Thread t : threads) {
            t.join();
        }
    }
}
```

```
ana@vm:~/fp/threads$ java Cost.java 1000
before:  Threads: 22, VmRSS: 123220 kB
started: 1000 threads in 185 ms
during:  Threads: 1021, VmRSS: 179372 kB
ana@vm:~/fp/threads$ java Cost.java 10000
before:  Threads: 22, VmRSS: 124084 kB
started: 10000 threads in 5501 ms
during:  Threads: 10021, VmRSS: 373624 kB
```

## Lendo os números

`Threads:` é a contagem do próprio sistema operacional para o processo. Antes de qualquer coisa
começar, a JVM já tinha umas vinte threads suas: o compilador, o coletor de lixo, o tratamento de
sinais. **A contagem subiu uma a cada `start()`**, de 22 para 1.021 e para 10.021, com uma ou outra
thread da própria JVM de diferença, o que prova que uma thread de plataforma é uma thread do sistema
operacional, uma para uma.

`VmRSS` é a memória que o processo realmente ocupa. Mil threads acrescentaram cerca de 56 MB, uns 56 KB
cada, e levaram 185 ms para iniciar. Dez mil acrescentaram cerca de 250 MB e levaram **cinco segundos
e meio**, mais de meio milissegundo por thread, só para criá-las. O trabalho de cada uma era dormir.

Cada thread também reserva espaço para uma pilha, um megabyte por padrão no Linux de 64 bits,
ajustável com `-Xss`. A maior parte dessa reserva é espaço de endereçamento que nunca é tocado, e é por
isso que a memória residente cresceu bem menos que um megabyte por thread; mas toda reserva conta
contra os limites que o kernel impõe a um processo, e são esses limites, não a memória, que costumam
derrubar um programa que inicia threads num laço.

## O que vem daqui

Um servidor que dá a cada requisição a sua própria thread de plataforma fica limitado a alguns
milhares de requisições em andamento ao mesmo tempo, por menos que cada uma faça, porque a maior parte
da vida de uma requisição é passada **esperando**: pelo banco de dados, por outro serviço, pela rede.
Esse é o custo que as aulas 16 e 17 atacam por dois lados. A aula 16 reaproveita um conjunto fixo de
threads através de um pool. A aula 17 torna as threads tão baratas que um milhão cabe onde dez mil não
cabiam.
