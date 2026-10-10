---
title: A página como árvore
version: 1
---

**Um teste só age sobre o que consegue achar, e o localizador é a parte do teste que acha.** Todo
clique, toda verificação de preço e toda contagem de cartões começa com um. Esta aula trata de
escrever localizadores que continuam achando o elemento certo depois que a página mudou de jeitos
que não têm nada a ver com o defeito que você procura.

A primeira imagem comum de um localizador é a de um endereço: o elemento mora em algum lugar, e o
localizador diz onde. **A página não tem endereços.** Ela tem uma árvore de elementos, e um
localizador é uma descrição de um deles: *o cartão cujo test id é `product-banana`*, *o segundo
cartão da lista*, *o botão dentro do cartão cujo título diz Mango*. Várias descrições batem com o
mesmo elemento hoje. O que as separa é o que precisa continuar verdadeiro para cada uma continuar
batendo com ele.

## Um programa que conta

A aula 1 usou a caixa de busca do painel Elements para perguntar quantos elementos um seletor
encontra. Este script faz a mesma pergunta num terminal, para que cada seletor desta aula venha
com o que achou na loja de verdade, e não com o que deveria achar. Salve-o como `count.mjs`:

```schooling-example
{"language": "javascript", "file": "count.mjs", "parts": [{"code": "// What the Elements panel's search box answers, printed: how many elements\n// each locator matches on the shop. Start the shop, then:\n//   node count.mjs 'locator' 'another locator' ...\nimport { chromium } from '@playwright/test';", "note": "O comentário diz como rodar. Como o `look.mjs` da aula 1, ele usa a biblioteca do Playwright, e não o executor de testes."}, {"code": "const browser = await chromium.launch();\nconst page = await browser.newPage();\nawait page.goto('http://localhost:3000/');\nawait page.locator('#products[aria-busy=\"false\"]').waitFor();", "note": "Abre a loja e espera até a lista dizer que não está mais ocupada. Contar logo depois do `goto` contaria uma lista vazia, porque os cartões chegam numa requisição posterior. A aula 3 trata dessa espera."}, {"code": "for (const locator of process.argv.slice(2)) {\n  const found = page.locator(locator);\n  const n = await found.count();\n  console.log(String(n).padStart(3) + '  ' + locator);", "note": "O `page.locator` aceita um seletor CSS, ou XPath quando o texto começa com `//` ou `xpath=`. O `count()` responde na hora e nunca espera, e é por isso que a espera de cima existe."}, {"code": "  if (n === 1) {\n    const html = await found.evaluate((element) => element.outerHTML);\n    console.log(html.replace(/^/gm, '       '));\n  }\n}\nawait browser.close();", "note": "Quando exatamente um elemento bate, imprime o HTML desse elemento como o DOM o tem agora, recuado abaixo da contagem. Um é o número que um localizador de uma coisa só precisa achar."}]}
```

Com a loja rodando em outro terminal (`npm start`), peça o cartão da banana pelo atributo que o
cartão traz para os testes:

```
%%CAP count-banana%%
```

Um resultado, e o cartão como o navegador o guarda depois que o `app.js` o montou.

## Pai, filho, irmão

Esse `<li>` é um nó da árvore, e tudo o que está dentro dele pende dele. O vocabulário é o de uma
família, e toda linguagem de localizadores o usa:

- o `li` é o **pai** do `h2`, do `p` e do `button`, que são seus **filhos**, e **irmãos** entre
  si;
- o `small` é filho do `p`, então é **descendente** do `li` dois níveis abaixo, e o `li` é um dos
  seus **ancestrais**;
- as palavras também são nós, **nós de texto**, filhos do elemento em que estão. O `p` tem um nó
  de texto e depois o elemento `small`;
- os **atributos** pertencem a um elemento e não são filhos dele: `class`, `id`, `data-testid` e
  `type` ficam no elemento que descrevem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"O cartão Banana desenhado como árvore. O elemento li, com os atributos class card, id card-4821 e data-testid product-banana, é o pai de três filhos: h2, p com a classe price e button. Abaixo deles, tracejados, estão os nós de texto: Banana, o preço com um espaço inseparável e Add to basket; um elemento small fica dentro do preço. Ao lado da árvore, quatro localizadores para o cartão: o test id e o texto do título continuam batendo com ele; o id e a posição quebram sem defeito nenhum na loja.\"><rect x=\"70\" y=\"16\" width=\"250\" height=\"72\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"84\" y=\"38\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">li class=\"card\"</text><text x=\"84\" y=\"57\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">id=\"card-4821\"</text><text x=\"84\" y=\"76\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">data-testid=\"product-banana\"</text><text x=\"16\" y=\"56\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">pai</text><path d=\"M150 88 L55 130\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M195 88 L190 130\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M250 88 L375 130\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><rect x=\"15\" y=\"130\" width=\"80\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"55\" y=\"151\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">h2</text><rect x=\"120\" y=\"130\" width=\"140\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"190\" y=\"151\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">p class=\"price\"</text><rect x=\"320\" y=\"130\" width=\"110\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"375\" y=\"151\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">button</text><path d=\"M55 162 L55 210\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M175 162 L165 210\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M210 162 L280 210\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M375 162 L375 210\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><rect x=\"10\" y=\"210\" width=\"90\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-dasharray=\"4 3\"></rect><text x=\"55\" y=\"231\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">\"Banana\"</text><rect x=\"105\" y=\"210\" width=\"125\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-dasharray=\"4 3\"></rect><text x=\"167\" y=\"231\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">\"R$&amp;nbsp;5,90 \"</text><rect x=\"245\" y=\"210\" width=\"70\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"280\" y=\"231\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">small</text><rect x=\"320\" y=\"210\" width=\"120\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-dasharray=\"4 3\"></rect><text x=\"380\" y=\"231\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">\"Add to basket\"</text><text x=\"10\" y=\"268\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">h2, p e button: filhos do li, irmãos entre si</text><text x=\"10\" y=\"286\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tracejado: nós de texto</text><text x=\"462\" y=\"36\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">quatro localizadores até este cartão</text><text x=\"462\" y=\"74\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">getByTestId('product-banana')</text><text x=\"462\" y=\"92\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um atributo escrito para testes</text><text x=\"462\" y=\"126\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">getByText('Banana')</text><text x=\"462\" y=\"144\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o que uma pessoa lê</text><text x=\"462\" y=\"178\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">#card-4821</text><text x=\"462\" y=\"196\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">sorteado de novo a cada carga</text><text x=\"462\" y=\"230\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">#products &gt; li:nth-child(1)</text><text x=\"462\" y=\"248\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">primeiro hoje, talvez não amanhã</text></svg>", "caption": "O cartão Banana como o navegador o guarda, com quatro jeitos de apontar para ele. Os dois em âmbar batem hoje e não têm promessa para amanhã."}
```

