---
title: Chaves, e a linha que fica com o input errado
version: 1
---

**Quando uma lista muda, o Svelte precisa decidir qual elemento existente vira qual item.** Sem chave
ele decide pela posição: o primeiro elemento mostra o primeiro item, o segundo o segundo, e quando a
ordem muda, cada elemento recebe outros dados. Quase sempre isso é invisível, porque o elemento mostra
os dados que receber. Deixa de ser invisível assim que um elemento guarda algo próprio que não é dado:
texto digitado num campo que não está ligado, o foco, uma animação em andamento, o estado interno de um
componente.

Para ver isso sem mexer no planner, use uma página só para isso, como a aula 4 fez com o código antigo.
Esta é o painel do curso reduzido a duas sessões, um botão que as ordena, e um campo ao lado de cada
uma para uma nota que não está ligada a nada:

```html
<!-- src/routes/keys/+page.svelte -->
<script>
	let sessions = $state([
		{ id: 3, date: '19 Oct', minutes: 90 },
		{ id: 6, date: '24 Oct', minutes: 60 }
	]);
	let shortestFirst = $state(false);
	let shown = $derived(shortestFirst ? sessions.toSorted((a, b) => a.minutes - b.minutes) : sessions);
</script>

<main>
	<button aria-pressed={shortestFirst} onclick={() => (shortestFirst = !shortestFirst)}>
		Shortest first
	</button>
	<ul>
		{#each shown as session}
			<li>
				{session.date}, {session.minutes} min
				<input aria-label="Note for {session.date}" />
			</li>
		{/each}
	</ul>
</main>
```

Digite uma nota para o dia 19 e depois ordene:

```
ana@dev:~/planner$ look http://localhost:5173/keys --fill 'Note for 19 Oct=read chapter 3' --click 'Shortest first'
-- fill Note for 19 Oct=read chapter 3
-- click Shortest first
at /keys
- main:
  - button "Shortest first" [pressed]
  - list:
    - listitem:
      - text: 24 Oct, 60 min
      - textbox "Note for 24 Oct": read chapter 3
    - listitem:
      - text: 19 Oct, 90 min
      - textbox "Note for 19 Oct"
```

**A nota agora está ao lado do dia 24.** O primeiro `<li>` recebeu os dados do dia 24, então o texto
dele e o rótulo do campo mudaram, e o texto digitado no campo, que pertence ao elemento e não aos
dados, ficou onde estava. O campo agora se chama "Note for 24 Oct" e diz "read chapter 3", que era uma
nota sobre o dia 19.

Uma chave diz ao Svelte a que item um elemento pertence, para que uma mudança de ordem **mova** os
elementos em vez de dar dados novos a eles. Ela vai entre parênteses depois do item, e tem de ser algo
que identifica o item e nunca muda, que é exatamente o que um id é:

```html
<!-- src/routes/keys/+page.svelte -->
<script>
	let sessions = $state([
		{ id: 3, date: '19 Oct', minutes: 90 },
		{ id: 6, date: '24 Oct', minutes: 60 }
	]);
	let shortestFirst = $state(false);
	let shown = $derived(shortestFirst ? sessions.toSorted((a, b) => a.minutes - b.minutes) : sessions);
</script>

<main>
	<button aria-pressed={shortestFirst} onclick={() => (shortestFirst = !shortestFirst)}>
		Shortest first
	</button>
	<ul>
		{#each shown as session (session.id)}
			<li>
				{session.date}, {session.minutes} min
				<input aria-label="Note for {session.date}" />
			</li>
		{/each}
	</ul>
</main>
```

```
ana@dev:~/planner$ look http://localhost:5173/keys --fill 'Note for 19 Oct=read chapter 3' --click 'Shortest first'
-- fill Note for 19 Oct=read chapter 3
-- click Shortest first
at /keys
- main:
  - button "Shortest first" [pressed]
  - list:
    - listitem:
      - text: 24 Oct, 60 min
      - textbox "Note for 24 Oct"
    - listitem:
      - text: 19 Oct, 90 min
      - textbox "Note for 19 Oct": read chapter 3
```

