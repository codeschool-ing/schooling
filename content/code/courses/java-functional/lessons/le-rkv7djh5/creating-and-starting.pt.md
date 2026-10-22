---
title: Criando e iniciando uma thread
version: 1
---

**Uma thread é uma linha de execução separada dentro do mesmo programa: com a sua própria pilha de
chamadas, rodando ao mesmo tempo que as outras, compartilhando os mesmos objetos.** Todo programa Java
já tem uma, a `main`. As aulas 11 a 18 tratam de acrescentar outras, e do que dá errado quando várias
mexem nos mesmos dados.

Uma thread roda um `Runnable`, a interface funcional da aula 2 com um método, `run`. Então um lambda é
tudo o que é preciso para descrever o trabalho:

```java
// First.java: a thread started, a thread run by mistake, and waiting for one to finish
public class First {
    static void report(String what) {
        System.out.println(what + " on " + Thread.currentThread().getName());
    }

    public static void main(String[] args) throws InterruptedException {
        Thread worker = new Thread(() -> report("work"));
        worker.start();
        worker.join();

        Thread mistake = new Thread(() -> report("run() instead of start()"));
        mistake.run();

        Thread named = Thread.ofPlatform().name("invoice-", 1).start(() -> report("builder"));
        named.join();

        report("main finishes");
    }
}
```

```
ana@vm:~/fp/threads$ java First.java
work on Thread-0
run() instead of start() on main
builder on invoice-1
main finishes on main
```

## `start`, não `run`

`worker.start()` pediu à JVM uma thread nova, e o trabalho saiu em `Thread-0`, o nome padrão da
primeira thread que um programa cria. **`mistake.run()` não iniciou nada**: `run` é um método comum de
`Thread`, então chamá-lo rodou o lambda ali mesmo, na `main`, como qualquer outra chamada de método.
Nada falhou. O programa simplesmente não era concorrente, e numa máquina rápida ninguém notaria até o
trabalho ficar lento. `start` é o único método que cria a thread; `run` é o que a thread nova chama
quando passa a existir.

## Esperando com `join`

`worker.join()` fez a `main` esperar até `worker` terminar. Sem ele, a `main` seguiria na hora, e a
saída das duas threads poderia sair em qualquer ordem, decidida pelo escalonador do sistema
operacional de uma execução para outra. **O `join` é a forma mais simples de coordenação**: uma
thread esperando outra acabar. Ele lança `InterruptedException`, uma exceção checada que a seção 03
explica, e é por isso que a `main` a declara.

## O builder

`Thread.ofPlatform()`, que chegou no Java 21, monta threads com uma API fluente (aula 26 do `java`).
`.name("invoice-", 1)` dá às threads que inicia os nomes `invoice-1`, `invoice-2` e assim por diante,
e um dump de threads cheio de `invoice-7` diz muito mais que um cheio de `Thread-7`. O nome
**platform** está lá para distinguir estas threads das threads virtuais da aula 17, que o mesmo
builder faz com `Thread.ofVirtual()`. Toda thread desta aula é uma thread de plataforma: uma thread do
sistema operacional, com um objeto Java na frente.
