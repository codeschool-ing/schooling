---
title: Uma flag que ninguém vê
version: 1
---

**Quando uma thread escreve num campo e outra o lê, o Java não promete que quem lê veja algum dia o
valor novo, a não ser que algo no programa crie essa promessa.** Essa frase é a aula inteira, e ela
contradiz a imagem que a maioria dos programadores carrega: uma memória só, com todas as threads
olhando para ela. A imagem está errada de um jeito que dá para rodar:

```java
// Stop.java: a worker that waits for a flag, and a main thread that sets it
public class Stop {
    static boolean stop = false;

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
ana@vm:~/fp/memory$ java Stop.java
main set stop = true
worker still running after 3 s: true
```

A `main` pôs `stop` em `true` e disse isso. **O worker nunca percebeu**: três segundos depois ele
ainda girava, e teria girado para sempre se o `System.exit` não tivesse encerrado o programa. A linha
que devia informar o número de voltas nunca foi impressa.

## O compilador tinha permissão para isso

O corpo do laço lê `stop` e não faz nada que possa mudá-lo. Nada no programa diz que outra thread
pode mudá-lo também. Então o compilador just-in-time, quando o laço ficou quente, tinha o direito de
ler `stop` uma vez, guardar o valor num registrador e transformar o laço em `while (true)`. **Isso não
é um bug da JVM; é uma otimização que a linguagem permite explicitamente**, e a mesma liberdade é o
que deixa um laço de uma thread só rodar rápido. `-Xint` roda o mesmo programa com o JIT desligado,
cada bytecode interpretado:

```
ana@vm:~/fp/memory$ java -Xint Stop.java
main set stop = true
worker saw stop after 160503205 spins
worker still running after 3 s: false
```

Interpretado, o laço leu o campo a cada volta e viu a mudança. **O mesmo código-fonte está certo ou
trava dependendo de como a JVM escolheu rodá-lo**, e é exatamente isso que faz esse tipo de bug
sobreviver aos testes: depende de quão quente está o código, do processador e da versão do
compilador.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Duas threads em dois núcleos. A main escreve stop = true no campo compartilhado na memória. O laço compilado do worker leu stop uma vez para um registrador e continua testando o registrador, que ainda diz false, então nunca lê o campo de novo e nunca vê o valor novo.\"><defs><marker id=\"cache-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"cache-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"cache-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"220\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">main</text><text x=\"130.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">stop = true</text><rect x=\"480\" y=\"20\" width=\"220\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">worker</text><text x=\"590.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">while (!register)</text><rect x=\"250\" y=\"140\" width=\"220\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">memória compartilhada</text><text x=\"360.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">stop = true</text><rect x=\"530\" y=\"140\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">registrador</text><text x=\"590.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">false</text><path d=\"M130 90 L130 170 L246 170\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#cache-ah-phosphor)\"></path><path d=\"M590 90 L590 136\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#cache-ah-amber)\" marker-start=\"url(#cache-ah-amber)\"></path><path d=\"M470 160 L520 160\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#cache-ah-paperdim)\"></path><text x=\"495\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lido uma vez</text></svg>", "caption": "Nada obrigava o worker a ler o campo de novo, então o compilador ficou com o primeiro valor que leu."}
```

O conserto é uma palavra, `volatile`, no campo, e a aula 13 trata do que essa palavra promete e do que
não promete. Antes de chegar a ela, a próxima seção mostra a segunda metade do problema: não só se uma
escrita é vista, mas em que ordem.
