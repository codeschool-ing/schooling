---
title: O seu computador, preparado para este curso
version: 1
---

**Tudo neste curso roda no seu próprio computador, e se você fez o curso `javascript` quase tudo
já está lá.** Aquele curso instalou o Node.js 22 na primeira aula, e este usa o mesmo Node, na
mesma versão, instalado do mesmo jeito, para que ninguém instale duas vezes nem acabe com dois. O
que este curso acrescenta fica em cada projeto: Vite, TypeScript e Playwright dentro do planner
que você constrói na próxima seção, e depois algumas ferramentas a mais, cada uma na aula que
precisa dela primeiro.

## Três jeitos de ter o ambiente

| caminho | o que você ganha | quanto custa ao seu computador | as transcrições |
|---|---|---|---|
| **instalado** (recomendado) | o Node.js numa pasta da sua home, e o Chromium na do Playwright | cerca de 205 MB para o Node, 650 MB para o navegador, 100 a 500 MB por projeto | iguais às impressas, no Linux |
| uma máquina virtual | Ubuntu Server 24.04 separado do seu sistema | o mesmo, mais alguns gigabytes para o sistema, e 4 GB de memória enquanto ela roda | iguais às impressas |
| online | uma máquina Linux numa aba do navegador | nada no seu computador; horas de uma cota mensal | parecidas, não exatas |

**Instale no computador que você usa.** Tudo neste curso mede quão rápido uma página carrega e
responde, e uma medida só vale alguma coisa numa máquina que você conhece. Uma máquina virtual
divide o processador com o seu próprio sistema, e uma máquina online divide um com desconhecidos;
as duas funcionam, e as duas deixam os tempos das suas transcrições mais ruidosos que os impressos
aqui. No **Linux** os comandos abaixo funcionam como estão. No **Windows**, instale o WSL antes —
`wsl --install -d Ubuntu-24.04` num PowerShell aberto como administrador, reinicie, abra o Ubuntu
pelo menu Iniciar — e digite tudo lá dentro. No **Mac**, o instalador do Node.js 22 do nodejs.org
dá o mesmo `node`; esse caminho não foi executado para este curso, então um caminho ou um tempo
numa transcrição pode ser diferente do seu.

**Uma máquina virtual** é o VirtualBox no Windows ou no Linux, ou o UTM num Mac com chip da Apple,
com o Ubuntu Server 24.04 LTS como convidado e os passos do Linux lá dentro. Um servidor não tem
área de trabalho, o que aqui não custa nada: todo navegador deste curso é controlado por um
programa e não tem janela. **Online**, o GitHub Codespaces e serviços parecidos dão um terminal
Linux numa aba do navegador, com uma cota mensal cujos termos a empresa define e pode mudar. Esse
caminho não foi executado para este curso. Qualquer que seja a escolha, `cat /etc/os-release` diz
em que sistema você está.

## O Node.js, em resumo

Esta é a seção "O seu computador, pronto para este curso" da aula 1 de javascript, sem a explicação;
leia lá se algum passo for novo para você. `uname -m` diz qual arquivo baixar: `x86_64` fica com o
que termina em `linux-x64`, e `aarch64` com o que termina em `linux-arm64`.

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

A última linha falha, e é o esperado. `~/.local/bin` entra no seu `PATH`, a lista de pastas onde o
shell procura um comando, só num terminal aberto depois que a pasta existe. Feche este e abra um
novo, e confira os dois programas e a única configuração de que este curso precisa:

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ npm --version
10.9.4
ana@dev:~$ npm config set update-notifier false
```

**O `node` tem de dizer `v22.22.0`**, ou um 22 mais novo. O `npm` veio na mesma pasta.
`npm config set update-notifier false` impede o npm de oferecer um npm mais novo embaixo de cada
instalação; o npm que veio com o Node 22 é o que este curso usa, e a oferta seria ruído em toda
transcrição.

## O que você vai acrescentar, e onde

Nada mais é instalado para o computador inteiro. Cada ferramenta entra no projeto que a usa, com a
versão escrita exatamente no `package.json` daquele projeto, para que um projeto aberto daqui a um
ano instale aquilo com que foi construído:

| ferramenta | versão | instalada em |
|---|---|---|
| Vite, a ferramenta de build e o servidor de desenvolvimento | 8.3.5 | a próxima seção |
| TypeScript | 6.0.3 | a próxima seção |
| Playwright, e o Chromium que ele controla | 1.63.0, Chromium 153 | a próxima seção |
| os quatro meta-frameworks | cada um a sua | aula 2 |
| `web-vitals` | 6.2.3 | aula 5 |
| Lighthouse | 13.5.0 | aula 6 |
| `sharp`, para fazer imagens | 0.35.5 | aula 7 |

Se você tem a pasta `~/js-tools` do curso `javascript`, ela guarda um Playwright mais antigo, e
pode ficar. Dois projetos com duas versões de uma biblioteca é normal; dois Nodes num mesmo `PATH`
não é, e a próxima seção diz como perceber.