Dois detalhes dessa saída voltam nesta aula. O primeiro é o `&nbsp;`, que é como o DOM escreve o
**espaço inseparável** de que a aula 1 avisou quando transforma a página de volta em HTML. Um
localizador ou uma verificação que digita um espaço comum está descrevendo outro texto. O segundo
é o espaço depois de `5,90`: o nó de texto do preço termina ali, antes de o `<small>` começar, então
o valor inteiro dele é `R$`, o espaço inseparável, `5,90` e um espaço comum. As quebras de linha e
os espaços entre `</h2>` e `<p>` também são nós de texto, feitos só de espaço em branco pelo modelo
do `app.js`. O painel Elements os esconde; o XPath, duas seções adiante, compara o texto exatamente
como ele é.

## Em que um teste pode se apoiar

Só com este cartão, um teste poderia nomeá-lo:

- **pela tag e pela classe**, `li.card`, que outros sete cartões compartilham;
- **pelo `id`**, que é único na página e sorteado toda vez que a página carrega;
- **pela posição**, primeiro da lista, porque a loja lista a banana primeiro;
- **pelo `data-testid`**, um atributo que existe só para ser achado por testes;
- **pelo que uma pessoa vê**: um título que diz Banana e um botão que diz Add to basket.

**Todos eles chegam ao cartão da banana agora mesmo**, e é exatamente por isso que um teste que
passa hoje não prova nada sobre o seu localizador. As duas próximas seções são as duas linguagens
clássicas para escrever essas descrições, CSS e XPath. As duas seguintes tratam de quais
descrições deixam de ser verdadeiras, e dos localizadores que o Playwright monta em torno do que
uma pessoa vê.
