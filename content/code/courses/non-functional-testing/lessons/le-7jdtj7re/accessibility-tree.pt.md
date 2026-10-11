---
title: O que um leitor de tela recebe
version: 1
---

Todo elemento que o navegador desenha, ele também descreve, numa estrutura paralela chamada
**árvore de acessibilidade**. Cada nó dela tem três coisas que um leitor de tela anuncia: um
**papel**, que tipo de coisa ele é (link, botão, campo de texto, título); um **nome**, qual deles é
("Book", "Your name"); e **estados**, em que condição está (selecionado, marcado, expandido,
inválido, nível 1). Um leitor de tela anuncia o nome, o papel e os estados, com palavras e numa
ordem que ele mesmo escolhe. **O que a árvore contém é escolha da página**, e dá para lê-la sem
leitor de tela, a partir de um script.

Em `~/a11y`, `nano tree.js`:

```schooling-example
{"language": "javascript", "file": "a11y/tree.js", "parts": [{"code": "// a11y/tree.js\n// Prints what a screen reader is told about a page: its accessibility tree as\n// the page loads, then what changes when Book is pressed with no name typed.\nconst { chromium } = require(\"playwright\");\n\nconst url = process.argv[2] || \"http://localhost:8000/book.html\";", "note": "O terceiro programa em `~/a11y`. Ele não precisa do axe, só do Playwright e do endereço da página."}, {"code": "\nfunction shorter(tree) {            // twenty shows: keep the first option, count the rest\n  const lines = tree.split(\"\\n\");\n  const options = lines.filter(l => l.trim().startsWith(\"- option\"));\n  return lines.filter(l => !options.slice(1).includes(l))\n    .map(l => l === options[0] && options.length > 1 ? `${l}  (and ${options.length - 1} more)` : l)\n    .join(\"\\n\");\n}", "note": "A lista de espetáculos tem vinte opções, e imprimir todas enterraria o resto. `shorter` mantém a primeira e diz quantas mais havia; nada mais na árvore é mexido."}, {"code": "\n(async () => {\n  const browser = await chromium.launch();\n  const page = await browser.newPage();\n  await page.goto(url);\n  await page.waitForLoadState(\"networkidle\");\n  const before = await page.locator(\"body\").ariaSnapshot();\n  console.log(shorter(before));", "note": "**`ariaSnapshot()`** é a visão do Playwright da árvore de acessibilidade: uma linha por nó, o papel, o nome acessível entre aspas e os estados entre colchetes, recuados pelo aninhamento. É a árvore que o navegador entrega à tecnologia assistiva, então é com ela que um leitor de tela tem que trabalhar."}, {"code": "\n  await page.getByText(\"Book\", { exact: true }).click();\n  await page.waitForTimeout(500);\n  const after = (await page.locator(\"body\").ariaSnapshot()).split(\"\\n\");\n  const changed = after.filter(line => !before.split(\"\\n\").includes(line));\n  console.log(\"\\nAfter Book with no name, the tree gains:\");\n  console.log(changed.length ? changed.join(\"\\n\") : \"  nothing\");\n  await browser.close();\n})();", "note": "Depois o caso de erro: aperta Book com o nome vazio, espera meio segundo, tira a árvore de novo e imprime as linhas que não estavam lá antes. **Um erro que não muda nada na árvore é um erro que um leitor de tela não consegue relatar**, seja qual for a cor que ele ponha na tela."}]}
```

## Antes: book.html

```
ana@nft:~/a11y$ node tree.js http://localhost:8000/book.html
- img
- navigation:
  - link "What's on":
    - /url: /shows
  - link "Prices":
    - /url: /prices
  - link "Access":
    - /url: /access
- heading "Book a seat" [level=1]
- paragraph: Seats are held for ten minutes. The price includes the booking fee.
- paragraph:
  - text: Show
  - combobox "Show":
    - option "Hamlet, 2027-10-02" [selected]  (and 19 more)
- paragraph:
  - text: Seat
  - spinbutton "Seat": "1"
- paragraph:
  - text: Your name
  - textbox
- text: Book
- paragraph

After Book with no name, the tree gains:
  nothing
```

