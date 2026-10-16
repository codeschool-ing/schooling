---
title: Uma mudança, contada, e por que o código vence
version: 1
---

Uma suíte não é escrita uma vez. Ela muda toda vez que a aplicação muda, e **o que uma gravação
custa é pago, quase todo, depois que ela é feita**. Isso dá para contar. Pegue uma mudança que um
redator pode pedir numa tarde qualquer, as palavras do botão de *Add to basket* para *Add to cart*,
e conte o que cada versão do teste precisa mudar para acompanhar.

## A mudança

Edite o `app/public/app.js` para o botão dizer `Add to cart`. É uma linha do HTML do cartão:

```
ana@laptop:~/quitanda$ grep -n "Add to" app/public/app.js
22:    <button type="button">Add to cart</button>`;
```

Agora conte onde as palavras antigas aparecem, nas gravações e no que a aula 12 escreveu:

```
ana@laptop:~/quitanda$ grep -c "Add to basket" recorded/codegen.spec.js pages/product-card.js tests/page-object.spec.js tests/two-fruit.spec.js
recorded/codegen.spec.js:3
pages/product-card.js:1
tests/page-object.spec.js:0
tests/two-fruit.spec.js:0
```

**Três linhas na gravação, uma no page object, nenhuma nos dois arquivos de teste que o usam.** A
gravação repete o nome do botão em todo passo que clica num, porque cada sessão foi gravada sozinha
e o codegen escreve o localizador inteiro toda vez. O page object o diz uma vez, no `ProductCard`, e
todo teste chega ao botão pelo `addToBasket`.

Rode os dois contra a loja mudada. As gravações, depois os testes da aula 12 e os desta aula juntos,
com um worker por causa da cesta compartilhada:

```
ana@laptop:~/quitanda$ npx playwright test --config recorded.config.js recorded/codegen.spec.js | grep -E '✓|✘|^  [0-9]+ (failed|flaky|passed)'
  ✘  1 recorded/codegen.spec.js:3:1 › banana (30.0s)
  ✘  2 recorded/codegen.spec.js:9:1 › two fruit (30.0s)
  ✘  3 recorded/codegen.spec.js:16:1 › acerola (30.0s)
  3 failed
ana@laptop:~/quitanda$ npx playwright test tests/page-object.spec.js tests/two-fruit.spec.js --workers 1 | grep -E '✓|✘|^  [0-9]+ (failed|flaky|passed)'
  ✘  1 tests/page-object.spec.js:3:1 › a banana goes into the basket (30.0s)
  ✘  2 tests/page-object.spec.js:8:1 › two fruit make two items (30.0s)
  ✘  3 tests/page-object.spec.js:15:1 › the total follows the price (30.0s)
  ✘  4 tests/two-fruit.spec.js:3:1 › a banana and a mango make two items (30.0s)
  4 failed
```

**Todos os testes falharam, dos dois lados, e isso é justo.** As palavras que um cliente lê mudaram
de fato, então um localizador por papel e nome deve olhar de novo; foi a troca que a aula 2 fez de
propósito. A diferença está só no custo do conserto. Do lado escrito à mão, é a única linha de
`pages/product-card.js`:

```
ana@laptop:~/quitanda$ grep -n "Add to" pages/product-card.js
7:    this.addButton = root.getByRole('button', { name: 'Add to cart' });
ana@laptop:~/quitanda$ npx playwright test tests/page-object.spec.js tests/two-fruit.spec.js --workers 1 | grep -E '✓|✘|^  [0-9]+ (failed|flaky|passed)'
  ✓  1 tests/page-object.spec.js:3:1 › a banana goes into the basket (266ms)
  ✓  2 tests/page-object.spec.js:8:1 › two fruit make two items (340ms)
  ✓  3 tests/page-object.spec.js:15:1 › the total follows the price (181ms)
  ✓  4 tests/two-fruit.spec.js:3:1 › a banana and a mango make two items (316ms)
  4 passed (2.8s)
