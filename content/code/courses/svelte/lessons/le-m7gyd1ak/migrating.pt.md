---
title: Migrando um componente
version: 1
---

**O compilador do Svelte consegue reescrever um componente Svelte 4 como um Svelte 5**, e faz a maior
parte do trabalho. A função é `migrate`, exportada de `svelte/compiler` ao lado do `compile` que você
chamou na aula 1, e um script do mesmo tamanho a chama. Salve como `migrate.mjs` ao lado do
`compile.mjs`:

```javascript
// migrate.mjs: print a Svelte 4 component rewritten for Svelte 5.
//   node migrate.mjs FILE.svelte
import { migrate } from "svelte/compiler";
import fs from "node:fs";

const [file] = process.argv.slice(2);
const { code } = migrate(fs.readFileSync(file, "utf8"), { filename: file });
process.stdout.write(code);
```

Ele imprime o componente reescrito e não muda nada no disco, então você pode lê-lo antes de decidir.
Rode no `WeekNav.svelte` como a penúltima seção o deixou:

```
ana@dev:~/planner$ node migrate.mjs src/lib/WeekNav.svelte
<svelte:options runes={false} />
<script>
	import { createEventDispatcher } from 'svelte';
	import { addDays, format } from '#lib/week.js';
	/**
	 * @typedef {Object} Props
	 * @property {any} week
	 * @property {string} [label]
	 */

	/** @type {Props} */
	let { week = $bindable(), label = 'Week of' } = $props();

	const dispatch = createEventDispatcher();
	let shown = $derived(`${label} ${format(week)}`);
	function move(days) {
		week = addDays(week, days);
		dispatch('change', { week });
	}
</script>
<p>
	<button onclick={() => move(-7)}>Previous week</button>
	{shown}
	<button onclick={() => move(7)}>Next week</button>
</p>
```

## O que ele fez

Linha por linha, a tabela do começo desta aula:

- **`<svelte:options runes={false} />` continua lá, e você precisa removê-lo.** O migrador muda a
  sintaxe e deixa em paz as opções do arquivo, e essa linha poria o resultado de volta no modo
  legado, onde `$props` é um erro.
- **`export let` virou `$props()`**, com um comentário JSDoc descrevendo o tipo de cada prop, deduzido
  do que ele conseguiu ver: `label` tem um padrão string, então é `string`, e `week` pode ser qualquer
  coisa.
- **`$: shown = …` virou `$derived(…)`**, o que é seguro aqui: as leituras da expressão agora são
  rastreadas em tempo de execução, então até a versão com `describe()` da seção anterior teria sido
  consertada por ele.
- **`on:click` virou `onclick`.**

## O que ele deixou para você

Duas coisas, e as duas são decisões, não sintaxe, e é por isso que uma ferramenta não as toma.

**O `createEventDispatcher` continua lá.** Ele ainda funciona no Svelte 5, obsoleto, e o migrador o
deixa em paz porque substituí-lo significa mudar também os pais do componente: cada `on:change` do
projeto teria de virar um `onchange`.

**`week` saiu como `$bindable()`**, porque o componente Svelte 4 atribuía à sua própria prop. O
migrador manteve esse comportamento como estava. Mas o componente nunca precisou ser dono da semana:
ele só precisa dizer ao pai qual semana mostrar em seguida. Uma prop de callback diz isso de um jeito
mais simples que uma ligação de mão dupla, e a aula 5 trata de quando cada uma é a certa.

Então termine à mão. Esta é a versão que o planner guarda:

```schooling-example
{"language": "html", "file": "src/lib/WeekNav.svelte", "parts": [
 {"code": "<script>\n\timport { addDays, format } from '#lib/week.js';\n\n\tlet { week, label = 'Week of', onchange } = $props();\n\n\tlet shown = $derived(`${label} ${format(week)}`);\n</script>", "note": "`onchange` é uma prop como as outras: uma função que o pai passa, e que este componente chama."},
 {"code": "<p>\n\t<button onclick={() => onchange(addDays(week, -7))}>Previous week</button>\n\t{shown}\n\t<button onclick={() => onchange(addDays(week, 7))}>Next week</button>\n</p>", "note": "O componente não atribui mais a `week`. Ele pede ao pai para movê-la, e o `week` novo desce de volta como prop."}
]}
```

E no `+page.svelte`, a linha que o usa escuta com o callback em vez de `on:change`:

```html
<WeekNav {week} onchange={(next) => (week = next)} />
```

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Previous week'
-- click Previous week
at /
title: 90 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 12 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 60 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 0 min
  - paragraph: 90 minutes this week (1 h 30 min)
  - heading "Linear algebra" [level=2]
  - list:
    - listitem:
      - button "13 Oct 2026, 60 min" [pressed]
    - listitem:
      - button "19 Oct 2026, 90 min" [pressed]
    - listitem:
      - button "24 Oct 2026, 60 min"
  - paragraph: 60 minutes for Linear algebra this week (1 h 0 min)
  - button "Add 30 minutes on 12 Oct 2026"
```

A semana de 12 de outubro, como na aula 3, com um componente a menos para ler na página. Para migrar
um projeto inteiro em vez de um arquivo, `npx sv migrate svelte-5` roda a mesma reescrita em cada
componente e atualiza o `package.json`; isso não foi rodado neste curso, porque o planner já nasceu
no Svelte 5.