Leia como quem usa leitor de tela a encontra, linha por linha:

- **`img`, sem nome.** O logo existe, e nada diz o que ele é. Dependendo do leitor e das
  configurações, o usuário ouve o nome do arquivo, a palavra para imagem, ou nada.
- **`textbox`, sem nome**, depois de uma linha de texto separada que diz "Your name". Os dois estão
  lado a lado na tela. Na árvore não têm relação, e quem chega ao campo com Tab cai numa caixa sem
  nome: é por isso que o 1.3.1 fala de **relações**. Os campos Show e Seat, que têm rótulos de
  verdade, saem como `combobox "Show"` e `spinbutton "Seat"`.
- **`text: Book`**, não um botão. Para a árvore, a `<div>` é uma palavra na página. Quem usa leitor
  de tela e lê a página a ouve como texto e não tem motivo para tentar apertá-la.
- **Nenhum `main`**, e nada depois do clique: a borda vermelha mudou um estilo, e estilo não está
  na árvore. O erro aconteceu só para os olhos.

## Depois das correções de teclado: book3.html

```
ana@nft:~/a11y$ node tree.js http://localhost:8000/book3.html
- link "Skip to the booking form":
  - /url: "#main"
- img "boxoffice"
- navigation:
  - link "What's on":
    - /url: /shows
  - link "Prices":
    - /url: /prices
  - link "Access":
    - /url: /access
- main:
  - heading "Book a seat" [level=1]
  - paragraph: Seats are held for ten minutes. The price includes the booking fee.
  - paragraph:
    - text: Show
    - combobox "Show":
      - option "Hamlet, 2027-10-02" [selected]  (and 19 more)
  - paragraph:
    - text: Seat
    - spinbutton "Seat": "1"
  - paragraph:
    - text: Your name
    - textbox "Your name"
  - button "Book"
  - paragraph

After Book with no name, the tree gains:
  nothing
```

`img "boxoffice"`, `textbox "Your name"`, `button "Book"`, um `main` com o formulário: as
correções das aulas 13 e 14 aparecem aqui como nomes e papéis, que é a mesma melhora vista do outro
lado. **Mas o erro continua não acrescentando nada à árvore.** O único defeito que resta é
justamente o que esta árvore ainda não consegue mostrar, e a próxima seção o corrige.

## Como um nome é calculado

