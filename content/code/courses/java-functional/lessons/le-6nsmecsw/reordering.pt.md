---
title: Reordenação
version: 1
---

**O compilador e o processador podem executar leituras e escritas independentes numa ordem diferente
da do código-fonte, desde que a thread que as faz não consiga perceber.** Outra thread consegue. O
teste clássico tem duas threads e duas variáveis, ambas começando em 0:

| thread A | thread B |
|---|---|
| `x = 1` | `y = 1` |
| `r1 = y` | `r2 = x` |

Tente todo entrelaçamento dessas quatro instruções e pelo menos uma escrita vem antes da leitura da
outra thread, então **pelo menos um entre `r1` e `r2` tem de ser 1**. O programa abaixo roda o teste
cinco milhões de vezes de uma vez: cada thread percorre as suas cópias das variáveis num par de
arrays, então as duas threads correm por posições correspondentes:

```java
// Litmus.java: two writes, two reads, and the outcome that no interleaving allows
import java.util.concurrent.CountDownLatch;

public class Litmus {
    public static void main(String[] args) throws Exception {
        int n = 5_000_000;
        int[] x = new int[n], y = new int[n], r1 = new int[n], r2 = new int[n];
        CountDownLatch go = new CountDownLatch(1);
        Thread a = new Thread(() -> {
            await(go);
            for (int i = 0; i < n; i++) {
                x[i] = 1;
                r1[i] = y[i];
            }
        });
        Thread b = new Thread(() -> {
            await(go);
            for (int i = 0; i < n; i++) {
                y[i] = 1;
                r2[i] = x[i];
            }
        });
        a.start();
        b.start();
        go.countDown();
        a.join();
        b.join();

        int[][] count = new int[2][2];
        for (int i = 0; i < n; i++) {
            count[r1[i]][r2[i]]++;
        }
        System.out.println("r1=0 r2=0: " + count[0][0]);
        System.out.println("r1=0 r2=1: " + count[0][1]);
        System.out.println("r1=1 r2=0: " + count[1][0]);
        System.out.println("r1=1 r2=1: " + count[1][1]);
    }

    static void await(CountDownLatch latch) {
        try {
            latch.await();
        } catch (InterruptedException e) {
            throw new IllegalStateException(e);
        }
    }
}
```

```
ana@vm:~/fp/memory$ java Litmus.java
r1=0 r2=0: 24
r1=0 r2=1: 481
r1=1 r2=0: 4999495
r1=1 r2=1: 0
```

## Lendo as quatro linhas

Quase todo par mostra uma thread terminando as suas duas instruções antes de a outra começar as suas,
o que dá `0, 1` ou `1, 0`. As duas escritas acontecendo antes das duas leituras dariam `1, 1`, e esta
execução não pegou nenhum. **E 24 pares mostram `0, 0`**, o resultado que nenhum entrelaçamento
produz. Neles, cada thread leu a variável da outra antes de a sua própria escrita ficar visível para a
outra. Neste processador, um x86, cada núcleo segura as suas escritas num store buffer por um instante
antes de elas chegarem à memória que todos compartilham, e uma leitura que vem depois de uma escrita
num endereço diferente pode terminar primeiro. O JIT tem permissão para fazer a mesma troca por conta
própria.

O `CountDownLatch` é o tiro de largada: as duas threads esperam nele, e o `countDown` solta as duas
juntas. A aula 15 o encontra de novo entre as ferramentas de concorrência.

Os números mudam a cada execução e são diferentes em outros processadores; processadores ARM reordenam
mais que o x86. O que não muda é a regra: **sem algo que as ordene, as leituras e escritas de duas
threads não têm ordem em que se possa confiar**. A próxima seção é esse algo.
