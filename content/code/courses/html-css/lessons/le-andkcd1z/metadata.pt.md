---
title: Metadados que fazem diferença
---

O `<head>` não aparece na tela e decide muita coisa do que acontece nela.

- `<meta charset="UTF-8">` — sem ele, acentos viram símbolos. Vem primeiro, porque o navegador precisa saber a codificação antes de interpretar o resto.
- `<meta name="viewport" content="width=device-width, initial-scale=1">` — sem ele, o celular finge ter 980px de largura e desenha a página miniaturizada. É a linha que separa "responsivo" de "página de computador espremida".
- `<title>` — vai na aba, no favorito e no resultado do buscador.
- `<meta name="description">` — o parágrafo que o buscador mostra abaixo do título.

A do *viewport* é a que mais dói quando falta, porque a página parece funcionar no computador e nasce quebrada no celular — que é onde está a maioria dos visitantes.
