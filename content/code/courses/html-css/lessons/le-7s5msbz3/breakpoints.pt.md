---
title: Escolhendo breakpoints pelo conteúdo
version: 1
---

Um **breakpoint** é uma largura em que uma media query muda o layout. O jeito tentador de escolhê-los é por uma lista de aparelhos: 375 para este celular, 768 para aquele tablet. Essa lista fica velha no ano em que é escrita, e há centenas de larguras entre os itens dela. **O conteúdo diz onde quebrar**: alargue a janela devagar e ponha um breakpoint onde o layout começa a ficar errado.

O que mais dá errado quando uma janela se alarga nem é um layout. São linhas de texto que ficam longas demais para ler:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <style>
      body { margin: 0 auto; padding: 0 1rem; font-family: system-ui, sans-serif; }
      .capped { max-width: 65ch; }
    </style>
  </head>
  <body>
    <p class="free">Andorinha Books opened in 2009 in a former bakery on Rua dos Pinheiros. It sells new and second-hand books, runs a reading group on Thursday evenings, and on Saturdays turns its back room into a workshop for anybody who wants to learn to bind a book by hand.</p>
    <p class="capped">Andorinha Books opened in 2009 in a former bakery on Rua dos Pinheiros. It sells new and second-hand books, runs a reading group on Thursday evenings, and on Saturdays turns its back room into a workshop for anybody who wants to learn to bind a book by hand.</p>
  </body>
</html>
```

```
ana@laptop:~/site$ probe --width 1200 measure.html box p
p.free    x 16     y 16     width 1168   height 40
p.capped  x 16     y 72     width 656.09 height 80
```

O parágrafo livre tem **1168** de largura numa janela de 1200, e o parágrafo inteiro cabe em duas linhas. Uma linha desse tamanho é difícil de ler: no fim de uma, o olho tem dificuldade de achar o começo da próxima. O parágrafo limitado tem **`max-width: 65ch`**, e tem **656,09** de largura, em quatro linhas. `ch` é a largura do zero na fonte do elemento, então `65ch` comporta algo como 65 a 75 caracteres de texto comum, o comprimento em que os livros e o velho conselho tipográfico se acertam.

Isso não precisou de media query nenhuma, e é o ponto a guardar: **`max-width`, `flex-wrap`, `auto-fit` e `clamp()` se adaptam sozinhos**, aulas 6, 8 e 9 e a seção 06 desta, e cada um deles é um breakpoint que você não precisou escolher. Media queries são para as mudanças que eles não conseguem fazer, como levar uma barra lateral de ao lado do conteúdo para baixo dele.

## Quantos

Um site típico precisa de **dois ou três** breakpoints para a moldura da página, e os componentes podem ter um ou dois próprios. Se você se pega escrevendo uma query a cada cem pixels, o layout provavelmente está brigando com o conteúdo, e uma trilha flexível ou um `minmax()` fariam o trabalho melhor.
