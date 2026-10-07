---
title: Andando passo a passo, e a instrução debugger
version: 2
---

**Com a página pausada, você pode avançá-la um passo de cada vez e ver o estado mudar.** O DevTools
tem três botões para isso, e o `--step` do `page` aceita as mesmas três palavras:

- **step over** roda a linha atual, chamadas incluídas, e para na linha seguinte da mesma função;
- **step into** segue a chamada da linha atual para dentro da função chamada;
- **step out** roda o resto da função atual e para de volta em quem a chamou.

Aqui a ana pausa na chamada a `render` da página corrigida e usa os três:

```
ana@dev:~/js$ page shelf.html --break shelf.js:4 --step into --step over --step out
paused at shelf.js:4
  call stack: load shelf.js:4
  local scope: res = {type: "basic", url: "http://127.0.0.1:8080/api/books", redirected: false, status: 200, ok: true, …}, books = Array(3) [{…}, {…}, {…}]
-- step into
paused at shelf.js:8
  call stack: render shelf.js:8  <  load shelf.js:4
  local scope: books = Array(3) [{…}, {…}, {…}], list = (uninitialised)
-- step over
paused at shelf.js:9
  call stack: render shelf.js:9  <  load shelf.js:4
  block scope: i = (uninitialised)
  local scope: books = Array(3) [{…}, {…}, {…}], list = ul#books
-- step out
paused at shelf.js:5
  call stack: load shelf.js:5
  local scope: res = {type: "basic", url: "http://127.0.0.1:8080/api/books", redirected: false, status: 200, ok: true, …}, books = Array(3) [{…}, {…}, {…}]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Duas funções lado a lado, load e render, com os quatro lugares onde a página pausada parou. Ela pausou em load linha 4, na chamada a render. Step into seguiu a chamada até render linha 8. Step over rodou a linha 8 e parou na linha 9 da mesma função. Step out rodou o resto de render e parou de volta em load, na linha 5.\"><defs><marker id=\"steps-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"steps-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"32\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">load</text><text x=\"40\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2  const res = await fetch(…);</text><text x=\"40\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3  const books = await res.json();</text><text x=\"40\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4  render(books);</text><text x=\"40\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5  }</text><text x=\"412\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">render</text><text x=\"420\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">8  const list = document.query…</text><text x=\"420\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">9  for (let i = 0; …) {</text><text x=\"420\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">   …</text><text x=\"420\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">15 }</text><rect x=\"34\" y=\"116\" width=\"160\" height=\"20\" rx=\"2\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"34\" y=\"146\" width=\"40\" height=\"20\" rx=\"2\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"414\" y=\"56\" width=\"200\" height=\"20\" rx=\"2\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"414\" y=\"86\" width=\"160\" height=\"20\" rx=\"2\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M194 126 L360 126 L360 66 L410 66\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#steps-ah-phosphor)\"></path><text x=\"300\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">step into</text><path d=\"M640 66 L660 66 L660 92 L578 96\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#steps-ah-phosphor)\"></path><text x=\"682\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">over</text><path d=\"M560 106 L560 176 L110 176 L110 160 L78 156\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#steps-ah-amber)\"></path><text x=\"330\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">step out</text></svg>", "caption": "Into segue uma chamada, over fica na função, out termina a função e volta para quem chamou."}
```

O step into levou a pilha de um quadro para dois. O step out a trouxe de volta. Na linha 8 `list`
está **uninitialised** (não inicializada): a linha que a cria ainda não rodou, e uma `const` antes
da declaração está na zona morta temporal da aula 3. Um step over depois, ela guarda a lista.

O step over é o que você mais vai apertar. **Entre nas chamadas que você escreveu e passe por cima
das que não escreveu**: entrar em `querySelector` ou `fetch` leva você ao código do próprio
navegador, ou de uma biblioteca, e o bug raramente está lá.

## A instrução debugger

Um breakpoint também pode ser escrito no código. A instrução `debugger;` pausa o programa
exatamente como um breakpoint faria, **mas só enquanto as ferramentas de desenvolvedor estão
abertas**. Fora isso, não faz nada. O `find.html` carrega este script com uma tag `<script>`, como o
`shelf.html` faz:

```javascript
const books = [
  { title: "Dom Casmurro", year: 1899 },
  { title: "Grande Sertão: Veredas", year: 1956 },
  { title: "A Hora da Estrela", year: 1977 },
];

function after(year) {
  const found = books.filter((book) => book.year > year);
  debugger;
  return found;
}

console.log(after(1950).length, "books after 1950");
```

```
ana@dev:~/js$ page find.html
2 books after 1950
ana@dev:~/js$ page find.html --break debugger
paused at find.js:9
  call stack: after find.js:9  <  (anonymous) find.js:13
  local scope: year = 1950, found = Array(2) [{…}, {…}]
  script scope: books = Array(3) [{…}, {…}, {…}]
2 books after 1950
```

A primeira execução é uma página sem ninguém olhando: a instrução foi ignorada e a contagem foi
impressa. Na segunda, o `--break debugger` conecta o depurador antes, como abrir o
DevTools faria. A página pausou na linha 9, com `found` já calculado. O escopo **script** guarda a
`const books` do topo do arquivo.

`debugger;` é útil quando a linha é difícil de achar no painel Sources, dentro de um callback num
arquivo longo, por exemplo. Ela não pode ir para o commit, porque um colega com o DevTools aberto
pararia ali também. A regra `no-debugger` do ESLint existe para pegar a que escapou.

## O Node tem o mesmo depurador

`node --inspect app.js` inicia um programa com o mesmo protocolo aberto, e a página
`chrome://inspect` do Chrome conecta o DevTools dele a esse programa, com breakpoints e tudo. Isso
não foi rodado para esta aula: a máquina em que ela foi gravada não tem uma área de trabalho onde
abrir uma janela do DevTools.
