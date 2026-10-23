---
title: Alcançável ou lixo
version: 1
---

O Java não tem `delete`. Um programa pede memória com `new` e nunca a devolve, e uma parte separada da
JVM, o **coletor de lixo** (garbage collector), decide quando essa memória pode ser usada de novo. A
imagem comum é a de um coletor que libera os objetos "quando você para de usá-los". **Ele libera os
objetos que nada consegue mais alcançar**, que é uma regra mais estreita e bem mais útil, porque dá
para conferir.

## A regra

Um objeto é **alcançável** se uma cadeia de referências leva até ele a partir de uma **raiz**: uma
variável local de um método que ainda está rodando, um atributo estático, e algumas coisas dentro da
JVM. Todo outro objeto é lixo, e o coletor pode reaproveitar a memória dele quando quiser.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Raízes à esquerda: uma variável local do main chamada pages, e o atributo estático latest. pages aponta para um ArrayList, que aponta para dois arrays de bytes; latest aponta para um array de bytes. Esses quatro objetos são alcançáveis e ficam. À direita, um Loan que aponta para um Book, sem seta alguma chegando a eles de uma raiz: os dois são inalcançáveis, e lixo.\"><defs><marker id=\"jv19-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"16\" y=\"20\" width=\"170\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"101\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">raízes</text><rect x=\"30\" y=\"60\" width=\"142\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"101\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">main: pages</text><rect x=\"30\" y=\"120\" width=\"142\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"101\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">static latest</text><text x=\"101\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">variáveis locais de</text><text x=\"101\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">métodos rodando,</text><text x=\"101\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">atributos estáticos</text><rect x=\"230\" y=\"50\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"290\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ArrayList</text><rect x=\"400\" y=\"30\" width=\"100\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">byte[]</text><rect x=\"400\" y=\"76\" width=\"100\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">byte[]</text><rect x=\"230\" y=\"124\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"290\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">byte[]</text><path d=\"M172 80 H228\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv19-a)\"></path><path d=\"M350 64 L398 49\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv19-a)\"></path><path d=\"M350 76 L398 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv19-a)\"></path><path d=\"M172 140 H228\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv19-a)\"></path><text x=\"450\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">alcançável: fica</text><rect x=\"540\" y=\"150\" width=\"164\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><rect x=\"560\" y=\"170\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Loan</text><rect x=\"560\" y=\"212\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Book</text><text x=\"622\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">inalcançável: lixo</text><text x=\"622\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sem caminho a partir de uma raiz</text><path d=\"M620 202 V210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv19-a)\"></path></svg>", "caption": "O coletor parte das raízes e segue cada referência. O que ele alcança fica; o que ele nunca alcança é memória livre, por mais que os objetos ali dentro apontem uns para os outros."}
```

Essa é a única regra. Um objeto que você nunca mais vai usar fica guardado enquanto algo alcançável
ainda apontar para ele, e o `this$0` escondido da lição 17 era um jeito de isso acontecer sem ninguém
perceber. Um objeto sem caminho a partir de uma raiz vai embora mesmo que cem outros objetos
inalcançáveis apontem para ele.

## Alocar muito mais do que o heap comporta

`Churn` pede dois milhões de arrays de um kilobyte cada, quase 2 GB, num heap limitado a 32 MB pelo
`-Xmx32m`. Ele guarda só o mais novo, num atributo estático:

```java
// Churn.java
public class Churn {
    static byte[] latest;

