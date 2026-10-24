---
title: Quando a instalação falha
version: 1
---

Instalar ferramentas é onde muita gente para, numa mensagem de erro sobre algo que ainda não
aprendeu. Estas são as falhas que esta instalação de fato produz, cada uma com o que significa e a
transcrição dela acontecendo. Leia agora, antes de precisar.

## `node: command not found`

Você viu esta de propósito em "O seu computador, preparado para este curso". O shell decide o seu
`PATH` quando abre, e `~/.local/bin` só está nele se a pasta já existia nessa hora. **Abra um
terminal novo.** Se um terminal novo ainda disser isso, `ls ~/.local/bin` deve listar `node`, `npm` e
`npx`; se não listar nada, a linha `ln -s` não rodou. No Ubuntu a mensagem pode sugerir
`sudo apt install nodejs`. Não aceite a sugestão, pelo motivo do próximo título.

## Um segundo Node, mais velho que o seu

O Ubuntu tem um Node próprio no seu repositório, a versão 18, e instalá-lo, ou instalar um programa
que dependa dele, põe um segundo `node` em `/usr/bin`. A sua `~/.local/bin` vem primeiro no `PATH`
que o `~/.profile` do Ubuntu monta, então normalmente é o seu que responde. Este terminal teve o
`PATH` alterado para pôr `/usr/bin` na frente, como um profile editado à mão ou o instalador de
outra ferramenta podem fazer:

```
ana@dev:~/planner$ PATH=/usr/bin:$PATH
ana@dev:~/planner$ which -a node
/usr/bin/node
/home/ana/.local/bin/node
/usr/bin/node
/bin/node
ana@dev:~/planner$ node --version
v18.19.1
ana@dev:~/planner$ npm install
npm error code EBADENGINE
npm error engine Unsupported engine
npm error engine Not compatible with your version of node/npm: @sveltejs/kit@3.1.0
npm error notsup Not compatible with your version of node/npm: @sveltejs/kit@3.1.0
npm error notsup Required: {"node":">=22.17"}
npm error notsup Actual:   {"npm":"10.9.4","node":"v18.19.1"}
npm error A complete log of this run can be found in: /home/ana/.npm/_logs/2026-10-23T22_15_46_547Z-debug-0.log
```

**`EBADENGINE` é o npm recusando, e é a falha útil.** O SvelteKit 3.1.0 declara que precisa do Node
22.17 ou mais novo, e a linha `engine-strict=true` no `.npmrc` do projeto transforma essa declaração
numa recusa. As linhas `Required` e `Actual` dizem exatamente o que foi pedido e o que foi
encontrado. O servidor de desenvolvimento, iniciado com o Node velho, falha de um jeito menos útil:

```
ana@dev:~/planner$ PATH=/usr/bin:$PATH npm run dev

> planner@0.0.1 dev
> vite dev

file:///home/ana/planner/node_modules/rolldown/dist/shared/create-bundler-option-DzNR1xQS.mjs:8
import { formatWithOptions, styleText } from "node:util";
                            ^^^^^^^^^
SyntaxError: The requested module 'node:util' does not provide an export named 'styleText'
    at ModuleJob._instantiate (node:internal/modules/esm/module_job:123:21)
    at async ModuleJob.run (node:internal/modules/esm/module_job:191:5)
    at async ModuleLoader.import (node:internal/modules/esm/loader:336:24)

Node.js v18.19.1
```

`styleText` é uma função que o Node acrescentou depois da versão 18, e o empacotador do Vite a
chama. A última linha diz qual Node rodou, e é a linha a ler primeiro sempre que um erro não fizer
sentido: **um erro sobre algo ausente de um módulo `node:` quase sempre é um Node velho.**
`which -a node` lista cada `node` do `PATH` na ordem em que o shell tenta; o primeiro responde.
`sudo apt remove nodejs` remove o do Ubuntu.

## O Playwright não acha o seu navegador

O `look` dirige um navegador que ele espera encontrar onde o `npx playwright install` o põe. Se esse
passo foi pulado, ou rodou para outra versão do Playwright, é isto que aparece:

```
ana@dev:~$ look 'data:text/html,<main><h1>It works</h1></main>'
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
    at /home/ana/svelte-tools/look.mjs:19:32 {
  log: [],
  name: 'Error'
}

Node.js v22.22.0
```

**O Playwright diz o que rodar, e ele está certo.** Cada versão do Playwright pede um build do
navegador, e uma pasta cheia de outros builds não serve. Rode de novo a linha de instalação de "O
comando look" dentro de `~/svelte-tools`, para que seja o mesmo Playwright pedindo.

## A porta já está em uso

Só um programa pode escutar numa porta. Iniciar um segundo servidor de desenvolvimento enquanto o
primeiro ainda roda, num outro terminal que você esqueceu, dá nisto:

```
ana@dev:~/planner$ timeout 5 npm run dev

> planner@0.0.1 dev
> vite dev

7:15:39 PM [vite] (ssr) connected.
Port 5173 is in use, trying another one...

  VITE v8.3.5  ready in 598 ms

  ➜  Local:   http://localhost:5174/
  ➜  Network: use --host to expose
```

**O Vite não falha; ele passa para a porta seguinte**, e diz isso na primeira linha. A página que
você estava vendo continua sendo a do primeiro servidor, na 5173, e o novo está na 5174, o que é
fácil de não notar. Pare o servidor que você não quer com Ctrl-C no terminal dele. (O `timeout 5` só
parou este depois de cinco segundos para a transcrição terminar.)

## O download falha

`curl` ou `npm` imprimindo `Could not resolve host` quer dizer que o computador está sem DNS; dentro
de uma máquina virtual, normalmente é uma VPN no hospedeiro no meio do caminho. Uma mensagem sobre
certificado quer dizer que algo entre você e a internet está inspecionando a conexão, como algumas
redes de empresas e escolas fazem. **Nunca responda a isso desligando a conferência de
certificado.** Peça a quem cuida da rede o certificado dela, ou instale de uma rede que não faça
isso.

## E quando nada mais funciona

Apague e faça de novo. `rm -rf ~/planner` remove o projeto e a seção do primeiro projeto o devolve
em mais ou menos um minuto; `rm -rf ~/svelte-tools ~/.cache/ms-playwright` faz o mesmo com o
`look`. Parece desistir, e é o que quem faz isso profissionalmente faz com uma pasta cujo estado
ninguém consegue mais explicar.
