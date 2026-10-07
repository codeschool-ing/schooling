---
title: Trazendo CSS, scripts e imagens
version: 2
---

Uma página raramente é um arquivo só. A página inicial do sebo precisa de uma folha de estilos, de um scriptzinho para o menu e de uma foto, e o HTML diz onde cada um está. Aqui está a página, `links.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Andorinha Books</title>
    <link rel="stylesheet" href="site.css">
    <script src="menu.js" defer></script>
  </head>
  <body>
    <h1>Andorinha Books</h1>
    <img src="cover.png" alt="The shop's front door" width="120" height="80">
  </body>
</html>
```

Três elementos apontam para três outros arquivos, e cada um se escreve de um jeito porque cada um é um tipo diferente de coisa:

- **`<link rel="stylesheet" href="site.css">`** traz CSS. `rel` diz qual é a relação, e `stylesheet` é uma de várias; o ícone da seção anterior era outra. Vai no head.
- **`<script src="menu.js" defer></script>`** traz JavaScript. Não é um elemento vazio: sempre precisa da tag de fechamento, mesmo vazio, e é o elemento em que esquecê-la engole o resto da página, como a seção 09 descreveu. O `defer` é explicado abaixo.
- **`<img src="cover.png" alt="…">`** traz uma imagem, e vai no body porque uma imagem é conteúdo. A aula 4 trata de imagens em detalhe, incluindo o que escrever no `alt`.

Os dois arquivos para os quais ela aponta têm uma linha cada, e vão ao lado da página. O `site.css` dá cor ao título:

```css
h1 { color: #2f6f4e; }
```

O `menu.js` marca a página como pronta para um menu, que é até onde um curso de HTML vai com ele:

```js
document.documentElement.dataset.menu = 'ready';
```

O `cover.png` é qualquer imagem pequena, como na seção 08.

Quando o navegador abre a página, ele pede cada um. `probe fetched` lista o que ele pediu, e `style` confirma que a folha de estilos chegou e foi aplicada:

```
ana@laptop:~/site$ probe links.html fetched style h1 color
site.css
menu.js
cover.png
h1  color: rgb(47, 111, 78)
```

A cor em `site.css` é `#2f6f4e`, e o navegador a informa como `rgb(47, 111, 78)`: a mesma cor na forma em que o navegador a guarda.

## Caminhos

`href="site.css"` é um **caminho relativo**: o navegador procura `site.css` no mesmo diretório da página. `href="css/site.css"` procuraria um diretório abaixo, e `href="../site.css"` um diretório acima. Um caminho que começa com `/`, como `/site.css`, começa na raiz do site, o que funciona num servidor e não quando você dá um clique duplo num arquivo do seu disco, porque ali a raiz é a raiz do disco inteiro. As páginas deste curso usam caminhos relativos exatamente por isso.

## Por que `defer`

Sem `defer`, um `<script>` no head para o parser: o navegador busca o script, executa, e só então continua lendo o HTML. Nada abaixo dele está na tela enquanto isso. Com `defer`, o navegador busca o script enquanto continua o parsing e o executa quando o documento inteiro foi lido. A aula 10 de `web-fundamentals` chama isso de caminho crítico, e a regra que ela dá é a que vale seguir: **um script no head leva `defer`**, ou `type="module"`, que já adia sozinho. O script em si é assunto do curso `javascript`.

Uma folha de estilos não tem o mesmo problema do mesmo jeito. O navegador continua o parsing enquanto baixa o CSS, mas espera a folha antes de desenhar qualquer coisa, porque desenhar conteúdo sem estilo e depois reestilizar faria a página pular. É por isso que folhas de estilo vão no head, cedo: quanto antes o navegador souber delas, antes consegue desenhar.