O dia 24 subiu, o dia 19 desceu, e a nota foi junto com o dia 19, porque o elemento dela foi junto. Apague a pasta, `rm -r src/routes/keys`, quando terminar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A mesma ordenação, com e sem chave. À esquerda, sem chave: os dois elementos da lista ficam onde estão e recebem dados novos, então o primeiro elemento, que guarda a nota read chapter 3, agora mostra o dia 24. À direita, com chave: os elementos se movem com as suas sessões, então o elemento que guarda a nota desce junto com o dia 19.\"><text x=\"180\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">sem chave</text><text x=\"80\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">antes</text><text x=\"270\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">depois de ordenar</text><rect x=\"20\" y=\"60\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">19 Oct, 90 min</text><rect x=\"30\" y=\"94\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">read chapter 3</text><rect x=\"20\" y=\"150\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">24 Oct, 60 min</text><rect x=\"30\" y=\"184\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\"></text><rect x=\"210\" y=\"60\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">24 Oct, 60 min</text><rect x=\"220\" y=\"94\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"226\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">read chapter 3</text><rect x=\"210\" y=\"150\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">19 Oct, 90 min</text><rect x=\"220\" y=\"184\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"226\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\"></text><line x1=\"152\" y1=\"95\" x2=\"208\" y2=\"95\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"208.0,95.0 200.6,98.1 200.6,91.9\" fill=\"var(--amber)\"></polygon><line x1=\"152\" y1=\"185\" x2=\"208\" y2=\"185\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"208.0,185.0 200.6,188.1 200.6,181.9\" fill=\"var(--amber)\"></polygon><text x=\"540\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">com (session.id)</text><text x=\"440\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">antes</text><text x=\"630\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">depois de ordenar</text><rect x=\"380\" y=\"60\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"445\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">19 Oct, 90 min</text><rect x=\"390\" y=\"94\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"396\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">read chapter 3</text><rect x=\"380\" y=\"150\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"445\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">24 Oct, 60 min</text><rect x=\"390\" y=\"184\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"396\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\"></text><rect x=\"570\" y=\"60\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">24 Oct, 60 min</text><rect x=\"580\" y=\"94\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"586\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\"></text><rect x=\"570\" y=\"150\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">19 Oct, 90 min</text><rect x=\"580\" y=\"184\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"586\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">read chapter 3</text><line x1=\"512\" y1=\"95\" x2=\"568\" y2=\"180\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"568.0,180.0 561.3,175.6 566.5,172.1\" fill=\"var(--phosphor)\"></polygon><line x1=\"512\" y1=\"185\" x2=\"568\" y2=\"100\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"568.0,100.0 566.5,107.9 561.3,104.4\" fill=\"var(--phosphor)\"></polygon><text x=\"180\" y=\"255\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">os elementos ficam; os dados mudam</text><text x=\"540\" y=\"255\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">os elementos vão com os seus dados</text></svg>", "caption": "Sem chave a nota pertence a uma posição; com chave, a uma sessão.", "same": ["19 Oct, 90 min", "24 Oct, 60 min"]}
```

## O que faz uma boa chave

**Um id, e nada mais.** O índice é a posição, que é exatamente o que muda quando a ordem muda, então
`(i)` é o mesmo que nenhuma chave. O próprio item, `(session)`, só funciona enquanto os mesmos objetos
forem mantidos, e falha no momento em que uma lista é recarregada do servidor como objetos novos com o
mesmo conteúdo. Um campo como a data ou o nome não é único, e no dia em que duas sessões dividirem uma
data, dois elementos reivindicam a mesma chave e o Svelte para com um erro. As sessões do planner têm
um `id` desde que a aula 3 deu forma aos dados, por esse motivo.
