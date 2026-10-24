---
title: O seu computador, preparado para este curso
version: 1
---

**Tudo neste curso roda no seu próprio computador, e se você fez `javascript` ele já está pronto.**
Aquele curso instalou o Node.js 22 na primeira aula. Este usa o mesmo Node, na mesma versão, instalado
do mesmo jeito, para que ninguém instale duas vezes nem acabe com dois. Cada ferramenta que o curso
acrescenta depois (o Vite aqui, o Vitest na aula 3, o Storybook na aula 6, o Playwright e o resto) entra
na pasta do projeto, numa versão escrita no `package.json`, na aula que precisa dela primeiro.

## Três jeitos de ter isso

| caminho | o que você ganha | o que custa ao seu computador | as transcrições |
|---|---|---|---|
| **instalado** (recomendado) | o Node.js numa pasta dentro da sua pasta pessoal | cerca de 200 MB de disco, mais o `node_modules` de cada projeto | batem como impressas no Linux |
| uma máquina virtual | Ubuntu 24.04 separado do seu sistema | alguns gigabytes de disco, e 4 GB de memória enquanto roda | batem como impressas |
| online | uma máquina Linux numa aba do navegador | nada no seu computador; horas de uma cota mensal | parecidas, não idênticas |

**Instale no computador que você usa.** O Node vai para `~/.local/node` e não mexe em mais nada, e todo
servidor deste curso escuta num endereço que só o seu computador alcança. No **Linux**, os comandos
abaixo funcionam como estão. No **Windows**, instale o WSL primeiro: `wsl --install -d Ubuntu-24.04` num
PowerShell aberto como administrador, reinicie, abra o Ubuntu pelo menu Iniciar e digite tudo lá dentro.
No **Mac**, o instalador do Node.js 22 do nodejs.org dá o mesmo `node`, mas esse caminho não foi
executado para este curso, e um caminho de pasta numa transcrição pode ser diferente.

**Uma máquina virtual** é o VirtualBox no Windows ou no Linux, ou o UTM num Mac com chip da Apple, com o
Ubuntu 24.04 LTS como convidado. Pegue a edição desktop, e não a de servidor: da aula 6 em diante um
navegador abre as páginas que você constrói, e a edição de servidor não tem nenhum. A memória é o motivo
de 4 GB, e não 2: um navegador e um build rodando juntos é a coisa mais pesada que este curso faz.
**Online**, o GitHub Codespaces e serviços parecidos dão um terminal e um editor numa aba do navegador,
com uma cota mensal cujos termos a empresa define e pode mudar. Isso não foi executado para este curso, e
uma página que você serve lá é alcançada por um endereço que o serviço encaminha, não por `127.0.0.1`.

## Node.js, em resumo

Esta é a seção "Node.js" da aula 1 de javascript, sem a explicação; leia lá se algum passo for novo para
você. `uname -m` diz qual arquivo pegar: `x86_64` fica com o que termina em `linux-x64`, e `aarch64` com
o que termina em `linux-arm64`.

```
ana@dev:~$ uname -m
x86_64
ana@dev:~$ curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.xz
ana@dev:~$ mkdir -p ~/.local/node ~/.local/bin
ana@dev:~$ tar -xJf node-v22.22.0-linux-x64.tar.xz -C ~/.local/node --strip-components=1
ana@dev:~$ ln -s ~/.local/node/bin/node ~/.local/node/bin/npm ~/.local/node/bin/npx ~/.local/bin/
ana@dev:~$ node --version
bash: line 13: node: command not found
```

A última linha falha, e isso é esperado. `~/.local/bin` entra no seu `PATH`, a lista de pastas onde o
shell procura um comando, só num terminal aberto depois que a pasta existe. Feche este e abra outro.

## Conferindo que cada ferramenta responde

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ npm --version
10.9.4
ana@dev:~$ git --version
git version 2.43.0
ana@dev:~$ npm config set update-notifier false
```

**O `node` precisa dizer `v22.22.0`**, ou um 22 mais novo, e o `npm` veio na mesma pasta. O **Git** é a
outra ferramenta que o curso pressupõe, do curso de git; o Ubuntu já traz, e se ele disser
`command not found`, `sudo apt install git` resolve. `npm config set update-notifier false` faz o npm
parar de oferecer um npm mais novo depois de cada instalação: o npm que veio com o Node 22 é o que este
curso usa, e a oferta seria ruído em toda transcrição.

Para ter certeza de que o `node` que responde é o que você acabou de instalar, pergunte onde ele está:

```
ana@dev:~$ which node npm
/home/ana/.local/bin/node
/home/ana/.local/bin/npm
ana@dev:~$ ls ~/.local/node
CHANGELOG.md
LICENSE
README.md
bin
include
lib
share
```

Os dois moram na sua pasta pessoal. Um `node` que responde de `/usr/bin` é um segundo Node, e a próxima
seção diz o que fazer com ele.

## Um navegador

As páginas que você constrói são abertas num navegador em `http://127.0.0.1:5173` ou numa porta parecida,
e qualquer navegador atual serve para lê-las. Duas aulas vão além de ler. A aula 6 compara capturas de
tela e a aula 8 testa um componente, e as duas controlam o **Chromium** pelo Playwright, que baixa a
própria cópia quando aquela aula pede. Até lá, o navegador que você já usa basta.