    public static void main(String[] args) {
        long total = 0;
        for (int i = 0; i < 2_000_000; i++) {
            latest = new byte[1024];
            total += latest.length;
        }
        System.out.println("allocated " + total / (1024 * 1024) + " MB, holding one page at a time");
    }
}
```
```
ana@vm:~/lifecycle$ javac Churn.java Hoard.java Request.java
ana@vm:~/lifecycle$ java -Xmx32m Churn
allocated 1953 MB, holding one page at a time
```

A linha do `javac` compilou de uma vez os três programas desta seção, então salve os outros dois,
mostrados abaixo, antes de digitá-la. **Funcionou, num heap sessenta vezes menor do que o que ele
alocou**, porque cada array virou lixo no instante em que o seguinte o substituiu em `latest`. O
`-Xlog:gc` faz o coletor relatar cada vez que roda:

```
ana@vm:~/lifecycle$ java -Xmx32m -Xlog:gc Churn > gc.log; head -4 gc.log
[0.004s][info][gc] Using G1
[0.112s][info][gc] GC(0) Pause Young (Normal) (G1 Evacuation Pause) 18M->1M(32M) 2.649ms
[0.114s][info][gc] GC(1) Pause Young (Normal) (G1 Evacuation Pause) 14M->1M(32M) 0.411ms
[0.117s][info][gc] GC(2) Pause Young (Normal) (G1 Evacuation Pause) 18M->1M(32M) 0.784ms
ana@vm:~/lifecycle$ grep -c Pause gc.log
111
```

Cada linha é uma **pausa**, um momento em que o programa parou enquanto o coletor trabalhava.
`18M->1M(32M)` se lê assim: 18 MB em uso antes, 1 MB depois, num heap de 32 MB. O coletor é o **G1**,
o padrão da JVM numa máquina como esta, e ele rodou 111 vezes nessa execução; os tempos e a contagem
mudam a cada execução e a cada máquina. Cada pausa encontrou quase tudo morto, e limpar objetos
mortos é o que um coletor assim faz mais depressa.

## Quando acaba

`Hoard` guarda tudo, numa lista presa a uma variável local do `main`:

```java
// Hoard.java
import java.util.ArrayList;
import java.util.List;

public class Hoard {
    public static void main(String[] args) {
        List<byte[]> pages = new ArrayList<>();
        while (true) {
            pages.add(new byte[1024 * 1024]);
        }
    }
}
```
```
ana@vm:~/lifecycle$ java -Xmx32m Hoard; echo $?
Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
	at Hoard.main(Hoard.java:9)
1
```

**`OutOfMemoryError: Java heap space`** (acabou o espaço do heap): cada megabyte continuava alcançável
por meio de `pages`, então o coletor não pôde liberar nada, e a JVM desistiu na linha que pediu mais
um. É um `Error`, não uma `Exception`, e a lição 38 diz por que um programa não deve tentar capturá-lo.
Quando você o encontra, a pergunta nunca é primeiro "como consigo mais memória". É **o que ainda está
segurando referências que deveria ter soltado**, e a resposta costuma ser uma coleção que só cresce.

## `System.gc()` é um pedido

`System.gc()` pede à JVM que colete agora. A JVM pode dizer não:

```java
// Request.java
public class Request {
    public static void main(String[] args) {
        byte[][] junk = new byte[8][];
        for (int i = 0; i < junk.length; i++) {
            junk[i] = new byte[1024 * 1024];
        }
        junk = null;
        System.gc();
        System.out.println("asked");
    }
}
```
```
ana@vm:~/lifecycle$ java -Xlog:gc Request
[0.003s][info][gc] Using G1
[0.054s][info][gc] GC(0) Pause Full (System.gc()) 18M->1M(14M) 10.252ms
asked
ana@vm:~/lifecycle$ java -XX:+DisableExplicitGC -Xlog:gc Request
[0.003s][info][gc] Using G1
asked
```

A primeira execução fez uma **`Pause Full (System.gc())`**, uma coleta completa do heap inteiro, que
levou muito mais tempo que qualquer pausa jovem do `Churn`. A segunda rodou com
`-XX:+DisableExplicitGC`, uma configuração que servidores usam justamente para ignorar essa chamada,
e coleta nenhuma aconteceu. Mesmo programa, mesma chamada. **Um programa que precisa do
`System.gc()` para funcionar direito está errado**, porque nada promete que a chamada faça alguma
coisa, e um que a chama por velocidade costuma ficar mais lento por isso.
