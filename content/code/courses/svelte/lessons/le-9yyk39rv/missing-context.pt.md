---
title: Quando nada acima o definiu
version: 1
---

**`getPlanner()` lança um erro quando nenhum componente acima chamou `setPlanner()`.** Isso é um
recurso do `createContext`, e uma melhora em relação ao antigo `getContext(key)`, que devolvia
`undefined` em silêncio e deixava o componente falhar depois, num lugar menos útil. Para ver, use o
`Days` onde não há planner: numa página própria, `src/routes/days/+page.svelte`, sem nada em volta:

```html
<!-- src/routes/days/+page.svelte -->
<script>
	import Days from '#lib/Days.svelte';
</script>

<main>
	<Days />
</main>
```

```
ana@dev:~/planner$ look http://localhost:5173/days
at /days
- heading "500" [level=1]
- paragraph: Internal Error
```

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

8:53:23 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 680 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
Svelte error: missing_context
Context was not set in the current component or any of its ancestors
https://svelte.dev/e/missing_context
    at eval (src/lib/Days.svelte:5:18)
    at eval (node_modules/svelte/src/internal/server/renderer.js:413:11)
    at Renderer.child (node_modules/svelte/src/internal/server/renderer.js:302:18)
    at Renderer.component (node_modules/svelte/src/internal/server/renderer.js:411:8)
    at Days (src/lib/Days.svelte:3:2)
    at eval (src/routes/days/+page.svelte:2:1)
500 GET /days
```

**`missing_context` diz o que está errado na primeira linha**, e o stack embaixo diz qual componente
pediu: `Days.svelte`, chamado pela página. A correção nunca está no `Days`; está em renderizá-lo dentro
de algo que definiu o contexto, que é o contrato inteiro. Apague a pasta, `rm -r src/routes/days`,
depois de ver.

## Quando um contexto é opcional

Às vezes um componente funciona com ou sem o seu contexto: uma lista que destaca o curso selecionado
quando há um planner em volta, e mostra linhas simples quando não há. O `createContext` devolve uma
terceira função para isso, que diz se o contexto foi definido:

```javascript
export const [getPlanner, setPlanner, hasPlanner] = createContext();
```

e o componente pergunta antes de obter: `const planner = hasPlanner() ? getPlanner() : null;`. Os
componentes do planner exigem um, então o obtêm sem condição e deixam o erro falar.

## Só enquanto o componente está sendo criado

**O contexto é lido e escrito durante a criação de um componente, no nível de cima do script**, e em
nenhum outro lugar. Chamar `getPlanner()` dentro de um handler de evento, de um `setTimeout` ou de um
efeito que roda depois falha, porque a essa altura o Svelte já não sabe qual componente está
perguntando. Os componentes do planner o chamam uma vez, no topo, e guardam o resultado numa
constante, que é o padrão a copiar: obtenha cedo, use quando quiser.
