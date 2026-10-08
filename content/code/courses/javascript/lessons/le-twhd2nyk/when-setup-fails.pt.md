---
title: Quando a instalação falha
version: 2
---

**Cada falha abaixo aconteceu de verdade enquanto este curso era montado, e cada mensagem diz
exatamente o que está errado quando você sabe lê-la.** Elas vêm na ordem em que você as
encontraria: instalando o Node, rodando o `page` e depois rodando os seus primeiros arquivos. Esta
seção é para o momento em que algo não funciona, então mostra cada mensagem antes de explicá-la.

## `node: command not found`

A última linha da instalação, antes de o terminal ser fechado:

```
ana@dev:~$ node --version
bash: line 13: node: command not found
```

O shell procurou um programa chamado `node` em cada pasta do seu `PATH` e não achou nenhum. **Um
terminal lê o `PATH` uma vez, quando abre**, então um terminal aberto antes de `~/.local/bin` existir
nunca olha lá. Abra um terminal novo antes de mudar qualquer outra coisa; numa área de trabalho,
saia da sessão e entre de novo se uma janela nova ainda disser o mesmo. Se continuar,
`ls ~/.local/bin` deve listar `node`, `npm` e `npx`, e uma resposta vazia quer dizer que a linha do
`ln` não rodou.

O próprio terminal do Ubuntu pode responder com uma sugestão de `sudo apt install nodejs`. **Não
aceite**, pelo motivo da seção depois da próxima.

## `cannot execute binary file: Exec format error`

```
ana@dev:~$ curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-arm64.tar.xz
ana@dev:~$ tar -xJf node-v22.22.0-linux-arm64.tar.xz
ana@dev:~$ ./node-v22.22.0-linux-arm64/bin/node --version
bash: line 7: ./node-v22.22.0-linux-arm64/bin/node: cannot execute binary file: Exec format error
```

**Esse arquivo foi feito para outro processador.** `linux-arm64` roda numa máquina ARM, como uma
máquina virtual Linux num Mac com chip da Apple, e este computador é `x86_64`. Rode `uname -m`, baixe
o arquivo cujo nome corresponde à resposta e desempacote esse na mesma pasta.

## O Node do próprio Ubuntu é antigo demais

```
ana@dev:~$ apt-cache policy nodejs | head -n 3
nodejs:
  Installed: (none)
  Candidate: 18.19.1+dfsg-6ubuntu5
```

O Ubuntu 24.04 traz, sim, um pacote chamado `nodejs`, e **ele é a versão 18**, quatro versões
principais atrás da que gravou este curso, e sem suporte do projeto Node. A maior parte do curso
rodaria nele, e então uma sintaxe mais nova falharia com um `SyntaxError` com cara de erro seu.
`node --version` é a conferência: qualquer coisa abaixo de `v22` é o Node errado.

## `Executable doesn't exist`

O `page` rodado antes de o navegador ser baixado:

```
ana@dev:~$ cd ~/js
ana@dev:~/js$ echo '<script>console.log("the browser works")</script>' > check.html
ana@dev:~/js$ page check.html 2>&1 | head -n 13
node:internal/modules/run_main:123
    triggerUncaughtException(
    ^

browserType.launchPersistentContext: Executable doesn't exist at /home/ana/.cache/ms-playwright/chromium_headless_shell-1194/chrome-linux/headless_shell
╔═════════════════════════════════════════════════════════════════════════╗
║ Looks like Playwright Test or Playwright was just installed or updated. ║
║ Please run the following command to download new browsers:              ║
║                                                                         ║
║     npx playwright install                                              ║
║                                                                         ║
║ <3 Playwright Team                                                      ║
╚═════════════════════════════════════════════════════════════════════════╝
```

O `npm install` trouxe o Playwright e não o navegador, e o caminho na primeira linha comprida é
onde o Playwright procurou um. A caixa sugere `npx playwright install`, que baixa três navegadores;
o comando da seção anterior baixa o único que o `page` usa. Rode-o em `~/js-tools`.

## `Cannot find package 'playwright'`

