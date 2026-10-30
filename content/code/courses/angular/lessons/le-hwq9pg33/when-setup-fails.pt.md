---
title: Quando a instalação falha
version: 1
---

Preparar o ambiente é onde um curso perde gente, e quase sempre para uma de meia dúzia de falhas.
Cada uma abaixo foi provocada de propósito na máquina da gravação, então a mensagem que você vê é a
que você vai receber. Duas regras antes, porque elas resolvem a maioria dos casos sozinhas.

**Leia o primeiro erro, não a última linha.** O npm imprime uma página e termina com o caminho de um
arquivo de log; a linha que diz o que deu errado fica perto do topo, depois de `npm error code`.

**Pesquise as palavras exatas.** Copie a mensagem sem os seus caminhos e nomes de arquivo para um
buscador, entre aspas. Alguém já teve o mesmo erro antes de você, e a resposta costuma estar no
rastreador de issues do próprio projeto.

## A CLI recusa o seu Node

A CLI do Angular confere a versão do Node antes de fazer qualquer coisa. O Angular 22, o major mais
novo quando este curso foi gravado, pede mais do que o Node que esta trilha instala. Pedir a versão
dele mostra as duas metades da resposta: primeiro o npm avisa sobre cada pacote, depois a própria
CLI para.

```
ana@dev:~$ npx @angular/cli@22.2.4 version 2>&1 | head -12
npm warn exec The following package was not found and will be installed: @angular/cli@22.2.4
npm warn EBADENGINE Unsupported engine {
npm warn EBADENGINE   package: '@angular/cli@22.2.4',
npm warn EBADENGINE   required: {
npm warn EBADENGINE     npm: '^6.11.0 || ^7.5.6 || >=8.0.0',
npm warn EBADENGINE     node: '^22.22.3 || ^24.15.0 || >=26.0.0',
npm warn EBADENGINE     yarn: '>= 1.13.0'
npm warn EBADENGINE   },
npm warn EBADENGINE   current: { node: 'v22.22.0', npm: '10.9.4' }
npm warn EBADENGINE }
npm warn EBADENGINE Unsupported engine {
npm warn EBADENGINE   package: '@angular-devkit/architect@0.2202.4',
```

`EBADENGINE` é o npm lendo o campo `engines` que cada pacote declara e notando que `v22.22.0` está
fora dele. O npm só avisa, e segue. Quem recusa é a CLI:

```
ana@dev:~$ npx @angular/cli@22.2.4 version 2>&1 | tail -4
The Angular CLI requires a minimum Node.js version of v22.22.3 or v24.15.0 or v26.0.0.

Please update your Node.js version or visit https://nodejs.org/ for additional instructions.
```

**É por isso que o curso usa o Angular 21.** A CLI dele aceita Node a partir do 22.12, então roda no
Node que a trilha inteira compartilha, e ele tem suporte de longo prazo até maio de 2027, dezoito
meses depois do lançamento em novembro de 2025. A aula 2 fixa essa versão, e a última seção dela
mostra o que seria preciso para ir ao 22. Se você vir esta mensagem com o 21, o seu Node é mais
velho que o 22.12: o `node --version` vai dizer, e a aula 1 de `javascript` é onde ele foi instalado.

## O npm não alcança o registro

Todo `npm install` e todo `npx` baixam do `registry.npmjs.org`. Quando a rede entre você e ele está
no caminho, um proxy da empresa, um firewall, a página de login do Wi-Fi de um hotel, o erro é sempre
sobre uma conexão. Este aqui foi feito apontando o npm para uma porta onde nada escuta:

```
ana@dev:~$ npm view @angular/cli version --registry http://127.0.0.1:9/
npm error code ECONNREFUSED
npm error syscall connect
npm error errno ECONNREFUSED
npm error FetchError: request to http://127.0.0.1:9/@angular%2fcli failed, reason: connect ECONNREFUSED 127.0.0.1:9
npm error     at ClientRequest.<anonymous> (/home/ana/.local/node/lib/node_modules/npm/node_modules/minipass-fetch/lib/index.js:130:14)
npm error     at ClientRequest.emit (node:events:519:28)
npm error     at emitErrorEvent (node:_http_client:107:11)
npm error     at _destroy (node:_http_client:954:9)
npm error     at onSocketNT (node:_http_client:974:5)
npm error     at process.processTicksAndRejections (node:internal/process/task_queues:91:21) {
npm error   code: 'ECONNREFUSED',
npm error   errno: 'ECONNREFUSED',
npm error   syscall: 'connect',
npm error   address: '127.0.0.1',
npm error   port: 9,
npm error   type: 'system'
npm error }
npm error
npm error If you are behind a proxy, please make sure that the
npm error 'proxy' config is set properly.  See: 'npm help config'
npm error A complete log of this run can be found in: /home/ana/.npm/_logs/2026-10-29T23_33_59_073Z-debug-0.log
```

`ECONNREFUSED` quer dizer que algo respondeu e disse não; `ETIMEDOUT`, que nada respondeu;
`ENOTFOUND`, que o nome do registro não foi resolvido, o que é um problema de DNS. A sugestão do
próprio npm no fim é a certa para uma rede de empresa: peça o endereço do proxy a quem cuida dela, e
configure-o com `npm config set proxy` e `npm config set https-proxy`.

`npm config get registry` diz para onde o npm aponta. Deve ser `https://registry.npmjs.org/`, a não
ser que a sua empresa tenha um espelho.

## Duas falhas que a aula 2 mostra onde elas acontecem

- **O npm para com `Cannot read properties of null (reading 'edgesOut')`** ao instalar um projeto
  novo. É um defeito do próprio npm 10.9.4, a versão que vem com este Node, e ele é disparado pelos
  pacotes que um projeto Angular novo pede. A aula 2, seção "Um projeto, em versões exatas", mostra
  o erro e a configuração de uma linha que o evita.
- **`Port 4200 is already in use`** ao iniciar o servidor de desenvolvimento: um servidor de antes
  continua rodando em outro terminal. A aula 2 mostra o que fazer com ele.

## O disco enche

Um projeto Angular novo tem algumas centenas de megabytes, quase tudo em `node_modules`, e o npm
guarda um cache de tudo o que baixou em `~/.npm`. Quando o disco acaba, o npm diz `ENOSPC`. Um
projeto que você terminou pode perder o `node_modules` sem risco, porque o `npm ci` o devolve
exatamente a partir do `package-lock.json`; o `npm cache clean --force` esvazia o cache.
