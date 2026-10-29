---
title: Callbacks entre componentes
version: 1
---

**Um componente avisa o pai de que algo aconteceu chamando uma função que o pai passou como prop.** É
só isso que um evento de componente é no Svelte 5, e o planner tem três: o `WeekNav` chama `onchange`,
o `CourseList` chamava `onselect` antes de a aula 5 ligá-lo por binding, e o `AddSession` chama
`onadd`. Esta seção reúne as convenções que mantêm esses callbacks fáceis de ler, porque os callbacks
de um componente são quase tudo o que o pai precisa saber sobre ele.

## Convenções que valem a pena

**Dê o nome `on` mais um verbo**, `onchange`, `onadd`, `onremove`. O nome diz que é um callback,
combina com os atributos de evento das seções anteriores, e se lê naturalmente onde é usado:
`<AddSession onadd={add} />`.

**Passe o que aconteceu, não o evento do navegador.** O `AddSession` chama `onadd({ date, minutes })`,
não `onadd(event)`. O pai não deveria precisar saber que a data mora num input dentro de um formulário
dentro do filho; se um dia o formulário virar um diálogo, o `add` do pai não muda.

**Torne um callback opcional quando o componente é útil sem ele.** Um componente que pode ser usado só
para leitura chama `onchange?.(next)`, então um pai que não escuta não é um erro. Um `WeekNav` sem
`onchange` mostraria uma semana e os seus botões não fariam nada, o que é uma leitura justa de
"ninguém está escutando".

**Deixe o pai decidir.** O callback relata um pedido; o estado do pai só muda se a função do pai o
mudar. É por isso que o `AddSession` não mexe nas sessões da página, e que o `WeekNav` não move a
semana sozinho: "Uma prop não é sua para mudar", da aula 5, era a versão longa desta regra.

## Repassando todos os outros atributos

Um componente pequeno que embrulha outro muitas vezes quer aceitar qualquer atributo que o seu
elemento aceita, handlers incluídos, sem listá-los. O `Panel` poderia repassar ao seu `<section>` tudo
o que ele não usa:

```html
<script>
	let { title, children, ...rest } = $props();
	const id = $props.id();
</script>

<section aria-labelledby={id} {...rest}>
	<h2 {id}>{title}</h2>
	{@render children()}
</section>
```

Agora `<Panel title="…" onkeydown={…} class="wide">` funciona, e o handler vai parar na section,
porque no Svelte 5 um handler é um atributo, e espalhar atributos espalha handlers também. No Svelte 4
isso exigia `on:keydown` repassado pelo nome, um evento de cada vez.

## E de fora da árvore de componentes

Duas últimas ferramentas, para código que não é marcação:

- **`on(element, type, handler, options)`**, de `svelte/events`, acrescenta um listener do mesmo jeito
  que o compilador, delegação incluída, e devolve uma função que o remove. Use num efeito em vez de
  `addEventListener`, pelo motivo de "Eventos são atributos": ele convive bem com os handlers
  delegados.
- **`createEventDispatcher`**, que a aula 4 viu na versão Svelte 4 do `WeekNav`, ainda funciona e está
  obsoleto. Componentes novos usam props de callback.
