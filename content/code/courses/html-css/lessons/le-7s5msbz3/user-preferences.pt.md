---
title: As outras preferências de quem lê
version: 1
---

A seção 06 da aula 10 respondeu a `prefers-color-scheme`. Quem lê pode dizer mais que isso, e as media queries conseguem ouvir. Duas importam para todo site.

## Movimento reduzido

Pessoas com distúrbios vestibulares podem sentir tontura ou enjoo com coisas se movendo na tela: parallax, um painel que desliza para dentro, uma página que dá zoom. Os sistemas operacionais têm uma configuração para **reduzir movimento**, e **`prefers-reduced-motion: reduce`** é como a página a enxerga. O aviso da livraria desce deslizando quando a página carrega; a aula 12 é sobre animações, e aqui só importa o interruptor:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <style>
      body { margin: 0; padding: 1rem; font-family: system-ui, sans-serif; }

      .notice { animation: drop-in 600ms ease-out; }
      @keyframes drop-in { from { translate: 0 -1rem; opacity: 0; } }

      @media (prefers-reduced-motion: reduce) {
        .notice { animation: none; }
      }

      button { min-height: 2rem; }
      @media (pointer: coarse) {
        button { min-height: 2.75rem; }
      }
    </style>
  </head>
  <body>
    <p class="notice">The shop closes at 5 pm on Saturday.</p>
    <button type="button">Dismiss</button>
  </body>
</html>
```

```
ana@laptop:~/site$ probe prefs.html style .notice animation-name
p.notice  animation-name: drop-in
ana@laptop:~/site$ probe --reduced-motion prefs.html style .notice animation-name
p.notice  animation-name: none
```

Sem a configuração, o aviso roda a animação `drop-in`. Com ela, a animação é **none**, e o aviso simplesmente está lá. O critério de sucesso 2.3.3 das WCAG, no nível AAA, pede exatamente isso para movimento disparado por interação, e é um bom hábito para qualquer movimento decorativo: mantenha o que se move só quando mover diz algo a alguém, e deixe todo o resto parar.

## Dedo ou mouse

**`pointer`** descreve o principal dispositivo de apontar de quem lê: `fine` para mouse ou trackpad, `coarse` para um dedo. **`hover`** diz se esse dispositivo consegue passar por cima de algo. Um dedo não consegue, então qualquer coisa que só aparece em `:hover` fica fora de alcance num celular:

```
ana@laptop:~/site$ probe prefs.html media "(pointer: coarse)" box button
(pointer: coarse)  does not match
button  x 16     y 68     width 62.66  height 32
ana@laptop:~/site$ probe --mobile --width 390 --height 844 prefs.html media "(pointer: coarse)" box button
(pointer: coarse)  matches
button  x 16     y 68     width 62.66  height 44
```

Na janela de desktop, `(pointer: coarse)` não casa e o botão tem **32** de altura. Com `--mobile`, que faz do Chromium uma tela de toque, casa, e o botão tem **44**. O critério de sucesso 2.5.8 das WCAG 2.2 pede alvos de pelo menos 24 por 24 pixels CSS, e as diretrizes da Apple para um dedo pedem 44 pontos, as do Android 48.

**Essas features descrevem um dispositivo, não um tamanho de tela.** Um tablet com teclado e trackpad conectados informa um ponteiro fino; uma tela de toque grande numa mesa informa um grosso. Nunca suponha que estreito quer dizer toque ou que largo quer dizer mouse.

## Outras que vale conhecer

`prefers-contrast: more` é definida por quem precisa de contraste maior. `forced-colors: active` quer dizer que o sistema operacional está trocando as cores da página por uma paleta pequena própria, como fazem os temas de contraste do Windows; bordas e contornos sobrevivem a isso, e cores de fundo usadas como único sinal de alguma coisa não. `print`, da seção 03, também é uma preferência: a pessoa quer papel.
