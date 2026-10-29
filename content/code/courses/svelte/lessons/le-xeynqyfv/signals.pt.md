---
title: Signals, e como uma mudança acha os seus leitores
version: 1
---

**Um signal é um valor que guarda uma lista do código que o leu.** O `$state` cria um. Quando um
efeito roda e lê `minutes`, o signal `minutes` anota esse efeito na sua lista. Quando `minutes`
recebe um valor novo depois, o signal percorre a lista e agenda cada efeito dela para rodar de novo.
Ninguém mais é consultado, então nada mais roda.

A lista é montada **enquanto o código roda**, pelas próprias leituras, e não pelo compilador
adivinhando a partir do código-fonte. Essa é a diferença para o Svelte 4, cujas instruções `$:` eram
organizadas em tempo de compilação a partir dos nomes que apareciam nelas; a aula 4 mostra o que
isso errava.

## Um valor que ninguém lê

Para ver a lista funcionando, dê ao contador um segundo estado que o efeito não lê: uma meta
semanal, com um botão para subi-la.

```schooling-example
{"language": "html", "file": "src/lib/Counter.svelte", "parts": [
 {"code": "<script>\n\tlet minutes = $state(0);\n\tlet goal = $state(120);\n\tconsole.log('the script ran');\n\n\t$effect(() => {\n\t\tconsole.log(`the effect ran: minutes is ${minutes}`);\n\t});\n</script>", "note": "Agora há dois signals. O efeito abaixo lê `minutes` e nunca `goal`."},
 {"code": "<button onclick={() => (minutes += 30)}>Add 30 minutes</button>\n<button onclick={() => (goal += 60)}>Raise the goal</button>\n<p>{minutes} minutes this week</p>\n<p>The goal is {goal} minutes.</p>", "note": "Cada botão define um signal. Cada parágrafo lê um."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/ --console --click 'Raise the goal' --click 'Add 30 minutes'
console: [vite] connecting...
console: [vite] connected.
console: the script ran
console: the effect ran: minutes is 0
-- click Raise the goal
-- click Add 30 minutes
console: the effect ran: minutes is 30
at /
- main:
  - heading "Study planner" [level=1]
  - button "Add 30 minutes"
  - button "Raise the goal"
  - paragraph: 30 minutes this week
  - paragraph: The goal is 180 minutes.
```

**Subir a meta não rodou o efeito**, porque o efeito nunca leu `goal`, então a lista de `goal` não o
contém. O segundo parágrafo mudou mesmo assim, porque o compilador escreveu para ele um template
effect separado que lê `goal`. Somar trinta minutos rodou o efeito uma vez, porque a lista de
`minutes` o contém.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Os signals do contador e os seus leitores. O signal minutes tem dois leitores: o template effect que define o primeiro parágrafo e o efeito que escreve no console. O signal goal tem um leitor: o template effect que define o segundo parágrafo. Apertar Raise the goal chega só ao leitor de goal; apertar Add 30 minutes chega só aos dois leitores de minutes.\"><rect x=\"40\" y=\"50\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">minutes</text><rect x=\"40\" y=\"160\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">goal</text><text x=\"115\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">signals</text><text x=\"560\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">os seus leitores</text><rect x=\"440\" y=\"40\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">define o primeiro parágrafo</text><rect x=\"440\" y=\"110\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o efeito que escreve no console</text><rect x=\"440\" y=\"185\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">define o segundo parágrafo</text><line x1=\"190\" y1=\"70\" x2=\"438\" y2=\"50\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"438.0,50.0 430.9,53.7 430.4,47.5\" fill=\"var(--phosphor)\"></polygon><line x1=\"190\" y1=\"80\" x2=\"438\" y2=\"120\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"438.0,120.0 430.2,121.9 431.2,115.8\" fill=\"var(--phosphor)\"></polygon><line x1=\"190\" y1=\"185\" x2=\"438\" y2=\"195\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"438.0,195.0 430.5,197.8 430.8,191.6\" fill=\"var(--phosphor)\"></polygon><text x=\"300\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma mudança percorre a lista do seu signal, e mais nada</text></svg>", "caption": "Cada signal guarda a lista de quem o leu. Subir a meta chega a um leitor; somar minutos chega a dois.", "same": ["signals"]}
```

## As leituras decidem, a cada execução

Como a lista é refeita cada vez que um efeito roda, um efeito que lê um signal só em algumas
execuções depende dele só nessas execuções. Normalmente é isso que você quer, e é a origem da única
surpresa que os signals têm. Um efeito como este:

```javascript
$effect(() => {
	if (minutes > 0) console.log(`${minutes} of ${goal}`);
});
```

não depende de `goal` enquanto `minutes` vale 0, porque nessa execução `goal` nunca foi lido. Suba a
meta primeiro e nada é impresso; some trinta minutos e ele imprime com a meta nova, e a partir daí
acompanha os dois. A regra que explica todos os casos é curta: **um efeito depende exatamente do que
ele leu na última vez que rodou.**

## Onde os signals moram

`$state` não é uma função que dê para chamar de qualquer arquivo JavaScript. É uma **rune**, uma
palavra que o compilador reconhece, e só funciona em arquivos `.svelte` e em módulos com nome
`.svelte.js`, que a aula 10 usa para compartilhar estado entre componentes. Nos dois, o compilador
reescreve a variável como um signal e cada uso dela como uma leitura ou uma escrita, como mostrou a
saída da aula 1. Essa reescrita é o motivo de `minutes += 30` bastar para mudar a página: o
compilador transformou essa linha em `$.set(minutes, $.get(minutes) + 30)`.
