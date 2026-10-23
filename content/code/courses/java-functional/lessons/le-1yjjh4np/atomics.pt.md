---
title: Atômicos
version: 1
---

**Uma variável atômica faz um read-modify-write como uma operação indivisível, sem lock.** As classes de
`java.util.concurrent.atomic`, `AtomicInteger`, `AtomicLong`, `AtomicReference` e parentes, usam uma
instrução que o processador oferece exatamente para isso: **compare-and-set** (comparar e definir), que
escreve um valor novo só se a variável ainda tiver o valor que a thread leu por último, e informa se
escreveu.

```schooling-example
{
  "language": "java",
  "file": "Atomics.java",
  "parts": [
    {
      "code": "// Atomics.java: lesson 13's counter, an atomic maximum, and LongAdder\nimport java.util.ArrayList;\nimport java.util.List;\nimport java.util.concurrent.atomic.AtomicLong;\nimport java.util.concurrent.atomic.LongAdder;\n\npublic class Atomics {\n    static void onFourThreads(Runnable work) throws InterruptedException {\n        List<Thread> threads = new ArrayList<>();\n        for (int t = 0; t < 4; t++) {\n            threads.add(Thread.ofPlatform().start(work));\n        }\n        for (Thread t : threads) {\n            t.join();\n        }\n    }"
    },
    {
      "code": "\n    public static void main(String[] args) throws InterruptedException {\n        AtomicLong count = new AtomicLong();\n        onFourThreads(() -> {\n            for (int i = 0; i < 1_000_000; i++) {\n                count.incrementAndGet();\n            }\n        });\n        System.out.println(\"count: \" + count.get() + \" of 4000000\");",
      "note": "O contador da aula 13 com `AtomicLong`. O `incrementAndGet` lê, soma e escreve como uma operação só, então nenhum incremento se perde, e não há lock em lugar nenhum."
    },
    {
      "code": "\n        AtomicLong largest = new AtomicLong(Long.MIN_VALUE);\n        onFourThreads(() -> {\n            for (long order = 1; order <= 1000; order++) {\n                long candidate = order * 37 % 10_007;\n                long seen = largest.get();\n                while (candidate > seen && !largest.compareAndSet(seen, candidate)) {\n                    seen = largest.get();\n                }\n            }\n        });\n        System.out.println(\"largest: \" + largest.get());",
      "note": "Um máximo corrente, escrito à mão com `compareAndSet`. Se outra thread mudou `largest` entre o `get` e o set, o set falha, o laço lê o valor novo e decide de novo. Esse laço de nova tentativa é como todo atômico funciona por dentro."
    },
    {
      "code": "\n        LongAdder hits = new LongAdder();\n        onFourThreads(() -> {\n            for (int i = 0; i < 1_000_000; i++) {\n                hits.increment();\n            }\n        });\n        System.out.println(\"hits: \" + hits.sum());\n    }\n}\n",
      "note": "O `LongAdder` mantém vários contadores por dentro e só os soma quando `sum()` é chamado, então quatro threads raramente disputam o mesmo. Ele serve para contadores escritos muito mais vezes do que lidos."
    }
  ],
  "output": "count: 4000000 of 4000000\nlargest: 9993\nhits: 4000000"
}
```

## O que o compare-and-set compra, e quanto custa

O contador chegou a quatro milhões, a mesma resposta da versão `synchronized` da aula 14, sem nenhuma
thread esperar por lock. **Uma thread que perde um compare-and-set não bloqueia; tenta de novo**, e é por
isso que atômicos são chamados de lock-free. Com pouca disputa a nova tentativa quase nunca acontece e um
atômico é mais barato que um lock. Com muita disputa, muitas threads tentam de novo contra a mesma
variável, e o `LongAdder` existe para espalhá-las por várias células.

O laço de `largest` também mostra o limite de um atômico: **ele protege uma variável.** Manter um mínimo
e um máximo coerentes entre si, ou um saldo e a lista de transações que o produziram, são duas variáveis
que precisam mudar juntas, e isso exige um lock ou um único objeto imutável atrás de um
`AtomicReference`, trocado inteiro (aula 12, seção 05).

`updateAndGet` e `accumulateAndGet` escrevem o laço de nova tentativa para você:
`largest.accumulateAndGet(candidate, Math::max)` faz o que o laço escrito à mão fez, numa linha. O laço
aparece porque toda operação atômica é esse laço por baixo, e conhecê-lo explica por que a função que
você passa **pode ser chamada mais de uma vez** e não pode ter efeitos colaterais.
