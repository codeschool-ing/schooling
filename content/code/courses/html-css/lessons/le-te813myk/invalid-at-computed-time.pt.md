---
title: Quando uma variável guarda o tipo errado de valor
version: 1
---

A seção 02 da aula 5 disse que uma declaração que o navegador não entende é ignorada, e que a declaração anterior então se aplica. **Com `var()`, não é isso que acontece**, e a diferença pega todo mundo uma vez. O último parágrafo de `fallback.html` define a cor duas vezes:

```css
.wrong {
  color: #8a1c1c;
  color: var(--gap);
}
```

`--gap` é `24px`, um comprimento. Um comprimento não é uma cor. A expectativa óbvia é que a segunda declaração seja descartada e o parágrafo fique vermelho. Eis o que o navegador decidiu:

```
ana@laptop:~/site$ probe fallback.html rules .wrong color
.wrong (0,1,0)  color: #8a1c1c                  <style> in the page
.wrong (0,1,0)  color: var(--gap)               <style> in the page
computed color: rgb(47, 111, 78)
```

**O parágrafo é verde**, `rgb(47, 111, 78)`, a cor do `<main>`. O vermelho não foi usado, embora estivesse logo ali.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Por que .wrong saiu verde. No parsing, as duas declarações de color são aceitas, porque um var() não pode ser conferido até ser resolvido. Na cascata, a última, a linha que lê --gap, vence. No valor computado, --gap é 24px, não uma cor, então a declaração é inválida, e a declaração vermelha já perdeu. A propriedade passa a se comportar como unset, e a cor herda o verde do main.\"><defs><marker id=\"ah10\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"160\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">1. parsing</text><text x=\"196\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o vermelho é válido; a linha que lê --gap também é aceita,</text><text x=\"196\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">porque nada consegue conferir um var() antes de resolvê-lo.</text><line x1=\"100\" y1=\"58\" x2=\"100\" y2=\"74\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah10)\"></line><rect x=\"20\" y=\"76\" width=\"160\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">2. cascata</text><text x=\"196\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Os dois casam com .wrong em (0,1,0). A última vence:</text><text x=\"196\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a linha que lê --gap.</text><line x1=\"100\" y1=\"120\" x2=\"100\" y2=\"136\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah10)\"></line><rect x=\"20\" y=\"138\" width=\"160\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">3. valor computado</text><text x=\"196\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">--gap é 24px, que não é uma cor. A declaração é inválida</text><text x=\"196\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no momento do valor computado, e o vermelho já ficou para trás.</text><line x1=\"100\" y1=\"182\" x2=\"100\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah10)\"></line><rect x=\"20\" y=\"200\" width=\"160\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">4. resultado</text><text x=\"196\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">color se comporta como unset, e a cor é herdada:</text><text x=\"196\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o verde do main, rgb(47, 111, 78).</text></svg>", "caption": "Um valor reserva escrito antes na mesma regra não ajuda: quando o var() falha, ele já perdeu.", "same": ["1. parsing"]}
```

O motivo é o momento da conferência. Quando a folha de estilos é lida, `color: var(--gap)` não pode ser conferida: um `var()` pode guardar qualquer coisa, e o valor dele só é conhecido quando é usado num elemento específico. Então a declaração é aceita, a cascata roda, e a declaração posterior vence, exatamente como a seção 09 da aula 5 descreveu. Só então, quando o navegador calcula o valor para este elemento, ele encontra um comprimento onde devia haver uma cor. Nessa hora o vermelho já perdeu, e o navegador não pode voltar a ele. A declaração é **inválida no momento do valor computado** (*invalid at computed-value time*), e a propriedade se comporta como se fosse `unset`: uma propriedade herdada, como `color`, herda, e qualquer outra pega o valor inicial.

## O que decorre disso

**Um valor reserva dentro do `var()` é o que funciona**: `color: var(--gap, #8a1c1c)` teria saído vermelho, porque o valor reserva é usado quando a variável falta. Mas ele não é usado quando a variável tem o tipo errado; aí o resultado continua sendo o verde herdado. **A correção de verdade é usar cada variável para um só tipo de valor**, e dar nomes que deixem o tipo óbvio: `--color-accent`, `--space-2`, nunca um nome que possa guardar qualquer um dos dois.

Há um jeito de dizer o tipo ao navegador, `@property`, que registra uma propriedade personalizada com uma sintaxe como `<color>` e um valor inicial. Uma propriedade registrada com um valor errado passa a cair nesse valor inicial em vez de `unset`. É também o que permite animar uma propriedade personalizada, coisa de que a aula 12 não precisa. Para uma folha de tokens, nomes cuidadosos fazem a maior parte do trabalho.