```
ana@dev:~$ cd ~/js
ana@dev:~/js$ node ~/Downloads/page.mjs check.html 2>&1 | head -n 5
node:internal/modules/package_json_reader:314
  throw new ERR_MODULE_NOT_FOUND(packageName, fileURLToPath(base), null);
        ^

Error [ERR_MODULE_NOT_FOUND]: Cannot find package 'playwright' imported from /home/ana/Downloads/page.mjs
```

O `page.mjs` foi salvo onde o navegador salva arquivos, em `~/Downloads`. **O Node procura um pacote
ao lado do programa que o importa**, numa pasta `node_modules` ali ou numa pasta acima, e o
Playwright está em `~/js-tools/node_modules`. Mova os dois arquivos para `~/js-tools`.

## `EADDRINUSE`

```
ana@dev:~$ cd ~/js
ana@dev:~/js$ node ~/js-tools/serve.mjs &
serving /home/ana/js on http://127.0.0.1:8080
ana@dev:~/js$ page check.html 2>&1 | head -n 5
node:events:497
      throw er; // Unhandled 'error' event
      ^

Error: listen EADDRINUSE: address already in use 127.0.0.1:8080
ana@dev:~/js$ kill %1
```

**Só um programa por vez pode escutar num endereço**, e o `serve.mjs` já ocupava `127.0.0.1:8080`
em segundo plano quando o `page` tentou abrir o próprio servidor ali. Pare o outro: `kill %1` para o
trabalho que este terminal mandou para o segundo plano, e fechar o terminal onde ele roda também o
para.

## `Cannot find module`

```
ana@dev:~/js$ node helo.js
node:internal/modules/cjs/loader:1386
  throw err;
  ^

Error: Cannot find module '/home/ana/js/helo.js'
    at Function._resolveFilename (node:internal/modules/cjs/loader:1383:15)
    at defaultResolveImpl (node:internal/modules/cjs/loader:1025:19)
    at resolveForCJSWithHooks (node:internal/modules/cjs/loader:1030:22)
    at Function._load (node:internal/modules/cjs/loader:1192:37)
    at TracingChannel.traceSync (node:diagnostics_channel:328:14)
    at wrapModuleLoad (node:internal/modules/cjs/loader:237:24)
    at Function.executeUserEntryPoint [as runMain] (node:internal/modules/run_main:171:5)
    at node:internal/main/run_main_module:36:49 {
  code: 'MODULE_NOT_FOUND',
  requireStack: []
}

Node.js v22.22.0
```

Comprida, e só uma linha importa: `Error: Cannot find module '/home/ana/js/helo.js'`. **O Node está
dizendo o caminho completo que tentou**, e o arquivo se chama `hello.js`. Tudo o que vem recuado
embaixo é o código do próprio Node a caminho desse erro; dá para ignorar até a aula 17 ensinar a
ler uma pilha. As duas causas comuns são um erro de digitação, como aqui, e um terminal parado num
diretório diferente do arquivo. `pwd` diz onde você está, `ls` o que tem ali.

## `Invalid or unexpected token`

Um arquivo colado de um editor de texto ou de uma janela de chat costuma trazer aspas tipográficas,
`“` e `”`, onde a linguagem quer o `"` simples:

```javascript
console.log(“Hello”);
```

```
ana@dev:~/js$ node quotes.js 2>&1 | head -n 5
/home/ana/js/quotes.js:1
console.log(“Hello”);
            

SyntaxError: Invalid or unexpected token
```

O `2>&1 | head -n 5` no fim mantém as cinco primeiras linhas; o resto é a mesma lista de internos
do Node de antes. **Um token é uma palavra da linguagem**, e `“` não é uma. O Node diz o arquivo e
a linha, `quotes.js:1`, e é ali que se olha. Redigite as aspas no seu editor.

## `Unexpected token '<'`

```
ana@dev:~/js$ node hello.html 2>&1 | head -n 5
/home/ana/js/hello.html:1
<!doctype html>
^

SyntaxError: Unexpected token '<'
```

**O Node recebeu uma página em vez de um programa.** `<` é onde o HTML começa e o JavaScript não. A
página vai para o `page`, ou para um navegador; só o arquivo `.js` vai para o `node`.
