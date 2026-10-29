---
title: Um componente genérico
version: 1
---

**O último erro estava na página do curso, no snippet que desenha a linha de uma sessão**, e a causa está
em `List.svelte`. O `List` recebe `items` e um snippet `row` que desenha um deles, e nada diz que os dois
são do mesmo tipo, então dentro de `{#snippet row(session)}` o verificador não faz ideia do que `session`
é. A lista não se importa com o que são os seus itens, desde que cada um tenha um `id` para o `{#each}`
com chave. É isso que um **genérico** diz: o componente funciona para qualquer tipo de item, e qualquer
que seja o tipo recebido, o snippet recebe o mesmo.

Substitua `src/lib/List.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/List.svelte", "parts": [
 {"code": "<script lang=\"ts\" generics=\"Item extends { id: number }\">\n\timport type { Snippet } from 'svelte';\n\timport { slide } from 'svelte/transition';\n\timport { flip } from 'svelte/animate';\n\timport { prefersReducedMotion } from 'svelte/motion';", "note": "`generics` declara um parâmetro de tipo para o componente inteiro, como `<T>` faz para uma função. `Item` pode ser qualquer tipo que tenha um `id` numérico."},
 {"code": "\tlet { items, row, empty }: { items: Item[]; row: Snippet<[Item]>; empty?: Snippet } = $props();\n\n\tlet duration = $derived(prefersReducedMotion.current ? 0 : 300);\n</script>", "note": "`Snippet<[Item]>` é um snippet que recebe um argumento, um `Item`. Com sessões em `items`, `row` recebe uma sessão."},
 {"code": "{#if items.length}\n\t<ul>\n\t\t{#each items as item (item.id)}\n\t\t\t<li transition:slide={{ duration }} animate:flip={{ duration }}>{@render row(item)}</li>\n\t\t{/each}\n\t</ul>\n{:else}\n\t{@render empty?.()}\n{/if}"}
]}
```

```
ana@dev:~/planner$ npm run check 2>&1 | tail -1
svelte-check found 0 errors and 0 warnings
```

**Zero.** Nada na página do curso mudou: o `items={sessions}` dela sempre foi uma lista de sessões, e
agora o verificador consegue levar esse tipo através do `List` até o snippet. A página pode continuar
JavaScript ou virar TypeScript; com o `List` genérico, o `session` do snippet é uma `Session` de um jeito
ou de outro.

## Quanto vale o zero

Cometa o erro que a primeira seção imaginou, de propósito: um erro de digitação no nome de uma
propriedade, na página do curso.

```
ana@dev:~/planner$ sed -i 's/{session.minutes} min/{session.minuts} min/' 'src/routes/(planner)/courses/[id=slug]/+page.svelte'
```

```
ana@dev:~/planner$ npm run check 2>&1 | grep -A4 Error
Error: Property 'minuts' does not exist on type 'Session'. Did you mean 'minutes'? (js)
			<input type="hidden" name="done" value={session.done ? 'no' : 'yes'} />
			<span class:done={session.done}>{format(session.date)}, {session.minuts} min</span>
			<button aria-label="{session.done ? 'Mark not done' : 'Mark done'}: {format(session.date)}">
```

**Pego, com uma sugestão**, num arquivo que ainda é JavaScript. Sem a verificação, a página teria
desenhado `undefined min` ao lado de cada sessão, e o primeiro a notar teria sido um estudante. Desfaça:

```
ana@dev:~/planner$ sed -i 's/{session.minuts} min/{session.minutes} min/' 'src/routes/(planner)/courses/[id=slug]/+page.svelte'
```

Uma contagem de zero é útil justamente por ser zero: um erro novo salta aos olhos, onde um a mais entre
sessenta e seis não saltaria. Mantê-la ali é questão de rodar `npm run check` antes de cada commit, e a
aula 19 acrescenta os testes para rodar ao lado.
