---
title: synchronized
version: 1
---

**Todo objeto Java tem um lock, chamado monitor, e o `synchronized` o obtém.** Um bloco `synchronized`
só roda enquanto a sua thread segura o lock do objeto nomeado entre parênteses; qualquer outra thread que
chegue a um bloco no mesmo objeto espera, no estado `BLOCKED` (aula 11, seção 03), até o lock ficar
livre. Um método `synchronized` é a mesma coisa com `this` como objeto, ou com a própria classe num
método estático.

```schooling-example
{
  "language": "java",
  "file": "Synced.java",
  "parts": [
    {
      "code": "// Synced.java: the counter and the account of lessons 13 and 14, synchronised\nimport java.util.ArrayList;\nimport java.util.List;\n\npublic class Synced {"
    },
    {
      "code": "    static class Counter {\n        private long count;\n\n        synchronized void increment() {\n            count++;\n        }\n\n        synchronized long get() {\n            return count;\n        }\n    }",
      "note": "Os dois métodos sincronizam no mesmo `Counter`, então um incremento nunca se sobrepõe a outro incremento nem a uma leitura. O campo não precisa mais de `volatile`: o lock dá visibilidade além de exclusão."
    },
    {
      "code": "\n    static class Account {\n        private long cents;\n\n        Account(long cents) {\n            this.cents = cents;\n        }\n\n        boolean withdraw(long amount) {\n            synchronized (this) {\n                if (cents < amount) {\n                    return false;\n                }\n                Thread.yield();\n                cents -= amount;\n                return true;\n            }\n        }\n\n        synchronized long balance() {\n            return cents;\n        }\n    }",
      "note": "A verificação e a ação agora estão dentro de um bloco só, então nenhuma outra caixa pode mudar `cents` entre elas. O mesmo intervalo continua lá, e ninguém consegue usá-lo."
    },
    {
      "code": "\n    static void onFourThreads(Runnable work) throws InterruptedException {\n        List<Thread> threads = new ArrayList<>();\n        for (int t = 0; t < 4; t++) {\n            threads.add(Thread.ofPlatform().start(work));\n        }\n        for (Thread t : threads) {\n            t.join();\n        }\n    }",
      "note": "Quatro threads rodando o mesmo trabalho, e um `join` em cada uma, que torna os resultados delas visíveis para a `main` (aula 12, seção 04)."
    },
    {
      "code": "\n    public static void main(String[] args) throws InterruptedException {\n        Counter counter = new Counter();\n        onFourThreads(() -> {\n            for (int i = 0; i < 1_000_000; i++) {\n                counter.increment();\n            }\n        });\n        System.out.println(\"count: \" + counter.get() + \" of 4000000\");\n\n        for (int run = 1; run <= 3; run++) {\n            Account account = new Account(100_000);\n            onFourThreads(() -> {\n                for (int i = 0; i < 1000; i++) {\n                    account.withdraw(50);\n                }\n            });\n            System.out.println(\"run \" + run + \": balance \" + account.balance());\n        }\n    }\n}\n",
      "note": "O mesmo trabalho de antes, nas classes sincronizadas."
    }
  ],
  "output": "count: 4000000 of 4000000\nrun 1: balance 0\nrun 2: balance 0\nrun 3: balance 0"
}
```

**Quatro milhões, exatos, e o saldo em zero toda vez.** Um lock dá duas coisas de uma vez: só uma
thread lá dentro, e, pela regra de happens-before dos monitores (aula 12, seção 04), tudo o que uma
thread fez lá dentro fica visível para a próxima thread que obtiver o mesmo lock. É por isso que `count`
não precisa de `volatile` quando todo acesso a ele é sincronizado, **inclusive a leitura**: um `get()`
sem sincronização poderia ler um valor velho.

## Três regras práticas

- **Todo acesso ao estado compartilhado passa pelo mesmo lock.** Sincronizar as escritas e não as
  leituras, ou dois métodos em dois objetos diferentes, não protege nada.
- **Mantenha o bloco curto**: a verificação e a ação, e nada que espere. Uma thread que segura um lock
  enquanto chama um serviço web faz todas as outras threads esperarem pelo serviço web também.
- **Trave num objeto que você controla.** `synchronized (this)` numa classe que outros enxergam deixa
  eles pegarem o seu lock também; um `private final Object lock = new Object();` o mantém seu.

Um bloco `synchronized` é **reentrante**: uma thread que já segura um lock pode entrar em outro bloco no
mesmo lock sem esperar por si mesma, e é por isso que um método sincronizado pode chamar outro método
sincronizado do mesmo objeto.
