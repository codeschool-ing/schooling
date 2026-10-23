---
title: Quando a preparação falha
version: 1
---

**Cada falha abaixo aconteceu de verdade enquanto este curso era gravado, e cada mensagem diz o que
está errado quando você sabe qual linha ler.** Elas vêm na ordem em que você as encontraria. Esta
seção é para o momento em que algo não funciona, então mostra cada mensagem antes de explicá-la.

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
npm error A complete log of this run can be found in: /home/ana/.npm/_logs/2026-10-23T22_52_38_470Z-debug-0.log
```

**O npm procura o `package.json` na pasta em que você está**, e o terminal estava na sua pasta
pessoal, não no projeto. A linha a ler é a terceira: o caminho que ele tentou. Faça `cd ~/planner` e
rode de novo. O resto é o npm dizendo onde guardou um log mais longo, de que você não vai precisar.

## `vite: not found`

```
ana@dev:~/planner$ rm -rf node_modules
ana@dev:~/planner$ npm run dev

> planner@0.0.0 dev
> vite

sh: 1: vite: not found
ana@dev:~/planner$ npm ci

added 18 packages, and audited 19 packages in 924ms

found 0 vulnerabilities
```

O `npm run dev` roda o script `dev` do `package.json`, que é `vite`, e **um script procura seus
programas em `node_modules/.bin`**. Sem `node_modules` não há `vite`. É assim que fica um clone novo do
projeto, já que o Git não guarda essa pasta. O `npm ci` a reconstrói a partir do lockfile, exatamente
como era, e se recusa se o `package.json` e o lockfile discordarem; o `npm install` acertaria os dois
em silêncio, que é o contrário do que você quer quando está tentando repetir uma configuração.

## `Port 5173 is in use`

```
ana@dev:~/planner$ npm run dev

> planner@0.0.0 dev
> vite

Port 5173 is in use, trying another one...

  VITE v8.3.5  ready in 182 ms

  ➜  Local:   http://localhost:5174/
  ➜  Network: use --host to expose
```

**Isto não é um erro, e é aí que está a armadilha.** Um primeiro `npm run dev` ainda rodava em outro
terminal, então o Vite pegou a próxima porta livre e disse isso numa linha. O app agora responde em
`http://localhost:5174/`, e uma aba ainda aberta na 5173 está conversando com o outro servidor. Os
testes da aula 4 esperam o planner na 5173, então pare o servidor perdido com Ctrl+C no terminal dele
antes de subir outro.

## `does not provide an export named 'styleText'`

```
ana@dev:~/planner$ node --version
v18.19.1
ana@dev:~/planner$ npm run dev

> planner@0.0.0 dev
> vite

file:///home/ana/planner/node_modules/rolldown/dist/shared/create-bundler-option-DzNR1xQS.mjs:8
import { formatWithOptions, styleText } from "node:util";
                            ^^^^^^^^^
SyntaxError: The requested module 'node:util' does not provide an export named 'styleText'
    at ModuleJob._instantiate (node:internal/modules/esm/module_job:123:21)
    at async ModuleJob.run (node:internal/modules/esm/module_job:191:5)
    at async ModuleLoader.import (node:internal/modules/esm/loader:336:24)

Node.js v18.19.1
```

**Este é o Node errado.** O Ubuntu traz seu próprio pacote chamado `nodejs`, e no Ubuntu 24.04 ele é a
versão 18, então é isto que o `sudo apt install nodejs` entrega. O Vite 8 precisa do Node 20.19 ou mais
novo, e a primeira coisa que ele faz num mais antigo é falhar com um `SyntaxError` dentro de um pacote
de que você nunca ouviu falar. A linha que conta é a última, `Node.js v18.19.1`. O `node --version` é
a checagem: qualquer coisa abaixo de `v22` não é o Node com que este curso foi gravado, e a correção é
remover o pacote (`sudo apt remove nodejs`) e abrir um terminal novo, para o shell achar o que está em
`~/.local/bin`.
