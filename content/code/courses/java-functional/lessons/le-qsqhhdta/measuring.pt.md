---
title: Medindo, não adivinhando
version: 1
---

**Um stream paralelo só é mais rápido quando o trabalho por elemento, vezes o número de elementos, é
grande o bastante para pagar a divisão, o agendamento e a combinação.** O único jeito confiável de
saber é medir, e a medição tem de ser honesta com a JVM: as primeiras execuções de qualquer código são
mais lentas, enquanto ele é interpretado e antes de o compilador otimizá-lo. Este programa roda cada
versão cinco vezes e fica com a melhor:

```java
// Primes.java: the same count, sequential and parallel, timed
import java.util.function.LongSupplier;
import java.util.stream.IntStream;

public class Primes {
    static boolean isPrime(int n) {
        if (n < 2) {
            return false;
        }
        for (int d = 2; (long) d * d <= n; d++) {
            if (n % d == 0) {
                return false;
            }
        }
        return true;
    }

    static void time(String label, LongSupplier work) {
        long best = Long.MAX_VALUE;
        long result = 0;
        for (int run = 0; run < 5; run++) {
            long start = System.nanoTime();
            result = work.getAsLong();
            best = Math.min(best, System.nanoTime() - start);
        }
        System.out.printf("%-22s %8d   best of 5: %9.3f ms%n", label, result, best / 1e6);
    }

    public static void main(String[] args) {
        System.out.println("processors: " + Runtime.getRuntime().availableProcessors());
        time("primes, sequential", () -> IntStream.range(0, 2_000_000).filter(Primes::isPrime).count());
        time("primes, parallel", () -> IntStream.range(0, 2_000_000).parallel().filter(Primes::isPrime).count());
        time("small sum, loop", () -> {
            long s = 0;
            for (int i = 0; i < 100; i++) {
                s += i;
            }
            return s;
        });
        time("small sum, sequential", () -> IntStream.range(0, 100).asLongStream().sum());
        time("small sum, parallel", () -> IntStream.range(0, 100).parallel().asLongStream().sum());
    }
}
```

```
ana@vm:~/fp/parallel$ java Primes.java
processors: 4
primes, sequential       148933   best of 5:   283.981 ms
primes, parallel         148933   best of 5:    81.114 ms
small sum, loop            4950   best of 5:     0.001 ms
small sum, sequential      4950   best of 5:     0.014 ms
small sum, parallel        4950   best of 5:     0.050 ms
```

**Os tempos são de uma execução nesta máquina**, e os seus vão ser diferentes; o que vale ler são as
proporções.

## Onde ajudou

Contar os primos abaixo de dois milhões testa cada número por divisão, o que é trabalho de verdade por
elemento, e os elementos são um `IntStream.range`, a fonte que melhor se divide. A versão paralela foi
cerca de três vezes e meia mais rápida em quatro processadores, 81 ms contra 284. Esse é o caso para
o qual os streams paralelos foram feitos: **muitos elementos, trabalho caro em cada um, nenhum estado
compartilhado**, e uma fonte que se divide por igual. Quatro processadores não deram um ganho de
quatro vezes, porque dividir, iniciar os workers e combinar as contagens custa algo, e o trabalho nos
números maiores se espalha de forma desigual.

## Onde atrapalhou

Somar cem números pequenos é o oposto. O laço levou cerca de um microssegundo e o stream sequencial
14, e o stream paralelo levou 50, **para fazer cerca de um microssegundo de aritmética**: o custo foi
entregar pedaços a outras threads e esperar por elas. A maioria dos streams num código comum de
negócio se parece com este, algumas dezenas de elementos e lambdas baratos, e é por isso que o
`parallel()` não é um interruptor para ligar em todo lugar e ver o que acontece.

## Como medir o seu caso

- **aqueça e repita**: a primeira execução inclui o JIT compilando o código. Ficar com a melhor de
  várias execuções, como o `time` faz, é a correção mais barata;
- **meça com dados do tamanho da produção**: um pipeline que perde com mil elementos pode ganhar com
  dez milhões, e vice-versa;
- **para decisões que importam, use o JMH**, a ferramenta de benchmarks do projeto OpenJDK, que trata
  do aquecimento, da eliminação de código morto e da estatística direito. Um laço com `nanoTime` é uma
  primeira olhada, não um veredito.