O nome que um nó recebe não é um palpite. Ele segue o *Accessible Name and Description
Computation* do W3C, que procura numa ordem fixa e fica com a primeira fonte que dá algo:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l15-name\" aria-label=\"A ordem em que o navegador procura o nome acessível de um elemento, ficando com a primeira fonte que dá algo. Primeiro aria-labelledby, o texto dos elementos para os quais aponta. Depois aria-label. Depois a fonte nativa: um label para um campo, o alt de uma imagem, o conteúdo de um botão ou link. Por último, title, e placeholder para um campo. Na página de reserva, o campo de nome recebe &quot;Your name&quot; do label; o logo recebe &quot;boxoffice&quot; do alt; o botão Book recebe &quot;Book&quot; do seu conteúdo.\"><defs><marker id=\"l15-name-nf-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l15-name-nf-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"150.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">procurado nesta ordem</text><text x=\"520.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">na página de reserva</text><rect x=\"40.0\" y=\"44.0\" width=\"220.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"56.0\" y=\"61.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"76.0\" y=\"61.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">aria-labelledby</text><text x=\"76.0\" y=\"79.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o texto dos ids que cita</text><path d=\"M150.0 96.0 L150.0 108.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-name-nf-ah-paper-dim)\"></path><rect x=\"40.0\" y=\"110.0\" width=\"220.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"56.0\" y=\"127.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"76.0\" y=\"127.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">aria-label</text><text x=\"76.0\" y=\"145.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um texto no próprio elemento</text><path d=\"M150.0 162.0 L150.0 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-name-nf-ah-paper-dim)\"></path><rect x=\"40.0\" y=\"176.0\" width=\"220.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"56.0\" y=\"193.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"76.0\" y=\"193.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">nativo</text><text x=\"76.0\" y=\"211.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;label&gt;, alt, conteúdo do botão</text><path d=\"M150.0 228.0 L150.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-name-nf-ah-paper-dim)\"></path><rect x=\"360.0\" y=\"130.0\" width=\"320.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"376.0\" y=\"143.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">textbox &quot;Your name&quot;</text><text x=\"376.0\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">do &lt;label for&gt;</text><path d=\"M264.0 201.0 L356.0 149.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-name-nf-ah-phosphor)\"></path><rect x=\"360.0\" y=\"178.0\" width=\"320.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"376.0\" y=\"191.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">img &quot;boxoffice&quot;</text><text x=\"376.0\" y=\"206.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">do alt</text><path d=\"M264.0 201.0 L356.0 197.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-name-nf-ah-phosphor)\"></path><rect x=\"360.0\" y=\"226.0\" width=\"320.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"376.0\" y=\"239.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">button &quot;Book&quot;</text><text x=\"376.0\" y=\"254.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">do conteúdo</text><path d=\"M264.0 201.0 L356.0 245.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-name-nf-ah-phosphor)\"></path><rect x=\"40.0\" y=\"242.0\" width=\"220.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"56.0\" y=\"259.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">4</text><text x=\"76.0\" y=\"259.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">title, placeholder</text><text x=\"76.0\" y=\"277.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">últimos recursos, e fracos</text><text x=\"360.0\" y=\"316.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a primeira fonte que dá um nome vence, e esconde as outras</text></svg>", "caption": "Como um nome acessível é encontrado. Na página de reserva todo nome vem da fonte nativa, que é a primeira a buscar."}
```

1. **`aria-labelledby`**, que aponta para os ids de outros elementos e junta o texto deles.
2. **`aria-label`**, um texto no próprio elemento.
3. **A fonte nativa**: o `<label>` ligado a um campo, o `alt` de uma imagem, o texto dentro de um
   botão ou de um link, o `<caption>` de uma tabela.
4. **`title`**, e para um campo, **`placeholder`**, como últimos recursos. Os dois são fracos: um
   `title` só aparece ao passar o mouse, e um placeholder some assim que alguém digita.

Duas consequências importam no teste. **A primeira fonte vence e esconde as outras**: um
`aria-label="Submit"` num botão cujo texto visível diz "Book" faz o nome dele ser "Submit", e quem
usa controle por voz e diz "clicar em Book" não consegue nada, que é o *2.5.3 Rótulo no nome*
reprovando. E um nome pode existir e estar errado, o que nenhuma árvore e nenhuma ferramenta julga;
essa é a metade humana do teste.

## A primeira regra do ARIA

O ARIA, Accessible Rich Internet Applications, é o conjunto de atributos, `role` e a família
`aria-*`, que deixa uma página definir papéis, nomes e estados à mão. Ele existe para widgets que
o HTML não tem: uma lista de abas, uma árvore, uma combobox com sugestões. **A primeira regra do
próprio W3C para usá-lo é não usar**: se um elemento HTML nativo já tem o significado e o
comportamento de que você precisa, use-o em vez de reaproveitar outro elemento e pôr ARIA nele.

A `<div>` mostra por quê. Transformá-la num botão de verdade à mão exige tudo isto:

```html
<div class="book" role="button" tabindex="0" onclick="book()"
     onkeydown="if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); book(); }">Book</div>
```

e isso ainda não é bem um botão: não envia o formulário, não é desativada por `disabled`, e cada
cópia dela é mais um lugar para o tratador de tecla estar errado. `<button
class="book">Book</button>` é tudo isso, embutido. **O ARIA muda o que a árvore diz e nada do que o
elemento faz**, e por isso `role="button"` numa `<div>` sem tratador de tecla é pior que ARIA
nenhum: promete um botão a quem usa leitor de tela e entrega uma palavra.
