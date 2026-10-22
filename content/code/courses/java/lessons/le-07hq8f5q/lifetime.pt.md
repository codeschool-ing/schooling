---
title: Tempo de vida, e a pilha onde as locais moram
version: 1
---

Escopo é sobre onde um nome pode ser **visto**, no código-fonte. Tempo de vida é sobre quanto tempo o
valor **existe**, enquanto o programa roda. Para uma variável local os dois coincidem, e o motivo é
onde as locais ficam guardadas.

Cada vez que um método é chamado, a JVM dá à chamada um **quadro** (frame): um pequeno bloco de
memória com os parâmetros e as variáveis locais daquela chamada. Os quadros se empilham numa
**pilha** (stack), uma por thread, com a chamada atual no topo. Quando o método retorna, o quadro dele
é removido e tudo o que estava nele some. **Uma variável local vive exatamente o tempo da chamada que a
declarou**, e uma segunda chamada ao mesmo método ganha um quadro novo, com cópias novas das locais.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 286\" role=\"img\" aria-label=\"A pilha da thread main desenhada como uma pilha de quadros: main embaixo, com args, depois dive(1), dive(2) e dive(3), cada um com o seu level, e acima deles o espaço que sobra, cerca de 1 MB ao todo. Cada chamada empilha um quadro com os seus parâmetros e locais; retornar o desempilha e as locais somem; quando não há espaço para o próximo quadro a JVM lança StackOverflowError.\"><rect x=\"40\" y=\"20\" width=\"300\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"190\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a pilha da thread main</text><rect x=\"60\" y=\"216\" width=\"260\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">main</text><text x=\"250\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">args</text><rect x=\"60\" y=\"176\" width=\"260\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">dive(1)</text><text x=\"250\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">level = 1</text><rect x=\"60\" y=\"136\" width=\"260\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">dive(2)</text><text x=\"250\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">level = 2</text><rect x=\"60\" y=\"96\" width=\"260\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">dive(3)</text><text x=\"250\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">level = 3</text><rect x=\"60\" y=\"56\" width=\"260\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"190\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">espaço livre, cerca de 1 MB ao todo</text><text x=\"520\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cada chamada empilha um quadro</text><text x=\"520\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">com os seus parâmetros e locais</text><text x=\"520\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">retornar o desempilha,</text><text x=\"520\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">e as locais dele somem</text><text x=\"520\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sem espaço para o próximo quadro:</text><text x=\"520\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">StackOverflowError</text></svg>", "caption": "Uma variável local vive no quadro do seu método, e o quadro vive exatamente o tempo da chamada. O Depth chegou ao topo depois de uns vinte e três mil deles."}
```

## Ficando sem pilha

A pilha tem tamanho fixo, então uma cadeia de chamadas que nunca retorna acaba ficando sem espaço. Um
método que chama a si mesmo, o que se chama **recursão**, é o jeito fácil de montar essa cadeia:

```java
// Depth.java
public class Depth {
    static int deepest = 0;

    static void dive(int level) {
        deepest = level;
        dive(level + 1);
    }

    public static void main(String[] args) {
        try {
            dive(1);
        } catch (StackOverflowError e) {
            System.out.println("frames before the stack ran out: " + deepest);
        }
    }
}
```

O `dive` anota a profundidade e chama a si mesmo um nível mais fundo, para sempre. Cada chamada
acrescenta um quadro, e quando não há espaço para o próximo a JVM lança `StackOverflowError`. As
lições 36 a 38 são sobre `try` e `catch`; aqui o `catch` é o que deixa o `main` imprimir a
profundidade em vez de morrer com um rastro de pilha.

```
ana@vm:~/scope$ javac Depth.java
ana@vm:~/scope$ java Depth
frames before the stack ran out: 23254
ana@vm:~/scope$ java Depth
frames before the stack ran out: 23254
ana@vm:~/scope$ java -Xss256k Depth
frames before the stack ran out: 1646
ana@vm:~/scope$ java -Xss4m Depth
frames before the stack ran out: 100048
```

**23.254 quadros na pilha padrão**, e o mesmo número duas vezes seguidas nesta máquina. O `-Xss`
define o tamanho da pilha de cada thread, que no Linux de 64 bits tem 1 MB por padrão. Com 256 KB a
cadeia quebrou depois de 1.646 chamadas, e com 4 MB chegou a 100.048. Os números não são
proporcionais aos tamanhos, e parte do motivo é o JIT da lição 1. Quadros de código interpretado e
quadros de código compilado não têm o mesmo tamanho, e quanto do `dive` foi compilado antes de a pilha
encher depende de quanto tempo ele rodou.

Um programa de verdade quase nunca precisa de uma pilha maior. Um `StackOverflowError` quase sempre
quer dizer uma recursão sem jeito de parar, como aqui, ou uma que para tarde demais, e a correção está
no código.

## O que sobrevive a uma chamada

Variáveis locais guardam primitivos e referências. Quando um método cria um **objeto**, com `new`, o
objeto não fica no quadro: ele mora numa área separada chamada **heap**, e a local guarda só uma
referência a ele. Então o quadro pode sumir enquanto o objeto fica, desde que alguma outra coisa ainda
se refira a ele: um campo, ou o valor que o método devolveu. A lição 12 desenha as duas áreas lado a
lado, e a lição 19 é sobre o que acontece com um objeto a que ninguém mais se refere.
