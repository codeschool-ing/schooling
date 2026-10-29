---
title: Modos e variáveis de ambiente
version: 1
---

**O código que roda no navegador não tem `process.env`, então o Vite dá a ele o `import.meta.env`, e
o preenche quando serve ou faz o build do arquivo.** Alguns nomes estão sempre lá: `MODE`, que é
`development` no `npm run dev` e `production` num build, `DEV` e `PROD`, os seus dois booleanos, e
`BASE_URL`, o `base` da configuração. O rodapé do planner pode dizer que tipo de página ele é:

```html
<!-- src/components/AppFooter.vue -->
<script setup lang="ts">
import { version } from 'vue'

// "development" under the dev server, "production" in a build.
const mode = import.meta.env.MODE
</script>

<template>
  <footer>
    <p>Built with Vue {{ version }}, {{ mode }} build</p>
  </footer>
</template>

<style scoped>
p {
  color: #666;
  font-size: 0.875rem;
}
</style>
```

## A variável do próprio planner

Qualquer outra vem de arquivos chamados `.env`, na pasta do projeto, ao lado do `package.json`. O
planner ganha um, para o endereço de onde lê os seus dados, que é o que tem mais chance de mudar
quando o planner for para um servidor próprio:

```sh
# .env: settings for every mode. Only names that start with VITE_ reach the browser.
VITE_DATA_URL=/courses.json
```

O TypeScript ainda não conhece o nome. O `env.d.ts`, da aula 16, ganha um comentário no topo, uma
declaração do que o `import.meta.env` carrega além dos nomes do próprio Vite, e uma chave que os tipos
do Vite oferecem, `strictImportMetaEnv`, sem a qual qualquer nome seria aceito e tipado como `any`:

```typescript
// env.d.ts: what TypeScript knows of the things Vite adds.
/// <reference types="vite/client" />

// A name not declared below is an error, not an `any`.
interface ViteTypeOptions {
  strictImportMetaEnv: unknown
}

// The planner's own settings, as import.meta.env carries them.
interface ImportMetaEnv {
  readonly VITE_DATA_URL: string
}
```

O `load` da store para de nomear o endereço e pede a variável:

```
ana@dev:~/vue/planner$ sed -i "s#fetch('/courses.json')#fetch(import.meta.env.VITE_DATA_URL)#" src/stores/planner.ts
ana@dev:~/vue/planner$ grep -n VITE_ src/stores/planner.ts
20:    loading ??= fetch(import.meta.env.VITE_DATA_URL)
```

```
ana@dev:~/vue/planner$ npm run type-check

> planner@0.0.0 type-check
> vue-tsc --noEmit
```

Um erro de digitação no nome agora é pego ali, antes de virar um `fetch(undefined)`:

```
ana@dev:~/vue/planner$ sed -i 's/VITE_DATA_URL/VITE_DATA_ULR/' src/stores/planner.ts
ana@dev:~/vue/planner$ npm run type-check

> planner@0.0.0 type-check
> vue-tsc --noEmit

src/stores/planner.ts(20,39): error TS2551: Property 'VITE_DATA_ULR' does not exist on type 'ImportMetaEnv'. Did you mean 'VITE_DATA_URL'?
```

Acerte o nome de novo. Um servidor de desenvolvimento rodando observa o `.env` como observa a sua
configuração, e se reinicia sozinho quando o arquivo muda (`.env changed, restarting server...`). O
rodapé informa o modo:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --text '#app > footer'
[vite] connecting...
[vite] connected.
== the text of #app > footer
Built with Vue 3.5.44, development build
```

## Substituída, não lida

Num build, o `import.meta.env.VITE_DATA_URL` não é consultado quando a página roda. **O Vite substitui
a expressão pelo seu valor enquanto faz o build**, então o arquivo do build contém a própria string.
Para ver a outra metade da regra do comentário, acrescente uma segunda variável sem o prefixo e faça o
build:

```
ana@dev:~/vue/planner$ echo 'PLANNER_NOTE=not-for-the-browser' >> .env
ana@dev:~/vue/planner$ npm run build > /dev/null
ana@dev:~/vue/planner$ grep -c 'courses.json' dist/assets/index-*.js
1
ana@dev:~/vue/planner$ cat dist/assets/*.js | grep -c 'not-for-the-browser'
0
```

**O endereço está no bundle uma vez; a nota não está em lugar nenhum.** O Vite expõe só os nomes que
começam com `VITE_`, porque um arquivo `.env` muitas vezes guarda coisas destinadas a ferramentas e
servidores, e tudo o que está no bundle é público: todo visitante o baixa e consegue lê-lo com as
ferramentas do próprio navegador. Então o prefixo é uma promessa que você faz sobre um valor, **isto
pode ser publicado**, e nunca um lugar para uma senha ou uma chave de API privada. Uma chave que
precisa ficar secreta fica num servidor, e o navegador pergunta a esse servidor, que é para o que serve
a pasta `server` do Nuxt na aula 18. Tire a nota do `.env` de novo; o planner não tem uso para ela.

O preview desse build diz o outro modo:

```
ana@dev:~/vue/planner$ look http://localhost:4173/ --text '#app > footer'
== the text of #app > footer
Built with Vue 3.5.44, production build
```

## Um modo seu

O `MODE` não se limita aos dois. O `vite build --mode staging` faz o build para um modo chamado
`staging`, e o Vite lê o `.env.staging` depois do `.env`, então um nome que está nos dois fica com o
valor do arquivo do modo:

```
ana@dev:~/vue/planner$ echo 'VITE_DATA_URL=/staging.json' > .env.staging
ana@dev:~/vue/planner$ npx vite build --mode staging > /dev/null
ana@dev:~/vue/planner$ grep -o '/[a-z]*\.json' dist/assets/index-*.js
/staging.json
ana@dev:~/vue/planner$ rm .env.staging
ana@dev:~/vue/planner$ npm run build > /dev/null
```

O `rm` e o último build deixam o planner como estava. A ordem, do mais fraco ao mais forte, é `.env`,
`.env.local`, `.env.[mode]` e `.env.[mode].local`, e uma variável já definida no shell que iniciou o
Vite vence os quatro. Os dois arquivos `.local` são para valores de um computador só, e o `.gitignore`
que o `create-vue` escreveu já tem uma linha `*.local`, então o git os deixa de fora.
