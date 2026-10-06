---
title: Animações com @keyframes
version: 1
---

Uma transição precisa de uma mudança que a dispare. Uma **animação** roda sozinha, por etapas descritas numa regra **`@keyframes`**:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <style>
      body { margin: 16px; font-family: system-ui, sans-serif; }

      @keyframes drop-in {
        from { opacity: 0; translate: 0 -16px; }
        to   { opacity: 1; translate: 0 0; }
      }

      .notice { animation: drop-in 400ms ease-out; }

      /* Starts late, and shows itself during the delay. */
      .late { animation: drop-in 400ms ease-out 300ms; }

      /* Starts late, and waits in the first keyframe. */
      .late-filled { animation: drop-in 400ms ease-out 300ms backwards; }

      @keyframes spin { to { rotate: 1turn; } }
      .spinner {
        width: 24px; height: 24px;
        border: 3px solid #2f6f4e; border-top-color: transparent; border-radius: 50%;
        animation: spin 1s linear infinite;
      }
    </style>
  </head>
  <body>
    <p class="notice">The shop closes at 5 pm on Saturday.</p>
    <p class="late">New arrivals are on the front table.</p>
    <p class="late-filled">Bookbinding has two places left.</p>
    <div class="spinner" role="status" aria-label="Loading"></div>
  </body>
</html>
```

`@keyframes drop-in` dá nome a uma animação e descreve as etapas dela: `from` é 0% e `to` é 100%, e porcentagens no meio são permitidas, `50% { … }`. O atalho `animation` em `.notice` a aplica: o **nome**, a **duração**, a **função de tempo** e, opcionalmente, um **atraso**, um **número de repetições**, uma **direção** e um **modo de preenchimento** (*fill mode*). Aqui está o aviso com 100 ms, e no fim:

```
ana@laptop:~/site$ probe keyframes.html at 100 style .notice opacity,translate at 400 style .notice opacity,translate
p.notice  opacity: 0.378138
p.notice  translate: 0px -9.94979px
p.notice  opacity: 1
p.notice  translate: none
```

Em 100 ms ele está **37,8% opaco** e **9,9 pixels** acima do lugar. Em 400 ms está totalmente opaco e o `translate` dele é **none**: a animação acabou, e o elemento voltou aos próprios estilos, que coincidem com o último keyframe. Esse é o desenho de costume, e o que se deve buscar: os keyframes descrevem como um elemento **chega ao** estado que os estilos normais dele já dão, então nada depende de a animação ter rodado.

## O atraso, e o modo de preenchimento

O segundo e o terceiro parágrafos começam 300 ms depois. Em 100 ms, nenhum começou:

```
ana@laptop:~/site$ probe keyframes.html at 100 style .late,.late-filled opacity
p.late  opacity: 1
p.late-filled  opacity: 0
```

`.late` está **totalmente visível**: durante o atraso, a animação ainda não vale, então o elemento mostra os próprios estilos. Aí, em 300 ms, ele pula para o primeiro keyframe, transparente, e surge aos poucos: um piscar. `.late-filled` acrescenta o modo de preenchimento **`backwards`**, que aplica o primeiro keyframe durante o atraso, e fica **transparente** enquanto espera. **`forwards`** mantém o último keyframe depois do fim, e **`both`** faz as duas coisas. Toda entrada com atraso precisa de `backwards` ou `both`.

## Repetindo

O spinner usa `animation: spin 1s linear infinite`:

```
ana@laptop:~/site$ probe keyframes.html at 250 style .spinner rotate at 750 style .spinner rotate
div.spinner  rotate: 90deg
div.spinner  rotate: 270deg
```

Em 250 ms ele girou **90 graus**, em 750 ms **270**: um quarto de volta a cada quarto de segundo, a velocidade constante do `linear`, e `infinite` repete para sempre. `alternate` como direção faria cada repetição rodar de trás para frente depois da de ida, que é como os pontos da seção 07 iam e voltavam.

O spinner tem `role="status"` e um `aria-label`: o giro diz a quem enxerga que algo está carregando, e o nome diz o mesmo a um leitor de tela. Movimento sozinho nunca carrega uma mensagem.
