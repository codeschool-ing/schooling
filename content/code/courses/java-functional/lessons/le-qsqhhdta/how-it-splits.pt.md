---
title: Como um stream paralelo divide o trabalho
version: 1
---

**`parallel()` pede ao stream que divida a fonte em pedaços, rode o pipeline nos pedaços em várias
threads ao mesmo tempo e combine os resultados parciais.** O código do pipeline não muda. O que muda é
quem o executa: a thread que chamou a operação terminal, mais threads de trabalho de um pool que a JVM
mantém para isso, o **pool fork-join comum**.

O jeito de ver isso é perguntar a cada elemento em que thread ele foi processado:

```java
// WhoWorks.java: which threads a parallel stream runs on
import java.util.Map;
import java.util.TreeMap;
import java.util.concurrent.ForkJoinPool;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

public class WhoWorks {
    public static void main(String[] args) {
        System.out.println("processors:            " + Runtime.getRuntime().availableProcessors());
        System.out.println("common pool workers:   " + ForkJoinPool.commonPool().getParallelism());

        Map<String, Long> sequential = IntStream.range(0, 100_000).boxed()
                .collect(Collectors.groupingBy(i -> Thread.currentThread().getName(), Collectors.counting()));
        System.out.println("sequential: " + sequential);

        Map<String, Long> parallel = IntStream.range(0, 100_000).parallel().boxed()
                .collect(Collectors.groupingByConcurrent(i -> Thread.currentThread().getName(), Collectors.counting()));
        new TreeMap<>(parallel).forEach((thread, count) -> System.out.println("  " + thread + ": " + count));
    }
}
```

```
ana@vm:~/fp/parallel$ java WhoWorks.java
processors:            4
common pool workers:   3
sequential: {main=100000}
  ForkJoinPool.commonPool-worker-1: 18750
  ForkJoinPool.commonPool-worker-2: 18750
  ForkJoinPool.commonPool-worker-3: 18750
  main: 43750
```

O stream sequencial fez tudo na `main`. O paralelo dividiu os 100.000 elementos entre a `main` e os
workers do pool. **O pool tem um worker a menos do que a máquina tem processadores**, três em quatro,
porque a thread que começou o trabalho também participa: quatro threads, quatro processadores. A
divisão não é igual, e muda de uma execução para outra, porque um worker que termina o seu pedaço
cedo rouba parte do de outro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Uma árvore. No topo, o intervalo de 0 a 2000. Ele é dividido em dois, de 0 a 1000 e de 1000 a 2000, e cada metade é dividida de novo em quartos de 500. Cada quarto é processado por uma thread: main e três workers do pool comum. Embaixo, os quatro resultados parciais são combinados num só.\"><defs><marker id=\"forkjoin-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"forkjoin-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"285\" y=\"14\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"31.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0 .. 2000</text><rect x=\"125\" y=\"72\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0 .. 1000</text><rect x=\"445\" y=\"72\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"520.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1000 .. 2000</text><path d=\"M360 48 L200 68\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#forkjoin-ah-paperdim)\"></path><path d=\"M360 48 L520 68\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#forkjoin-ah-paperdim)\"></path><rect x=\"20\" y=\"130\" width=\"155\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"97.5\" y=\"146.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0 .. 500</text><text x=\"97.5\" y=\"163.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">main</text><path d=\"M200 106 L97 126\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#forkjoin-ah-paperdim)\"></path><path d=\"M97 180 L360 222\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#forkjoin-ah-phosphor)\"></path><rect x=\"195\" y=\"130\" width=\"155\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"272.5\" y=\"146.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">500 .. 1000</text><text x=\"272.5\" y=\"163.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">worker-1</text><path d=\"M200 106 L272 126\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#forkjoin-ah-paperdim)\"></path><path d=\"M272 180 L360 222\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#forkjoin-ah-phosphor)\"></path><rect x=\"370\" y=\"130\" width=\"155\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"447.5\" y=\"146.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1000 .. 1500</text><text x=\"447.5\" y=\"163.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">worker-2</text><path d=\"M520 106 L447 126\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#forkjoin-ah-paperdim)\"></path><path d=\"M447 180 L360 222\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#forkjoin-ah-phosphor)\"></path><rect x=\"545\" y=\"130\" width=\"155\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"622.5\" y=\"146.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1500 .. 2000</text><text x=\"622.5\" y=\"163.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">worker-3</text><path d=\"M520 106 L622 126\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#forkjoin-ah-paperdim)\"></path><path d=\"M622 180 L360 222\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#forkjoin-ah-phosphor)\"></path><rect x=\"240\" y=\"226\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">resultados parciais combinados</text></svg>", "caption": "No caso mais simples, a fonte é dividida até haver um pedaço por thread, e os resultados parciais são combinados na volta."}
```

## Dividir é trabalho da fonte

Um stream paralelo divide a fonte com um **spliterator**, um iterador que também sabe se cortar em
dois. O quanto isso funciona bem depende inteiramente da fonte:

| fonte | divide | por quê |
|---|---|---|
| `ArrayList`, arrays, `IntStream.range` | por igual e barato | o índice do meio é conhecido na hora |
| `HashSet`, chaves de `HashMap` | razoavelmente | os baldes da tabela podem ser repartidos |
| `LinkedList` | mal | achar o meio é percorrer metade da lista |
| `Stream.iterate`, `Files.lines`, um `Iterator` | mal | cada elemento depende do anterior, ou o tamanho é desconhecido |

O `groupingByConcurrent` do programa é o coletor feito para isso: todas as threads acrescentam a um
`ConcurrentHashMap` só, em vez de cada uma montar um mapa e depois juntá-los. A aula 15 explica esse
mapa; a aula 16 explica o pool de onde vieram os workers, e por que ele é compartilhado pelo programa
inteiro.
