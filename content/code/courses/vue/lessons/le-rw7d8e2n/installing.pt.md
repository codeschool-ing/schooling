---
title: Instalando o Vitest, e uma primeira execução
version: 1
---

**O Vitest é um executor de testes construído sobre o Vite: ele lê o mesmo `vite.config.js`, usa os
mesmos plugins, e por isso roda um arquivo `.vue` num teste exatamente como o servidor de
desenvolvimento o serve.** É por isso que ele é o que esta aula usa, e por isso quase não há o que
configurar. Mais dois pacotes vão com ele: o **Vue Test Utils**, a biblioteca do próprio Vue para
montar um componente num teste e agir sobre ele, e o **jsdom**, um documento de navegador escrito em
JavaScript, para que um componente tenha elementos onde desenhar sem um navegador. Os testes são para
o planner do Vite, `~/vue/planner`, cujas regras a aula 3 escreveu exatamente para isto. Pare o
servidor de desenvolvimento dele se estiver rodando, e instale os três, com versão fixa e só para
desenvolvimento:

```
ana@dev:~/vue/planner$ npm install --save-dev --save-exact vitest@5.0.5 @vue/test-utils@2.5.1 jsdom@30.1.3

added 71 packages, and audited 163 packages in 3s

39 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

O jsdom 30 pede o Node 22.22.2 ou mais novo, que a atualização da aula 18 já fornece. A configuração
ganha uma linha, `test`, que só o Vitest lê, e uma referência no topo que conta ao TypeScript que a
opção existe:

```javascript
// vite.config.js: how Vite serves, builds and tests the planner.
/// <reference types="vitest/config" />
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
  // Tests run in jsdom, a document without a browser, so components have somewhere to draw.
  test: { environment: 'jsdom' },
})
```

E um script, para que o `npm test` o rode:

```
ana@dev:~/vue/planner$ npm pkg set scripts.test='vitest'
```

```
ana@dev:~/vue/planner$ npx vitest run

 RUN  v5.0.5 /home/ana/vue/planner

No test files found, exiting with code 1

include: **/*.{test,spec}.?(c|m)[jt]s?(x)
exclude:  **/node_modules/**, **/.git/**

```

**Nenhum arquivo de teste, e código de saída 1**: o Vitest procurou arquivos cujos nomes terminam em
`.test.ts` ou `.spec.ts`, entre outros, não achou nenhum, e conta isso como uma falha, para que um job
de CI apontado para a pasta errada não possa passar sem testar nada. O `vitest run` roda uma vez e
para; o `vitest` sozinho, que é o que o `npm test` roda, fica aberto e roda de novo sempre que um
arquivo muda, que é como ele é usado enquanto se trabalha. Os arquivos de teste ficam ao lado dos
arquivos que testam, `planner.test.ts` junto de `planner.ts`.
