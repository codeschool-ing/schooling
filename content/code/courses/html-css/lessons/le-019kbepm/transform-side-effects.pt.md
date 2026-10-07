---
title: Duas coisas que um transform também faz
version: 1
---

Um transform faz mais duas coisas que surpreendem as pessoas, e a aula 7 apontou para as duas.

## Vira o bloco de contenção dos descendentes fixos

A seção 06 da aula 7 disse que um elemento `position: fixed` é posicionado em relação à janela. **A não ser que um ancestral tenha um transform**: aí esse ancestral vira o bloco de contenção, e o elemento "fixo" se move com ele. Aqui estão dois avisos idênticos, `position: fixed; bottom: 16px; right: 16px`, um na página e um dentro de um painel com `transform: translateX(0)`, um transform que não move nada:

```
ana@laptop:~/site$ probe fixed.html box .toast scroll 600 box .toast
p.toast.outside  x 808    y 696    width 200    height 40
p.toast.inside   x 808    y 228    width 200    height 40
p.toast.outside  x 808    y 1296   width 200    height 40
p.toast.inside   x 808    y 228    width 200    height 40
```

Antes da rolagem, o aviso de fora está em y **696**, no pé da janela, e o de dentro em y **228**, no pé do painel de 300 pixels. Depois de rolar 600, o aviso de fora está em **1296**: ainda no pé da janela, como o fixed promete. O de dentro continua em **228**, e rolou embora com a página. Um transform em qualquer ancestral, mesmo um que não muda nada visível, faz isso. Quando um cabeçalho fixo ou um modal deixa de ser fixo, procure um transform, um `filter` ou um `will-change: transform` acima dele.

## Cria um contexto de empilhamento

A seção 08 da aula 7 mostrou que um contexto de empilhamento prende o `z-index` de tudo dentro dele. Um transform cria um. Um cartão tem um menu com `z-index: 100`, e o cartão seguinte tem `z-index: 1`. Com o primeiro cartão levantado por um `translateY` de 4 pixels, e sem:

```
ana@laptop:~/site$ probe stack.html top 100 140
at 100,140: div.next  "Book swap"
ana@laptop:~/site$ probe flat.html top 100 140
at 100,140: div.menu  "Share · Save · Report"
```

Com o transform, o ponto onde o menu fica por cima do cartão seguinte mostra **o cartão seguinte**: o 100 do menu só vale dentro do contexto de empilhamento do cartão levantado, e esse contexto inteiro é desenhado abaixo de um irmão com `z-index: 1`. Sem o transform, o menu fica por cima. Um efeito de hover que levanta um cartão pode, portanto, esconder o próprio dropdown sob o cartão de baixo, e é por isso que a correção da aula 7 vale aqui também: dê ao cartão aberto um `z-index` maior que o dos irmãos, ou tire o menu de dentro dele.
