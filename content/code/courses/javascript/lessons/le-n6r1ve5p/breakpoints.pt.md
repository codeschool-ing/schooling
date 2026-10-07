---
title: Breakpoints: parando a página
version: 1
---

**Um breakpoint (ponto de parada) pausa o programa numa linha, antes de ela rodar, e deixa tudo como
estava.** Enquanto ele está pausado, você lê toda variável no escopo e a cadeia de chamadas que
levou até ali. Esta página tem um bug:

```html
<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>Shelf</title></head>
<body>
  <ul id="books"></ul>
  <script src="shelf.js"></script>
</body>
</html>
```

```javascript
async function load() {
  const res = await fetch("/api/books");
  const books = await res.json();
  render(books);
}

function render(books) {
  const list = document.querySelector("#books");
  for (let i = 0; i <= books.length; i++) {
    const book = books[i];
    const item = document.createElement("li");
    item.textContent = `${book.title} (${book.year})`;
    list.append(item);
  }
}

load();
```

```
ana@dev:~/js$ page shelf.html --dom '#books'
Uncaught TypeError: Cannot read properties of undefined (reading 'title')
<ul id="books"><li>Dom Casmurro (1899)</li><li>Grande Sertão: Veredas (1956)</li><li>A Hora da Estrela (1977)</li></ul>
```

**A página parece certa e está errada.** Os três livros foram desenhados, e então o script lançou
um erro. Ninguém olhando só a tela saberia, e é por isso que o console é a primeira coisa a abrir
quando uma página se comporta mal. A mensagem nomeia uma propriedade, `title`, e um valor,
`undefined`, mas não qual livro nem por quê.

## Pausando no erro

No DevTools, o painel Sources tem uma chave para **pausar em exceções não capturadas**. O
`--break uncaught` do laboratório pede a mesma coisa ao Chromium:

```
ana@dev:~/js$ page shelf.html --break uncaught
paused at shelf.js:12, on TypeError: Cannot read properties of undefined (reading 'title')
  call stack: render shelf.js:12  <  load shelf.js:4
  block scope: book = undefined, item = li
  block scope: i = 3
  local scope: books = Array(3) [{…}, {…}, {…}], list = ul#books
Uncaught TypeError: Cannot read properties of undefined (reading 'title')
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Uma página pausada, desenhada em três painéis. À esquerda, o código de render com a linha 12 marcada como a linha em que o navegador parou, a template string que lê book.title. No alto à direita, a pilha de chamadas: render na linha 12, chamada por load na linha 4. Abaixo, os escopos: book é undefined, i é 3, books guarda três itens. Os três fatos juntos explicam o erro: o laço pediu um quarto livro.\"><defs><marker id=\"paused-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"400\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">shelf.js</text><text x=\"48\" y=\"64\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7</text><text x=\"56.0\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">function render(books) {</text><text x=\"48\" y=\"86\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><text x=\"66.8\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">const list = document.querySelector(&quot;#books&quot;);</text><text x=\"48\" y=\"108\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">9</text><text x=\"66.8\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">for (let i = 0; i &lt;= books.length; i++) {</text><text x=\"48\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><text x=\"77.6\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">const book = books[i];</text><text x=\"48\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">11</text><text x=\"77.6\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">const item = document.createElement(&quot;li&quot;);</text><rect x=\"26\" y=\"164\" width=\"388\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"48\" y=\"174\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">12</text><text x=\"77.6\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">item.textContent = `${book.title} (${book.year})`;</text><text x=\"48\" y=\"196\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">13</text><text x=\"77.6\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">list.append(item);</text><text x=\"48\" y=\"218\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">14</text><text x=\"66.8\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">}</text><text x=\"48\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15</text><text x=\"56.0\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">}</text><rect x=\"450\" y=\"20\" width=\"250\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"462\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Pilha de chamadas</text><text x=\"462\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">render   shelf.js:12</text><text x=\"462\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">load     shelf.js:4</text><rect x=\"450\" y=\"136\" width=\"250\" height=\"124\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"462\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Escopo</text><text x=\"462\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">book  = undefined</text><text x=\"462\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">i     = 3</text><text x=\"462\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">books = Array(3)</text><text x=\"462\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">list  = ul#books</text><path d=\"M420 174 L446 180\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#paused-ah-amber)\"></path></svg>", "caption": "Onde parou, como chegou lá, e o que cada variável guardava naquele momento."}
```

Três fatos, lidos de uma pausa:

- **onde**: linha 12, a template string que lê `book.title`;
- **como chegou lá**: `render`, chamada por `load` na linha 4. Essa lista é a **pilha de
  chamadas**, a chamada mais nova primeiro;
- **o que tudo guardava**: `book` é `undefined`, `i` é `3`, e `books` tem três itens. O índice 3
  de um array de três itens não existe.

Os escopos vêm em camadas, a cadeia de escopos da aula 6: dois escopos de **bloco**, um para o corpo
do laço e um para o `i` do laço, e então o escopo **local** da função. A causa agora cabe numa
frase: o laço roda enquanto `i <= books.length`, então pede um livro a mais.

## Um breakpoint numa linha, com condição

Pausar no erro funciona quando há um erro. Mais vezes há só um valor errado, e você pausa numa linha
que escolhe. No DevTools você clica no número da linha no painel Sources. Um breakpoint simples na
linha 11 pausaria quatro vezes, uma por volta do laço. Um **breakpoint condicional** só pausa quando
uma expressão é verdadeira:

```
ana@dev:~/js$ page shelf.html --break shelf.js:11 --if 'book === undefined'
paused at shelf.js:11
  call stack: render shelf.js:11  <  load shelf.js:4
  block scope: book = undefined, item = li
  block scope: i = 3
  local scope: books = Array(3) [{…}, {…}, {…}], list = ul#books
Uncaught TypeError: Cannot read properties of undefined (reading 'title')
```

A condição rodou em toda volta e só foi verdadeira na última. Essa é a ferramenta para um bug no
item 900 de uma lista: você escreve como é o "errado" e deixa o navegador esperar por ele.

## A correção

```
ana@dev:~/js$ sed -i 's/i <= books.length/i < books.length/' shelf.js
ana@dev:~/js$ sed -n 9p shelf.js
  for (let i = 0; i < books.length; i++) {
ana@dev:~/js$ page shelf.html --dom '#books'
<ul id="books"><li>Dom Casmurro (1899)</li><li>Grande Sertão: Veredas (1956)</li><li>A Hora da Estrela (1977)</li></ul>
```

Nenhum erro, e os mesmos três livros. A correção é um caractere, e achá-la levou duas execuções e
nenhuma edição no código.
