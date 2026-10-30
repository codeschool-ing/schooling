---
title: O seu computador, preparado para este curso
version: 1
---

**Este curso precisa de três coisas no seu computador: Node.js 22, git e um editor de texto.** O
Node.js roda a lógica do planner de estudos e os programas pequenos que as aulas mostram; o git guarda
o seu trabalho; e qualquer editor que salve texto puro serve, embora um que pinte TypeScript, como o
VS Code, deixe o código mais fácil de ler.

## Três jeitos de ter um

| caminho | o que você ganha | o que custa ao seu computador | as transcrições |
|---|---|---|---|
| **instalado** (recomendado) | Node.js e git no computador que você já usa | cerca de 200 MB de disco para o Node.js | iguais às impressas no Linux; parecidas no Windows e no macOS |
| uma máquina virtual | Ubuntu 24.04 separado do seu sistema | alguns gigabytes de disco, e 2 GB de memória enquanto roda | iguais às impressas |
| online | uma máquina Linux numa aba do navegador | nada no seu computador; horas de uma cota mensal | parecidas, não idênticas |

**Instale no computador que você usa.** O Node.js vai para uma pasta dentro da sua pasta pessoal e
não mexe em mais nada. No **Linux**, os comandos funcionam como estão impressos. No **Windows**,
digite-os no WSL, o Linux que vem com o Windows: `wsl --install -d Ubuntu-24.04` num PowerShell
aberto como administrador, uma reinicialização, e depois o Ubuntu pelo menu Iniciar. Num **Mac**, use
o instalador do Node.js 22 do nodejs.org. Os caminhos de Windows e Mac não foram executados para este
curso, então um caminho ou uma versão numa transcrição pode ser diferente do seu.

**Uma máquina virtual** são os mesmos passos de Linux numa máquina própria: VirtualBox no Windows ou
no Linux, UTM num Mac com chip Apple, e Ubuntu 24.04 LTS como convidado. Ela mantém o curso longe do
seu sistema, e custa a memória que você der a ela enquanto roda.

**Online**, o GitHub Codespaces oferece uma máquina Linux com terminal numa aba do navegador. O
GitHub dá às contas pessoais uma cota mensal e cobra o que passar dela, em termos que ele define e
pode mudar. Esse caminho não foi executado para este curso.

## O Node.js, exatamente como o `javascript` instala

O curso `javascript` instala o Node.js na aula 1, seção "O seu computador, preparado para este curso",
e este curso usa essa instalação sem mudar nada: **versão 22.22.0**, descompactada do arquivo do
nodejs.org em `~/.local/node`, com `node`, `npm` e `npx` ligados em `~/.local/bin`. No Linux ou no WSL
são cinco linhas:

```sh
curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.xz
mkdir -p ~/.local/node ~/.local/bin
tar -xJf node-v22.22.0-linux-x64.tar.xz -C ~/.local/node --strip-components=1
ln -s ~/.local/node/bin/node ~/.local/node/bin/npm ~/.local/node/bin/npx ~/.local/bin/
rm node-v22.22.0-linux-x64.tar.xz
```

O arquivo que termina em `linux-x64` é para um processador Intel ou AMD; num ARM, que o `uname -m`
mostra como `aarch64`, use o que termina em `linux-arm64`. Depois **feche o terminal e abra outro**,
porque o shell lê a lista de pastas onde procurar, o `PATH`, quando começa. No terminal novo, as três
ferramentas respondem:

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ npm --version
10.9.4
ana@dev:~$ git --version
git version 2.43.0
```

**A versão 22.22.0 importa por um motivo em especial.** A partir do Node.js 22.18, o `node` roda um
arquivo TypeScript direto: ele apaga as anotações de tipo e roda o que sobra, sem compilador e sem
etapa de build. Todo programa deste curso é um arquivo `.ts` rodado desse jeito. Um Node.js 22 mais
antigo recusa o mesmo arquivo, e a seção sobre falhas, mais abaixo, mostra o que ele diz. Se você já
tem Node.js de outro lugar, confira a versão antes de seguir; **duas cópias no mesmo computador
significam que a versão que você recebe depende de qual delas o terminal encontra primeiro**.

O git vem dos pacotes do seu sistema, `sudo apt install git` no Ubuntu, e o curso `git` o configurou
com o seu nome e endereço. Qualquer versão dos últimos anos faz o que este curso pede.
