---
title: Ponto flutuante, e por que 0.1 + 0.2 não é 0.3
version: 1
---

A crença comum é que um `double` guarda um número decimal com uns dezesseis dígitos, então `0.1` é
um décimo. **Um `double` guarda uma fração binária, e um décimo não tem forma binária exata**, pelo
mesmo motivo que um terço não tem forma decimal exata. O valor guardado para `0.1` é a fração binária
mais próxima, um pouquinho acima de um décimo, e a aritmética com esses valores carrega os pequenos
erros junto. Na maior parte do tempo eles ficam invisíveis, abaixo dos dígitos que o `println`
mostra. Às vezes aparecem:

```java
// Floats.java
public class Floats {
    public static void main(String[] args) {
        System.out.println(0.1 + 0.2);
        System.out.println(0.1 + 0.2 == 0.3);
        System.out.println(Math.abs((0.1 + 0.2) - 0.3) < 1e-9);
        System.out.println(new java.math.BigDecimal(0.3));
        System.out.println(new java.math.BigDecimal(0.1 + 0.2));

        double total = 0;
        for (int k = 0; k < 10; k++) {
            total += 0.1;
        }
        System.out.println(total);

        System.out.println(1.0 / 0);
        System.out.println(-1.0 / 0);
        double nan = 0.0 / 0;
        System.out.println(nan);
        System.out.println(nan == nan);
        System.out.println(Double.isNaN(nan));
        System.out.println(0.0 == -0.0);
        System.out.println(1 / -0.0);

        System.out.println(1 / 0);
    }
}
```

```
ana@vm:~/maths$ java Floats.java
0.30000000000000004
false
true
0.299999999999999988897769753748434595763683319091796875
0.3000000000000000444089209850062616169452667236328125
0.9999999999999999
Infinity
-Infinity
NaN
false
true
true
-Infinity
Exception in thread "main" java.lang.ArithmeticException: / by zero
	at Floats.main(Floats.java:25)
```

A primeira linha é a famosa. `0.1 + 0.2` imprimiu `0.30000000000000004`, e **o `==` contra `0.3`
disse `false`**. As duas linhas depois do `true` imprimem os valores exatos envolvidos, entregando os
`double` ao `BigDecimal`, que é o assunto da seção 05; aqui ele só mostra todos os dígitos. O literal
`0.3` é guardado um fio abaixo de três décimos, e a soma cai um fio acima:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma reta numérica perto de 0,3. O literal 0.3 é guardado como o double 0,29999999999999998889, logo abaixo do 0,3 real. A soma 0.1 + 0.2 cai no double seguinte, 0,30000000000000004440. Não há double entre os dois, então a comparação 0.1 + 0.2 == 0.3 dá falso.\"><path d=\"M40 120 H680\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60 112 V128\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M200 112 V128\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M520 112 V128\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M660 112 V128\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M200 104 V136\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M520 104 V136\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M360 112 V128\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\" fill=\"none\"></path><text x=\"360\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o 0,3 real, que nenhum double guarda</text><text x=\"360\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0.3</text><rect x=\"40\" y=\"24\" width=\"320\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">0.3 no código</text><text x=\"200\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0.29999999999999998889…</text><rect x=\"380\" y=\"24\" width=\"300\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"530\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">0.1 + 0.2</text><text x=\"530\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0.30000000000000004440…</text><rect x=\"40\" y=\"170\" width=\"640\" height=\"64\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dois doubles vizinhos, sem nenhum outro double no meio</text><text x=\"360\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0.1 + 0.2 arredonda para o da direita, então não é == 0.3</text></svg>", "caption": "O double mais próximo de 0,3 e a soma 0.1 + 0.2 são vizinhos. Os dois valores são os que o BigDecimal imprimiu acima, cortados na vigésima casa decimal."}
```

## Comparando com uma tolerância

Então o `==` entre `double` calculados faz uma pergunta que a aritmética não consegue responder com
segurança. **Compare a distância entre eles com uma tolerância**: `Math.abs(a - b) < 1e-9` imprimiu
`true`. `1e-9` é um bilionésimo, escrito em notação científica, e o tamanho certo depende dos
números: um bilionésimo é minúsculo perto de um preço e enorme perto da largura de um átomo. Somar
`0.1` dez vezes mostra a mesma coisa pelo outro lado: o total saiu `0.9999999999999999`, e um laço
que rodasse `while (total != 1.0)` nunca pararia.

## Os valores que não são números

A divisão inteira por zero não tem resposta, e a linha 25, `1 / 0`, parou o programa com
`ArithmeticException: / by zero`. **A divisão por zero em ponto flutuante não para nada.** Ela tem
respostas, definidas pelo padrão IEEE 754 que os processadores seguem:

| expressão | imprimiu | |
|---|---|---|
| `1.0 / 0` | `Infinity` | grande demais para guardar, do lado positivo |
| `-1.0 / 0` | `-Infinity` | o mesmo do lado negativo |
| `0.0 / 0` | `NaN` | não é um número: não existe resposta |
| `nan == nan` | `false` | **NaN é diferente de tudo, inclusive dele mesmo** |
| `Double.isNaN(nan)` | `true` | o único teste confiável |
| `0.0 == -0.0` | `true` | dois zeros, iguais entre si |
| `1 / -0.0` | `-Infinity` | e mesmo assim dividem de jeitos diferentes |

Um `NaN` se espalha em silêncio: qualquer conta com ele dá `NaN`, e toda comparação com ele dá
`false`, então uma ordenação ou um `max` que encontra um dá respostas que parecem erradas e não lançam
nada. **Quando um cálculo pode produzir um, teste com `Double.isNaN` onde ele é produzido**, antes
que chegue a qualquer outro lugar.
