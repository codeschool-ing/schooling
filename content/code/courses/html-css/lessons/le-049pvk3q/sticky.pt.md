---
title: sticky: no fluxo até que fosse sair
version: 1
---

**`position: sticky`** é o híbrido. A caixa está no fluxo normal e ocupa o espaço dela, como uma static, **até que a rolagem a levasse para além da borda definida pelo inset**; aí ela gruda nessa borda, e fica ali até o fim do pai passar. Os meses da página de eventos têm títulos sticky, `top: 0`, e a seção de cada mês tem 900 pixels de altura:

```
ana@laptop:~/site$ probe fixed.html box h2
h2  x 0      y 0      width 1024   height 52
h2  x 0      y 900    width 1024   height 52
ana@laptop:~/site$ probe fixed.html scroll 500 box h2 top 100 20
h2  x 0      y 500    width 1024   height 52
h2  x 0      y 900    width 1024   height 52
at 100,20: h2  "October"
ana@laptop:~/site$ probe fixed.html scroll 880 box h2 top 100 20
h2  x 0      y 848    width 1024   height 52
h2  x 0      y 900    width 1024   height 52
at 100,20: h2  "November"
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"A janela de fixed.html em três posições de rolagem, com as duas seções de mês e os títulos fixos delas. Na rolagem 0 o título de outubro está no topo da página. Na rolagem 500 ele fica preso no topo da janela, em y 500 da página. Na rolagem 880 ele chegou ao fim da seção de 900 pixels e é empurrado para 848, enquanto o título de novembro chega ao topo.\"><text x=\"85\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">scroll 0</text><rect x=\"20\" y=\"30\" width=\"130\" height=\"130.56\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><rect x=\"28\" y=\"30\" width=\"114\" height=\"130.56\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"28\" y=\"30\" width=\"114\" height=\"8.84\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"156\" y=\"34.42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">h2 October</text><text x=\"321\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">scroll 500</text><rect x=\"256\" y=\"30\" width=\"130\" height=\"130.56\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><rect x=\"264\" y=\"30\" width=\"114\" height=\"68\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"264\" y=\"98\" width=\"114\" height=\"62.56\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"264\" y=\"30\" width=\"114\" height=\"8.84\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"392\" y=\"34.42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">h2 October</text><rect x=\"264\" y=\"98\" width=\"114\" height=\"8.84\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"392\" y=\"102.42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">h2 November</text><text x=\"557\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">scroll 880</text><rect x=\"492\" y=\"30\" width=\"130\" height=\"130.56\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><rect x=\"500\" y=\"30\" width=\"114\" height=\"3.4\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"500\" y=\"33.4\" width=\"114\" height=\"127.16\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"500\" y=\"30\" width=\"114\" height=\"3.4\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"500\" y=\"33.4\" width=\"114\" height=\"8.84\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"628\" y=\"37.82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">h2 November</text><text x=\"30\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Em 500 o título de outubro fica preso no topo da janela. Em 880 ele chegou ao fim da sua</text><text x=\"30\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">seção e é empurrado para cima, em 848, enquanto novembro chega ao topo.</text></svg>", "caption": "Um título sticky gruda dentro da própria seção, e sai junto com ela."}
```

No topo da página, os títulos estão onde o fluxo os pôs: outubro em 0, novembro em 900. Rolando até 500, o título de outubro está em **y 500 da página**, o topo da janela, e a linha de cima da janela continua sendo o título de outubro: ele grudou. Rolando até 880, ele está em **848**, não mais no topo da janela: a seção dele termina em 900 e o título de 52 pixels foi empurrado para cima junto, enquanto o título de novembro, em 900, chegou ao topo da janela e é o que fica ali.

**Uma caixa sticky nunca sai do pai.** É isso que a torna certa para títulos de seção: cada um fica visível enquanto você lê a seção dele e passa a vez para o próximo.

## Por que o sticky às vezes não faz nada

A reclamação mais comum sobre o sticky é que ele não gruda, e a causa mais comum é esta:

```
ana@laptop:~/site$ probe sticky-broken.html scroll 500 box h2
h2  x 0      y 0      width 1024   height 52
h2  x 0      y 900    width 1024   height 52
```

A mesma página com as seções envolvidas numa `<div>` que tem **`overflow: hidden`**, rolada até 500: o título continua em **0**. Não grudou. Uma caixa sticky gruda no ancestral **com rolagem** mais próximo, e `overflow: hidden`, `auto` ou `scroll` em qualquer ancestral transforma esse ancestral no escolhido, mesmo que ele próprio nunca role. O título grudou fielmente no topo de uma caixa que nunca se mexeu. A correção é tirar o `overflow`, ou usar `overflow: clip`, que corta o conteúdo que transborda sem criar um contêiner de rolagem.

As outras duas causas: **nenhum inset**, porque `position: sticky` sem `top` ou outro inset nunca gruda; e **um pai sem altura maior que a caixa sticky**, o que não lhe deixa espaço para se mover.
