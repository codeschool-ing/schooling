---
title: Valores reserva, e uma variável que não existe
version: 1
---

O `var()` aceita um segundo argumento, usado quando a variável não está definida: `var(--padding, 8px)`. Aqui estão dois parágrafos, um usando uma variável que nunca foi declarada, com valor reserva, e um usando um nome com erro de digitação, sem:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Fallbacks · Andorinha Books</title>
    <style>
      :root { --gap: 24px; }
      .missing { padding: var(--padding, 8px); }
      .typo { padding: var(--paddng); }
      main { color: #2f6f4e; }
      .wrong {
        color: #8a1c1c;
        color: var(--gap);
      }
    </style>
  </head>
  <body>
    <main>
      <p class="missing">--padding is never declared.</p>
      <p class="typo">--paddng is a typo.</p>
      <p class="wrong">--gap is a length, used as a colour.</p>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe fallback.html style .missing padding-left style .typo padding-left
p.missing  padding-left: 8px
p.typo  padding-left: 0px
```

O primeiro recebeu o valor reserva, **8px**. O segundo, `var(--paddng)`, não achou nada e não tinha reserva, então `padding-left` virou **0px**: o valor inicial da propriedade. Não houve erro nem aviso na página. Um nome de variável digitado errado se comporta exatamente como uma propriedade que nunca foi definida, e é o tipo de engano mais difícil de ver, porque nada parece quebrado; só parece um espaço menor do que alguém queria.

## Quando escrever um valor reserva

**Para variáveis que um componente espera receber de fora**, que uma página pode definir ou não, o valor reserva é o padrão do componente: `padding: var(--card-padding, 1rem)` funciona tenha alguém configurado ou não.

**Para os seus próprios design tokens, declarados em `:root`**, um valor reserva quase só esconde erros de digitação. Se `--space` está sempre declarada, `var(--space, 8px)` só vai usar os 8px quando o nome estiver errado, e aí esconde o engano atrás de um valor plausível. Deixe esses sem reserva e deixe o DevTools mostrar: o painel Computed lista toda propriedade personalizada que um elemento enxerga, e o painel Styles marca um `var()` cuja variável não existe.

Um valor reserva pode usar outra variável, `var(--card-accent, var(--accent))`, que se lê como "a cor de destaque do próprio cartão se alguém definiu uma, a do site se não".
