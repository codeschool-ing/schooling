---
title: Kernel, shell, terminal — três coisas, uma palavra
version: 1
---

As pessoas dizem "o terminal" para as três coisas, e na maior parte do tempo ninguém se machuca.
Começa a custar caro na primeira vez em que algo quebra, porque **as três falham de formas
diferentes e a mensagem de erro diz qual delas foi** — se você souber que são três.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 336\" role=\"img\" aria-label=\"Quatro camadas empilhadas: você no topo, depois o emulador de terminal, depois o shell, depois o kernel, depois o hardware. Setas descem pela pilha. Ao lado de cada camada está a falha que ela produz: tela embaralhada do terminal, command not found do shell, permission denied do kernel.\"><defs><marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"ahd\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"190\" y=\"14\" width=\"300\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"340.0\" y=\"31.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Você</text><rect x=\"190\" y=\"68\" width=\"300\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"340.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Emulador de terminal</text><text x=\"340.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">desenha caracteres, envia teclas</text><text x=\"506\" y=\"84\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">tela embaralhada</text><text x=\"506\" y=\"98\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o desenho se perdeu,</text><text x=\"506\" y=\"110\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não o comando</text><rect x=\"190\" y=\"140\" width=\"300\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"340.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Shell — bash</text><text x=\"340.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">lê a linha, acha o programa</text><text x=\"506\" y=\"156\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">bash: fooo: command not found</text><text x=\"506\" y=\"170\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ele procurou, e não existe</text><text x=\"506\" y=\"182\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">programa com esse nome</text><rect x=\"190\" y=\"212\" width=\"300\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"340.0\" y=\"229.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Kernel — Linux</text><text x=\"340.0\" y=\"247.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">processador, memória, disco, rede</text><text x=\"506\" y=\"228\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Permission denied</text><text x=\"506\" y=\"242\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o shell pediu, e</text><text x=\"506\" y=\"254\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o kernel recusou</text><rect x=\"190\" y=\"284\" width=\"300\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"340.0\" y=\"303.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Hardware</text><path d=\"M340 48 L340 66\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path><path d=\"M340 118 L340 138\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path><path d=\"M340 190 L340 210\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path><path d=\"M340 262 L340 282\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path><text x=\"172\" y=\"43\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">você digita</text><text x=\"172\" y=\"165\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">a única camada que</text><text x=\"172\" y=\"178\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">este curso ensina</text><text x=\"172\" y=\"237\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">a única que não é</text><text x=\"172\" y=\"250\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">só um programa</text><text x=\"340\" y=\"326\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">leia a primeira palavra: ela nomeia a camada</text></svg>", "caption": "Três das quatro são programas comuns e uma não é. Quando algo te recusa, a mensagem diz qual camada disse não."}
```

## O kernel

O kernel é o programa que é dono da máquina. Ele é carregado quando o computador liga e só para
quando o computador para.

Ele tem o hardware: o tempo do processador, a memória, os discos, a placa de rede. Ele decide qual
programa roda em seguida e por quanto tempo. Ele sabe quais arquivos existem e quem pode abri-los.
Nada mais toca o hardware diretamente — um programa que quer ler um arquivo **pede ao kernel**, e o
kernel decide.

Essa última frase é de onde vêm as permissões, e vale guardá-la. Quando a aula 4 disser que um
arquivo é legível pelo dono e por mais ninguém, quem está garantindo isso é o kernel, no momento do
pedido. Não é uma convenção que os programas educadamente respeitam.

**"Linux" é o kernel, e nada além disso.** Falando com rigor, é só isso que o projeto do Linus
Torvalds é: o programa do meio. Tudo o que você vai digitar neste curso — `ls`, `grep`, o próprio
`bash` — veio de outro lugar, quase tudo do projeto GNU. É disso que trata a discussão
"GNU/Linux" que você vai ver por aí, e agora você sabe do que se trata.

Você nunca fala com o kernel diretamente. Você fala com algo que fala.

## O shell

O shell é um programa que lê uma linha que você digitou, descobre o que você quis dizer, e executa.

É esse o trabalho inteiro, e o mais útil de entender sobre ele é o quanto ele é comum: **o shell é
só um programa**, como o `ls` é um programa. Ele tem nome, mora num arquivo, pode ser iniciado e
encerrado, e você pode trocá-lo por outro. Ele não faz parte do Linux. Ele não é privilegiado. É um
programa cujo trabalho, por acaso, é iniciar outros programas.

Um laço, em linhas gerais:

1. imprime um prompt;
2. espera você digitar uma linha e apertar enter;
3. expande o que você escreveu — `*` vira uma lista de arquivos, `$HOME` vira o seu diretório
   pessoal;
4. procura o programa que você nomeou;
5. pede ao kernel para executá-lo, e espera terminar;
6. imprime o prompt de novo.

O passo 3 é o que surpreende as pessoas mais adiante, e a seção 10 da aula 3 volta nele: **a
expansão é do shell, não do comando.** Quando você digita `rm *.txt`, o `rm` nunca vê o `*` — ele
recebe uma lista de nomes de arquivo que o shell montou antes.

**Em qual shell eu estou?** Existem vários — o `bash` é o padrão comum no Linux, o `zsh` no macOS,
o `dash` como o pequeno e estrito, o `fish` para quem quer um conjunto de trocas mais amigável.
Duas formas de perguntar, e elas respondem duas perguntas diferentes:

```
ana@vm:~$ echo $0
bash
ana@vm:~$ echo $SHELL
/bin/bash
```

`$0` é **o shell rodando agora**. `$SHELL` é o shell **que a sua conta está configurada para
iniciar no login**. Normalmente são o mesmo, e a diferença importa exatamente quando ela te morde:
se você digitar `zsh` e cair num zsh, o `$0` diz `zsh` e o `$SHELL` continua dizendo `/bin/bash`,
porque a sua conta não mudou. Confie no `$0` para saber "no que eu estou digitando".

Este curso é um curso de bash. Onde algo for específico do bash em vez de POSIX, o texto avisa.

## O terminal

O terminal é a janela. Ele desenha os caracteres, manda as suas teclas adiante e cuida do fato de
que o texto chega em cores e move o cursor de um lado para o outro.

O nome é peça de museu, e saber disso faz o comportamento fazer sentido. Um terminal já foi um
objeto físico: um teclado e uma tela, numa mesa, ligados por fio a um computador em outra sala. Um
*emulador de terminal* é um programa fingindo ser um daqueles, e o fingimento vai fundo o
suficiente para ele ainda ter um arquivo de dispositivo:

```
ana@vm:~$ tty
/dev/pts/0
```

`pts` é "pseudo-terminal, slave" — o substituto em software do cabo que ia até a máquina no porão.
O seu shell acredita que está falando com hardware. Ele está falando com uma janela.

O que você está usando de fato é um destes: GNOME Terminal, Konsole, Windows Terminal, iTerm2,
Alacritty, Kitty, o retângulo preto que abre quando você roda `wsl`. **Eles são intercambiáveis e
nenhum deles é o Linux.** Escolher um é como escolher um editor de texto para escrever e-mail — uma
questão de preferência que não muda nada do que você pode fazer.

## Por que a divisão em três se paga

Porque a falha te diz onde olhar, e isso é a maior parte de depurar:

| o que você vê | qual camada | o que significa |
|---|---|---|
| `bash: fooo: command not found` | **o shell** | ele procurou um programa chamado `fooo` e não achou. A mensagem até se identifica: `bash:` |
| `Permission denied` | **o kernel** | o shell achou e pediu; o kernel recusou |
| `Killed` | **o kernel** | o kernel parou o programa, normalmente porque a memória acabou (aula 11) |
| tela embaralhada, texto no lugar errado | **o terminal** | o desenho se perdeu, não o comando — `reset` geralmente resolve |
| nada acontece, nenhum prompt novo | **o programa** | ele está rodando e não terminou. `Ctrl+C` é como você diz pare, e a seção 08 explica o que essa tecla realmente envia |

Leia o prefixo de um erro. `bash:` quer dizer que é o bash falando. `ls:` quer dizer que é o `ls`.
`sudo:` quer dizer que é o sudo. O programa que imprimiu a mensagem é o programa que tem um
problema, e metade das perguntas que as pessoas fazem é respondida pela primeira palavra da linha
que elas colaram.

## A pilha em uma frase

**Você digita num terminal, que alimenta um shell, que pede ao kernel, que é dono da máquina.**

Quatro coisas, três delas programas comuns e uma que não é. O resto deste curso passa o tempo na
segunda camada — o shell é a ferramenta que você está aprendendo — e o motivo de valer a pena
nomear as quatro é que, quando você travar, saber qual delas está te recusando é quase a resposta.
