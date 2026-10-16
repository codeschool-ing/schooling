---
title: Os leitores de tela, e como um testador inicia um
version: 1
---

Um leitor de tela transforma o que está na tela em fala, ou em braile numa linha braile, e deixa o
usuário andar por ela com o teclado ou pelo toque. **Ele não lê os pixels.** Ele pergunta à
interface de acessibilidade do sistema operacional, que pergunta ao navegador, que responde a
partir da árvore de acessibilidade: uma versão da página que guarda, para cada elemento que
importa, um papel, um nome e um estado. Tudo que quem usa leitor de tela fica sabendo sobre a
página de reserva chega por essa árvore. É por isso que a próxima seção lê a árvore, e por isso
uma página pode parecer perfeita e não dizer nada.

## Os leitores que vale conhecer

| leitor | onde | quanto custa | como iniciar |
|---|---|---|---|
| **NVDA** | Windows | gratuito, código aberto, da NV Access | instale a partir de nvaccess.org; `Ctrl+Alt+N` o inicia depois que o instalador cria o atalho |
| **JAWS** | Windows | comercial, da Freedom Scientific, com um modo de demonstração por tempo limitado | pelo menu Iniciar depois de instalar |
| **Narrador** | Windows | embutido | `Win+Ctrl+Enter` |
| **VoiceOver** | macOS, iOS, iPadOS | embutido | `Cmd+F5` num Mac; num iPhone, Ajustes, Acessibilidade, VoiceOver |
| **Orca** | Linux, GNOME | gratuito, em geral instalado com o desktop | `Super+Alt+S` no GNOME |
| **TalkBack** | Android | embutido | Configurações, Acessibilidade, TalkBack; ou segure as duas teclas de volume se o atalho estiver ligado |

**Com quais testar é uma pergunta sobre usuários, não sobre ferramentas.** As pesquisas da WebAIM
com usuários de leitores de tela encontram há anos o NVDA e o JAWS como os mais usados no desktop,
e o VoiceOver no celular. As combinações importam tanto quanto os leitores: o NVDA costuma ser
testado com Firefox ou Chrome, o JAWS com Chrome ou Edge, o VoiceOver com Safari. Uma combinação
que funciona diz pouco sobre outra, porque cada navegador monta a sua árvore e cada leitor a lê do
seu jeito.

## Os poucos comandos de que um testador precisa

Quem usa leitor de tela conhece centenas de comandos. Um testador precisa de uma dúzia, e a mesma
dúzia existe em todo leitor de desktop com teclas diferentes. Os do NVDA estão abaixo; o
modificador, escrito **NVDA**, é o `Insert` por padrão, ou o `Caps Lock` se você escolher o layout
de laptop.

| para fazer isto | NVDA | VoiceOver num Mac |
|---|---|---|
| parar de falar | `Ctrl` | `Ctrl` |
| ler daqui em diante | `NVDA+Down` | `VO+A` (VO é `Ctrl+Option`) |
| item seguinte e anterior | `Down`, `Up` no modo de navegação | `VO+Right`, `VO+Left` |
| próximo título, próximo campo, próximo link | `H`, `F`, `K` | o Rotor, `VO+U`, depois as setas |
| lista de títulos ou de links | `NVDA+F7` | o Rotor, `VO+U` |
| andar entre controles | `Tab`, como sem leitor | `Tab` |
| digitar num campo | `Enter` nele, o que passa para o modo de foco | interagir com `VO+Shift+Down` |
| desligar | `NVDA+Q` | `Cmd+F5` |

O **modo de navegação e o modo de foco** do NVDA são a ideia que derruba testadores. No modo de
navegação, as letras são comandos de navegação: `H` pula para o próximo título. No modo de foco,
em que o NVDA entra sozinho quando você chega a um campo de texto, as letras digitam. Uma página
que rouba teclas com atalhos próprios se comporta diferente em cada um, o que é mais uma coisa a
testar.

## Onde ele roda, neste curso

**Nada disso foi rodado nestas aulas, e nenhuma transcrição delas é fala.** O laboratório em que o
curso foi gravado não tem desktop nem som, então um leitor de tela não roda lá; na sua VM é igual,
porque ela também não tem desktop. Um leitor de tela roda no **seu próprio computador**, como a
aula 1 disse, contra a bilheteria na VM. Suba o servidor para que ele responda a outras máquinas:

```sh
cd ~/boxoffice && BOXOFFICE_HOST=0.0.0.0 python3 app.py
```

e abra o `book.html`, depois o `book4.html`, no endereço da VM no seu próprio navegador, como a
aula 1 explica. Depois inicie o leitor e feche os olhos, ou baixe o brilho da tela até o fim; um
testador que vê a página completa com a visão o que a fala deixa de fora.

O que estas aulas capturam no lugar é a metade que pode ser capturada com honestidade: o que o
navegador **conta** ao leitor de tela. As palavras que um leitor específico fala depois dependem do
leitor, da versão, das configurações e do navegador, e citar uma fala que ninguém gravou seria
inventar uma.
