---
title: O seu computador, preparado para este curso
version: 1
---

**Tudo neste curso roda no seu próprio computador, e esta seção prepara o que as primeiras aulas
precisam.** As ferramentas chegam uma de cada vez, cada uma na aula anterior à primeira que a usa: o
Capacitor na aula 2, o Android Studio na aula 3, o Expo na aula 7, o Electron na aula 11 e o Rust com o
Tauri na aula 12. Hoje você precisa de três coisas que muito provavelmente já tem: **Node.js 22, git e
um navegador**.

## Três jeitos de ter um

| caminho | o que você ganha | quanto custa ao seu computador | as transcrições |
|---|---|---|---|
| **instalado** (recomendado) | as ferramentas no computador que você usa, com a tela dele | o maior disco dos três, somado aula a aula | iguais como impressas no Linux; parecidas no Windows e no macOS |
| uma máquina virtual | Ubuntu Desktop 24.04, separado do seu sistema | a memória e o disco que você der a ela; 4 GB e 40 GB são um bom começo | iguais como impressas, menos o emulador Android |
| online | uma máquina Linux numa aba do navegador | nada no seu computador; horas de uma cota mensal | parecidas, e sem janela nem emulador |

**Instale as ferramentas no computador que você usa.** Este curso põe apps em janelas e em celulares, e
as duas coisas são mais fáceis onde a tela e a porta USB já estão. Os comandos estão escritos para
Linux, e funcionam como impressos lá. No **Windows**, os comandos de terminal rodam no WSL, o Linux que
vem com o Windows: `wsl --install -d Ubuntu-24.04` num PowerShell aberto como administrador, e depois
reiniciar. O Android Studio e o emulador dele se instalam no próprio Windows, pelo instalador do
Google, e a aula 3 diz como os dois se encontram. Num **Mac**, todo comando roda no app Terminal como
impresso, e um Mac é o único computador que faz as metades iOS das aulas 3 e 14. Os caminhos de
Windows e Mac não foram rodados para este curso, então um caminho ou uma versão numa transcrição pode
ser diferente do seu.

O disco vai se somando, e vale saber para onde ele vai. O que este curso mediu na própria máquina: o
Node.js ocupou 205 MB, a cópia do Chromium do Electron 274 MB dentro de cada projeto que o usa, e o
Rust com o compilador 816 MB. **O Android Studio com o SDK e um emulador é o maior de todos**, e o
Google lista a memória e o disco que ele exige na página de download; um emulador também quer um
processador com a virtualização ligada.

**Uma máquina virtual** mantém tudo isso longe do seu sistema: VirtualBox no Windows ou no Linux, UTM
num Mac com chip Apple, e o **Ubuntu Desktop** 24.04 como convidado, porque as aulas 11 e 12 abrem
janelas. O ponto fraco dela é o emulador Android, que é ele próprio uma máquina virtual e roda devagar
ou nem roda dentro de outra. Um celular Android de verdade, com cabo e as opções de desenvolvedor
ligadas, substitui o emulador; a aula 3 mostra como.

**Online**, o GitHub Codespaces dá uma máquina Linux numa aba do navegador. Ele basta para as aulas
que constroem e inspecionam: os projetos do Capacitor, o build web do Expo, os pacotes da aula 13. Ele
não tem janela onde abrir um app nem emulador, e o GitHub dá às contas pessoais uma cota mensal e
cobra o que passar dela, em termos que ele define e pode mudar. Ele não foi rodado para este curso.

## As três coisas

**Node.js 22.** O curso `javascript` o instala na aula 1, e este curso usa exatamente aquela
instalação: a versão 22.22.0, do nodejs.org, em `~/.local/node`. Confira, e o git junto:

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ npm --version
10.9.4
ana@dev:~$ git --version
git version 2.43.0
```

Se `node --version` não imprimir nada, ou imprimir uma versão abaixo de `v22`, volte à aula 1 de
`javascript`, seção "O seu computador, pronto para este curso", e faça lá uma vez. **Não instale um
segundo Node** pelos pacotes do seu sistema ou por outro site: duas cópias num computador fazem a
versão de uma transcrição depender de qual delas o terminal encontra primeiro.

**Git**, do curso `git`, com o seu nome e o seu endereço configurados. Todo projeto aqui é um
repositório, porque as ferramentas deste curso acrescentam pastas e arquivos ao seu app, e
`git status` é como você vê o que elas acrescentaram.

**Um navegador.** Qualquer um atual mostra o planner enquanto você trabalha. As transcrições usam uma
cópia do Chromium controlada por um programa, e a seção depois da próxima a prepara.