```

Quatro testes seguiram uma linha. A gravação precisa que suas três linhas sejam achadas e editadas
à mão, e uma suíte real de gravações traz o mesmo clique uma vez por sessão que o fez: cinquenta
fluxos gravados pela loja são cinquenta cópias do nome do botão. O mesmo vale para o resto do
projeto deste curso, e vale a pena vê-lo inteiro antes de pôr as palavras de volta:

```
ana@laptop:~/quitanda$ grep -rc 'Add to basket' --include='*.js' --include='*.mjs' --exclude-dir=node_modules . | grep -v ':0$'
./recorded/codegen.spec.js:3
./cypress/e2e/shop.cy.js:2
./app/routes/ssr.js:1
./tests/banana.spec.js:1
./tests/waiting.spec.js:1
./tests/locators.spec.js:1
./tests/contexts.spec.js:1
./tests/basket-data.spec.js:1
./tests/ssr.spec.js:1
./evidence/ssr.spec.js:1
```

Testes das aulas 2, 6, 9, 10, 11, 15 e 16 também nomeiam o botão direto, então uma mudança de
palavras chega a cada um deles. Isso não é argumento contra esses testes: cada um foi escrito para
ensinar uma ideia, não para ser mantido junto com os outros. É a medida daquilo para que serve um
page object. Uma linha dessa lista nem é teste: o `app/routes/ssr.js` desenha o mesmo botão na
página renderizada no servidor da aula 6, então a mudança do redator também são duas edições na
loja, e este experimento fez só a de `/`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 284\" role=\"img\" aria-label=\"Uma mudança no alto: as palavras do botão passam de Add to basket para Add to cart. À esquerda, a gravação, recorded/codegen.spec.js: três das linhas dela nomeiam o botão e são atingidas pela mudança, a linha da banana do teste banana e as linhas da banana e da manga do teste two fruit; a quarta linha, no teste acerola, nomeia um id de cartão. Três linhas para achar e editar. À direita, o page object: uma linha, addButton em pages/product-card.js, é atingida pela mudança, e quatro testes chegam ao botão por ela. Uma linha; quatro testes a seguem.\"><rect x=\"230\" y=\"14\" width=\"300\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"380\" y=\"39\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Add to basket → Add to cart</text><text x=\"190\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">a gravação</text><rect x=\"20\" y=\"96\" width=\"340\" height=\"150\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"30\" y=\"116\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">recorded/codegen.spec.js</text><rect x=\"40\" y=\"124\" width=\"300\" height=\"20\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\"></rect><text x=\"50\" y=\"138\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">test('banana')  · banana</text><rect x=\"40\" y=\"150\" width=\"300\" height=\"20\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\"></rect><text x=\"50\" y=\"164\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">test('two fruit') · banana</text><rect x=\"40\" y=\"176\" width=\"300\" height=\"20\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\"></rect><text x=\"50\" y=\"190\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">test('two fruit') · mango</text><rect x=\"40\" y=\"202\" width=\"300\" height=\"20\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-dasharray=\"5 4\"></rect><text x=\"50\" y=\"216\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">test('acerola')  · #card-…</text><path d=\"M380 54 L380 186\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M380 134 L342 134\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M342 134 L348.4 131.3 L348.4 136.7 Z\" fill=\"var(--amber)\"></path><path d=\"M380 160 L342 160\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M342 160 L348.4 157.3 L348.4 162.7 Z\" fill=\"var(--amber)\"></path><path d=\"M380 186 L342 186\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M342 186 L348.4 183.3 L348.4 188.7 Z\" fill=\"var(--amber)\"></path><text x=\"190\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">3 linhas para achar e editar</text><text x=\"570\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">o page object</text><rect x=\"420\" y=\"96\" width=\"320\" height=\"40\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\"></rect><text x=\"430\" y=\"121\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">pages/product-card.js · addButton</text><path d=\"M430 56 L520 94\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M520 94 L513.0 94.0 L515.1 89.0 Z\" fill=\"var(--amber)\"></path><rect x=\"450\" y=\"146\" width=\"290\" height=\"20\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"460\" y=\"160\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">two fruit make two items</text><path d=\"M435 136 L435 156 L450 156\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"450\" y=\"170\" width=\"290\" height=\"20\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"460\" y=\"184\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">a banana goes into the basket</text><path d=\"M435 136 L435 180 L450 180\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"450\" y=\"194\" width=\"290\" height=\"20\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"460\" y=\"208\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">the total follows the price</text><path d=\"M435 136 L435 204 L450 204\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"450\" y=\"218\" width=\"290\" height=\"20\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"460\" y=\"232\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">a banana and a mango make…</text><path d=\"M435 136 L435 228 L450 228\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"580\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">1 linha; 4 testes a seguem</text></svg>", "caption": "A mesma mudança, contada dos dois lados. Uma gravação repete um nome uma vez para cada clique que o usou; um page object o diz uma vez, e os testes pedem por ele.", "same": ["Add to basket → Add to cart"]}
```

