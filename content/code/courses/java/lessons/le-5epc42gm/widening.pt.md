---
title: Alargamento, que o Java faz sozinho
version: 1
---

A lição 4 deu um tipo a cada valor. Valores encontram valores de outros tipos o tempo todo: uma
contagem `int` entra num total `long`, um preço `int` é dividido por uma taxa `double`. **O Java só
converte sozinho na direção que não pode estourar**, de um tipo menor para um maior, e isso se chama
**conversão de alargamento** (widening). A outra direção precisa que você diga, que é a seção 03.

## A direção segura

```java
// Widen.java
public class Widen {
    public static void main(String[] args) {
        int copies = 16_777_217;
        long asLong = copies;
        double asDouble = copies;
        float asFloat = copies;
        System.out.println(copies);
        System.out.println(asLong);
        System.out.println(asDouble);
        System.out.println(asFloat);
        System.out.println(asFloat == 16_777_216);
        char initial = 'J';
        int code = initial;
        System.out.println(code);
    }
}
```

```
ana@vm:~/convert$ java Widen.java
16777217
16777217
1.6777217E7
1.6777216E7
true
74
```

O mesmo `int`, 16.777.217, entrou num `long`, num `double` e num `float` sem cast escrito e sem
reclamação do compilador. `char` para `int` também é alargamento: `initial` virou 74, o código de
`J`. O `long` e o `double` guardaram o número exato; o `double` só o imprime em notação científica,
`1.6777217E7`, que quer dizer 1,6777217 × 10⁷.

**O `float` não o guardou.** Imprimiu `1.6777216E7`, um a menos, e a comparação na linha seguinte
confirmou que o valor na variável é 16.777.216. Um `float` tem 32 bits e gasta 24 deles com os
dígitos, então guarda todo número inteiro até 2²⁴, que é 16.777.216, e daí em diante só alguns.
**Uma conversão de alargamento nunca estoura, e algumas delas arredondam**: a faixa de um `float` é
muito maior que a de um `int`, e a precisão é menor.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"As conversões de alargamento que o Java faz sozinho, como setas da esquerda para a direita: byte para short para int para long para float para double, e char para int. Toda seta é automática. As setas tracejadas marcam as que podem arredondar o valor: int para float, e long para float ou double.\"><defs><marker id=\"jv6-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"jv6-b\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">byte</text><rect x=\"135\" y=\"70\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">short</text><rect x=\"250\" y=\"70\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"295\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">int</text><rect x=\"365\" y=\"70\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"410\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">long</text><rect x=\"480\" y=\"70\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"525\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">float</text><rect x=\"595\" y=\"70\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"640\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">double</text><path d=\"M110 87 H133\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv6-a)\"></path><path d=\"M225 87 H248\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv6-a)\"></path><path d=\"M340 87 H363\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv6-a)\"></path><path d=\"M455 87 H478\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" fill=\"none\" marker-end=\"url(#jv6-b)\"></path><path d=\"M570 87 H593\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv6-a)\"></path><rect x=\"250\" y=\"160\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"295\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">char</text><path d=\"M295 160 V106\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv6-a)\"></path><path d=\"M295 70 C 330 20, 480 20, 520 68\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\" fill=\"none\" marker-end=\"url(#jv6-b)\"></path><path d=\"M410 104 C 440 140, 600 140, 635 106\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\" fill=\"none\" marker-end=\"url(#jv6-b)\"></path><text x=\"408\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">int para float: pode perder dígitos</text><text x=\"520\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">long para float, e para double: pode perder dígitos</text><text x=\"360\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">toda seta é automática; as tracejadas podem arredondar o valor</text></svg>", "caption": "O alargamento só vai para a direita. A faixa sempre cabe; os dígitos nem sempre cabem, e foi assim que 16.777.217 virou 16.777.216."}
```

As setas vão num sentido só. Todo tipo à esquerda cabe em todo tipo à direita sem cast, `byte` em
`double` inclusive. As setas que arredondam são as três em que o destino tem menos dígitos que a
origem: `int` para `float`, `long` para `float` e `long` para `double`. Para dinheiro, contagens e
identificadores isso importa, e a lição 8 é sobre o que usar no lugar de um tipo de ponto flutuante
quando todo dígito precisa sobreviver.

O `boolean` não está em seta nenhuma. Não se converte em nada e nada se converte nele: `true` não é 1
em Java, e `if (count)` não compila.
