---
title: O seu computador, preparado para este curso
version: 1
---

**Tudo neste curso roda no seu próprio computador, e se você fez o `javascript` quase tudo já está
lá.** Aquele curso instalou o Node.js 22 na primeira aula, e este usa o mesmo Node, na mesma versão,
instalado do mesmo jeito, para que ninguém instale duas vezes nem acabe com dois. Esta seção repete
esses passos em resumo para quem chega sem eles. A próxima seção acrescenta a única ferramenta que
este curso pede além disso: um jeito de abrir uma página num navegador de verdade e ler, no
terminal, o que há nela.

## Três jeitos de ter isso

| caminho | o que você tem | quanto custa ao seu computador | as transcrições |
|---|---|---|---|
| **instalado** (recomendado) | o Node.js numa pasta da sua home, e o Chromium ao lado | uns 200 MB para o Node, 260 MB para o navegador, 85 MB para o projeto | iguais às impressas no Linux |
| uma máquina virtual | o Ubuntu Server 24.04 separado do seu sistema | alguns gigabytes de disco, e 4 GB de memória enquanto roda | iguais às impressas |
| online | uma máquina Linux numa aba do navegador | nada no seu computador; horas de uma cota mensal | parecidas, não idênticas |

**Instale no computador que você usa.** O Node vai para `~/.local/node` e não mexe em mais nada, o
navegador é uma cópia própria e não o que você usa para navegar, e o servidor de desenvolvimento
escuta num endereço que só o seu computador alcança. No **Linux** os comandos abaixo funcionam como
estão. No **Windows**, instale o WSL antes: `wsl --install -d Ubuntu-24.04` num PowerShell aberto
como administrador, reinicie, abra o Ubuntu pelo menu Iniciar e digite tudo dentro dele. No **Mac**,
o instalador do Node.js 22 de nodejs.org dá o mesmo `node`; esse caminho não foi rodado para este
curso, então um caminho de pasta numa transcrição pode ser diferente do seu.

**Uma máquina virtual** é o VirtualBox no Windows ou no Linux, ou o UTM num Mac com chip Apple, com
o Ubuntu Server 24.04 LTS como convidado e os passos do Linux dentro dele. Foi assim que este curso
foi gravado. Um servidor não tem área de trabalho, então lá não há janela de navegador, e o comando
`look` da próxima seção é como você vê uma página. Dê 4 GB de memória em vez de 2: um build do
planner e um navegador rodando ao mesmo tempo precisam de mais que um terminal.

**Online**, o GitHub Codespaces e serviços parecidos dão um terminal Linux numa aba do navegador,
numa cota mensal cujas condições a empresa define e pode mudar. Esse caminho não foi rodado para
este curso, e lá um servidor de desenvolvimento é acessado por um endereço que o serviço fornece, e
não por `localhost`. Seja qual for a escolha, `cat /etc/os-release` diz em que sistema você está.

## O Node.js, em resumo

Esta é a seção "Node.js" da aula 1 do `javascript` sem a explicação; leia lá se algum passo for
novo para você. `uname -m` diz qual arquivo pegar: `x86_64` pega o que termina em `linux-x64`, e
`aarch64` o que termina em `linux-arm64`.

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
shell procura um comando, só num terminal aberto depois que a pasta existe. **Feche este terminal e
abra um novo**:

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ npm --version
10.9.4
ana@dev:~$ npm config set update-notifier false
```

**O `node` tem de dizer `v22.22.0`.** O SvelteKit 3 recusa qualquer coisa mais antiga que o Node
22.17, e a seção "Quando a instalação falha" mostra como essa recusa aparece. O `npm` veio na mesma
pasta. `npm config set update-notifier false` faz o npm parar de oferecer uma cópia mais nova de si
mesmo embaixo de cada instalação: o npm que veio com o Node 22 é o que este curso usa, e a oferta
seria ruído em cada transcrição.
