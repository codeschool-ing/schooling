---
title: Futures
version: 1
---

**O `submit` devolve um `Future`: uma alça para um resultado que ainda não existe.** O `get()` espera a
tarefa terminar e devolve o que ela devolveu. Quando a tarefa é um `Callable`, uma interface funcional
cujo único método devolve um valor e pode lançar exceção, o `Future` traz esse valor de volta; e quando
a tarefa lança exceção, o `Future` traz a exceção de volta no lugar.

```java
// Futures.java: results, a failure that is not lost, and a timeout
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

public class Futures {
    public static void main(String[] args) throws InterruptedException {
        try (ExecutorService pool = Executors.newFixedThreadPool(2)) {
            Callable<Long> stock = () -> {
                Thread.sleep(200);
                return 12L;
            };
            Callable<Long> broken = () -> {
                throw new IllegalStateException("price file is missing");
            };
            Callable<Long> slow = () -> {
                Thread.sleep(5_000);
                return 0L;
            };

            Future<Long> f1 = pool.submit(stock);
            Future<Long> f2 = pool.submit(broken);
            System.out.println("submitted; f1 done yet? " + f1.isDone());
            System.out.println("stock: " + f1.get());

            try {
                f2.get();
            } catch (ExecutionException e) {
                System.out.println("broken task failed: " + e.getCause());
            }

            Future<Long> f3 = pool.submit(slow);
            try {
                f3.get(300, TimeUnit.MILLISECONDS);
            } catch (TimeoutException e) {
                System.out.println("gave up waiting after 300 ms; cancelled: " + f3.cancel(true));
            }
        } catch (ExecutionException e) {
            throw new IllegalStateException(e);
        }
    }
}
```

```
ana@vm:~/fp/executors$ java Futures.java
submitted; f1 done yet? false
stock: 12
broken task failed: java.lang.IllegalStateException: price file is missing
gave up waiting after 300 ms; cancelled: true
```

## Três desfechos do `get`

**Um resultado.** `f1.isDone()` era `false` logo depois do `submit`, e `f1.get()` esperou os 200 ms e
devolveu 12. O `get` é como uma thread espera a resposta de outra, com a aresta happens-before embutida
(aula 12, seção 04): o que a tarefa escreveu fica visível depois que o `get` volta.

**Uma falha, guardada.** A tarefa quebrada lançou exceção, e a exceção não sumiu num log, como a de uma
thread sumiu na seção 05 da aula 11. **O `get` lançou `ExecutionException`, com a exceção da própria
tarefa como causa.** Quem pede o resultado descobre que não há nenhum e por quê; uma falha só fica
silenciosa se ninguém nunca perguntar, e esse é um motivo para guardar todo `Future` que você submete até
ter olhado para ele.

**Uma espera com limite.** `get(300, MILLISECONDS)` desistiu com `TimeoutException`, e `cancel(true)`
interrompeu a tarefa, que estava dormindo e parou na hora. Sem o limite, uma tarefa que trava faz quem a
chamou travar também. Cancelar depende de a tarefa responder à interrupção (aula 11, seção 03): uma
tarefa que a ignora continua rodando depois de cancelada.
