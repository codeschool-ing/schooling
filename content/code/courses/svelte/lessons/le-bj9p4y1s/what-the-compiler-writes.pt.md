---
title: O que o compilador escreve
version: 1
---

**Um componente é uma descrição, e o compilador a transforma em dois programas**: um que monta o HTML
no servidor, como uma string, e um que dá vida a esse HTML no navegador. O jeito mais rápido de
acreditar nisso é rodar o compilador você mesmo, num componente pequeno, e ler os dois.

Aqui está o componente. Ele não faz parte do planner; é a menor coisa que tem estado, um evento e um
texto que depende do estado. Salve no projeto como `src/lib/Counter.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/Counter.svelte", "parts": [
 {"code": "<script>\n\tlet minutes = $state(0);\n</script>", "note": "O script roda uma vez, quando o componente é criado. `$state(0)` marca `minutes` como um valor do qual a página depende."},
 {"code": "<button onclick={() => (minutes += 30)}>Add 30 minutes</button>\n<p>{minutes} minutes this week</p>", "note": "A marcação é HTML com expressões entre chaves. `onclick` é um atributo comum cujo valor é uma função."}
]}
```

O compilador é uma função, `compile`, exportada pelo pacote `svelte` que o projeto já tem. Este
script, salvo como `compile.mjs` na raiz do projeto, lê um componente, compila e imprime o
JavaScript produzido:

```javascript
// compile.mjs: compile one component and print the JavaScript it becomes.
//   node compile.mjs FILE.svelte [client|server]
import { compile } from "svelte/compiler";
import fs from "node:fs";

const [file, generate = "client"] = process.argv.slice(2);
const { js } = compile(fs.readFileSync(file, "utf8"), { filename: file, generate });
console.log(js.code);
```

## A metade do navegador

```
ana@dev:~/planner$ node compile.mjs src/lib/Counter.svelte
import 'svelte/internal/disclose-version';
import * as $ from 'svelte/internal/client';

var root = $.from_html(`<button>Add 30 minutes</button> <p> </p>`, 1);

export default function Counter($$anchor) {
	let minutes = $.state(0);
	var fragment = root();
	var button = $.first_child(fragment);
	var p = $.sibling(button, 2);
	var text = $.only_child(p);

	$.template_effect(() => $.set_text(text, `${$.get(minutes) ?? ''} minutes this week`));
	$.delegated('click', button, () => $.set(minutes, $.get(minutes) + 30));
	$.append($$anchor, fragment);
}

$.delegate(['click']);
```

Leia de cima para baixo, porque cada linha é algo que o navegador não precisa descobrir:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um arquivo, Counter.svelte, entra no compilador e sai como dois programas. O programa do cliente tem a marcação como template, minutes como um signal lido com get e escrito com set, um efeito que define o texto do parágrafo e um listener de clique delegado. O programa do servidor tem minutes como uma variável comum e empurra uma string de HTML com o valor escapado. O que nenhum dos dois tem é uma descrição da página guardada para comparar com a próxima.\"><rect x=\"20\" y=\"110\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Counter.svelte</text><text x=\"95\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que você escreve</text><line x1=\"170\" y1=\"145\" x2=\"218\" y2=\"145\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"218.0,145.0 210.6,148.1 210.6,141.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"220\" y=\"115\" width=\"110\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">compile()</text><text x=\"275\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no seu computador</text><path d=\"M330 135 C 360 135, 360 70, 390 70\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><line x1=\"388\" y1=\"70\" x2=\"396\" y2=\"70\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"396.0,70.0 388.6,73.1 388.6,66.9\" fill=\"var(--phosphor)\"></polygon><path d=\"M330 155 C 360 155, 360 225, 390 225\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><line x1=\"388\" y1=\"225\" x2=\"396\" y2=\"225\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"396.0,225.0 388.6,228.1 388.6,221.9\" fill=\"var(--phosphor)\"></polygon><rect x=\"398\" y=\"18\" width=\"302\" height=\"118\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"410\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">cliente: roda no navegador</text><text x=\"410\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">$.from_html(`&lt;button&gt;…`)</text><text x=\"410\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">let minutes = $.state(0)</text><text x=\"410\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">$.template_effect(() =&gt; $.set_text(…))</text><text x=\"410\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">$.delegated('click', button, …)</text><rect x=\"398\" y=\"168\" width=\"302\" height=\"92\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"410\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">servidor: monta o HTML uma vez</text><text x=\"410\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">let minutes = 0</text><text x=\"410\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">$$renderer.push(`&lt;button&gt;…</text><text x=\"410\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">  ${$.escape(minutes)}…`)</text><text x=\"360\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">nenhum dos dois guarda uma cópia da página para comparar com a próxima</text></svg>", "caption": "Um componente, dois programas: um vivo para o navegador e um montador de string para o servidor."}
```

- **A marcação virou uma string de template**, `root`, transformada uma vez em nós do DOM e copiada
  cada vez que um `Counter` é criado. O `<p>` guarda um único espaço onde o texto vai ficar.
- **`minutes` virou `$.state(0)`**, e cada leitura dela virou `$.get(minutes)` e cada escrita
  `$.set(minutes, …)`. Esse é todo o truque do `$state`: o compilador reescreveu a sua variável como
  um signal, um valor que sabe quem o lê. A aula 2 trata do que isso dá.
- **Um `template_effect` define um nó de texto.** É o único código que roda quando `minutes` muda, e
  ele muda exatamente o texto dentro do `<p>`. Nada mais na página é olhado.
- **`onclick` virou `$.delegated('click', …)`**, um listener na raiz do documento cuidando dos
  cliques de cada botão que pediu um. A aula 7 volta a isso.

O que falta é o ponto. Não há uma descrição da página guardada na memória para comparar com a
próxima, e nada percorre a marcação em tempo de execução para descobrir o que mudou. O compilador
descobriu isso uma vez, a partir do código-fonte, e escreveu a resposta.

## A metade do servidor

```
ana@dev:~/planner$ node compile.mjs src/lib/Counter.svelte server
import * as $ from 'svelte/internal/server';

export default function Counter($$renderer) {
	let minutes = 0;

	$$renderer.push(`<button>Add 30 minutes</button> <p>${$.escape(minutes)} minutes this week</p>`);
}
```

**No servidor, o `$state` desaparece por completo.** `minutes` é um `let` comum, porque uma página
renderizada no servidor é uma string mandada uma vez e nunca atualizada lá; não há a que reagir. O
componente é uma função que empurra HTML para o `$$renderer`, com `$.escape` em volta do valor para
que um texto que parece marcação não possa virar marcação. Quando o navegador recebe esse HTML, a
metade do cliente encontra os nós já na página em vez de criá-los, e se liga a eles. Esse passo se
chama **hidratação**, e a aula 15 o abre.

Você não vai rodar o `compile.mjs` de novo neste curso; o Vite chama a mesma função cada vez que você
salva um arquivo. Guarde o script, mesmo assim. Quando um componente se comportar de um jeito que
você não consegue explicar, compilá-lo e ler o que saiu é um jeito legítimo de descobrir o porquê.
