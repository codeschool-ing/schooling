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

As duas edições no `HomeView` foram cada uma um `hmr update`, a do `planner.ts` um `page reload`.
Quando uma mudança parece não aparecer, esse log é o primeiro lugar para olhar, e recarregar a página é
o segundo, porque o HMR é uma conveniência do servidor de desenvolvimento e um reload é o que vê um
aluno que abre a página.
