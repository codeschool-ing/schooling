---
title: Tarefas que sobrevivem a quem as chamou
version: 1
---

**Quando um método inicia tarefas em outras threads e retorna, nada liga essas tarefas ao método.** A
página da aula 16 pedia um preço e um estoque ao mesmo tempo. Faça a consulta de preço falhar, e veja o
que acontece com a consulta de estoque iniciada ao lado dela:

```java
// Orphan.java: one lookup fails, and the other runs on with nobody waiting for it
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class Orphan {
    static long price() {
        sleep(300);
        throw new IllegalStateException("price service down");
    }

    static int stock() {
        sleep(1000);
        System.out.println("stock: finished, for nobody");
        return 3;
    }

    static void sleep(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    public static void main(String[] args) {
        long start = System.nanoTime();
        try (ExecutorService io = Executors.newVirtualThreadPerTaskExecutor()) {
            CompletableFuture<Long> p = CompletableFuture.supplyAsync(Orphan::price, io);
            CompletableFuture<Integer> s = CompletableFuture.supplyAsync(Orphan::stock, io);
            try {
                System.out.println(p.join() + " " + s.join());
            } catch (RuntimeException e) {
                System.out.printf("page failed after %d ms: %s%n", (System.nanoTime() - start) / 1_000_000, e.getCause());
            }
        }
        System.out.printf("main returned after %d ms%n", (System.nanoTime() - start) / 1_000_000);
    }
}
```

```
ana@vm:~/fp/structured$ java Orphan.java
page failed after 308 ms: java.lang.IllegalStateException: price service down
stock: finished, for nobody
main returned after 1008 ms
```

## O que deu errado

A página sabia que tinha falhado depois de 300 ms. **A consulta de estoque não sabia**, e rodou o seu
segundo inteiro, imprimiu um resultado que ninguém leria, e só então deixou o executor fechar. Num
servidor, essa é a forma de um vazamento de recursos: uma requisição que já respondeu "erro" continua
segurando uma conexão, uma thread e uma vaga no limite de taxa de outra pessoa, por um trabalho que vai
jogar fora. Cancelar `s` à mão quando `p` falha é possível, e precisa ser escrito, lembrado e mantido
correto em todo lugar que inicia duas tarefas.

O problema mais fundo é que **a relação entre as tarefas só existe na cabeça de quem programou**. O
código diz "inicie duas coisas"; não diz "estas duas são partes de um trabalho só, e o trabalho acaba
quando qualquer uma falha". Um dump de threads mostraria a thread virtual da consulta de estoque sem
nenhuma pista de a que requisição ela pertencia. A concorrência estruturada é a proposta de escrever
essa relação no código.
