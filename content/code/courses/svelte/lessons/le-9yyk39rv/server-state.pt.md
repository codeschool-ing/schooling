---
title: Por que não um módulo, no servidor
version: 1
---

**Um valor exportado de um módulo existe uma vez por processo, e no servidor um processo atende todos
os visitantes.** No navegador isso não é problema: o navegador guarda uma página para uma pessoa,
então um valor no nível do módulo é dessa pessoa. Durante a renderização no servidor, toda requisição
roda o mesmo módulo importado, e um valor que uma requisição muda é o valor que a próxima encontra.
Esse é o motivo de o contexto existir ao lado dos módulos, e o motivo de o planner pôr a sua instância
no contexto em vez de exportá-la.

Aqui está o erro na sua forma mais curta. Um módulo guarda o nome de um visitante, e uma página o
define a partir do endereço e cumprimenta quem estiver guardado. Salve o módulo como
`src/lib/visitor.svelte.js`:

```javascript
// visitor.svelte.js: one visitor's name, in a module. This is the mistake.
export const visitor = $state({ name: null });
```

e a página como `src/routes/hello/+page.svelte`:

```html
<!-- src/routes/hello/+page.svelte -->
<script>
	import { page } from '$app/state';
	import { visitor } from '#lib/visitor.svelte.js';

	const name = page.url.searchParams.get('name');
	if (name) visitor.name = name;
</script>

<main>
	<p>Hello, {visitor.name ?? 'stranger'}.</p>
</main>
```

O `page` de `$app/state` é a página atual, e `page.url.searchParams` lê o `?name=…` do endereço. Agora
seja duas pessoas. A Ana abre a página com o nome dela; um instante depois, outra pessoa a abre sem
nome nenhum:

```
ana@dev:~/planner$ curl -s 'http://localhost:5173/hello?name=Ana' | grep -o 'Hello[^<]*'
Hello, Ana.
ana@dev:~/planner$ curl -s http://localhost:5173/hello | grep -o 'Hello[^<]*'
Hello, Ana.
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Um processo de servidor atendendo dois visitantes. À esquerda, com um módulo: as duas requisições importam o mesmo módulo, que guarda um único objeto visitor; a requisição da Ana define o nome, e a do desconhecido, um instante depois, lê o mesmo objeto e é cumprimentada como Ana. À direita, com contexto: cada requisição cria o seu próprio componente de página, e cada componente põe o seu próprio visitor no contexto, então cada saudação lê o seu.\"><text x=\"180\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">um módulo: um para todas as requisições</text><rect x=\"20\" y=\"40\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">?name=Ana</text><rect x=\"190\" y=\"40\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sem nome</text><rect x=\"80\" y=\"130\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">visitor.svelte.js</text><text x=\"180\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">{ name: 'Ana' }</text><line x1=\"95\" y1=\"80\" x2=\"150\" y2=\"128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"150.0,128.0 142.4,125.5 146.5,120.8\" fill=\"var(--paper-dim)\"></polygon><line x1=\"265\" y1=\"80\" x2=\"210\" y2=\"128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"210.0,128.0 213.5,120.8 217.6,125.5\" fill=\"var(--paper-dim)\"></polygon><text x=\"95\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Hello, Ana.</text><text x=\"265\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Hello, Ana.</text><text x=\"540\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">contexto: um por requisição</text><rect x=\"380\" y=\"40\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">?name=Ana</text><rect x=\"550\" y=\"40\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sem nome</text><rect x=\"380\" y=\"130\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"455\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">o seu contexto</text><text x=\"455\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">{ name: 'Ana' }</text><line x1=\"455\" y1=\"80\" x2=\"455\" y2=\"128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"455.0,128.0 451.9,120.6 458.1,120.6\" fill=\"var(--paper-dim)\"></polygon><text x=\"455\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Hello, Ana.</text><rect x=\"550\" y=\"130\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">o seu contexto</text><text x=\"625\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">{ name: null }</text><line x1=\"625\" y1=\"80\" x2=\"625\" y2=\"128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"625.0,128.0 621.9,120.6 628.1,120.6\" fill=\"var(--paper-dim)\"></polygon><text x=\"625\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Hello, stranger.</text><text x=\"360\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o mesmo código, o mesmo servidor: só muda onde o valor mora</text></svg>", "caption": "Um valor no nível do módulo é compartilhado por toda requisição que o servidor atende. Um contexto pertence a uma."}
```

**O segundo visitante foi cumprimentado como Ana.** A primeira requisição definiu `visitor.name` na
única cópia do módulo que o servidor tem, e a segunda, de outra pessoa completamente diferente,
renderizou com ele. Troque um nome pelas sessões de um aluno, ou por qualquer coisa privada, e isto é
um vazamento de dados entre desconhecidos, produzido por um código que funcionou perfeitamente
enquanto uma pessoa o testava num navegador.

## A mesma página, com contexto

O contexto é criado por instância de componente, e no servidor cada requisição cria as suas próprias
instâncias, então um valor no contexto pertence a uma requisição. A correção mantém o módulo, mas faz
ele exportar um par de funções em vez de uma instância:

```javascript
// visitor.svelte.js: one visitor's name, in context, so one per request.
import { createContext } from 'svelte';

export const [getVisitor, setVisitor] = createContext();
```

```html
<!-- src/routes/hello/+page.svelte -->
<script>
	import { page } from '$app/state';
	import { setVisitor } from '#lib/visitor.svelte.js';

	const visitor = $state({ name: page.url.searchParams.get('name') });
	setVisitor(visitor);
</script>

<main>
	<p>Hello, {visitor.name ?? 'stranger'}.</p>
</main>
```

```
ana@dev:~/planner$ curl -s 'http://localhost:5173/hello?name=Ana' | grep -o 'Hello[^<]*'
Hello, Ana.
ana@dev:~/planner$ curl -s http://localhost:5173/hello | grep -o 'Hello[^<]*'
Hello, stranger.
```

Cada requisição criou o seu visitante, e o desconhecido é um desconhecido. Apague o experimento,
`rm -r src/routes/hello src/lib/visitor.svelte.js`.

**A regra que sai disso é curta: numa página que renderiza no servidor, nada que pertença a uma pessoa
vai numa variável no nível do módulo.** Módulos são para coisas que são iguais para todo mundo: uma
função, uma constante, um store que lê a hora. O estado que pertence a um visitante é criado num
componente, e compartilhado com contexto.
