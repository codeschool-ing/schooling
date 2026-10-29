---
title: O script roda uma vez
version: 1
---

**O `<script>` de um componente Svelte roda uma vez, quando o componente é criado, e nunca mais.** No
React a função do componente roda a cada mudança, então tudo dentro dela, cada variável e cada
função, é criado de novo a cada vez. No Svelte o script prepara as coisas e acabou; depois disso, só
rodam os pequenos efeitos que o compilador escreveu, cada um quando algo que ele leu mudou.

O mais fácil é acreditar vendo. Mude o `Counter` da aula 1 para que ele diga quando o seu script
roda e quando um efeito roda. O `$effect` é assunto da aula 3; aqui ele é uma sonda, uma função que
roda uma vez quando o componente aparece e de novo sempre que um valor que ela leu muda:

```schooling-example
{"language": "html", "file": "src/lib/Counter.svelte", "parts": [
 {"code": "<script>\n\tlet minutes = $state(0);\n\tconsole.log('the script ran');", "note": "O `console.log` está no próprio script, então ele imprime cada vez que o script roda."},
 {"code": "\t$effect(() => {\n\t\tconsole.log(`the effect ran: minutes is ${minutes}`);\n\t});\n</script>", "note": "O efeito lê `minutes`, então roda de novo cada vez que `minutes` muda."},
 {"code": "<button onclick={() => (minutes += 30)}>Add 30 minutes</button>\n<p>{minutes} minutes this week</p>", "note": "A marcação é a da aula 1, sem mudança."}
]}
```

E ponha o contador na página do planner nesta aula, embaixo do título. `#lib` é um nome para
`src/lib` que o `package.json` do projeto declara, então o import não depende de onde fica o arquivo
que importa:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport Counter from '#lib/Counter.svelte';\n</script>", "note": "Um import no script de um componente traz outro componente, usado como tag."},
 {"code": "<main>\n\t<h1>Study planner</h1>\n\t<Counter />\n</main>", "note": "A aula 3 troca esta página pelo planner de verdade; por enquanto o contador fica embaixo do título."}
]}
```

Agora abra a página, aperte o botão três vezes e imprima o console do navegador:

```
ana@dev:~/planner$ look http://localhost:5173/ --console --click 'Add 30 minutes' --click 'Add 30 minutes' --click 'Add 30 minutes'
console: [vite] connecting...
console: [vite] connected.
console: the script ran
console: the effect ran: minutes is 0
-- click Add 30 minutes
console: the effect ran: minutes is 30
-- click Add 30 minutes
console: the effect ran: minutes is 60
-- click Add 30 minutes
console: the effect ran: minutes is 90
at /
- main:
  - heading "Study planner" [level=1]
  - button "Add 30 minutes"
  - paragraph: 90 minutes this week
```

As duas primeiras linhas são do próprio Vite: a página se conectando de volta ao servidor de
desenvolvimento, que é como um arquivo salvo chega a um navegador aberto. Depois delas, **`the script
ran` aparece uma vez.** Três cliques depois, o script não rodou de novo; o efeito rodou, uma vez ao
aparecer e uma por clique. A variável `minutes` nunca foi declarada uma segunda vez, e nada recriou
o handler de clique do botão.

## E no servidor

O terminal que roda o `npm run dev` tem algo a acrescentar:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

7:32:06 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 486 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
the script ran
200 GET /
```

A penúltima linha é o mesmo `console.log`, impresso pelo servidor enquanto renderizava a página em
HTML, e `200 GET /` é a requisição que ele estava respondendo. Então o script rodou **duas vezes ao
todo: uma no servidor e uma no navegador**, e em cada lugar exatamente uma vez. O efeito não
imprimiu nada no servidor. **Efeitos nunca rodam durante a renderização no servidor**, porque nada lá
vai mudar: o servidor monta uma string, manda e esquece. A aula 1 viu a mesma coisa pelo outro lado,
na saída do servidor, onde o `$state` era um `let` comum.

## Por que "roda uma vez" importa

Tudo o que vem depois neste curso se apoia nisso. Uma função declarada num script Svelte é a mesma
função pela vida do componente, então não há nada como o `useCallback` do React para mantê-la
estável. Um valor calculado no script não é recalculado na próxima mudança a não ser que você peça
isso com `$derived`, que é da aula 3. E um código que deve rodar de novo quando algo muda tem de dizer
isso, estando num efeito, num valor derivado ou na marcação, porque nada mais roda de novo.

Esse último ponto é onde quem vem do React se enrosca. A pessoa escreve um cálculo no script e espera
que ele acompanhe o estado, porque no React a função inteira teria rodado de novo:

```schooling-example
{"language": "html", "file": "src/lib/Counter.svelte", "parts": [
 {"code": "<script>\n\tlet minutes = $state(0);\n\tlet hours = minutes / 60;\n</script>", "note": "Isto roda uma vez, quando `minutes` vale 0, e `hours` fica 0 para sempre."},
 {"code": "<button onclick={() => (minutes += 30)}>Add 30 minutes</button>\n<p>{hours} hours this week</p>", "note": "O parágrafo mostra `hours`, que nunca muda, então apertar o botão não muda nada na tela."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Add 30 minutes' --click 'Add 30 minutes'
-- click Add 30 minutes
-- click Add 30 minutes
at /
- main:
  - heading "Study planner" [level=1]
  - button "Add 30 minutes"
  - paragraph: 0 hours this week
```

Dois cliques, uma hora de estudo, e o parágrafo ainda diz `0`. O compilador avisa no terminal que
roda o `npm run dev`, mas só se você estiver olhando para lá naquela hora. A linha `hmr update`
embaixo do primeiro aviso é o Vite mandando o arquivo alterado para o navegador aberto:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

7:32:06 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 486 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
the script ran
200 GET /
7:32:10 PM [vite-plugin-svelte] src/lib/Counter.svelte:3:13 This reference only captures the initial value of `minutes`. Did you mean to reference it inside a closure instead?
https://svelte.dev/e/state_referenced_locally
7:32:10 PM [vite] (client) hmr update /src/lib/Counter.svelte
7:32:10 PM [vite] (ssr) page reload src/lib/Counter.svelte
7:32:10 PM [vite] (ssr) program reload
7:32:10 PM [vite-plugin-svelte] src/lib/Counter.svelte:3:13 This reference only captures the initial value of `minutes`. Did you mean to reference it inside a closure instead?
https://svelte.dev/e/state_referenced_locally
200 GET /
7:32:12 PM [vite-plugin-svelte] src/lib/Counter.svelte:3:13 This reference only captures the initial value of `minutes`. Did you mean to reference it inside a closure instead?
https://svelte.dev/e/state_referenced_locally
```

**`state_referenced_locally` é o compilador dizendo que você leu um valor reativo uma vez, num lugar
que nunca vai lê-lo de novo.** É um aviso e não um erro porque ler o valor inicial de propósito às
vezes é o certo. Aqui é o bug, e a aula 3 o conserta com uma palavra:
`let hours = $derived(minutes / 60)`. Volte o contador para a versão do começo desta seção antes de
seguir.
