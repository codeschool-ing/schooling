---
title: Deadlock
version: 1
---

**Um deadlock são duas ou mais threads, cada uma segurando um lock de que a outra precisa, cada uma
esperando que a outra solte.** Nenhuma vai soltar, então o programa para sem erro, sem mensagem e sem
processador girando: simplesmente não faz nada, para sempre. O caso clássico é uma transferência entre
duas contas que trava primeiro quem envia e depois quem recebe:

```java
// Deadlock.java: two transfers that lock two accounts in opposite orders
public class Deadlock {
    static class Account {
        final String id;
        long cents;

        Account(String id, long cents) {
            this.id = id;
            this.cents = cents;
        }
    }

    static void transfer(Account from, Account to, long cents) {
        synchronized (from) {
            pause();
            synchronized (to) {
                from.cents -= cents;
                to.cents += cents;
            }
        }
    }

    static void pause() {
        try {
            Thread.sleep(100);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    public static void main(String[] args) throws InterruptedException {
        Account shop = new Account("shop", 100_000);
        Account supplier = new Account("supplier", 50_000);
        Thread a = Thread.ofPlatform().name("pay-supplier").start(() -> transfer(shop, supplier, 2_000));
        Thread b = Thread.ofPlatform().name("refund-shop").start(() -> transfer(supplier, shop, 500));
        a.join();
        b.join();
        System.out.println("never printed");
    }
}
```

`pay-supplier` trava `shop` e depois quer `supplier`; `refund-shop` trava `supplier` e depois quer
`shop`. O `pause` mantém cada thread dentro do seu primeiro lock tempo bastante para a outra pegar o seu.
Inicie-o em segundo plano e depois pergunte à JVM o que as threads dela estão fazendo. O `jcmd` manda
comandos para uma JVM em execução; sem argumentos, ele lista as JVMs rodando com o seu usuário, cada uma
depois do seu id de processo, e o `Thread.print` é o dump de threads da seção 03 da aula 11. O `kill` com
o mesmo id encerra o programa:

```
ana@vm:~/fp/locks$ java Deadlock.java > /dev/null &
ana@vm:~/fp/locks$ jcmd | grep Deadlock
15108 jdk.compiler/com.sun.tools.javac.launcher.SourceLauncher Deadlock.java
ana@vm:~/fp/locks$ jcmd 15108 Thread.print | grep -A 16 'Found one'
Found one Java-level deadlock:
=============================
"pay-supplier":
  waiting to lock monitor 0x00007f4978002130 (object 0x00000007360c30a0, a Deadlock$Account),
  which is held by "refund-shop"

"refund-shop":
  waiting to lock monitor 0x00007f496c000f20 (object 0x00000007360c3058, a Deadlock$Account),
  which is held by "pay-supplier"

Java stack information for the threads listed above:
===================================================
"pay-supplier":
	at Deadlock.transfer(Deadlock.java:17)
	- waiting to lock <0x00000007360c30a0> (a Deadlock$Account)
	- locked <0x00000007360c3058> (a Deadlock$Account)
	at Deadlock.lambda$main$0(Deadlock.java:34)
ana@vm:~/fp/locks$ kill 15108
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Um ciclo de quatro caixas. A thread pay-supplier segura o lock de shop e espera o lock de supplier. A thread refund-shop segura o lock de supplier e espera o lock de shop. Setas vão de cada thread ao lock que segura, e de cada thread ao lock que quer, que a outra segura, fechando o ciclo.\"><defs><marker id=\"cycle-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"cycle-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40\" y=\"20\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">pay-supplier</text><rect x=\"480\" y=\"150\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">refund-shop</text><rect x=\"480\" y=\"20\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">lock de shop</text><rect x=\"40\" y=\"150\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">lock de supplier</text><path d=\"M240 45 L476 45\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#cycle-ah-phosphor)\"></path><text x=\"358\" y=\"35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">segura</text><path d=\"M480 175 L244 175\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#cycle-ah-phosphor)\"></path><text x=\"362\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">segura</text><path d=\"M140 70 L140 146\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\" marker-end=\"url(#cycle-ah-amber)\"></path><text x=\"150\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">espera</text><path d=\"M580 150 L580 74\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\" marker-end=\"url(#cycle-ah-amber)\"></path><text x=\"570\" y=\"110\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">espera</text></svg>", "caption": "Cada thread segura o que a outra quer; nenhuma solta, então nenhuma anda."}
```

## O dump diz com todas as letras

**`Found one Java-level deadlock`**, e depois o ciclo: `pay-supplier` espera um monitor que
`refund-shop` segura, que espera um que `pay-supplier` segura. As informações de pilha abaixo dão a
linha, `Deadlock.java:17`, o `synchronized` de dentro, e qual lock cada thread segura e qual quer. Um
programa travado em produção recebe o mesmo tratamento: um dump de threads primeiro, e ele muitas vezes
responde a pergunta num parágrafo.

## Prevenindo: uma ordem só para todos os locks

Um deadlock precisa de um ciclo, e um ciclo precisa de duas threads obtendo os mesmos locks em ordens
diferentes. **Obtenha os locks numa ordem global única** e o ciclo não se forma. Para contas, ordene por
algo em que toda thread concorde:

```java
// Ordered.java: the same transfers, locking the two accounts in id order
public class Ordered {
    static class Account {
        final String id;
        long cents;

        Account(String id, long cents) {
            this.id = id;
            this.cents = cents;
        }
    }

    static void transfer(Account from, Account to, long cents) {
        Account first = from.id.compareTo(to.id) < 0 ? from : to;
        Account second = first == from ? to : from;
        synchronized (first) {
            Deadlock.pause();
            synchronized (second) {
                from.cents -= cents;
                to.cents += cents;
            }
        }
    }

    public static void main(String[] args) throws InterruptedException {
        Account shop = new Account("shop", 100_000);
        Account supplier = new Account("supplier", 50_000);
        Thread a = Thread.ofPlatform().start(() -> transfer(shop, supplier, 2_000));
        Thread b = Thread.ofPlatform().start(() -> transfer(supplier, shop, 500));
        a.join();
        b.join();
        System.out.println("shop " + shop.cents + ", supplier " + supplier.cents);
    }
}
```

```
ana@vm:~/fp/locks$ java Ordered.java
shop 98500, supplier 51500
```

As duas transferências agora travam `shop` antes de `supplier`, qualquer que seja a direção do dinheiro,
e terminam: `shop` pagou 2.000 e recebeu 500. O `tryLock` com tempo limite, da seção 04, é a outra
defesa: uma thread que não consegue o segundo lock solta o primeiro e tenta de novo depois. Menos locks é
a melhor defesa de todas, e as aulas 15 e 16 tratam quase só de ferramentas que não precisam de nenhum.
