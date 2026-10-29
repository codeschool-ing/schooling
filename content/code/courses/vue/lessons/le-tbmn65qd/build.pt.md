---
title: O build, e o que ele deixa em dist
version: 1
---

**O `npm run build` transforma o que o servidor de desenvolvimento enviou em trinta e três requisições
num punhado de arquivos que qualquer servidor web consegue enviar.**
Desde a aula 16 o script confere os tipos primeiro e só depois roda o `vite build`:

```
ana@dev:~/vue/planner$ npm run build

> planner@0.0.0 build
> vue-tsc --noEmit && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 61 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                        0.43 kB │ gzip:  0.28 kB
dist/assets/CourseView-7bymtRQi.css    0.06 kB │ gzip:  0.08 kB
dist/assets/index-iufgghmN.css         1.34 kB │ gzip:  0.61 kB
dist/assets/CourseAll-DhFoYFUW.js      0.53 kB │ gzip:  0.36 kB
dist/assets/CourseWeek-CqqcOOPL.js     0.59 kB │ gzip:  0.40 kB
dist/assets/CourseView-CUyh3DIL.js     0.84 kB │ gzip:  0.51 kB
dist/assets/index-BPp-uHAO.js        122.34 kB │ gzip: 47.25 kB

✓ built in 615ms
```

Entraram sessenta e um módulos, contando os do próprio Vue e do router, e a lista nomeia sete arquivos. **Os
três arquivos JavaScript pequenos são as rotas que a aula 12 tornou lazy**, o `CourseView` e os seus
dois filhos, separados porque o router os importa com `import()`; um aluno que nunca abre um curso
nunca os baixa. Todo o resto está num único arquivo `index` de 122 kB, 47 kB depois de comprimido, a
maior parte dele Vue, o router e o Pinia. Os dois arquivos CSS são o `<style>` de cada componente
juntos, de novo um deles para as rotas lazy. Esta é a pasta:

```
ana@dev:~/vue/planner$ ls -R dist
dist:
assets
courses.json
favicon.ico
index.html

dist/assets:
CourseAll-DhFoYFUW.js
CourseView-7bymtRQi.css
CourseView-CUyh3DIL.js
CourseWeek-CqqcOOPL.js
index-BPp-uHAO.js
index-iufgghmN.css
```

O `courses.json` e o `favicon.ico` vieram de `public/`, que é copiada como está: um arquivo em
`public` mantém o nome e nunca é processado, e é por isso que a store consegue buscar o
`/courses.json` por esse endereço. Tudo em `assets` tem um **hash no nome**, `index-BPp-uHAO.js`,
calculado a partir do conteúdo. Uma mudança no código dá ao arquivo um nome novo, então um servidor
pode mandar os navegadores guardarem esses arquivos por um ano, e um deploy ainda assim chega a todo
mundo de uma vez, pelo único arquivo cujo nome nunca muda:

```
ana@dev:~/vue/planner$ cat dist/index.html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <link rel="icon" href="/favicon.ico">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Study planner</title>
    <script type="module" crossorigin src="/assets/index-BPp-uHAO.js"></script>
    <link rel="stylesheet" crossorigin href="/assets/index-iufgghmN.css">
  </head>
  <body>
    <div id="app"></div>
  </body>
</html>
```

Esse é o `index.html` do projeto com o `<script>` de desenvolvimento trocado pelo do build e a folha de
estilos acrescentada.

## Olhando o build

O `dist` é uma pasta estática, e qualquer servidor web consegue enviá-la. O Vite tem um para conferir
um build no seu próprio computador, o `vite preview`, que o `create-vue` pôs nos scripts:

```
ana@dev:~/vue/planner$ npm run preview

> planner@0.0.0 preview
> vite preview

  ➜  Local:   http://localhost:4173/
  ➜  Network: use --host to expose
```

Ele escuta em outra porta, a `4173`, para poder rodar ao lado do servidor de desenvolvimento. A página
da semana, servida por ele:

```
ana@dev:~/vue/planner$ look http://localhost:4173/ --network --text '#app > footer'
net  GET /  200
net  GET /assets/index-iufgghmN.css  200
net  GET /assets/index-BPp-uHAO.js  200
net  GET /courses.json  200
== the text of #app > footer
Built with Vue 3.5.44
```

