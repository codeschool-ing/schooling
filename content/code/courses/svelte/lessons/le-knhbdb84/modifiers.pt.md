---
title: Modificadores, escritos como código
version: 1
---

**O Svelte 4 tinha modificadores de evento, escritos depois de uma barra: `on:click|preventDefault|once`.
O Svelte 5 não tem nenhum, e cada um agora é uma linha de JavaScript no handler.** A seção anterior viu
o mais comum, `preventDefault`, como `event.preventDefault()` no topo do `submit`. Os outros seguem a
mesma ideia, e tê-los no handler quer dizer que tudo o que um handler faz está num lugar só, em vez de
dividido entre o handler e o atributo.

| modificador do Svelte 4 | o que fazia | no Svelte 5 |
|---|---|---|
| `preventDefault` | impedir a ação do próprio navegador | `event.preventDefault()` no handler |
| `stopPropagation` | impedir o evento de chegar aos pais | `event.stopPropagation()`, com a ressalva sobre delegação de "Eventos são atributos" |
| `once` | tratar só o primeiro evento | um handler que se remove, ou uma marca que o handler confere |
| `self` | só quando o próprio elemento foi o alvo | `if (event.target !== event.currentTarget) return;` |
| `capture` | escutar na descida em vez de na subida | o atributo com `capture` no fim: `onclickcapture` |
| `passive` | prometer não chamar `preventDefault`, para a rolagem fluir | o navegador já supõe isso para listeners de toque e de roda na janela e no documento; nos outros casos, `on(…, { passive: true })` de `svelte/events` |
| `trusted` | ignorar eventos criados por scripts | `if (!event.isTrusted) return;` |

Uma pequena função auxiliar cobre o `once` sem repetição, e mostra a forma de todos eles, uma função
que embrulha um handler:

```javascript
// once.js: a handler that runs the first time and then does nothing.
export function once(handler) {
	let done = false;
	return (event) => {
		if (done) return;
		done = true;
		handler(event);
	};
}
```

`onclick={once(save)}` se lê tão claramente quanto `on:click|once={save}` se lia, e é JavaScript comum
que você consegue testar, ler e mudar.

Duas das linhas merecem uma frase cada. **O `capture` é o único modificador que sobreviveu como
sintaxe**, porque ele muda como o listener é registrado, e não o que o handler faz; não havia como
escrevê-lo dentro do handler. E **o `passive` quase não importa mais**: o trabalho dele era dizer ao
navegador que podia rolar sem esperar o handler, e os navegadores agora supõem isso para os listeners
de rolagem e de toque em que fazia diferença.
