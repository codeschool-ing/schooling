---
title: Quando a instalação falha
version: 1
---

Instalar um conjunto de ferramentas é onde muita gente para, diante de uma mensagem de erro sobre algo
que ainda não aprendeu. Estas são as falhas que acontecem com esta instalação, o que cada uma quer
dizer, e a transcrição dela acontecendo.

## `node: command not found`

Você viu esta de propósito na seção anterior. O shell decide o seu `PATH` quando abre, e `~/.local/bin`
só está nele se a pasta já existia naquela hora. **Abra um terminal novo.** Se um terminal novo ainda
disser isso, `ls ~/.local/bin` deve listar `node`, `npm` e `npx`; se não listar nada, a linha `ln -s` não
rodou. No Mac a pasta nem está no `PATH` até que `export PATH="$HOME/.local/bin:$PATH"` seja acrescentado
ao `~/.zprofile`.

## O processador errado

Um arquivo para o processador errado desempacota sem reclamar e se recusa a rodar. Esta é a versão
`arm64` desempacotada num computador `x86_64`:

```
ana@dev:~$ mkdir ~/wrong && cd ~/wrong
ana@dev:~/wrong$ curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-arm64.tar.xz
ana@dev:~/wrong$ tar -xJf node-v22.22.0-linux-arm64.tar.xz --strip-components=1
ana@dev:~/wrong$ ./bin/node --version
bash: line 9: ./bin/node: cannot execute binary file: Exec format error
```

**`Exec format error` quer dizer que o programa é para outro processador.** Apague a pasta, confira
`uname -m` de novo e pegue o outro arquivo. Um Mac com chip da Apple e muitos notebooks Windows recentes
com Snapdragon são `arm64`; a maioria dos outros computadores é `x86_64`.

## Dois Nodes, e o Vite recusando o velho

O Ubuntu tem um Node próprio no seu repositório de pacotes, e instalá-lo, ou instalar um programa que
dependa dele, põe um segundo `node` em `/usr/bin`. Esta máquina tinha o pacote `nodejs` do Ubuntu
instalado ao lado do Node do curso, e um projeto da próxima seção para testar:

```
ana@dev:~/planner$ which -a node
/home/ana/.local/bin/node
/usr/bin/node
/bin/node
ana@dev:~/planner$ node --version
v22.22.0
ana@dev:~/planner$ /usr/bin/node --version
v18.19.1
ana@dev:~/planner$ /usr/bin/node node_modules/.bin/vite
file:///home/ana/planner/node_modules/rolldown/dist/shared/create-bundler-option-DzNR1xQS.mjs:8
import { formatWithOptions, styleText } from "node:util";
                            ^^^^^^^^^
SyntaxError: The requested module 'node:util' does not provide an export named 'styleText'
    at ModuleJob._instantiate (node:internal/modules/esm/module_job:123:21)
    at async ModuleJob.run (node:internal/modules/esm/module_job:191:5)
    at async ModuleLoader.import (node:internal/modules/esm/loader:336:24)

Node.js v18.19.1
```

`which -a` lista todo `node` do `PATH` na ordem em que o shell os tenta, e **o primeiro ganha**. Aqui
ainda é o seu, porque o `~/.profile` do Ubuntu põe `~/.local/bin` na frente. O de `/usr/bin` é o Node
18, e **o Vite 8 não sobe com ele**. Ele não diz isso com essas palavras: falha em `styleText`, uma
função que o Node 18 não tem, e a mensagem não cita o Vite nem uma versão. É por isso que `node
--version` é a primeira coisa a conferir quando uma ferramenta falha com um erro que não faz sentido. Um
script que chama `/usr/bin/node` pelo caminho completo, ou um terminal que não lê o `~/.profile`, pega
aquele. Se `node --version` imprimir qualquer coisa que não seja 22, `which -a node` diz com qual você
está falando, e `sudo apt remove nodejs` remove o do Ubuntu.

## A porta está ocupada

`npm run dev` serve o app na porta 5173. Se outra coisa já ocupa essa porta, na maior parte das vezes uma
segunda cópia do dev server esquecida em outro terminal, o Vite não falha. Ele pega a próxima porta
livre e avisa:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.0 dev
> vite


  VITE v8.3.5  ready in 269 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

**Leia o endereço que o Vite imprime, e não o que você espera.** Uma página que não atualiza enquanto
você edita é quase sempre o servidor velho, ainda respondendo na 5173 num terminal esquecido. Ache esse
terminal e pare o servidor com Ctrl-C.

## `npm install -g` diz `EACCES`

Nada neste curso instala algo globalmente, então você não deve ver isto. Você vai ver o conselho de
resolver com `sudo npm install -g`, e ele está errado: roda os scripts de instalação de um pacote como
root, e a aula 21 de javascript mostrou que esses scripts são código que outra pessoa escreveu. Com o
Node na sua pasta pessoal, como aqui, `-g` grava em `~/.local/node` e não precisa de `sudo` nenhum.

## O download falha

`curl` ou `npm` imprimindo `Could not resolve host` quer dizer que o computador está sem DNS; numa
máquina virtual, uma VPN no hospedeiro é uma causa comum. Uma mensagem sobre certificado quer dizer que
algo entre você e a internet está inspecionando a conexão, como fazem algumas redes de empresa e de
escola. **Nunca responda a isso desligando a verificação de certificados.** Peça o certificado a quem
cuida da rede, ou instale a partir de uma rede que não faça isso.

## E quando nada mais funciona

Apague e faça de novo. `rm -rf ~/.local/node ~/.local/bin/node ~/.local/bin/npm ~/.local/bin/npx` remove
este Node por completo, e a seção anterior a esta o põe de volta em mais ou menos um minuto. Para um
projeto, `rm -rf node_modules` seguido de `npm install` refaz tudo a partir do lockfile. Parece desistir,
e é o que gente que faz isso por profissão faz com uma máquina cujo estado ninguém mais consegue
explicar.
