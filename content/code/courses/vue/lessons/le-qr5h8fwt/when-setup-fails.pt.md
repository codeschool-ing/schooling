---
title: Quando a instalação falha
version: 1
---

**Cada falha abaixo foi produzida de verdade na máquina em que este curso foi gravado, fazendo a coisa
errada de propósito, e cada mensagem diz o que está errado quando você sabe onde olhar.** Elas vêm na
ordem em que você as encontraria. Leia-as agora, rápido, para reconhecer uma quando ela chegar.

## `node: command not found`

Você a viu na primeira seção: um terminal aberto antes de `~/.local/bin` existir nunca olha lá. Abra
um terminal novo. Se um novo ainda disser isso, `ls ~/.local/bin` deve listar `node`, `npm` e `npx`,
e a seção "Quando a instalação falha" da aula 1 do javascript tem o resto dessa história, inclusive o
Node mais antigo que o Ubuntu oferece para instalar e por que não aceitá-lo. **O Vite 8 é escrito para
o Node 22.18 e posteriores**, como diz a linha `engines` do `package.json` do planner, então
`node --version` é a primeira coisa a conferir sempre que algo aqui se comportar mal.

## `Could not read package.json`

```
ana@dev:~/vue$ npm run dev
npm error code ENOENT
npm error syscall open
npm error path /home/ana/vue/package.json
npm error errno -2
npm error enoent Could not read package.json: Error: ENOENT: no such file or directory, open '/home/ana/vue/package.json'
npm error enoent This is related to npm not being able to find a file.
npm error enoent
npm error A complete log of this run can be found in: /home/ana/.npm/_logs/2026-10-23T22_33_36_574Z-debug-0.log
```

**O npm procurou o `package.json` na pasta em que você está, e não há nenhum**, porque o projeto fica
uma pasta abaixo. A linha a ler é a do `path`, `/home/ana/vue/package.json`: ela diz em que pasta o
npm estava. `cd planner` e tente de novo. Todo comando `npm` deste curso é digitado dentro da própria
pasta do projeto.

## `vite: not found`

```
ana@dev:~/vue/planner$ mv node_modules /tmp/vuelab/nm
ana@dev:~/vue/planner$ npm run dev

> planner@0.0.0 dev
> vite

sh: 1: vite: not found
```

O script `dev` é `vite`, e o npm procura esse programa em `node_modules/.bin`. **Não há
`node_modules`**: aqui porque ele foi movido de propósito, na sua máquina porque o `npm install` não
foi rodado, ou falhou no meio. Rode `npm install` e leia as últimas linhas dele. Uma cópia de um
projeto de outra pessoa, um `git clone` novo inclusive, nunca tem `node_modules`, porque ele é refeito
a partir do lockfile e não é guardado.

## `Port 5173 is in use`

Um segundo `npm run dev`, com o primeiro ainda rodando:

```
ana@dev:~/vue/planner$ npm run dev

> planner@0.0.0 dev
> vite

Port 5173 is in use, trying another one...

  VITE v8.3.5  ready in 411 ms

  ➜  Local:   http://localhost:5174/
  ➜  Network: use --host to expose
```

O Vite não falhou. **Ele pegou a porta seguinte e disse isso**, e a página agora está na `5174`,
enquanto a aba do navegador que você tinha aberta ainda conversa com o primeiro servidor. É assim que
alguém acaba editando um projeto e olhando para outro. Ache o terminal que já está rodando um servidor
de desenvolvimento e use-o, ou pare-o com Ctrl-C. Toda transcrição deste curso usa a `5173`.

## `Executable doesn't exist`

O `look` rodado antes de o navegador ser baixado:

```
ana@dev:~/vue/planner$ look http://localhost:5173/
node:internal/modules/run_main:123
    triggerUncaughtException(
    ^

browserType.launch: Executable doesn't exist at /home/ana/.cache/ms-playwright/chromium_headless_shell-1243/chrome-headless-shell-linux64/chrome-headless-shell
╔════════════════════════════════════════════════════════════╗
║ Looks like Playwright was just installed or updated.       ║
║ Please run the following command to download new browsers: ║
║                                                            ║
║     npx playwright install                                 ║
║                                                            ║
║ <3 Playwright Team                                         ║
╚════════════════════════════════════════════════════════════╝
    at /home/ana/vue-tools/look.mjs:47:32 {
  log: [],
  name: 'Error'
}

Node.js v22.22.0
```

