---
title: A página é uma árvore
version: 1
---

::: track frontend backend qa
Você escreveu páginas no html-css, então a marcação desta seção é conhecida. O que é novo é o outro
lado: **o navegador não guarda o seu HTML como texto**. Ele o lê uma vez e constrói uma estrutura de
objetos que um script alcança.
:::

::: track *
Uma página web se escreve em **HTML**: elementos entre sinais de menor e maior, como
`<h1>My shelf</h1>`, aninhados uns dentro dos outros. O curso `html-css` ensina isso direito; este
só precisa disso. O que importa aqui é o outro lado: **o navegador não guarda o HTML como texto**. Ele
o lê uma vez e constrói uma estrutura de objetos que um script alcança.
:::

Essa estrutura é o **DOM**, o Document Object Model. Um script consegue percorrê-la:

```html
<!doctype html>
<html lang="en">
<head><title>Shelf</title></head>
<body>
  <h1>My shelf</h1>
  <ul id="books">
    <li class="book">Iracema</li>
    <li class="book read">Dom Casmurro</li>
  </ul>
  <script>
    function walk(node, depth) {
      const pad = "  ".repeat(depth);
      if (node.nodeType === Node.TEXT_NODE) {
        if (node.textContent.trim()) console.log(pad + "#text " + JSON.stringify(node.textContent));
        return;
      }
      if (node.nodeType === Node.ELEMENT_NODE && node.tagName !== "SCRIPT") {
        console.log(pad + node.tagName.toLowerCase());
        for (const child of node.childNodes) walk(child, depth + 1);
      }
    }
    walk(document.documentElement, 0);
    console.log(document.body.childNodes.length, document.body.children.length);
  </script>
</body>
</html>
```

```
ana@dev:~/js$ page tree.html
html
  head
    title
      #text "Shelf"
  body
    h1
      #text "My shelf"
    ul
      li
        #text "Iracema"
      li
        #text "Dom Casmurro"
6 3
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A árvore que o navegador construiu a partir de tree.html. O elemento html tem dois filhos, head e body. head guarda title, que guarda o texto Shelf. body guarda h1, com o texto My shelf, e ul com o id books, que guarda dois elementos li com os textos Iracema e Dom Casmurro.\"><rect x=\"305.0\" y=\"14\" width=\"110\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">html</text><rect x=\"95.0\" y=\"74\" width=\"110\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">head</text><rect x=\"415.0\" y=\"74\" width=\"110\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">body</text><rect x=\"95.0\" y=\"134\" width=\"110\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">title</text><rect x=\"95.0\" y=\"194\" width=\"110\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"150.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">&quot;Shelf&quot;</text><rect x=\"275.0\" y=\"134\" width=\"110\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">h1</text><rect x=\"500.0\" y=\"134\" width=\"120\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ul#books</text><rect x=\"275.0\" y=\"194\" width=\"110\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"330.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">&quot;My shelf&quot;</text><rect x=\"425.0\" y=\"194\" width=\"110\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">li.book</text><rect x=\"575.0\" y=\"194\" width=\"130\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">li.book.read</text><rect x=\"425.0\" y=\"254\" width=\"110\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"480.0\" y=\"267.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">&quot;Iracema&quot;</text><rect x=\"575.0\" y=\"254\" width=\"130\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"640.0\" y=\"267.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">&quot;Dom Casmurro&quot;</text><path d=\"M360 40 L150 74\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M360 40 L470 74\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M150 100 L150 134\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M150 160 L150 194\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M470 100 L330 134\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M470 100 L560 134\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M330 160 L330 194\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M560 160 L480 194\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M560 160 L640 194\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M480 220 L480 254\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M640 220 L640 254\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><rect x=\"20\" y=\"44\" width=\"120\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">elemento</text><rect x=\"20\" y=\"14\" width=\"120\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"80.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">nó de texto</text></svg>", "caption": "A marcação de uma página vira uma árvore de objetos, e um script muda a página mudando a árvore."}
```

**Todo elemento virou um objeto, e todo pedaço de texto dentro de um também.** Todos se chamam
**nós**, e ficam pendurados numa árvore: `html` na raiz, `head` e `body` abaixo dele, a lista abaixo
do body, cada item abaixo da lista, e cada título como nó de texto abaixo do seu item. O script
imprimiu a árvore pedindo os filhos a cada nó, que é o formato de quase todo programa de DOM.

## Elementos e nós de texto

A última linha, `6 3`, vale ser lida com cuidado. `document.body.childNodes` contou **seis**,
enquanto `children` contou **três**: `h1`, `ul` e `script`. Os outros três são **nós de texto que
guardam só espaço em branco**, as quebras de linha e a indentação entre as tags, que a caminhada
pulou e o navegador guardou. `children` dá só elementos, que é quase sempre o que você quer; o resto
desta aula usa a versão de elementos de cada propriedade.

## Para que serve a árvore

A árvore não é uma cópia da página; **ela é a página**. Mude um nó e o navegador redesenha o que ele
mostra. Esta aula inteira é isso: achar um nó, mudá-lo, fazer nós novos. O global `document` é a
porta de entrada da árvore, e todo método das próximas seções sai dele ou de um elemento achado por
ele.
