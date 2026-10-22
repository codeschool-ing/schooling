---
title: Mapas concorrentes
version: 1
---

**O `HashMap` foi escrito para uma thread por vez, e compartilhá-lo entre threads sem lock o corrompe.**
O `ConcurrentHashMap` é o mapa feito para compartilhar: muitas threads leem e escrevem nele ao mesmo
tempo, cada operação é thread-safe, e ele tem métodos que fazem um read-modify-write inteiro numa chave
como um passo só. Contar palavras a partir de várias threads mostra a diferença:

```java
// WordCount.java: four threads counting words into a HashMap, then into a ConcurrentHashMap
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class WordCount {
    static final String[] WORDS = {"dune", "emma", "ulysses", "beowulf", "middlemarch", "persuasion"};

    static void onFourThreads(Runnable work) throws InterruptedException {
        List<Thread> threads = new ArrayList<>();
        for (int t = 0; t < 4; t++) {
            threads.add(Thread.ofPlatform().start(work));
        }
        for (Thread t : threads) {
            t.join();
        }
    }

    static long total(Map<String, Integer> counts) {
        return counts.values().stream().mapToLong(Integer::longValue).sum();
    }

    public static void main(String[] args) throws InterruptedException {
        for (int run = 1; run <= 3; run++) {
            Map<String, Integer> plain = new HashMap<>();
            onFourThreads(() -> {
                for (int i = 0; i < 100_000; i++) {
                    String w = WORDS[i % WORDS.length];
                    plain.put(w, plain.getOrDefault(w, 0) + 1);
                }
            });
            System.out.println("HashMap, run " + run + ": " + total(plain) + " of 400000");
        }

        Map<String, Integer> shared = new ConcurrentHashMap<>();
        onFourThreads(() -> {
            for (int i = 0; i < 100_000; i++) {
                shared.merge(WORDS[i % WORDS.length], 1, Integer::sum);
            }
        });
        System.out.println("ConcurrentHashMap with merge: " + total(shared) + " of 400000");

        Map<String, Integer> almost = new ConcurrentHashMap<>();
        onFourThreads(() -> {
            for (int i = 0; i < 100_000; i++) {
                String w = WORDS[i % WORDS.length];
                almost.put(w, almost.getOrDefault(w, 0) + 1);
            }
        });
        System.out.println("ConcurrentHashMap with get then put: " + total(almost) + " of 400000");
    }
}
```

```
ana@vm:~/fp/concurrent$ java WordCount.java
HashMap, run 1: 237328 of 400000
HashMap, run 2: 195332 of 400000
HashMap, run 3: 199674 of 400000
ConcurrentHashMap with merge: 400000 of 400000
ConcurrentHashMap with get then put: 312264 of 400000
```

## Três resultados

**O `HashMap` compartilhado perdeu cerca de metade das contagens**, um número diferente a cada execução.
O `put` dele não é thread-safe, e duas threads escrevendo ao mesmo tempo podem perder uma entrada ou
deixar os elos internos da tabela num estado que nenhuma thread sozinha poderia produzir. Nada lançou
exceção. Essa é a forma mais perigosa de corrida, porque o programa segue em frente, com números
errados.

**O `ConcurrentHashMap` com `merge` pegou os 400.000.** `merge(chave, 1, Integer::sum)` põe 1 se a chave
falta, ou soma 1 ao valor atual, como um passo atômico para aquela chave. `compute` e `computeIfAbsent`
são parentes dele, e entre eles cobrem todo "ler esta chave, mudar, escrever de volta" de que um
programa precisa.

**O `ConcurrentHashMap` com `get` e depois `put` perdeu contagens de novo.** Cada chamada é thread-safe
sozinha; o par é um verificar-depois-agir, exatamente o saque a descoberto da aula 14. **Uma coleção
thread-safe não transforma duas chamadas numa.** É por isso que `merge` e `compute` existem, e por que
ler um código que chama `get` e depois `put` num mapa compartilhado é ler um bug.
