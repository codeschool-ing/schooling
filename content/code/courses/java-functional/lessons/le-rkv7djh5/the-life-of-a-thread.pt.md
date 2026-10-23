---
title: A vida de uma thread
version: 1
---

**Uma thread está sempre num de poucos estados, e o `getState()` diz qual.** Ela é `NEW` antes do
`start`, `RUNNABLE` enquanto roda ou está pronta para rodar, um de três estados de espera enquanto
espera por algo, e `TERMINATED` quando o seu `run` retornou. Ver uma thread passar por eles torna
concreto o vocabulário das próximas sete aulas:

```java
// States.java: one thread's states, and a sleep cut short by interrupt
public class States {
    public static void main(String[] args) throws InterruptedException {
        Thread sleeper = new Thread(() -> {
            try {
                Thread.sleep(5_000);
                System.out.println("slept the whole five seconds");
            } catch (InterruptedException e) {
                System.out.println("woken early: " + e.getMessage()
                        + ", interrupted flag now " + Thread.currentThread().isInterrupted());
            }
        });
        System.out.println("before start: " + sleeper.getState());
        sleeper.start();
        Thread.sleep(200);
        System.out.println("while asleep: " + sleeper.getState());
        sleeper.interrupt();
        sleeper.join();
        System.out.println("after join:   " + sleeper.getState());
    }
}
```

```
ana@vm:~/fp/threads$ java States.java
before start: NEW
while asleep: TIMED_WAITING
woken early: sleep interrupted, interrupted flag now false
after join:   TERMINATED
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Um diagrama de estados. NEW vai para RUNNABLE quando start é chamado. RUNNABLE vai para TIMED_WAITING com sleep, e volta para RUNNABLE quando o tempo acaba ou interrupt é chamado. RUNNABLE também vai para WAITING com join ou wait, e para BLOCKED quando precisa esperar um lock de outra thread, voltando quando a espera acaba. RUNNABLE vai para TERMINATED quando run retorna ou lança exceção.\"><defs><marker id=\"states-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"states-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">NEW</text><rect x=\"220\" y=\"90\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">RUNNABLE</text><rect x=\"590\" y=\"90\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">TERMINATED</text><path d=\"M130 112 L216 112\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#states-ah-phosphor)\"></path><text x=\"173\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">start()</text><path d=\"M360 112 L586 112\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#states-ah-paperdim)\"></path><text x=\"473\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">run retorna ou lança</text><rect x=\"400\" y=\"14\" width=\"160\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"480.0\" y=\"30.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">TIMED_WAITING</text><text x=\"480.0\" y=\"45.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sleep(ms)</text><rect x=\"400\" y=\"166\" width=\"160\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"480.0\" y=\"182.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">WAITING</text><text x=\"480.0\" y=\"197.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">join(), wait()</text><rect x=\"60\" y=\"166\" width=\"160\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"140.0\" y=\"182.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">BLOCKED</text><text x=\"140.0\" y=\"197.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um lock, aula 14</text><path d=\"M330 90 L330 38 L396 38\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#states-ah-paperdim)\" marker-start=\"url(#states-ah-paperdim)\"></path><path d=\"M330 134 L330 190 L396 190\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#states-ah-paperdim)\" marker-start=\"url(#states-ah-paperdim)\"></path><path d=\"M250 134 L250 190 L224 190\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#states-ah-paperdim)\" marker-start=\"url(#states-ah-paperdim)\"></path></svg>", "caption": "Uma thread é NEW uma vez, TERMINATED uma vez, e se move entre rodar e os três tipos de espera no meio."}
```

## Interromper é pedir

`sleeper.interrupt()` não parou a thread. **Ele ligou uma flag nela e a acordou do `sleep`**, que
respondeu lançando `InterruptedException`; a thread a capturou, imprimiu uma linha e retornou
normalmente. O Java não tem um jeito seguro de parar uma thread de fora. O `Thread.stop()` existia,
matava uma thread onde quer que ela estivesse, deixava objetos atualizados pela metade para trás, e foi
descontinuado por isso e, no Java 20, passou a lançar exceção. A interrupção é a substituta: **um
pedido que a thread confere em pontos que ela escolhe**, e todo método bloqueante, `sleep`, `join`,
`wait`, um lock obtido com `lockInterruptibly`, é um desses pontos.

Repare na segunda metade da linha impressa: a flag já era `false` dentro do `catch`. Lançar
`InterruptedException` a limpa. Um código que captura a exceção e não pode parar na hora deve chamar
`Thread.currentThread().interrupt()` para religar a flag, para o código acima dele poder ver o pedido.
**Capturá-la e não fazer nada é o jeito clássico de tornar uma thread impossível de parar.**

## Os três estados de espera

| estado | a thread está | entra por |
|---|---|---|
| `TIMED_WAITING` | esperando, com limite de tempo | `sleep(ms)`, `join(ms)`, `wait(ms)` |
| `WAITING` | esperando, sem limite | `join()`, `wait()`, `LockSupport.park()` |
| `BLOCKED` | esperando para entrar num bloco `synchronized` que outra thread segura | aula 14 |

Um dump de threads, que o `jcmd <pid> Thread.print` imprime para uma JVM em execução, lista cada thread
com o seu estado e a linha em que está. Quando um programa trava, essa é a primeira coisa a ler: as
threads que estão `BLOCKED` e `WAITING`, e esperando o quê.