Ponha as palavras de volta nos dois arquivos antes de seguir: `Add to basket` no
`app/public/app.js` e no `pages/product-card.js`.

## Por que o código vence

A contagem é um motivo de seis. Cada um dos outros é algo que a gravação não consegue guardar,
porque não é um clique.

- **Controle de versão e revisão.** Um arquivo de teste viaja no mesmo pull request que a mudança
  que o exigiu, e alguém lê os dois juntos. Um teste na conta de um fornecedor é editado em outro
  lugar, por outra pessoa, em outra hora.
- **Abstração.** `addToBasket('mango')` diz para que serve o passo. Quando a página muda, uma classe
  muda, que é a contagem acima.
- **Esperas.** Uma asserção que espera pela página espera aquilo que importa ao teste. Uma gravação
  não espera nada, ou espera uma pausa que alguém acrescentou depois de uma falha, que a aula 3
  mediu e a aula 13 desmonta.
- **Dados.** A fixture esvazia a cesta antes de cada teste. Uma gravação parte do que a loja tinha,
  e o segundo teste do codegen falhou exatamente nisso, e depois passou nisso.
- **CI.** Um arquivo no repositório roda onde o repositório for, do jeito que a aula 5 de
  `testing-cicd` monta. Uma gravação precisa da ferramenta dela, ou do fornecedor dela, do outro
  lado.
- **Intenção.** Um teste chamado `a banana and a mango make two items` diz a quem lê a falha o que
  quebrou. Um teste chamado `test` diz por onde começar a ler.

## Quando um gravador é a ferramenta certa

**O código vence quando o teste precisa durar.** Alguns não precisam, e um gravador os serve bem.

- **Uma reprodução descartável.** A gravação dos onze cliques que derrubam o checkout, anexada a um
  relato de defeito, é um relato melhor que um parágrafo, como a aula 15 de `manual-testing`
  gostaria. Ninguém precisa mantê-la, porque ela é apagada junto com o defeito.
- **Uma primeira verificação de fumaça feita por quem não programa.** Uma testadora sem JavaScript
  grava os cinco caminhos principais da loja numa tarde e tem uma verificação agendada rodando à
  noite. Ela vai quebrar, e tudo bem, desde que todo mundo saiba que é um primeiro passo, não a
  suíte.
- **Gerar localizadores para editar.** O codegen e o `pick.mjs` respondem "como o Playwright chamaria
  isto?" mais rápido do que ler a página. Fique com os seis nomes bons, troque os dois ids aleatórios
  e o texto do total, e leve-os para um page object. Usado assim, o gravador escreve um primeiro
  rascunho e você escreve o teste.

A aula 22 faz a pergunta maior, quais testes valem a pena automatizar. Um gravador torna alguns
testes baratos de criar, e criá-los nunca foi a parte cara.
