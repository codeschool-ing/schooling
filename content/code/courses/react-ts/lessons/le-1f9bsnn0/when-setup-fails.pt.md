---
title: Quando a instalação falha
version: 1
---

**Cada falha abaixo foi produzida de verdade na máquina de onde vêm estas transcrições**, na ordem em
que você provavelmente as encontraria, e cada mensagem diz o que está errado quando você sabe onde
olhar. As falhas do próprio Node, um `node: command not found` ou um Node velho demais, estão na
seção "Quando a instalação falha" da aula 1 do `javascript`, e a cura é a mesma aqui.

## `Could not read package.json`

```
ana@dev:~$ npm run dev
npm error code ENOENT
npm error syscall open
npm error path /home/ana/package.json
npm error errno -2
npm error enoent Could not read package.json: Error: ENOENT: no such file or directory, open '/home/ana/package.json'
npm error enoent This is related to npm not being able to find a file.
npm error enoent
npm error A complete log of this run can be found in: /home/ana/.npm/_logs/2026-10-23T22_17_45_358Z-debug-0.log
```

**O npm procura o `package.json` na pasta em que você está**, e o prompt diz que este terminal está
em `~`, a pasta pessoal, e não em `~/planner`. Todo `npm run` deste curso é digitado dentro do
projeto. Faça `cd ~/planner` e tente de novo. O arquivo de log que ele cita conta a mesma história
mais longamente, e você pode apagá-lo.

## `Port 5173 is in use`

Um segundo `npm run dev`, enquanto o primeiro ainda roda em outro terminal:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.0 dev
> vite

Port 5173 is in use, trying another one...

  VITE v8.3.5  ready in 295 ms

  ➜  Local:   http://localhost:5174/
  ➜  Network: use --host to expose
```

**Isto não é um erro, e é isso que confunde.** O Vite encontrou a porta de costume ocupada e pegou a
seguinte sem alarde, então este servidor está na `5174` e a página que você tem aberta na `5173`
continua sendo a do primeiro. Dois servidores no mesmo projeto são dois lugares onde uma edição pode
ou não aparecer. Pare o que você não quer com Ctrl+C no terminal dele. Se você não lembra de ter
iniciado o primeiro, ele está num terminal esquecido, ou num que você fechou enquanto rodava;
`ss -ltnp | grep 5173` mostra qual programa ocupa a porta.

## `Executable doesn't exist`

O `look` rodado num computador em que o navegador do Playwright nunca foi baixado:

```
ana@dev:~/planner$ look http://localhost:5173/
node:internal/modules/run_main:123
    triggerUncaughtException(
    ^

browserType.launch: Executable doesn't exist at /home/ana/no-browser-here/chromium_headless_shell-1243/chrome-headless-shell-linux64/chrome-headless-shell
╔════════════════════════════════════════════════════════════╗
║ Looks like Playwright was just installed or updated.       ║
║ Please run the following command to download new browsers: ║
║                                                            ║
║     npx playwright install                                 ║
║                                                            ║
║ <3 Playwright Team                                         ║
```

O caminho na linha longa é onde o Playwright procurou, e o número nele, `1243`, é o build que esta
versão quer. A caixa sugere `npx playwright install`, que baixa três navegadores. **Você precisa de
um**: rode a linha da seção "Lendo uma página como texto", com `--only-shell chromium`, dentro de
`~/react-tools`. Rodada de outra pasta, ela pode instalar um build para outro Playwright, e a
mensagem volta com o mesmo número.

## `ERR_CONNECTION_REFUSED`

```
ana@dev:~/planner$ look http://localhost:5173/ 2>&1 | head -n 6
node:internal/modules/run_main:123
    triggerUncaughtException(
    ^

page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5173/
Call log:
```

**Nada está escutando naquele endereço.** O servidor de desenvolvimento não está rodando, ou está
rodando em outra porta. Olhe o terminal dele: se voltou ao prompt, ele parou, e as linhas acima do
prompt dizem por quê. `npm run dev` o inicia de novo.

## O app não aparece

A falha mais comum enquanto você escreve código, e não enquanto instala. Um erro de digitação num
import, por exemplo:

```
ana@dev:~/planner$ sed -i "1s/'react'/'reakt'/" src/App.tsx
ana@dev:~/planner$ head -n 1 src/App.tsx
import { useState } from 'reakt'
ana@dev:~/planner$ look http://localhost:5173/
[error] Failed to load resource: the server responded with a status of 500 (Internal Server Error)
- text: "[plugin:vite:import-analysis] Failed to resolve import \"reakt\" from \"src/App.tsx\". Does the file exist? /home/ana/planner/src/App.tsx:1:25 1 | import { useState } from \"reakt\"; | ^ 2 | import heroImg from \"./assets/hero.png\"; 3 | import reactLogo from \"./assets/react.svg\"; at TransformPluginContext._formatLog (file:///home/ana/planner/node_modules/vite/dist/node/chunks/node.js:8803:39) at TransformPluginContext.error (file:///home/ana/planner/node_modules/vite/dist/node/chunks/node.js:8800:14) at resolveId (file:///home/ana/planner/node_modules/vite/dist/node/chunks/node.js:26594:18) at async file:///home/ana/planner/node_modules/vite/dist/node/chunks/node.js:26693:23 at async Promise.all (index 0) at async TransformPluginContext.transform (file:///home/ana/planner/node_modules/vite/dist/node/chunks/node.js:26666:4) at async EnvironmentPluginContainer.transform (file:///home/ana/planner/node_modules/vite/dist/node/chunks/node.js:8582:14) at async loadAndTransform (file:///home/ana/planner/node_modules/vite/dist/node/chunks/node.js:20155:26) Click outside, press Esc key, or fix the code to dismiss. You can also disable this overlay by setting"
- code: server.hmr.overlay
- text: to
- code: "false"
- text: in
- code: vite.config.ts
- text: .
```

O console tem um erro, uma requisição que falhou com status 500, e a página foi substituída pelo
**painel de erro do Vite**, o que o seu navegador desenha por cima do app, e que o `look` lê como uma
linha longa de texto. A mesma mensagem, arrumada para ser lida, está no terminal onde roda o
servidor de desenvolvimento:

```
7:17:54 PM [vite] (client) Pre-transform error: Failed to resolve import "reakt" from "src/App.tsx". Does the file exist?
  Plugin: vite:import-analysis
  File: /home/ana/planner/src/App.tsx:1:25
  1  |  import { useState } from "reakt";
     |                            ^
  2  |  import heroImg from "./assets/hero.png";
  3  |  import reactLogo from "./assets/react.svg";
```

O Vite dá o nome do arquivo, da linha e do import que não encontrou, e aponta a coluna. O painel no
seu navegador fecha com Esc, o que é útil e facilita dispensá-lo sem ler. Corrija a linha, salve, e a
página volta sozinha:

```
ana@dev:~/planner$ sed -i "1s/'reakt'/'react'/" src/App.tsx
ana@dev:~/planner$ look http://localhost:5173/ --quiet
```

O `--quiet` imprime só o console, e uma resposta vazia quer dizer que a página não disse nada: nenhum
erro sobrou. **Um app que não aparece é sempre um erro em algum lugar**, e os dois lugares para olhar
são o console do navegador e o terminal do servidor. A aula 12 trata de dar ao usuário algo melhor que
uma página vazia quando o erro acontece na frente dele, e não na sua.
