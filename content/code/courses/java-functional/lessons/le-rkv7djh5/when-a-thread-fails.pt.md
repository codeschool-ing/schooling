---
title: Quando uma thread falha
version: 1
---

**Uma exceção que ninguém captura termina a thread em que foi lançada, e só essa thread.** Na `main`,
isso termina o programa, o que é barulhento e óbvio. Em qualquer outra thread, a JVM imprime um stack
trace e o programa segue em frente, com o que aquela thread deveria fazer deixado por fazer:

```java
// Failing.java: an uncaught exception in a worker, and a handler that reports it
public class Failing {
    public static void main(String[] args) throws InterruptedException {
        Thread quiet = new Thread(() -> {
            System.out.println("worker: about to divide");
            int ratio = 10 / Integer.parseInt("0");
            System.out.println("worker: ratio is " + ratio);
        }, "worker-a");
        quiet.start();
        quiet.join();
        System.out.println("main: still running, and nothing told me the worker failed");

        Thread reported = new Thread(() -> {
            throw new IllegalStateException("stock file is missing");
        }, "worker-b");
        reported.setUncaughtExceptionHandler((t, e) ->
                System.out.println("handler: " + t.getName() + " died with " + e));
        reported.start();
        reported.join();

        Thread daemon = new Thread(() -> {
            try {
                Thread.sleep(60_000);
                System.out.println("daemon: never printed");
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });
        daemon.setDaemon(true);
        daemon.start();
        System.out.println("main: done, and the daemon does not keep the JVM alive");
    }
}
```

```
ana@vm:~/fp/threads$ java Failing.java
worker: about to divide
Exception in thread "worker-a" java.lang.ArithmeticException: / by zero
	at Failing.lambda$main$0(Failing.java:6)
	at java.base/java.lang.Thread.run(Thread.java:1474)
main: still running, and nothing told me the worker failed
handler: worker-b died with java.lang.IllegalStateException: stock file is missing
main: done, and the daemon does not keep the JVM alive
```

## Um stack trace não é um aviso

`worker-a` morreu na divisão, e a JVM imprimiu `Exception in thread "worker-a"` com o trace. Depois
**a `main` seguiu e imprimiu a sua próxima linha**, sem ter como saber o que aconteceu. Num terminal,
alguém talvez note o trace. Num servidor cuja saída vai para um log que ninguém lê, uma thread que
devia processar pedidos para, e o programa continua respondendo como se tudo estivesse bem. Essa é a
falha que as regras deste repositório chamam de silenciosa, e é o jeito mais comum de threads
perderem trabalho.

O `setUncaughtExceptionHandler` dá à thread um lugar para avisar da sua morte: o handler recebeu a
thread e a exceção, e poderia registrá-la, contá-la ou parar o programa de propósito. Também há um
handler padrão para todas as threads, `Thread.setDefaultUncaughtExceptionHandler`, definido uma vez na
inicialização. A aula 16 mostra uma resposta melhor ainda: com um executor, a exceção é guardada e
entregue a quem pedir o resultado da tarefa.

## Daemons

`daemon.setDaemon(true)` marcou a terceira thread como **daemon**: uma ajudante pela qual a JVM não
espera. O programa termina quando a sua última thread não daemon acaba, então a `main` retornou e a
JVM parou, levando junto a daemon que dormia, e é por isso que a linha dela nunca apareceu. Uma thread
que você esquece de esperar mantém a JVM viva se não for daemon, e uma daemon de que você depende é
morta no meio do trabalho quando a `main` acaba. Nenhuma das duas coisas é motivo para evitá-las; as
duas são motivo para decidir de propósito.
