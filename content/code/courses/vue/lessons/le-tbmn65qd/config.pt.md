---
title: vite.config.js
version: 1
---

**O Vite funciona sem nenhum arquivo de configuração, e o `vite.config.js` é onde um projeto diz o
que faz de diferente.** A aula 1 percorreu o que o `create-vue` escreveu: o plugin do Vue e o alias
`@`. O arquivo é um módulo JavaScript que roda no Node, antes de o servidor iniciar ou de o build
começar, então ele pode importar pacotes, ler arquivos e calcular valores, e o `defineConfig` só dá ao
editor a lista de opções para sugerir.

O do planner ganha duas linhas, uma para cada um dos servidores do Vite:

```javascript
// vite.config.js: how Vite serves and builds the planner.
import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
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

A aula 1 mostrou o que acontece quando um segundo servidor de desenvolvimento inicia enquanto o
primeiro ainda está rodando: ele diz `Port 5173 is in use, trying another one...` e fica com a `5174`,
e a aba do navegador ainda aberta na `5173` continua falando com o primeiro servidor. Com
`strictPort`, o segundo se recusa:

```
ana@dev:~/vue/planner$ npm run dev

> planner@0.0.0 dev
> vite

error when starting dev server:
Error: Port 5173 is already in use
    at httpServerStart (file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:14661:10)
    at process.processTicksAndRejections (node:internal/process/task_queues:105:5)
    at async startServer (file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:25127:30)
    at async Object.listen (file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:24933:4)
    at async CAC.<anonymous> (file:///home/ana/vue/planner/node_modules/vite/dist/node/cli.js:735:3)
```

**Um erro que faz você parar é melhor do que um servidor que funciona numa porta para a qual você não
está olhando.** O mesmo é definido para o `vite preview` na sua própria porta, a `4173`. O servidor não
precisa ser reiniciado para isso: o Vite observa o seu arquivo de configuração, e uma mudança nele
reinicia o servidor sozinho.

Um arquivo ao lado dele já cumpriu o seu papel. O `jsconfig.json`, da aula 1, contava ao editor sobre
o alias `@` num projeto JavaScript, e desde a aula 16 o `tsconfig.json` diz o mesmo nos seus `paths`,
então o arquivo antigo pode sair:

```
ana@dev:~/vue/planner$ rm jsconfig.json
```

## As opções que vale conhecer

A configuração tem algumas centenas de opções e a maioria dos projetos define cinco. Estas são as que
um projeto Vue encontra primeiro, todas no mesmo arquivo:

| opção | o que ela decide |
| --- | --- |
| `plugins` | o que o Vite entende além de JavaScript, CSS e HTML: `vue()` para arquivos `.vue` |
| `resolve.alias` | nomes curtos para pastas, o `@` para `src` |
| `server.port`, `server.strictPort`, `server.host` | onde o servidor de desenvolvimento escuta, e se outros computadores podem alcançá-lo |
| `server.proxy` | endereços que o servidor de desenvolvimento repassa para outro servidor, para que `/api` chegue a um backend em outra porta |
| `base` | o caminho sob o qual o site do build fica, `/planner/` se ele não estiver na raiz do seu domínio |
| `build.outDir` | para onde o build vai, `dist` a não ser que você diga outra coisa |

O `server.proxy` é o que o planner não vai precisar e muitos projetos precisam. Um backend rodando em
`localhost:3000` e uma página em `localhost:5173` são duas origens, então o navegador aplica CORS
entre eles; com `proxy: { '/api': 'http://localhost:3000' }` a página pergunta ao próprio servidor, e
o Vite repassa a requisição. O proxy pertence aos dois servidores do Vite, `dev` e `preview`, e a nada
mais. Um build é uma pasta de arquivos, e em produção o mesmo trabalho fica com o host ou com o que
estiver na frente do backend.
