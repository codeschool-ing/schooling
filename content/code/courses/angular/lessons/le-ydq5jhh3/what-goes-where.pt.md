---
title: O que pertence a cada nível
version: 1
---

**Cada nível de teste responde uma pergunta diferente, a um preço diferente, e uma falha quer dizer
algo diferente em cada um.** O planner agora tem um teste em cada nível que o Angular tem:

| nível | no planner | o que uma falha quer dizer | preço |
| --- | --- | --- | --- |
| uma função simples | `planner.spec.ts`, `minutes-pipe.spec.ts` | a regra está errada | quase nada, e uma falha aponta para uma função |
| um serviço, com um servidor falso | `planner-store.spec.ts` | o store trata mal uma resposta | o `TestBed`, um backend falso, um `tick()` |
| um componente, pela página | `course-sessions.spec.ts`, `week-summary.spec.ts` | a página mostra a coisa errada | o componente e tudo que ele importa, renderizado no jsdom |
| um componente, com harnesses | o segundo teste de `course-sessions.spec.ts` | um controle não faz o que diz | um harness por controle, e um `await` por passo |
| a aplicação inteira, num navegador | as transcrições de `look` deste curso | as peças não se encaixam | um servidor rodando, um navegador, e segundos por verificação |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Cinco níveis de teste, um por linha, de uma função simples no topo à aplicação inteira num navegador embaixo. Cada linha tem uma barra cujo comprimento é o preço de um teste naquele nível, crescendo de curta a longa, e dá o nome do arquivo do planner naquele nível. Uma seta descendo ao lado diz que, mais para baixo, uma falha cobre mais e aponta menos.\"><text x=\"20\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma função simples</text><rect x=\"230\" y=\"34\" width=\"115\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"238\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">planner.spec.ts</text><text x=\"20\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um serviço, servidor falso</text><rect x=\"230\" y=\"78\" width=\"185\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"238\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">planner-store.spec.ts</text><text x=\"20\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um componente, a página</text><rect x=\"230\" y=\"122\" width=\"250\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"238\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">course-sessions.spec.ts</text><text x=\"20\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um componente, harnesses</text><rect x=\"230\" y=\"166\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"238\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">MatCheckboxHarness</text><text x=\"20\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a aplicação, um navegador</text><rect x=\"230\" y=\"210\" width=\"400\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"238\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">look</text><text x=\"230\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">preço de um teste</text><line x1=\"680\" y1=\"40\" x2=\"680\" y2=\"238\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"680.0,238.0 676.9,230.6 683.1,230.6\" fill=\"var(--wire)\"></polygon><text x=\"672\" y=\"246\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cobre mais, aponta menos</text></svg>", "caption": "Cada regra vai para o nível mais barato que consegue vê-la; os níveis abaixo do topo custam mais e dizem menos sobre onde está o defeito."}
```

Duas regras decidem onde um teste vai.

**Empurre cada regra para o nível mais barato que consegue vê-la.** A aritmética da semana foi
testada pelo `Week` na aula 10, o que precisou do roteador, de um token e de uma página renderizada
para conferir um intervalo de datas. A mesma regra testada no `weekOf` não precisa de nada disso, e
quando falha dá o nome da função. Um teste de componente deve conferir o que o componente acrescenta,
a escolha, a ordenação e o esconder, e confiar nos níveis de baixo para o resto.

**Teste o que uma pessoa ou quem chama consegue ver, nunca como é feito.** Todo teste desta aula lê
um resultado: o texto de uma página, o valor de um signal, a requisição que foi mandada. Nenhum lê um
campo privado ou conta quantas vezes um método rodou. É isso que deixa um teste sobreviver a uma
reescrita do código que ele testa, que é o motivo de ter um.

## O nível que esta aula não escreve

A última linha é o teste ponta a ponta: o servidor de verdade, a API de verdade, um navegador de
verdade, os passos de uma pessoa da primeira página ao resultado. É o único nível que pega um falso
que se afastou do que imita, uma API que renomeou um campo enquanto todo teste seguia respondendo com
o antigo. O CLI do Angular não traz runner para isso; o `ng e2e` oferece acrescentar um, Playwright ou
Cypress entre eles. O programa `look` que este curso usa desde a aula 2 é uma versão pequena da mesma
ideia, o Playwright dirigindo o Chromium, e as transcrições dele são as verificações ponta a ponta
deste curso: rodadas de novo, falhariam se o planner deixasse de fazer o que as aulas dizem.

Testes ponta a ponta valem a pena e custam caro para manter: são lentos, precisam de tudo rodando, e
quando um falha, a causa pode estar em qualquer lugar. Alguns, para os caminhos que mais importam,
marcar uma sessão ou acrescentar uma, cobrem o que os níveis de baixo não cobrem.

## Sobre contar

O `ng test --coverage` relata quais linhas os testes rodaram. Ele precisa de mais um pacote, e diz:

```
ana@dev:~/planner$ npx ng test --watch=false --coverage 2>&1 | tail -3
The following packages are required but were not found:
  - @vitest/coverage-v8
Please install the missing packages and rerun the test command.
```

Instalado, numa versão exata como todo o resto, ele responde "o que não tem teste nenhum", o que é
útil, e mais nada. Uma linha que rodou não foi necessariamente conferida: o "should create" do CLI
rodou cada linha de um construtor e não afirmou nada sobre nenhuma. Escreva o teste que pegaria a
falha que você sabe nomear, como esta aula fez com o domingo e o `PATCH` recusado, e deixe o número
ser o que der.

```
ana@dev:~/planner$ git add -A && git commit -q -m "Tests: the arithmetic, the store against a fake server, a component and a harness"
```
