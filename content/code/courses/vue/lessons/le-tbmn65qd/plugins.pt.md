---
title: Um plugin do próprio planner
version: 1
---

**Um plugin do Vite é um objeto com um nome e algumas funções, chamadas *hooks*, que o Vite chama em
momentos conhecidos: quando o build começa, quando um arquivo é pedido, quando o código de um arquivo
está prestes a ser servido.** O `@vitejs/plugin-vue` é um deles, e tudo o que ele faz com um arquivo
`.vue` acontece nos seus hooks; o Nuxt e o Vitest acrescentam ao Vite boa parte do que fazem do mesmo
jeito, e o roteamento por arquivos do Vue Router também. Os hooks são os do Rollup, os que o Rolldown
manteve, mais alguns que só fazem sentido num servidor de desenvolvimento.

Os dados do planner têm um jeito de estar errados que nenhuma tela informa: uma sessão que nomeia um
curso que o `courses.json` não tem. A lista da semana mostraria o id dele, os totais o contariam sob
curso nenhum, e nada falharia. Um plugin pode se recusar a iniciar, ou a fazer o build, enquanto isso
for verdade:

```javascript
// plugins/check-planner-data.js: a Vite plugin that refuses to start, or to
// build, while courses.json has a session that names no course.
import { readFile } from 'node:fs/promises'

export function checkPlannerData() {
  return {
    name: 'check-planner-data',
    async buildStart() {
      const data = JSON.parse(await readFile('public/courses.json', 'utf8'))
      const ids = new Set(data.courses.map((course) => course.id))
      const orphans = data.sessions.filter((session) => !ids.has(session.course))
      if (orphans.length > 0) {
        const list = orphans.map((s) => `${s.id} (${s.course})`).join(', ')
        this.error(`courses.json: these sessions name a course that does not exist: ${list}`)
      }
    },
  }
}
```

O `buildStart` roda uma vez antes de qualquer arquivo ser processado, num build e quando o servidor de
desenvolvimento inicia. O `this.error` para o que estiver rodando com essa mensagem e o nome do plugin
ao lado. A função em volta do objeto é a convenção que todo plugin segue, o `vue()` incluído, para que
as opções tenham onde entrar. A configuração ganha um import e uma entrada em `plugins`, e este é o
arquivo inteiro agora:

```javascript
// vite.config.js: how Vite serves and builds the planner.
import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { checkPlannerData } from './plugins/check-planner-data.js'

export default defineConfig({
  plugins: [vue(), checkPlannerData()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  // Fail instead of quietly taking the next port (lesson 1's "Port 5173 is in use").
  server: { port: 5173, strictPort: true },
  preview: { port: 4173, strictPort: true },
})
```

Com os dados como estão, o build passa:

```
ana@dev:~/vue/planner$ npm run build 2>&1 | tail -3
dist/assets/index-CNeZWQJG.js        122.37 kB │ gzip: 47.27 kB

✓ built in 542ms
```

## O plugin se recusando

Dê a uma sessão um curso que ninguém tem, `piano`, e faça o build:

```
ana@dev:~/vue/planner$ sed -i 's/"course": "guitar"/"course": "piano"/' public/courses.json
ana@dev:~/vue/planner$ npm run build

> planner@0.0.0 build
> vue-tsc --noEmit && vite build

vite v8.3.5 building client environment for production...
✓ 0 modules transformed.
✗ Build failed in 58ms
error during build:
Build failed with 1 error:

[plugin check-planner-data]
RolldownError: courses.json: these sessions name a course that does not exist: s5 (piano)
    at error (file:///home/ana/vue/planner/node_modules/rolldown/dist/shared/logs-DyTyzzWG.mjs:164:24)
    at PluginContextImpl.error (file:///home/ana/vue/planner/node_modules/rolldown/dist/shared/bindingify-input-options-BMZwyvQ7.mjs:285:10)
    at PluginContextImpl.buildStart (file:///home/ana/vue/planner/node_modules/.vite-temp/vite.config.js.timestamp-1792800417300-5fd982b820031.mjs:15:10)
    at async plugin (file:///home/ana/vue/planner/node_modules/rolldown/dist/shared/bindingify-input-options-BMZwyvQ7.mjs:1606:3)
    at async plugin.<computed> (file:///home/ana/vue/planner/node_modules/rolldown/dist/shared/bindingify-input-options-BMZwyvQ7.mjs:2284:12)
    at aggregateBindingErrorsIntoJsError (file:///home/ana/vue/planner/node_modules/rolldown/dist/shared/error-D0SD8_tL.mjs:49:18)
    at unwrapBindingResult (file:///home/ana/vue/planner/node_modules/rolldown/dist/shared/error-D0SD8_tL.mjs:19:128)
    at #build (file:///home/ana/vue/planner/node_modules/rolldown/dist/shared/rolldown-CMhwwZPA.mjs:145:34)
    at async buildEnvironment (file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:34849:66)
    at async Object.build (file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:35270:19)
    at async Object.buildApp (file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:35267:153)
    at async CAC.<anonymous> (file:///home/ana/vue/planner/node_modules/vite/dist/node/cli.js:790:3) {
  errors: [Getter/Setter]
}
```

**`[plugin check-planner-data]` e a mensagem, acima do stack trace do Rolldown**, que diz em que ponto
do Vite o erro foi lançado e não serve para nada aqui; a única linha que importa nomeia a sessão e o
curso. O servidor de desenvolvimento se recusa com as mesmas palavras:

```
ana@dev:~/vue/planner$ npm run dev

> planner@0.0.0 dev
> vite

error when starting dev server:
Error: courses.json: these sessions name a course that does not exist: s5 (piano)
    at PluginContext._formatLog (file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:8803:39)
    at PluginContext.error (file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:8800:14)
    at PluginContext.buildStart (file:///home/ana/vue/planner/node_modules/.vite-temp/vite.config.js.timestamp-1792800417896-caf4ea780060a.mjs:15:10)
    at async Promise.all (index 7)
    at async EnvironmentPluginContainer.hookParallel (file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:8437:3)
    at async file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:8448:4
    at async EnvironmentPluginContainer.buildStart (file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:8451:3)
    at async file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:25099:41
    at async httpServer.listen (file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:25110:5) {
  plugin: 'check-planner-data'
}
```

Ponha o curso de volta, e os dois passam de novo:

```
ana@dev:~/vue/planner$ sed -i 's/"course": "piano"/"course": "guitar"/' public/courses.json
ana@dev:~/vue/planner$ npm run build 2>&1 | tail -3
dist/assets/index-CNeZWQJG.js        122.37 kB │ gzip: 47.27 kB

✓ built in 761ms
```

## O que ele não pega

**O `buildStart` roda quando o servidor de desenvolvimento inicia, não enquanto ele roda.** Quebre o
`courses.json` com o servidor já no ar, e nada avisa até o próximo início ou o próximo build. Um plugin
também consegue observar um arquivo no servidor de desenvolvimento, com o hook `configureServer`, que
entrega a ele o servidor e o seu observador de arquivos; para uma verificação como esta, o build é onde
ela conta, porque o build é o que chega aos alunos, e o build sempre a roda. Outros hooks fazem outros
trabalhos: `resolveId` e `load` inventam um módulo que não está no disco, e o `transform` recebe o
código de cada arquivo antes de ele ser servido e pode alterá-lo, que é como o `plugin-vue` transforma
um arquivo `.vue` em JavaScript.
