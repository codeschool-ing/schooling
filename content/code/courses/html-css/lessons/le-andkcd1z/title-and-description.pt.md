---
title: O título, a descrição e o que outros programas leem
version: 2
---

O resto do head é informação para programas que não são a janela do navegador: a barra de abas, o buscador, o aplicativo de mensagens que transforma um link colado numa prévia. Nada disso é desenhado na página, e tudo é lido por alguém. Aqui está o head da página de eventos do sebo:

```schooling-example
{"language": "html", "file": "head.html", "parts": [
 {"code": "<!doctype html>\n<html lang=\"en\">\n  <head>\n    <meta charset=\"utf-8\">\n    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"},
 {"code": "    <title>Events · Andorinha Books</title>", "note": "Aparece na aba, vira o nome do favorito, é lido primeiro por um leitor de tela e costuma ser o texto do link nos resultados de busca. A parte específica primeiro: várias abas do mesmo site se distinguem pelas primeiras palavras."},
 {"code": "    <meta name=\"description\" content=\"Readings, signings and a monthly swap at a second-hand bookshop in Pinheiros, São Paulo.\">", "note": "Uma frase sobre a página. Buscadores costumam mostrá-la embaixo do título, e a reescrevem quando acham que a deles é melhor."},
 {"code": "    <link rel=\"icon\" href=\"icon.svg\" type=\"image/svg+xml\">", "note": "A imagenzinha na aba. Um SVG fica nítido em qualquer tamanho que o navegador pedir."},
 {"code": "    <link rel=\"canonical\" href=\"https://andorinha.example/events\">", "note": "Qual endereço é o verdadeiro, quando a mesma página responde em vários. Os buscadores a contam uma vez em vez de dividi-la."},
 {"code": "    <meta property=\"og:title\" content=\"Events at Andorinha Books\">\n    <meta property=\"og:image\" content=\"https://andorinha.example/share.png\">", "note": "Open Graph: o título e a imagem que um aplicativo de mensagens ou uma rede social mostra quando alguém cola o link."},
 {"code": "  </head>\n  <body>\n    <h1>Events</h1>\n  </body>\n</html>"}
]}
```

## O título é o que mais importa

De todos esses, **`<title>` é o único que uma página tem de ter**: um documento sem ele é HTML inválido, e o validador da seção 13 aponta isso. É a primeira coisa que um leitor de tela anuncia quando a página abre, e é como alguém com vinte abas abertas encontra a sua. O `probe` o lê do jeito que o navegador lê:

```
ana@laptop:~/site$ probe head.html title
title: "Events · Andorinha Books"
```

Um bom título é específico e curto. "Events · Andorinha Books" nomeia a página primeiro e o site depois, para que três abas do mesmo site digam *Events*, *Order a book* e *Opening hours*, e não três *Andorinha Books…* iguais. Um título que diz "Home" ou "Untitled Document" em toda página não diz nada a ninguém.

## Descrição, ícone e o resto

A descrição não muda a posição de uma página na busca. É o que um resultado de busca pode mostrar embaixo do título, então ela é escrita para uma pessoa decidindo se vai clicar: o que tem na página, numa frase. O ícone é cosmético e também é como as pessoas acham a sua aba entre vinte. O link `canonical` e as propriedades Open Graph importam quando o site está público e é compartilhado, e uma página sem eles funciona do mesmo jeito.

O ícone que a página cita é uma linha de SVG, um círculo verde. Salve-o ao lado da página como `icon.svg`:

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16"><circle cx="8" cy="8" r="7" fill="#2f6f4e"/></svg>
```

## De onde vem o título de uma página num site grande

Num site com centenas de páginas, ninguém escreve o head à mão: um template escreve, e o título e a descrição são campos que alguém preenche para cada página. Vale saber disso porque o defeito mais comum em sites de verdade é um template que dá o mesmo título a todas as páginas. Ele é invisível enquanto você olha uma página por vez, e óbvio no instante em que você vê uma fileira de abas ou uma página de resultados de busca.