**Quatro requisições onde o servidor de desenvolvimento precisou de trinta e três**: a página, a
folha de estilos, o script e os dados. Nenhum `[vite] connecting...` também, porque um build não tem
cliente de HMR dentro dele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"O mesmo planner chegando ao navegador de dois jeitos. À esquerda, npm run dev: o navegador pede main.ts, App.vue, HomeView.vue, planner.ts, a store e o resto um por um, trinta e três requisições, e o servidor de desenvolvimento converte cada arquivo quando ele é pedido; só as dependências, Vue, Pinia e Vue Router, foram empacotadas antes. À direita, npm run build: o Rolldown lê os sessenta e um módulos uma vez e escreve o dist, um index.html, um script, uma folha de estilo e os pedaços lazy das rotas do curso. A página da semana então leva quatro requisições: a página, o script, a folha de estilo e os dados.\"><text x=\"180\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">npm run dev</text><rect x=\"110\" y=\"34\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">navegador</text><rect x=\"30\" y=\"100\" width=\"140\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">main.ts</text><rect x=\"190\" y=\"100\" width=\"140\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">App.vue</text><rect x=\"30\" y=\"134\" width=\"140\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">HomeView.vue</text><rect x=\"190\" y=\"134\" width=\"140\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">planner.ts</text><rect x=\"30\" y=\"168\" width=\"140\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">stores/planner.ts</text><rect x=\"190\" y=\"168\" width=\"140\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">router.ts</text><rect x=\"30\" y=\"202\" width=\"140\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">SessionRow.vue</text><rect x=\"190\" y=\"202\" width=\"140\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">deps/vue.js</text><line x1=\"180\" y1=\"66\" x2=\"180\" y2=\"96\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"180.0,96.0 176.9,88.6 183.1,88.6\" fill=\"var(--phosphor)\"></polygon><text x=\"180\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">33 requisições, cada arquivo convertido quando é pedido</text><line x1=\"360\" y1=\"20\" x2=\"360\" y2=\"255\" stroke=\"var(--scan)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></line><text x=\"540\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">npm run build</text><rect x=\"400\" y=\"40\" width=\"110\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">src/</text><text x=\"455\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">61 módulos</text><line x1=\"512\" y1=\"72\" x2=\"548\" y2=\"72\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"548.0,72.0 540.6,75.1 540.6,68.9\" fill=\"var(--amber)\"></polygon><rect x=\"550\" y=\"54\" width=\"140\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">Rolldown</text><line x1=\"620\" y1=\"92\" x2=\"620\" y2=\"116\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"620.0,116.0 616.9,108.6 623.1,108.6\" fill=\"var(--amber)\"></polygon><rect x=\"520\" y=\"120\" width=\"170\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">index.html</text><rect x=\"520\" y=\"150\" width=\"170\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">assets/index-….js</text><rect x=\"520\" y=\"180\" width=\"170\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">assets/index-….css</text><rect x=\"520\" y=\"210\" width=\"170\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">assets/CourseView-….js</text><text x=\"540\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a página da semana: 4 requisições</text></svg>", "caption": "No desenvolvimento nada é empacotado além das dependências; o build empacota tudo uma vez."}
```

O `vite preview` é para olhar, não para servir alunos; é um servidor pequeno, sem nada do trabalho que
um host de verdade faz. Pôr o `dist` num host, os planos gratuitos e como um deploy chega até eles, é a
aula 1 de `front-delivery`. Uma regra desse host já importa aqui: o planner usa `createWebHistory`,
então um endereço como `/courses/spanish` precisa responder com o `index.html` e deixar o router
cuidar do resto. O `vite preview` faz isso:

```
ana@dev:~/vue/planner$ curl -sI http://localhost:4173/courses/spanish | head -3
HTTP/1.1 200 OK
Vary: Origin
Content-Type: text/html
```

Não existe arquivo chamado `courses/spanish` em `dist`, e a resposta é um `200` com HTML, o
`index.html`. Um host precisa ser instruído a fazer o mesmo, senão o endereço funciona quando clicado
dentro do planner e falha quando digitado ou recarregado; isso são os redirecionamentos da aula 4 de
`front-delivery`.
