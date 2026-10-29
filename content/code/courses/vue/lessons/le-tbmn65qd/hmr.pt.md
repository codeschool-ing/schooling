---
title: Hot module replacement
version: 1
---

**Quando você salva um arquivo, o servidor de desenvolvimento diz à página aberta qual módulo mudou, e
a página troca esse módulo pelo novo sem recarregar.** Isso é o *hot module replacement*, HMR, e é a
razão de uma mudança aparecer no navegador antes de a sua mão sair do teclado. As linhas
`[vite] connecting...` e `[vite] connected.` que todo `look` imprimiu desde a aula 1 são a página
abrindo o canal pelo qual é avisada, um WebSocket para o servidor de desenvolvimento.

O que uma troca preserva depende de qual parte do componente mudou, e o `look` consegue mostrar: a sua
ação `run` roda um comando com a página aberta, aqui um `sed` que edita um arquivo do jeito que o seu
editor editaria. Vá para a próxima semana e depois mude o título no template do `HomeView.vue`:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Next week' --do 'run sed -i "s#<h1>This week</h1>#<h1>This study week</h1>#" src/views/HomeView.vue' --do 'wait 1000' --text 'main h1' --html 'main section:nth-child(3) h2'
[vite] connecting...
[vite] connected.
-- click text=Next week
-- run sed -i "s#<h1>This week</h1>#<h1>This study week</h1>#" src/views/HomeView.vue
[vite] hot updated: /src/views/HomeView.vue
-- wait 1000
== the HTML of main section:nth-child(3) h2
<h2 data-v-0710be83="">Week of 26 October 2026</h2>
== the text of main h1
This study week
```

**O título é o novo e a semana continua sendo a do dia 26.** Uma mudança no template só substitui a
função de render, e a instância do componente, com o seu ref `monday` definido pelo clique, fica onde
estava. Agora o mesmo clique, e uma mudança no script, um comentário acima de `monday`:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Next week' --do 'run sed -i "s#^const monday = ref#// The Monday whose week the page shows.\nconst monday = ref#" src/views/HomeView.vue' --do 'wait 1000' --text 'main h1' --html 'main section:nth-child(3) h2'
[vite] connecting...
[vite] connected.
-- click text=Next week
-- run sed -i "s#^const monday = ref#// The Monday whose week the page shows.\nconst monday = ref#" src/views/HomeView.vue
[vite] hot updated: /src/views/HomeView.vue
-- wait 1000
== the HTML of main section:nth-child(3) h2
<h2 data-v-0710be83="">Week of 19 October 2026</h2>
== the text of main h1
This study week
```

**De volta ao dia 19**, embora a mudança fosse só um comentário. Uma mudança no `<script setup>` faz o
setup do componente rodar de novo, porque o Vite não tem como saber que o novo setup construiria o
mesmo estado que o antigo, então o componente é criado do zero, com `monday` vindo de
`weekStart(new Date())`. Só este componente recomeça: a store, que vive no seu próprio módulo, mantém
as suas sessões, e o mesmo vale para tudo o que está acima do `HomeView` na página.

## Quando ninguém consegue receber a mudança

O último caso é o `planner.ts`, o módulo simples de datas e totais que vários componentes importam. Um
comentário no topo dele:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Next week' --do 'run sed -i "1s#^#// Dates, weeks and totals.\n#" src/planner.ts' --do 'wait 1000' --text - --html 'main section:nth-child(3) h2'
[vite] connecting...
[vite] connected.
-- click text=Next week
-- run sed -i "1s#^#// Dates, weeks and totals.\n#" src/planner.ts
[vite] connecting...
[vite] connected.
-- wait 1000
== the HTML of main section:nth-child(3) h2
<h2 data-v-0710be83="">Week of 19 October 2026</h2>
```

**Um segundo `[vite] connecting...`: a página recarregou.** Um arquivo `.vue` *aceita* as próprias
atualizações, o que quer dizer que ele pode ser trocado. Um módulo simples que não as aceita passa a
atualização para cima, para cada módulo que o importa, e cada um deles faz o mesmo, até algum aceitar.
O `HomeView` importa o `planner.ts` e receberia a atualização, mas a store também o importa, o router
importa a store, o `main.ts` importa o router, e ninguém importa o `main.ts`. Nesse caminho a
atualização chega ao topo sem ninguém para recebê-la, e quando qualquer caminho faz isso, um reload
completo é tudo o que sobra. O terminal do próprio servidor de desenvolvimento diz qual dos dois
aconteceu em cada vez:

```
ana@dev:~/vue/planner$ npm run dev

> planner@0.0.0 dev
> vite


  VITE v8.3.5  ready in 401 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
9:06:09 PM [vite] (client) hmr update /src/views/HomeView.vue
9:06:12 PM [vite] (client) hmr update /src/views/HomeView.vue
9:06:15 PM [vite] (client) page reload src/planner.ts
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Para onde vai uma edição no planner.ts. O planner.ts não aceita atualizações próprias, então a atualização sobe para todo módulo que o importa. O HomeView.vue o importa, e um arquivo vue aceita as próprias atualizações, então ele receberia a atualização. Mas a store também o importa, o router importa a store, e o main.ts importa o router; ninguém importa o main.ts. Nesse caminho a atualização chega ao topo sem ninguém para recebê-la, e a página recarrega: o servidor de desenvolvimento registra page reload src/planner.ts.\"><rect x=\"20\" y=\"100\" width=\"130\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"85\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">planner.ts</text><text x=\"85\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">editado</text><rect x=\"210\" y=\"30\" width=\"160\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"290\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">HomeView.vue</text><text x=\"290\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">aceita: receberia</text><rect x=\"210\" y=\"170\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"280\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a store</text><rect x=\"390\" y=\"170\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o router</text><rect x=\"560\" y=\"170\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">main.ts</text><line x1=\"152\" y1=\"110\" x2=\"206\" y2=\"62\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"206.0,62.0 202.6,69.2 198.4,64.6\" fill=\"var(--phosphor)\"></polygon><line x1=\"152\" y1=\"134\" x2=\"206\" y2=\"180\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"206.0,180.0 198.4,177.6 202.4,172.9\" fill=\"var(--wire)\"></polygon><line x1=\"352\" y1=\"190\" x2=\"386\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"386.0,190.0 378.6,193.1 378.6,186.9\" fill=\"var(--wire)\"></polygon><line x1=\"532\" y1=\"190\" x2=\"556\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"556.0,190.0 548.6,193.1 548.6,186.9\" fill=\"var(--wire)\"></polygon><text x=\"178\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">importado por</text><line x1=\"630\" y1=\"168\" x2=\"630\" y2=\"106\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"630.0,106.0 633.1,113.4 626.9,113.4\" fill=\"var(--amber)\"></polygon><text x=\"622\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">ninguém o importa</text><rect x=\"540\" y=\"50\" width=\"160\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">page reload</text><text x=\"620\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a página inteira de novo</text></svg>", "caption": "Uma atualização sobe por quem importa até alguém aceitá-la; um caminho que chega ao main.ts recarrega a página."}
```

As duas edições no `HomeView` foram cada uma um `hmr update`, a do `planner.ts` um `page reload`.
Quando uma mudança parece não aparecer, esse log é o primeiro lugar para olhar, e recarregar a página é
o segundo, porque o HMR é uma conveniência do servidor de desenvolvimento e um reload é o que vê um
aluno que abre a página.
