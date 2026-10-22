---
title: A interface Lock
version: 1
---

**`java.util.concurrent.locks.Lock` faz o que o `synchronized` faz, como um objeto com métodos**, e os
métodos acrescentam três coisas que a palavra-chave não oferece: desistir depois de um tempo limite,
parar de esperar quando interrompida, e conferir sem esperar. `ReentrantLock` é a implementação que você
vai usar. O preço é que a liberação deixa de ser automática, então ela vai sempre num `finally`:

```java
// TryLock.java: lock with a time limit, and the finally that always unlocks
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.ReentrantLock;

public class TryLock {
    static final ReentrantLock stockLock = new ReentrantLock();

    static void reserve(String who, long holdMs) throws InterruptedException {
        if (stockLock.tryLock(200, TimeUnit.MILLISECONDS)) {
            try {
                System.out.println(who + ": got the lock, holding it " + holdMs + " ms");
                Thread.sleep(holdMs);
            } finally {
                stockLock.unlock();
            }
        } else {
            System.out.println(who + ": gave up after 200 ms, stock is busy");
        }
    }

    public static void main(String[] args) throws InterruptedException {
        Thread slow = Thread.ofPlatform().start(() -> run("slow", 1000));
        Thread.sleep(50);
        Thread hurried = Thread.ofPlatform().start(() -> run("hurried", 10));
        slow.join();
        hurried.join();
        Thread late = Thread.ofPlatform().start(() -> run("late", 10));
        late.join();
        System.out.println("held now: " + stockLock.isLocked());
    }

    static void run(String who, long holdMs) {
        try {
            reserve(who, holdMs);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
```

```
ana@vm:~/fp/locks$ java TryLock.java
slow: got the lock, holding it 1000 ms
hurried: gave up after 200 ms, stock is busy
late: got the lock, holding it 10 ms
held now: false
```

`slow` pegou o lock e o segurou por um segundo. `hurried` pediu 50 ms depois, esperou os seus 200 ms, e
**desistiu com uma mensagem**, onde um bloco `synchronized` teria esperado o segundo inteiro sem uma
palavra. `late`, depois de as duas terminarem, pegou o lock na hora, e o `isLocked()` confirma que todo
`lock` teve o seu `unlock`.

## O `finally` não é opcional

Com o `synchronized`, sair do bloco de qualquer jeito, normalmente ou por exceção, libera o lock. Com um
`Lock`, **só o `unlock()` o libera**, então uma exceção lançada entre o `lock` e o `unlock` sem um
`finally` deixa o lock preso para sempre, e toda thread que pedir por ele depois espera para sempre. A
forma acima, obter, depois `try`, depois o trabalho, depois o `unlock` no `finally`, é a única segura.

| precisa de | use |
|---|---|
| exclusão mútua simples | `synchronized`: mais curto, e não vaza |
| desistir depois de um tempo limite | `tryLock(tempo, unidade)` |
| parar de esperar quando a thread é interrompida | `lockInterruptibly()` |
| muitos leitores, poucos escritores | `ReentrantReadWriteLock`: leitores compartilham, um escritor fica sozinho |

Desde o Java 24, uma thread virtual esperando dentro de `synchronized` não segura mais a sua thread
portadora, o que tirou o principal motivo pelo qual código com threads virtuais preferia o
`ReentrantLock`; a aula 17 explica o que isso significa. Escolha pela tabela, não pelo hábito.
