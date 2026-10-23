---
title: O conserto da flag
version: 1
---

**Um campo declarado `volatile` precisa ser lido da memória toda vez que o código o lê, e escrito na
memória toda vez que o código o escreve.** O compilador não pode guardá-lo num registrador ao longo de
um laço, e o processador não pode deixar uma leitura posterior passar à frente dele. Era exatamente o
que faltava em `Stop.java` na aula 12, e o conserto é uma palavra na declaração:

```java
// VolatileStop.java: lesson 12's flag, declared volatile
public class VolatileStop {
    static volatile boolean stop = false;

    public static void main(String[] args) throws InterruptedException {
        Thread worker = new Thread(() -> {
            long spins = 0;
            while (!stop) {
                spins++;
            }
            System.out.println("worker saw stop after " + spins + " spins");
        });
        worker.start();
        Thread.sleep(1000);
        stop = true;
        System.out.println("main set stop = true");
        worker.join(3000);
        System.out.println("worker still running after 3 s: " + worker.isAlive());
        System.exit(0);
    }
}
```

```
ana@vm:~/fp/volatile$ java VolatileStop.java
main set stop = true
worker saw stop after 3676553062 spins
worker still running after 3 s: false
```

O worker percebeu a escrita e terminou, e o `join` da `main` voltou na hora em vez de esperar os três
segundos. **O programa agora está correto pelas regras da linguagem**, e não pela sorte de como a JVM
o rodou, então se comporta igual interpretado, compilado, no x86 e no ARM.

Compare as contagens de voltas. O worker da aula 12, rodado com `-Xint`, deu cerca de 160 milhões de
voltas em um segundo; este, compilado e com uma leitura `volatile` a cada volta, deu cerca de 3,7
bilhões. **A leitura `volatile` não deixou o laço lento**: no x86 ela custa pouco mais que uma leitura
comum, porque o processador já mantém as leituras em ordem. O que o `volatile` tirou foi só a liberdade
do compilador de ler o campo uma vez, que é exatamente a liberdade que quebrou o programa.