**O Playwright está instalado e o navegador dele não.** O caminho na mensagem é onde ele procurou:
`chromium_headless_shell-1243` é o build que o Playwright 1.63.0 controla. A caixa sugere
`npx playwright install`, que baixa todos os navegadores que o Playwright conhece; a linha da primeira
seção baixa só o que o `look` usa. Rode-a dentro de `~/vue-tools`, porque é lá que esta cópia do
Playwright mora, e uma versão diferente em outro lugar baixaria outro build.

## Uma página em branco

A última não é uma falha de instalação, e é a que você mais vai encontrar. Uma tag de fechamento no
`App.vue` foi trocada de `</h1>` para `</h2>`, e a página ficou em branco:

```
ana@dev:~/vue/planner$ look http://localhost:5173/
[error] Failed to load resource: the server responded with a status of 500 (Internal Server Error)
[vite] connecting...
[vite] connected.
== the text of #app
```

O navegador quase não diz nada: uma requisição falhou com um 500, e o texto do `#app` está vazio.
**A explicação está no outro terminal**, onde o servidor de desenvolvimento roda:

```
ana@dev:~/vue/planner$ npm run dev

> planner@0.0.0 dev
> vite


  VITE v8.3.5  ready in 430 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
7:33:40 PM [vite] (client) hmr update /src/App.vue
7:33:41 PM [vite] (client) Pre-transform error: Invalid end tag.
  Plugin: vite:vue
  File: /home/ana/vue/planner/src/App.vue:4:18
  2  |  
  3  |  <template>
  4  |    <h1>You did it!</h2>
     |                    ^
  5  |    <p>
  6  |      Visit <a href="https://vuejs.org/" target="_blank" rel="noopener">vuejs.org</a> to read the
7:33:41 PM [vite] Internal server error: Invalid end tag.
  Plugin: vite:vue
  File: /home/ana/vue/planner/src/App.vue:4:18
  2  |  
  3  |  <template>
  4  |    <h1>You did it!</h2>
     |                    ^
  5  |    <p>
  6  |      Visit <a href="https://vuejs.org/" target="_blank" rel="noopener">vuejs.org</a> to read the
      at createCompilerError (/home/ana/vue/planner/node_modules/@vue/compiler-core/dist/compiler-core.cjs.js:1378:17)
      at emitError (/home/ana/vue/planner/node_modules/@vue/compiler-core/dist/compiler-core.cjs.js:3036:5)
      at Object.onclosetag (/home/ana/vue/planner/node_modules/@vue/compiler-core/dist/compiler-core.cjs.js:2413:9)
      at Tokenizer.stateInClosingTagName (/home/ana/vue/planner/node_modules/@vue/compiler-core/dist/compiler-core.cjs.js:799:16)
      at Tokenizer.parse (/home/ana/vue/planner/node_modules/@vue/compiler-core/dist/compiler-core.cjs.js:1157:16)
      at Object.baseParse (/home/ana/vue/planner/node_modules/@vue/compiler-core/dist/compiler-core.cjs.js:3075:13)
      at Object.parse (/home/ana/vue/planner/node_modules/@vue/compiler-dom/dist/compiler-dom.cjs.js:916:23)
      at Object.parse$1 [as parse] (/home/ana/vue/planner/node_modules/@vue/compiler-sfc/dist/compiler-sfc.cjs.js:1918:24)
      at createDescriptor (file:///home/ana/vue/planner/node_modules/@vitejs/plugin-vue/dist/index.mjs:50:42)
      at handleHotUpdate (file:///home/ana/vue/planner/node_modules/@vitejs/plugin-vue/dist/index.mjs:1202:25)
```

Leia de cima para baixo. `Invalid end tag` é o erro, `File: …/src/App.vue:4:18` é o arquivo, a linha
e a coluna, e as cinco linhas numeradas com um acento circunflexo embaixo apontam para o caractere.
Tudo de `at createCompilerError` para baixo é onde, dentro do compilador, o erro foi levantado, o que
importa para quem escreveu o compilador e não para você. No seu próprio navegador a mesma mensagem
aparece por cima da página, numa camada vermelha que o Vite desenha, até você salvar um arquivo
corrigido.

**Quando uma página estiver em branco, olhe primeiro o terminal do servidor de desenvolvimento, e
depois o console do navegador.**
