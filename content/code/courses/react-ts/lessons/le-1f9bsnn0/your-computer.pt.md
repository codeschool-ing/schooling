---
title: O seu computador, preparado para este curso
version: 1
---

**Tudo neste curso roda no seu próprio computador, e se você fez o `javascript` quase tudo já está
lá.** Aquele curso instalou o Node.js 22.22.0 na primeira aula, e este usa o mesmo Node, na mesma
versão, instalado do mesmo jeito, para que ninguém instale duas vezes nem acabe com dois. O que este
curso acrescenta vai dentro dos seus projetos, e as duas próximas seções instalam.

## Três jeitos de ter o ambiente

| caminho | o que você ganha | quanto custa ao seu computador | as transcrições |
|---|---|---|---|
| **instalado** (recomendado) | o Node.js na sua pasta pessoal, o app em `~/planner`, o seu navegador ao lado | uns 200 MB para o Node, 120 MB para o projeto novo, 280 MB para o `look` e o navegador dele | iguais às impressas, no Linux |
| uma máquina virtual | Ubuntu Server 24.04, separado do seu sistema | alguns gigabytes de disco, e 2 GB de memória enquanto roda | iguais às impressas |
| online | uma máquina Linux numa aba do navegador | nada no seu computador; horas de uma cota mensal | parecidas, não idênticas |

**Instale no computador que você usa.** O Node vai para `~/.local/node` e não toca em mais nada, os
pacotes do app vão para a pasta do próprio app, e o servidor de desenvolvimento que você inicia na
próxima seção responde só ao seu computador. No **Linux** os comandos funcionam como impressos. No
**Windows**, instale o WSL primeiro, com `wsl --install -d Ubuntu-24.04` num PowerShell aberto como
administrador, reinicie, abra o Ubuntu pelo menu Iniciar e digite tudo lá dentro; o navegador do
Windows abre o app que o WSL serve no mesmo endereço. No **Mac**, o instalador do Node.js 22 do
nodejs.org dá o mesmo `node`; esse caminho não foi rodado para este curso, então um caminho numa
transcrição pode ser diferente do seu.

**Uma máquina virtual** é o VirtualBox no Windows ou no Linux, ou o UTM num Mac com chip Apple, com
o Ubuntu Server 24.04 LTS como sistema convidado e os passos de Linux dentro dele. Foi assim que este
curso foi gravado. Um servidor não tem área de trabalho nem navegador, então você lê o app pelo
navegador do seu próprio computador, e isso pede duas coisas que o caminho instalado não pede: o
servidor de desenvolvimento iniciado com `--host`, para que responda no endereço de rede da máquina e
não só dentro dela, e uma porta encaminhada do seu computador para a máquina. A aula 20 mostra o
`--host` rodando.

**Online**, o GitHub Codespaces e serviços parecidos dão um terminal Linux numa aba do navegador, e
encaminham a porta do servidor de desenvolvimento para um endereço próprio. A cota é mensal e as
condições são da empresa, que pode mudá-las. Esse caminho não foi rodado para este curso. Seja qual
for o caminho, `cat /etc/os-release` diz em que sistema você está.

## O Node.js

Se a aula 1 do `javascript` preparou este computador, as três respostas abaixo já são suas e você
pode pular para o último parágrafo desta seção. Se não, a seção "O seu computador, preparado para
este curso" daquela aula instala o Node em sete comandos e explica cada um; pegue `x86_64` ou
`aarch64` do `uname -m`, e o arquivo cujo nome termina em `linux-x64` ou `linux-arm64` de acordo.

```sh
curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.xz
mkdir -p ~/.local/node ~/.local/bin
tar -xJf node-v22.22.0-linux-x64.tar.xz -C ~/.local/node --strip-components=1
ln -s ~/.local/node/bin/node ~/.local/node/bin/npm ~/.local/node/bin/npx ~/.local/bin/
```

Depois, **num terminal novo**, porque um terminal lê a lista de pastas onde procura comandos quando
abre:

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ npm --version
10.9.4
ana@dev:~$ command -v node
/home/ana/.local/bin/node
ana@dev:~$ npm config set update-notifier false
```

**O `node` precisa dizer `v22.22.0`**, ou uma 22 mais nova, e o `npm` veio na mesma pasta. O
`command -v` diz qual `node` respondeu, e precisa ser o da sua pasta pessoal: um `node` que responde
de `/usr/bin` é um segundo Node, e a seção sobre falhas trata disso. A última linha impede o npm de
oferecer um npm mais novo embaixo de cada instalação. O que veio com o Node 22 é o que este curso
usa, e a oferta seria ruído em todas as transcrições.

## Um navegador

Você já tem um, e é com ele que vai olhar o app na maior parte do tempo: o servidor de
desenvolvimento imprime um endereço, e você o abre. Qualquer Chrome, Edge, Firefox ou Safari atual
funciona. As transcrições do curso usam também um segundo navegador, sem janela, que um programa
consegue dirigir, e a seção depois da próxima o instala junto de uma pequena ferramenta que imprime o
que uma página mostra.
