---
title: Quando a instalação falha
version: 1
---

Instalar ferramentas é onde muita gente para, diante de um erro sobre algo que ainda não aprendeu.
Estas são as falhas que esta instalação produz, o que cada uma quer dizer e, onde foi possível
gravar, a transcrição dela acontecendo.

## `node: command not found`

Você viu esta de propósito na seção anterior. O shell decide o seu `PATH` quando abre, e
`~/.local/bin` só está nele se a pasta já existia nessa hora. **Abra um terminal novo.** Se um
terminal novo ainda disser isso, `ls ~/.local/bin` deve listar `node`, `npm` e `npx`; se não listar
nada, a linha do `ln -s` não rodou. No Ubuntu a mensagem pode sugerir `sudo apt install nodejs`:
não siga a sugestão, pelo motivo da seção depois da próxima.

## O processador errado

Um arquivo para o processador errado se descompacta sem reclamar e depois se recusa a rodar, com
`cannot execute binary file: Exec format error`. Apague a pasta, confira `uname -m` de novo e baixe
o outro arquivo. Um Mac com chip da Apple e muitos notebooks Windows recentes com Snapdragon são
`arm64`; a maioria dos outros computadores é `x86_64`. A seção "When the setup fails" da aula 1 de
javascript tem a transcrição.

## Um segundo Node, mais antigo

O Ubuntu tem um Node próprio no seu repositório, e instalá-lo, ou um programa que dependa dele,
põe um segundo `node` em `/usr/bin`. Esse é a versão 18, e as ferramentas deste curso não rodam
nele. Esta máquina tinha o pacote `nodejs` do Ubuntu instalado ao lado do Node do curso, e um
terminal cujo `PATH` tinha perdido `~/.local/bin`, que é o que tem um terminal aberto antes de a
pasta existir:

```
ana@dev:~/planner$ which -a node
/usr/bin/node
/bin/node
ana@dev:~/planner$ node --version
v18.19.1
ana@dev:~/planner$ node node_modules/.bin/vite
file:///home/ana/planner/node_modules/rolldown/dist/shared/create-bundler-option-DzNR1xQS.mjs:8
import { formatWithOptions, styleText } from "node:util";
                            ^^^^^^^^^
SyntaxError: The requested module 'node:util' does not provide an export named 'styleText'
    at ModuleJob._instantiate (node:internal/modules/esm/module_job:123:21)
    at async ModuleJob.run (node:internal/modules/esm/module_job:191:5)
    at async ModuleLoader.import (node:internal/modules/esm/loader:336:24)

Node.js v18.19.1
```

**Nada nesse erro diz "versão errada do Node".** O Vite, pelo bundler que ele traz dentro, pediu ao
Node uma função chamada `styleText`, que o Node 18 não tem, e o programa parou antes de imprimir
uma palavra sua. `node node_modules/.bin/vite` é o que o `npm run dev` roda, digitado por extenso
porque este terminal não tinha `npm` nenhum: o Ubuntu o empacota à parte. Então, quando uma
ferramenta falhar com um `SyntaxError` dentro de `node_modules`, num arquivo que você nunca
escreveu, **pergunte `node --version` primeiro**. A correção não está no projeto: devolva
`~/.local/bin` ao `PATH` (um terminal novo faz isso) ou remova o segundo Node com
`sudo apt remove nodejs`. `which -a node` lista todo `node` que o shell consegue achar, na ordem em
que ele tenta, e o primeiro é o que roda.

## A porta está ocupada

O servidor de desenvolvimento do Vite escuta na porta 5173. Se algo já escuta nela, ele pega a
próxima livre e avisa, o que é fácil de perder num terminal que rolou. Aqui o `npm run dev` ainda
rodava em outro terminal, e `timeout 5` parou o segundo depois de cinco segundos:

```
ana@dev:~/planner$ timeout 5 npx vite
Port 5173 is in use, trying another one...

  VITE v8.3.5  ready in 213 ms

  ➜  Local:   http://localhost:5174/
  ➜  Network: use --host to expose
```

A página fica então no endereço da linha `Local:`, não no que você digitou no navegador ontem. O
outro servidor costuma ser um `npm run dev` esquecido num terminal; `Ctrl-C` naquele terminal o
para. O servidor que você vai escrever nesta aula escuta na porta 3000 e não muda: ele falha com
`EADDRINUSE`, que quer dizer a mesma coisa.

## O Playwright não acha o navegador

O pacote `playwright` e o navegador que ele controla são dois downloads, e o primeiro não busca o
segundo. Um programa que abre o Chromium antes de `npx playwright install chromium` rodar falha
como este, o `tools/look.ts`, que a seção "Client-side rendering, measured" entrega a você.
`PLAYWRIGHT_BROWSERS_PATH` manda o Playwright procurar numa pasta vazia, que é o que tem um
computador que nunca rodou a instalação:

```
ana@dev:~/planner$ PLAYWRIGHT_BROWSERS_PATH=/tmp/empty node tools/look.ts http://localhost:5173/
node:internal/modules/run_main:123
    triggerUncaughtException(
    ^

browserType.launch: Executable doesn't exist at /tmp/empty/chromium_headless_shell-1243/chrome-headless-shell-linux64/chrome-headless-shell
╔════════════════════════════════════════════════════════════╗
║ Looks like Playwright was just installed or updated.       ║
║ Please run the following command to download new browsers: ║
║                                                            ║
║     npx playwright install                                 ║
║                                                            ║
║ <3 Playwright Team                                         ║
╚════════════════════════════════════════════════════════════╝
    at /home/ana/planner/tools/look.ts:11:32 {
  log: [],
  name: 'Error'
}

Node.js v22.22.0
```

A mensagem diz a pasta onde procurou e o comando que a preenche. Cada versão do Playwright controla
um build do Chromium, então depois de mudar a versão no `package.json` o mesmo erro volta até o
comando de instalação rodar de novo.

## O Chromium está lá e não abre

Num Linux sem área de trabalho, o Chromium pode não ter bibliotecas de que precisa para desenhar, e
o erro lista arquivos terminados em `.so`. `npx playwright install-deps chromium` as instala com o
`apt`, e pede a sua senha para isso. *Esse comando não foi executado onde este curso foi gravado,
porque aquela máquina já tinha todas as bibliotecas.*

## O npm não alcança o registro

`npm install` busca pacotes em `registry.npmjs.org`. Numa rede que o bloqueia, ou atrás de um proxy
de empresa, a instalação para com `ECONNREFUSED`, `ETIMEDOUT` ou um erro de certificado, e nada é
instalado. Tente de novo em outra rede, ou pergunte a quem cuida daquela rede o que o npm precisa
saber: um proxy se configura com `npm config set proxy`, e o certificado próprio de uma empresa com
`npm config set cafile`. Nunca responda a um erro de certificado desligando a verificação; isso faz
o erro sumir aceitando qualquer servidor que diga ser o registro.
