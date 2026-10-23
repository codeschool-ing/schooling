---
title: O que é uma thread virtual
version: 1
---

**Uma thread virtual é uma `java.lang.Thread` que a própria JVM escalona, em vez de entregá-la ao
sistema operacional.** Ela tem pilha, nome, estado, interrupção e tudo o mais que as aulas 11 a 16
usaram. O que ela não tem é uma thread do sistema operacional só sua. Um pequeno pool de threads comuns,
chamadas **portadoras** (carriers), roda as threads virtuais: uma thread virtual fica **montada** numa
portadora enquanto roda, e quando bloqueia, num `sleep`, num lock, num socket ou numa fila, a JVM a
**desmonta**, guarda a pilha dela no heap e entrega a portadora a outra thread virtual. O Projeto Loom as
construiu, e elas viraram parte padrão do Java no Java 21.

```java
// Virtual.java: a virtual thread, its carrier, and the carrier it comes back on
import java.time.Duration;

public class Virtual {
    public static void main(String[] args) throws InterruptedException {
        Thread v = Thread.ofVirtual().name("lookup").start(() -> {
            System.out.println("before sleep: " + Thread.currentThread());
            try {
                Thread.sleep(Duration.ofMillis(100));
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            System.out.println("after sleep:  " + Thread.currentThread());
            System.out.println("virtual: " + Thread.currentThread().isVirtual());
        });
        v.join();
        System.out.println("main is virtual: " + Thread.currentThread().isVirtual());
    }
}
```

```
ana@vm:~/fp/virtual$ java Virtual.java
before sleep: VirtualThread[#24,lookup]/runnable@ForkJoinPool-1-worker-1
after sleep:  VirtualThread[#24,lookup]/runnable@ForkJoinPool-1-worker-1
virtual: true
main is virtual: false
```

`Thread.currentThread()` imprimiu o nome da thread virtual e, depois do `@`, a portadora que a roda: um
worker de um pool fork-join próprio, não o pool comum da aula 9. **O mesmo código, a mesma API de
`Thread`**, e o `isVirtual()` é o único jeito de o código perceber. A `main` é uma thread de plataforma,
como sempre foi.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"O tempo corre da esquerda para a direita em duas threads portadoras. Na portadora 1, a thread virtual A roda e depois bloqueia; enquanto A espera no heap, B roda na portadora 1. Na portadora 2, C roda, e depois A retoma ali quando a espera acaba. Embaixo, uma caixa chamada heap guarda as pilhas das threads virtuais que esperam.\"><defs><marker id=\"carriers-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">portadora 1</text><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">portadora 2</text><rect x=\"120\" y=\"22\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">A roda</text><rect x=\"300\" y=\"22\" width=\"180\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">B roda</text><rect x=\"120\" y=\"92\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">C roda</text><rect x=\"400\" y=\"92\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">A retoma</text><rect x=\"240\" y=\"170\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"350.0\" y=\"186.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">heap</text><text x=\"350.0\" y=\"203.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a pilha de A, enquanto A dorme</text><path d=\"M270 58 L300 166\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#carriers-ah-phosphor)\"></path><path d=\"M420 166 L470 132\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#carriers-ah-phosphor)\"></path></svg>", "caption": "Uma thread virtual que espera não segura portadora; ela retoma em qualquer portadora livre."}
```

## Montada, desmontada

O que importa na figura é o espaço em branco. Enquanto uma thread virtual espera, **ela não ocupa
portadora nenhuma**: a pilha dela é um objeto no heap, menos de um kilobyte para uma pilha de chamadas
rasa, como mede a próxima seção, e a portadora está rodando outra. Quando a espera acaba, a thread
virtual volta para uma fila e é montada na próxima portadora livre, que pode ser outra. O escalonador tem
tantas portadoras quanto a máquina tem processadores, quatro aqui, porque portadoras existem para
calcular, e só calcular precisa de processador.
