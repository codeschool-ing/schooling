---
title: Eventos são atributos
version: 1
---

**No Svelte 5 um handler de evento é um atributo como qualquer outro, com o nome `on` seguido do
evento:** `onclick`, `oninput`, `onsubmit`, `onkeydown`. O valor dele é uma função, que o navegador
chama com o evento quando ele acontece. Não há sintaxe especial para aprender além disso, e esse é o
ponto: um handler pode ser passado como prop, espalhado com `{...rest}`, escolhido com um ternário ou
deixado de fora, exatamente como `class` ou `href`.

O planner já os usa. Os botões do `WeekNav` têm `onclick={() => onchange(addDays(week, -7))}`, uma
arrow function que ignora o evento; o `CourseList` tem a mesma forma. Quando a função precisa do
evento, ela o recebe como parâmetro:

```javascript
function report(event) {
	console.log(event.type, event.currentTarget.textContent);
}
```

e é passada pelo nome, `onclick={report}`, ou pelo atalho `{onclick}` quando uma variável com esse
nome a guarda. `event.currentTarget` é o elemento em que o handler está; `event.target` é o elemento
onde o evento começou, que é outro quando você clica num `<span>` dentro de um botão.

## Os que você vai usar

| atributo | dispara quando | uso típico no planner |
|---|---|---|
| `onclick` | um botão é apertado, por mouse, toque ou teclado | os botões da semana, os botões dos cursos |
| `oninput` | o valor de um campo muda, a cada tecla | o que o `bind:value` usa por baixo |
| `onchange` | o valor de um campo é confirmado: um checkbox marcado, uma data escolhida | o que o `bind:checked` usa por baixo |
| `onsubmit` | um formulário é enviado, pelo botão ou por Enter num campo | acrescentar uma sessão, na próxima seção |
| `onkeydown` | uma tecla desce, no elemento com foco ou na janela | os atalhos da semana, em "O teclado, e os elementos que respondem a ele" |

**`onclick` num `<button>` também é o handler do teclado.** O navegador dispara `click` num botão com
foco quando Enter ou Espaço é apertado, então um botão não precisa de mais nada para ser operável
pelo teclado. Esse é o principal motivo de os controles do planner serem botões, e é a propriedade de
que a seção sobre o teclado depende.

## Delegação

O contador compilado da aula 1 registrou o seu clique com `$.delegated('click', …)` e um único
`$.delegate(['click'])`. Para os eventos comuns, o Svelte põe **um** listener na raiz da aplicação em
vez de um por elemento, e ele mesmo despacha para o handler certo. Uma lista de trezentas sessões com
um checkbox cada custa um listener, e não trezentos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um clique num de três botões, com delegação. Os botões não têm listeners próprios; os handlers ficam guardados nos elementos. O clique sobe do botão pelo item da lista e pela lista até a raiz da aplicação, onde um listener de click acha o handler guardado no botão e o chama. Um listener acrescentado à mão na lista que pare a propagação pararia o clique antes de ele chegar à raiz.\"><rect x=\"20\" y=\"20\" width=\"680\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">a raiz da aplicação: um listener de click</text><rect x=\"60\" y=\"100\" width=\"600\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">&lt;ul&gt;</text><rect x=\"90\" y=\"140\" width=\"160\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;button&gt;</text><text x=\"170\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Linear algebra</text><rect x=\"280\" y=\"140\" width=\"160\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;button&gt;</text><text x=\"360\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">Spanish</text><rect x=\"470\" y=\"140\" width=\"160\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;button&gt;</text><text x=\"550\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Guitar</text><path d=\"M370 140 C 370 110, 390 100, 390 74\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><line x1=\"390\" y1=\"80\" x2=\"390\" y2=\"72\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"390.0,72.0 393.1,79.4 386.9,79.4\" fill=\"var(--amber)\"></polygon><text x=\"400\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o clique sobe</text><text x=\"360\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o handler é procurado no botão clicado, e chamado</text></svg>", "caption": "Delegação: um listener na raiz em vez de um por botão. O clique tem de chegar até ele.", "same": ["Guitar", "Linear algebra", "Spanish"]}
```

Você não vai notar a delegação até parar um evento no caminho para cima. **`event.stopPropagation()`
num handler comum de `addEventListener` num elemento pai também impede o evento de chegar à raiz**,
onde os handlers delegados do Svelte esperam, e um botão dentro desse elemento então não faz nada. Se
você precisar parar a propagação, faça isso em handlers do Svelte, que conhecem a delegação, e não em
listeners acrescentados à mão.
