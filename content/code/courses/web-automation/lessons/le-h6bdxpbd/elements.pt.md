---
title: O painel Elements, e a página que um teste vê
version: 1
---

Todo navegador que você provavelmente vai usar tem ferramentas de desenvolvedor embutidas. Abra a
loja no Chrome, no Edge ou no Firefox, clique com o botão direito no cartão **Banana** e escolha
**Inspecionar**: um painel abre, ao lado ou embaixo da página, com o elemento que você clicou
destacado numa árvore de tags. **F12** abre o mesmo painel, e Ctrl+Shift+I também, ou
Cmd+Option+I num Mac. A aula 22 de `javascript` usa essas ferramentas para depurar um script que
você escreveu. Esta aula as usa como um testador usa: para descobrir o que um teste vai encontrar
antes de escrevê-lo.

## A árvore não é o arquivo

A primeira ideia comum sobre o painel Elements é que ele mostra o HTML da página. **Ele mostra a
página como ela está agora**, o que é outra coisa, e a loja deixa a diferença fácil de ver. Isto é o
que o servidor envia quando o navegador pede `/`, na parte dos produtos:

```
ana@laptop:~/quitanda$ curl -s http://localhost:3000/ | grep -n products
22:    <ul id="products" aria-busy="true"></ul>
```

Uma lista vazia, com `aria-busy="true"`. No painel Elements, o mesmo `<ul>` tem oito elementos
`<li>` e diz `aria-busy="false"`. Nada no arquivo mudou. O script rodou depois que a página carregou,
pediu os produtos ao servidor e montou os cartões dentro da página.

O que o painel mostra é o **DOM**, o Document Object Model: a árvore de objetos que o navegador
monta a partir do HTML e que os scripts depois alteram. A aula 11 de `javascript` mostra como um
script o lê e o altera. Para a automação, a consequência cabe numa frase: **um teste vê o DOM,
nunca o arquivo**. Botão direito e **Exibir código-fonte da página** mostra o arquivo, o que serve
para exatamente uma pergunta, o que chegou antes de qualquer script rodar, e essa pergunta volta na
aula 6.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"À esquerda, o HTML que o servidor enviou: uma lista vazia marcada aria-busy true. Uma seta com o rótulo app.js roda e pede /api/products leva à direita, ao DOM um instante depois: a mesma lista com oito cartões e aria-busy false.\"><rect x=\"20\" y=\"40\" width=\"250\" height=\"170\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"36\" y=\"66\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">o que o servidor enviou</text><text x=\"36\" y=\"104\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">&lt;ul id=\"products\"</text><text x=\"36\" y=\"124\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">    aria-busy=\"true\"&gt;</text><text x=\"36\" y=\"144\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">&lt;/ul&gt;</text><text x=\"36\" y=\"186\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">nenhum produto nela</text><path d=\"M280 125 L430 125\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M430 125 L420 119 L420 131 Z\" fill=\"var(--phosphor)\"></path><text x=\"355\" y=\"105\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">app.js runs</text><text x=\"355\" y=\"150\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">e pede</text><text x=\"355\" y=\"166\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">/api/products</text><rect x=\"440\" y=\"20\" width=\"260\" height=\"210\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"456\" y=\"46\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">o DOM, um instante depois</text><text x=\"456\" y=\"76\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">&lt;ul id=\"products\"</text><text x=\"456\" y=\"96\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">    aria-busy=\"false\"&gt;</text><rect x=\"470\" y=\"108\" width=\"200\" height=\"16\" rx=\"3\" fill=\"var(--scan)\"></rect><rect x=\"470\" y=\"128\" width=\"200\" height=\"16\" rx=\"3\" fill=\"var(--scan)\"></rect><rect x=\"470\" y=\"148\" width=\"200\" height=\"16\" rx=\"3\" fill=\"var(--scan)\"></rect><text x=\"570\" y=\"178\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">… oito cartões ao todo</text><text x=\"456\" y=\"212\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">&lt;/ul&gt;</text></svg>", "caption": "A mesma lista duas vezes. Um teste que olha entre os dois momentos não acha nada para clicar."}
```

## O que ler num elemento

No painel Elements, clique no botão **Add to basket** dentro do cartão Banana. Quatro coisas nele, e
nos elementos em volta, decidem como um teste consegue achá-lo de novo:

- **a tag e o texto**: um `<button>` cujo texto é *Add to basket*. É também como uma pessoa o acha;
- **o papel e o nome acessível**, mostrados na aba **Accessibility** do painel: o papel é `button` e
  o nome é *Add to basket*. É o que um leitor de tela anuncia, e o que o `getByRole` do Playwright,
  o localizador que o teste de fumaça usou para o título, procura;
- **atributos escritos para testes**: o cartão em volta tem `data-testid="product-banana"`, um
  atributo que existe só para ser encontrado;
- **atributos que por acaso estão lá**: o `id` do cartão, algo como `card-4821`.

**Recarregue a página e olhe esse `id` de novo.** O número é outro, porque o `app.js` o sorteia a
cada vez, e o comentário ao lado dessa linha o chama de falha conhecida. Um teste que achasse o
cartão pelo `id` copiado deste painel falharia já na primeira execução, porque a página que ele abre sorteia outro número. A aula 2 trata de
distinguir essas quatro coisas, e de por que a última é a armadilha.

## Testando um localizador antes de escrevê-lo

No painel Elements, Ctrl+F (Cmd+F num Mac) abre uma caixa de busca que aceita texto puro, um
seletor CSS ou uma expressão XPath, e diz quantos elementos batem: `1 of 8` para `.card button`
enquanto os produtos estão na tela, por exemplo. **Um localizador que acha o número errado de
elementos já está errado antes de qualquer teste rodar**, e essa caixa é o lugar mais barato para
descobrir isso. A aula 2 a usa para cada seletor que mostra.

Você também pode mudar a página ali: clique duas vezes num atributo para editá-lo, ou apague um
elemento com a tecla Delete. A mudança dura até o próximo carregamento e não toca no servidor, o que
faz dela um jeito seguro de perguntar *o que o meu teste faria se este botão sumisse?*
