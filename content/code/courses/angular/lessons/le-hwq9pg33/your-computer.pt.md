---
title: O seu computador, conferido para este curso
version: 1
---

**Tudo neste curso roda no seu próprio computador.** Não há máquina para entrar nem playground no
navegador: você instala as ferramentas, você cria o projeto, e toda transcrição das aulas é o que
esse computador imprimiu. Esta seção confere se você tem aquilo de que o curso parte e diz o que ele
acrescenta.

## O que você já tem

`javascript` é exigido antes deste curso, e a aula 1 dele montou três coisas que este curso usa como
estão:

- **o Node.js 22.22.0**, descompactado do nodejs.org em `~/.local/node`, com `node`, `npm` e `npx`
  ligados em `~/.local/bin`;
- **o npm 10.9.4**, que veio na mesma pasta;
- **`~/js-tools`**, uma pasta com o Playwright 1.56.0, o Chromium que ele controla, e o `page.mjs`.

Abra um terminal e pergunte:

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ npm --version
10.9.4
ana@dev:~$ ls ~/js-tools
node_modules
package-lock.json
package.json
page.mjs
serve.mjs
ana@dev:~$ du -sh ~/.local/node ~/js-tools
205M	/home/ana/.local/node
13M	/home/ana/js-tools
```

Se alguma dessas três respostas vier diferente, ou se `~/js-tools` não existir, volte à aula 1 de
`javascript`, seção "O seu computador, pronto para este curso", e faça como está escrito. **Não
instale um segundo Node**: a trilha `frontend` inteira roda neste, e duas cópias do Node na mesma
máquina são o jeito mais comum de o `npm` e o programa que você queria rodar discordarem sobre qual
deles está respondendo.

O `du` mediu quanto custam as duas pastas. O navegador que o Playwright baixou fica em
`~/.cache/ms-playwright`, que a aula 1 de `javascript` calculou em cerca de 320 MB.

## O que este curso acrescenta

| | onde | cerca de |
|---|---|---|
| TypeScript, para as duas seções desta aula | `~/ts` | 23 MB |
| o projeto Angular que você constrói ao longo de 25 aulas | `~/planner` | 330 MB, quase tudo em `node_modules` |
| mais um programa ao lado do `page.mjs`, chamado `look` | `~/js-tools` | alguns kilobytes |

A aula 2 cria o projeto e o mede, e mostra o `look` inteiro. Nada é instalado globalmente: a CLI do
Angular mora dentro do projeto, na versão exata que o projeto declara, para que um segundo projeto
no ano que vem possa usar outra sem as duas se encontrarem.

## Três jeitos de ter o computador

Os três caminhos são os que a aula 1 de `javascript` descreve, e o conselho é o mesmo.

| caminho | o que custa ao seu computador | as transcrições |
|---|---|---|
| **instalado** (recomendado) | o disco das tabelas acima; o servidor de desenvolvimento da aula 2 ocupa cerca de 370 MB de memória enquanto roda | iguais às impressas no Linux; parecidas nos outros |
| uma máquina virtual | alguns gigabytes de disco para o Ubuntu Server 24.04, e memória para o convidado; 4 GB deixam espaço para o servidor de desenvolvimento e um navegador | iguais às impressas |
| online | nada no seu computador; horas de uma cota mensal | parecidas, não idênticas |

**Instalado no computador que você usa** é a recomendação, pelo mesmo motivo de antes: o navegador
com que você testa está na mesma máquina que o servidor com que ele conversa, e `localhost` quer dizer
uma coisa só. No Windows isso quer dizer o WSL, como a aula 1 de `javascript` o montou, e todo
comando deste curso é digitado no terminal Ubuntu dele.

**Uma máquina virtual** funciona, com uma coisa a saber: o servidor de desenvolvimento escuta no
`localhost` de dentro do convidado, então um navegador na sua área de trabalho não o alcança até o
servidor ser iniciado com `--host 0.0.0.0` e a máquina virtual encaminhar a porta. A aula 2 mostra a
opção. O `look`, que roda dentro do convidado, não precisa de nenhuma das duas.

**Online**, o GitHub Codespaces dá uma máquina Linux numa aba do navegador e encaminha a porta do
servidor de desenvolvimento para você. Ele não foi usado neste curso, e a cota gratuita é do GitHub
para mudar quando quiser, então trate-o como a alternativa para quando nenhum dos outros for
possível.

## Um editor que conhece Angular

Qualquer editor serve, e as transcrições nunca mostram um. Se você usa o Visual Studio Code, o
projeto que a aula 2 cria recomenda uma extensão, **Angular Language Service**, e o VS Code oferece
instalá-la quando você abre a pasta. Ela lê os seus templates do jeito que o compilador lê, então
um erro de digitação em `{{ minutes }}` aparece sublinhado antes do build. Ela não fez parte da
gravação, que usou só o terminal.
