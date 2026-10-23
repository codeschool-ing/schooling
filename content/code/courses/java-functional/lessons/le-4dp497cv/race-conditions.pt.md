---
title: Condições de corrida
version: 1
---

**Uma condição de corrida é um bug cujo resultado depende do tempo das threads.** A atualização perdida
da aula 13 é um tipo. O outro tipo comum é **verificar-depois-agir**: uma thread confere uma condição,
depois age com base nela, e outra thread muda a condição no meio. Dinheiro deixa a consequência clara:

```java
// Overdraft.java: two withdrawals that each check the balance first
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;

public class Overdraft {
    static class Account {
        private long cents;

        Account(long cents) {
            this.cents = cents;
        }

        boolean withdraw(long amount) {
            if (cents >= amount) {
                Thread.yield();
                cents -= amount;
                return true;
            }
            return false;
        }

        long balance() {
            return cents;
        }
    }

    public static void main(String[] args) throws InterruptedException {
        for (int run = 1; run <= 5; run++) {
            Account account = new Account(100_000);
            CountDownLatch open = new CountDownLatch(1);
            List<Thread> tills = new ArrayList<>();
            for (int t = 0; t < 4; t++) {
                tills.add(Thread.ofPlatform().start(() -> {
                    awaitQuietly(open);
                    for (int i = 0; i < 1000; i++) {
                        account.withdraw(50);
                    }
                }));
            }
            open.countDown();
            for (Thread t : tills) {
                t.join();
            }
            System.out.println("run " + run + ": balance " + account.balance());
        }
    }

    static void awaitQuietly(CountDownLatch latch) {
        try {
            latch.await();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
```

```
ana@vm:~/fp/locks$ java Overdraft.java
run 1: balance -100
run 2: balance -100
run 3: balance -150
run 4: balance -150
run 5: balance -100
```

## Lendo

Quatro caixas tentam 4.000 saques de 50 centavos numa conta com 100.000 centavos, que cobre 2.000
deles. Rodando numa thread só, o `withdraw` recusa assim que o dinheiro acaba, e o saldo termina em
exatamente 0. Rodando em quatro, soltas juntas pelo `CountDownLatch` da seção 03 da aula 12, **a conta
terminou abaixo de zero em toda execução**: dinheiro que não existia foi pago.

A janela é o intervalo entre `if (cents >= amount)` e `cents -= amount`. O `Thread.yield()` fica nesse
intervalo só para alargá-lo, convidando o escalonador a trocar de thread ali, para a falha aparecer numa
máquina tranquila; **código real tem o mesmo intervalo sem ele**, e sob carga ele é atingido do mesmo
jeito, só com menos frequência. Duas caixas leem um saldo de 50, as duas passam na verificação, e as duas
subtraem, deixando −50. E o próprio `cents -= amount` é um read-modify-write, então subtrações também
podem se perder, o que empurra o saldo para o outro lado.

Nenhuma das duas formas, verificar-depois-agir e read-modify-write, é resolvida com `volatile`, porque
cada uma são **vários passos que precisam acontecer juntos**. O que elas precisam é que uma thread por
vez rode a sequência inteira: exclusão mútua, que é a próxima seção.
