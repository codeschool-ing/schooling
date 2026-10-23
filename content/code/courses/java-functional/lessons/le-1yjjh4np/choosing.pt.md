---
title: Escolhendo uma coleção concorrente
version: 1
---

**O `java.util.concurrent` tem uma resposta thread-safe para a maioria dos jeitos como threads
compartilham dados, e escolher uma é escolher como o compartilhamento funciona.** O lock que você teria
escrito já está lá dentro, escrito por gente que mediu.

| o compartilhamento | use | notas |
|---|---|---|
| um contador, muitos escritores | `AtomicLong`, ou `LongAdder` se as escritas forem muito mais que as leituras | seção 02 |
| uma referência, trocada inteira | `AtomicReference` com um objeto imutável | aula 12, seção 05 |
| um mapa que muitas threads leem e atualizam | `ConcurrentHashMap`, atualizando com `merge`, `compute` | seção 03 |
| trabalho entregue de produtores a consumidores | `ArrayBlockingQueue` (limitada) ou `LinkedBlockingQueue` | seção 04 |
| uma lista lida muito mais vezes do que mudada | `CopyOnWriteArrayList` | abaixo |
| esperar até N coisas acontecerem | `CountDownLatch` | aula 12, seção 03 |
| no máximo N threads ao mesmo tempo num trecho de código | `Semaphore` | abaixo |

## Mais duas, rapidamente

```java
// TwoMore.java: a list that copies on write, and a semaphore that admits two at a time
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.Semaphore;
import java.util.concurrent.atomic.AtomicInteger;

public class TwoMore {
    public static void main(String[] args) throws InterruptedException {
        List<String> listeners = new CopyOnWriteArrayList<>(List.of("audit", "email"));
        for (String l : listeners) {
            listeners.add(l + "-copy");
        }
        System.out.println(listeners);

        Semaphore printers = new Semaphore(2);
        AtomicInteger inside = new AtomicInteger();
        AtomicInteger most = new AtomicInteger();
        Thread[] jobs = new Thread[6];
        for (int j = 0; j < jobs.length; j++) {
            jobs[j] = Thread.ofPlatform().start(() -> {
                try {
                    printers.acquire();
                    try {
                        most.accumulateAndGet(inside.incrementAndGet(), Math::max);
                        Thread.sleep(50);
                        inside.decrementAndGet();
                    } finally {
                        printers.release();
                    }
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            });
        }
        for (Thread t : jobs) {
            t.join();
        }
        System.out.println("six jobs, at most " + most.get() + " printing at once");
    }
}
```

```
ana@vm:~/fp/concurrent$ java TwoMore.java
[audit, email, audit-copy, email-copy]
six jobs, at most 2 printing at once
```

**O `CopyOnWriteArrayList` copia o array inteiro a cada mudança**, então um laço sobre ele percorre a
cópia com que começou e nunca vê uma `ConcurrentModificationException`: o laço acima acrescentou à lista
enquanto a percorria, e terminou tendo visto só os dois elementos originais. Todo `add` custa uma cópia
inteira, o que é tranquilo para uma lista de listeners mudada algumas vezes por dia e desastroso para uma
mudada o tempo todo.

**Um `Semaphore` distribui permissões.** Com duas permissões, seis tarefas rodaram no máximo duas por
vez, e as outras esperaram no `acquire`. É a ferramenta certa para limitar quantas threads usam um
recurso escasso ao mesmo tempo: conexões com um banco de dados, chamadas a um serviço com limite de
taxa. A aula 17 usa um para proteger um serviço de um milhão de threads virtuais.
