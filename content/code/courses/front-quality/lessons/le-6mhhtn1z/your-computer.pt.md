---
title: Seu computador, preparado para este curso
version: 1
---

**Tudo neste curso roda no seu próprio computador, num projeto pequeno que você constrói nesta aula
e testa em todas as aulas seguintes.** O projeto é um planner de estudos escrito em TypeScript e
servido pelo Vite. Ele precisa do Node.js 22, do npm que vem com ele, do Git, de um terminal e de um
editor de texto. A aula 4 acrescenta um navegador que um programa consegue controlar, e o instala lá.

O curso não usa framework nenhum. Qualquer que seja o dos quatro que você aprendeu, os testes, os
ataques contra os quais você se defende e as pessoas que não conseguem usar um mouse são os mesmos,
e um planner sem framework deixa cada aula mostrar a ideia e mais nada.

## O que você já deveria ter

Na trilha `frontend`, a aula 1 de `javascript` instalou o Node.js 22.22.0 em `~/.local/node`, e o
curso `git` deu seu nome ao Git. Confira os três antes de qualquer outra coisa:

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ npm --version
10.9.4
ana@dev:~$ git --version
git version 2.43.0
```

**Não instale o Node uma segunda vez**, e não deixe um tutorial convencer você a usar um gerenciador
de versões neste curso: duas cópias do Node numa máquina é como um programa acaba rodando na que você
não queria. Qualquer 22 mais novo funciona igual ao 22.22.0. A versão do Git importa menos; qualquer
uma dos últimos anos serve.

## Se você veio direto para este curso

Os três jeitos de ter o ambiente são os que a aula 1 de `javascript` dá, e a recomendação também:

| caminho | o que você ganha | quanto custa ao seu computador |
|---|---|---|
| **instalado** (recomendado) | o Node.js no computador que você já usa | uns 200 MB para o Node, e uns 450 MB a mais para os pacotes e o navegador que este curso acrescenta |
| uma máquina virtual | um Ubuntu Server 24.04 separado do seu sistema | alguns gigabytes de disco, e 2 GB de memória enquanto roda |
| online | uma máquina Linux numa aba do navegador, como o GitHub Codespaces | nada no seu computador; horas de uma cota mensal, em condições que o fornecedor define |

**No Linux**, o Node vem do nodejs.org como uma pasta compactada, e estas são as linhas que aquela
aula grava e explica. O `uname -m` diz qual arquivo pegar: `x86_64` pega o `linux-x64`, `aarch64`
pega o `linux-arm64`.

```sh
curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.xz
mkdir -p ~/.local/node ~/.local/bin
tar -xJf node-v22.22.0-linux-x64.tar.xz -C ~/.local/node --strip-components=1
ln -s ~/.local/node/bin/node ~/.local/node/bin/npm ~/.local/node/bin/npx ~/.local/bin/
```

Depois feche o terminal e abra outro, porque um terminal só lê a lista de pastas em que procura
programas quando abre. **No Windows**, instale antes o WSL com `wsl --install -d Ubuntu-24.04` num
PowerShell aberto como administrador, reinicie, e siga as linhas do Linux dentro do Ubuntu. **No
Mac**, pegue o instalador do Node.js 22 no nodejs.org. Nenhum desses dois caminhos foi executado
para este curso, então um caminho de pasta numa transcrição pode ser diferente do seu.

Uma máquina virtual é o mesmo passo a passo do Linux dentro de uma máquina só dela. Ela tem aqui
uma desvantagem que não tinha em `javascript`: a aula 4 abre o seu app num navegador de verdade, e um
servidor não tem tela para mostrá-lo. Os testes rodam mesmo assim, porque o navegador que eles usam
não precisa de janela.

## Onde as coisas ficam

O seu projeto fica em `~/planner`, a próxima seção o cria, e nada mais neste curso mora fora dele. O
que uma aula instala fica listado no `package.json` do projeto com uma versão exata, e o
`package-lock.json` ao lado registra tudo o que esses pacotes trouxeram junto. Assim o projeto no seu
disco diz do que precisa, e o `npm ci` o reconstrói igual em outra máquina.
