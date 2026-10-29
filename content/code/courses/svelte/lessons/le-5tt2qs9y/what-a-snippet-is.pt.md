---
title: No que um snippet se transforma
version: 1
---

**Um snippet é uma função, e o `{@render}` a chama.** O `compile.mjs` da aula 1 mostra isso direto.
Rode-o no `List.svelte`:

```
ana@dev:~/planner$ node compile.mjs src/lib/List.svelte
import 'svelte/internal/disclose-version';
import * as $ from 'svelte/internal/client';

var root = $.from_html(`<li><!></li>`);
var root_1 = $.from_html(`<ul></ul>`);

export default function List($$anchor, $$props) {
	$.push($$props, true);

	var fragment = $.comment();
	var node = $.first_child(fragment);

	{
		var consequent = ($$anchor) => {
			var ul = root_1();

			$.each(ul, 21, () => $$props.items, (item) => item.id, ($$anchor, item) => {
				var li = root();
				var node_1 = $.child(li);

				$.snippet(node_1, () => $$props.row, () => $.get(item));
				$.reset(li);
				$.append($$anchor, li);
			});

			$.reset(ul);
			$.append($$anchor, ul);
		};

		var alternate = ($$anchor) => {
			var fragment_1 = $.comment();
			var node_2 = $.first_child(fragment_1);

			$.snippet(node_2, () => $$props.empty ?? $.noop);
			$.append($$anchor, fragment_1);
		};

		$.if(node, ($$render) => {
			if ($$props.items.length) $$render(consequent); else $$render(alternate, -1);
		});
	}

	$.append($$anchor, fragment);
	$.pop();
}
```

A linha a procurar é `$.snippet(node_1, () => $$props.row, () => $.get(item))`. Ela diz três coisas:
renderize em `node_1`, o lugar que o template deixou no `<li>`; o snippet a renderizar é o que `row`
for **agora**, e é por isso que o primeiro argumento é uma função; e o argumento a passar é `item`,
também atrás de uma função. O ramo do `empty` é a mesma chamada com `?? $.noop`, a função que não faz
nada que o `?.()` pediu para quando nenhum `empty` foi dado.

## Parâmetros são lidos quando são usados

Esse último detalhe tem uma consequência que vale conhecer. **O parâmetro de um snippet não é uma
cópia do valor passado; é um jeito de lê-lo.** Quando `item` muda, uma linha que leu `item.minutes` se
atualiza, porque cada uso do parâmetro dentro do snippet volta por `() => $.get(item)`. Então um
snippet se comporta como a marcação que ele substituiu: continua vivo.

O mesmo vale para o próprio snippet. Se a página trocasse o snippet `row` por outro depois, a lista
começaria a renderizar o novo, porque o `List` pede `$$props.row` a cada vez em vez de guardar o
primeiro que viu.

## Mais três formas

**Um snippet pode ser passado explicitamente**, como qualquer prop, quando é declarado em outro
lugar. Um snippet declarado no nível mais alto da marcação da página poderia ser dado ao `List` como
`<List items={ofCourse} {row} />`. Declará-lo entre as tags é um atalho exatamente para isso.

**Parâmetros podem ser desestruturados, com valores padrão**: `{#snippet row({ date, minutes })}` lê
os dois campos de que precisa, e `{#snippet badge(label = 'new')}` tem um padrão. Eles não podem ser
reatribuídos dentro do snippet, o que é coerente com o que são: uma vista de algo que pertence a outro
lugar.

**Um componente cujo `children` é opcional** os renderiza como `{@render children?.()}`, o mesmo
`?.()` do `empty`. Um `Panel` usado sem conteúdo entre as tags renderizaria então só o seu título, em
vez de falhar.
