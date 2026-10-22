---
title: `for`, `while` e `do-while`
version: 1
---

Um laço executa um bloco de novo e de novo enquanto uma condição vale. O Java tem três tipos, e
**eles diferem numa coisa só: quando a condição é testada**. Escolher o certo é dizer para que o laço
serve, para que o leitor saiba já na primeira linha. Crie um diretório para esta lição, `~/loops`, e
salve isto como `Counting.java`:

```schooling-example
{
  "language": "java",
  "file": "Counting.java",
  "parts": [
    {
      "code": "public class Counting {\n    public static void main(String[] args) {\n        for (int i = 1; i <= 3; i++) {\n            System.out.println(\"copy \" + i);\n        }",
      "note": "**O `for` é para contar.** O cabeçalho dele tem três partes, separadas por ponto e vírgula: onde o `i` começa, o teste que mantém o laço rodando, e o que acontece depois de cada volta. Três voltas, de `copy 1` a `copy 3`."
    },
    {
      "code": "\n        int pages = 300;\n        int days = 0;\n        while (pages > 0) {\n            pages -= 70;\n            days++;\n        }\n        System.out.println(days + \" days, \" + pages + \" pages\");",
      "note": "**O `while` é para repetir até algo ficar verdadeiro**, quando ninguém sabe de antemão quantas voltas vai levar. Lendo 70 páginas por dia, um livro de 300 páginas leva 5 dias, e o contador termina em `-50`: o último dia precisava só de 50 páginas, e o laço subtraiu 70 mesmo assim."
    },
    {
      "code": "\n        int n = 0;\n        while (n < 0) {\n            System.out.println(\"never printed\");\n        }\n        do {\n            System.out.println(\"do-while ran once, n = \" + n);\n        } while (n < 0);",
      "note": "O mesmo teste, dois laços. **O `while` testa antes**, então, com o teste falso desde o início, o corpo rodou zero vezes. **O `do-while` testa depois do corpo**, então sempre roda pelo menos uma vez."
    },
    {
      "code": "\n        int count = 0;\n        for (int i = 0; i <= 3; i++) {\n            count++;\n        }\n        System.out.println(\"i from 0 to 3 inclusive: \" + count + \" passes\");\n    }\n}",
      "note": "O **erro de um a mais** (off-by-one). De 0 até 3, inclusive, são quatro valores, não três. `i <= 3` onde se queria `i < 3` roda uma volta a mais, e num array lê uma posição depois do fim, que é a exceção da lição 9."
    }
  ],
  "output": "copy 1\ncopy 2\ncopy 3\n5 days, -50 pages\ndo-while ran once, n = 0\ni from 0 to 3 inclusive: 4 passes\n"
}
```

## A ordem em que um `for` roda

O cabeçalho de um `for` se lê da esquerda para a direita, e não roda da esquerda para a direita. As
três partes dele rodam em três momentos diferentes:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 256\" role=\"img\" aria-label=\"A ordem em que um laço for roda. O inicializador, int i = 1, roda uma vez. Depois o teste, i <= 3, roda antes de cada volta: quando é verdadeiro o corpo roda, depois a atualização, i++, e o controle volta ao teste. Quando o teste é falso o laço termina. Como o teste vem antes do corpo, um teste falso logo de início roda o corpo zero vezes.\"><defs><marker id=\"jv11-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"150\" y=\"14\" width=\"420\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">for (int i = 1; i <= 3; i++) { body }</text><rect x=\"40\" y=\"90\" width=\"120\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">int i = 1</text><text x=\"100\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma vez, primeiro</text><rect x=\"220\" y=\"90\" width=\"120\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"280\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">i <= 3</text><text x=\"280\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">antes de cada volta</text><rect x=\"400\" y=\"90\" width=\"120\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">body</text><text x=\"460\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">se o teste deu verdadeiro</text><rect x=\"580\" y=\"90\" width=\"120\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"640\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">i++</text><text x=\"640\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">depois de cada volta</text><path d=\"M160 116 H218\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv11-a)\"></path><path d=\"M340 116 H398\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv11-a)\"></path><text x=\"369\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">true</text><path d=\"M520 116 H578\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv11-a)\"></path><path d=\"M640 142 V176 H280 V144\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv11-a)\"></path><text x=\"460\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">de volta ao teste</text><path d=\"M280 90 V66 H700 V200\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv11-a)\" stroke-dasharray=\"5 4\"></path><text x=\"500\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">falso: sai do laço</text><rect x=\"40\" y=\"212\" width=\"640\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"227\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">testado antes do corpo, então um teste falso logo de início roda o corpo zero vezes</text></svg>", "caption": "As três partes do cabeçalho de um for rodam em três momentos diferentes. Um laço while é o mesmo diagrama, com a primeira e a última caixa fora do cabeçalho."}
```

Então `for (int i = 1; i <= 3; i++)` roda o teste quatro vezes e o corpo três: o quarto teste
encontra `i` valendo 4 e encerra o laço. E **o `i` só existe dentro do laço**. Declarado no
cabeçalho, ele some junto com o laço, que é o escopo da lição 5, e o laço seguinte pode declarar o
seu próprio `i`.

Todo `for` pode ser reescrito como um `while`, levando a primeira parte para cima do laço e a
terceira para o fim do corpo. O motivo para manter o `for` é que as três partes ficam numa linha só,
onde o leitor as confere juntas. **Use `for` quando estiver contando, e `while` quando estiver
esperando** uma condição, como um livro com páginas por ler.

## Um laço que nunca termina

Se nada no corpo empurra a condição para `false`, o laço roda até alguém pará-lo. Este esquece de
somar 1 ao `i`:

```java
// Forever.java
public class Forever {
    public static void main(String[] args) {
        int i = 0;
        while (i < 10) {
            System.out.println("i = " + i);
        }
    }
}
```

```
ana@vm:~/loops$ javac Forever.java && timeout 1 java Forever | head -3
i = 0
i = 0
i = 0
ana@vm:~/loops$ timeout 1 java Forever | wc -l
514426
```

O `timeout 1` é um comando do Linux que para um programa depois de um segundo, usado aqui porque uma
transcrição não consegue apertar uma tecla. **No seu terminal, `Ctrl+C` o para.** Naquele um segundo
o programa imprimiu 514.426 linhas, todas `i = 0`, e a contagem muda a cada execução. Um laço sem fim
é o tipo de bug que aparece como um programa que simplesmente nunca responde; a primeira coisa a ler
é o que, dentro do laço, deveria mudar a condição.
