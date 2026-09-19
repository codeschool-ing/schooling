---
title: Uma família, e o que eles realmente compartilham
version: 1
---

Existe um motivo para um comando que você aprende hoje funcionar num servidor em Frankfurt, num
Mac, dentro de um contêiner e num Raspberry Pi em cima da sua mesa. Não é que eles rodem o mesmo
software. **É que eles combinaram, décadas atrás, como os comandos se chamariam e como se
comportariam.**

Esse acordo tem nome e tem história, e os dois valem dez minutos, porque explicam o que atravessa
de uma máquina para outra e o que não atravessa — que é a diferença entre confiança e superstição
quando você senta num sistema que nunca viu.

## A árvore genealógica

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Uma árvore genealógica. O Unix, de 1969, se ramifica em System V e BSD; o BSD leva ao macOS. O Linux fica à parte, ligado ao Unix por uma linha tracejada que desce pela margem, marcada como imitando a interface sem compartilhar código. O Windows NT fica do outro lado de um divisor, sem ligação com nenhum deles. Uma faixa no pé marca o POSIX como o acordo que os quatro sistemas da esquerda mantêm.\"><defs><marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"ahd\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"200\" y=\"18\" width=\"150\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"275.0\" y=\"31.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Unix</text><text x=\"275.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Bell Labs, 1969</text><path d=\"M275 60 L180 100\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M275 60 L370 100\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"110\" y=\"102\" width=\"140\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">System V</text><rect x=\"300\" y=\"102\" width=\"140\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"370.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">BSD</text><path d=\"M370 140 L370 186\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"300\" y=\"188\" width=\"140\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"370.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">macOS</text><text x=\"370.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Darwin, do BSD</text><rect x=\"30\" y=\"188\" width=\"150\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"105.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Linux, 1991</text><text x=\"105.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">escrito do zero</text><path d=\"M200 39 L20 39 L20 210 L26 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\" marker-end=\"url(#ahd)\"></path><text x=\"30\" y=\"158\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">imita a interface</text><text x=\"30\" y=\"172\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">não compartilha código</text><path d=\"M540 14 L540 286\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"560\" y=\"102\" width=\"145\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"632.5\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Windows NT</text><text x=\"632.5\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">linhagem VMS, 1993</text><text x=\"632\" y=\"176\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">sem ancestral comum</text><text x=\"632\" y=\"192\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">nada se transfere</text><rect x=\"30\" y=\"250\" width=\"490\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".12\" stroke=\"var(--phosphor)\"></rect><text x=\"275\" y=\"269\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">POSIX · o acordo escrito que estes quatro mantêm</text><path d=\"M105 232 L105 248\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M370 232 L370 248\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path></svg>", "caption": "O Linux não é descendente do Unix: é uma reimplementação que ficou com o comportamento e com nenhum do código. O que os quatro da esquerda compartilham é um acordo, não um ancestral — e o Windows não compartilha nem um nem outro.", "same": ["Unix", "System V", "BSD", "macOS", "Linux, 1991", "Windows NT"]}
```

O **Unix** foi escrito no Bell Labs a partir de 1969. Não foi o primeiro sistema operacional, mas
foi aquele cujas *ideias* se espalharam: programas pequenos que fazem uma coisa só, texto como
formato universal entre eles, e um sistema de arquivos como uma árvore única. Tudo o que está
abaixo herda essas três ideias.

Ele se dividiu em duas linhas que discutiram entre si por vinte anos — a linha **System V**, que
virou os Unixes comerciais, e a linha **BSD**, saída de Berkeley. Essa discussão é o motivo de
duas máquinas poderem ser ambas "Unix" e discordarem sobre o que o `ps` imprime.

**O macOS está genuinamente na família.** Seu núcleo, o Darwin, descende do BSD, e a certificação
não é folclore: o macOS é formalmente registrado como UNIX. Quando você abre o Terminal num Mac,
você está nessa árvore, de verdade.

**O Linux não está.** E é aqui que as pessoas se surpreendem: o Linux não compartilha código nenhum
com o Unix. Linus Torvalds escreveu um kernel do zero em 1991, imitando de propósito a *interface*
de um sistema cujo código-fonte ele não podia ter. Em volta dele vieram as ferramentas do projeto
GNU — que também tinham sido escritas do zero, pelo mesmo motivo.

Então o Linux não é um descendente. **É uma reimplementação que ficou com o comportamento e jogou
fora a linhagem** — e é por isso que ele é juridicamente livre do Unix, e se comporta como Unix
mesmo assim.

## A promessa é a interface, e ela está escrita

O que se herda aqui não é código. É uma especificação, e ela se chama **POSIX** — um documento que
diz o que um sistema compatível tem de oferecer: que existe um comando chamado `ls`, que ele lista
um diretório, que `|` manda a saída de um programa para o próximo, que caminhos são separados por
`/`, que um arquivo tem dono e bits de permissão, que um programa pode receber um sinal.

O POSIX é o motivo de isto valer:

```
$ uname -s
Linux
```

…e de o mesmo comando imprimir `Darwin` num Mac, e `FreeBSD` num servidor FreeBSD — e de, nos três
casos, o comando existir, ser escrito igual e significar a mesma coisa. Sistemas diferentes, um
acordo só.

**O que o POSIX garante, e com o que você pode contar em qualquer ponto deste curso:**

| | |
|---|---|
| o formato de um comando | um nome, depois opções, depois argumentos |
| uma árvore só | `/` na raiz, e todo o resto montado em algum lugar dentro dela |
| os comandos essenciais | `ls`, `cd`, `cp`, `mv`, `rm`, `cat`, `grep`, `chmod`, `ps`, `kill` |
| pipes e redirecionamento | `\|`, `>`, `<`, e os três fluxos por trás deles |
| o modelo de permissões | dono, grupo, outros — três bits cada |
| sinais | uma mensagem numerada que você manda para um programa em execução |

## O que ele não garante, e onde você vai se machucar

O POSIX é um piso, não um teto, e todo sistema real constrói acima dele. As partes acima do piso
são onde duas máquinas parecidas param de concordar:

**Flags além das padronizadas.** As ferramentas GNU no Linux aceitam opções longas —
`ls --human-readable`, `grep --recursive`. As ferramentas BSD do macOS muitas vezes não. A versão
mais comum disso é o `sed -i`, que edita um arquivo no lugar: no Linux `sed -i 's/a/b/' f`
funciona, e no macOS a mesma linha falha, porque lá o `-i` quer um argumento com o sufixo do
backup.

**Qual shell o `sh` realmente é.** O POSIX diz que existe um shell chamado `sh`. Não diz qual. No
Ubuntu:

```
$ ls -l /bin/sh
lrwxrwxrwx 1 root root 4 Mar 31  2024 /bin/sh -> dash
```

O `sh` é o **dash**, um shell pequeno e estrito — não o bash. Então um script que começa com
`#!/bin/sh` e usa um recurso do bash funciona quando você testa digitando, e falha quando roda
sozinho. Essa custa uma tarde a muita gente, e a aula 9 volta nela com a correção.

**Tudo o que está acima do piso.** Como software é instalado, como serviços são iniciados, onde
fica a configuração, qual é o firewall — nada disso é POSIX, tudo isso muda, e a aula 2 é
inteiramente sobre essas diferenças.

## O Windows não está nessa árvore

Vale ser preciso aqui, porque "o Windows é diferente" normalmente é dito como reclamação e é, na
verdade, um fato sobre ancestralidade. O Windows NT — a linha de que todo Windows moderno
descende — foi projetado em 1988 por um time vindo da Digital, e sua herança é o VMS, não o Unix.
Não é um fork, não é uma reimplementação, não é um primo. É outra resposta ao mesmo problema,
alcançada separadamente.

É por isso que nada se transfere. Caminhos usam `\` e começam numa letra de unidade. Não existe
`/etc`. Permissões são listas de controle de acesso, e não nove bits. Serviços não são daemons.
Maiúsculas são preservadas mas não significam nada. A configuração fica num registro em vez de em
arquivos de texto — o que significa que você não pode dar `grep` nela nem colocá-la no git.

**E é por isso que o WSL existe.** A resposta da Microsoft para "desenvolvedores precisam de Unix"
não foi deixar o Windows mais parecido com Unix. Foi entregar um kernel Linux de verdade ao lado
do Windows e deixar você abrir um terminal para dentro dele. Isso é admitir que a distância não se
fecha por imitação — e, para você, é o jeito mais fácil de fazer este curso numa máquina Windows.
A próxima seção configura isso.

## O que isso te dá, na prática

O formato prático da herança, dito como retorno sobre as setenta horas que você está prestes a
investir:

- **Em qualquer Linux, em qualquer lugar** — um servidor, um contêiner, um Pi, uma instância na
  nuvem, o WSL — praticamente tudo neste curso se aplica direto. Essa é a grande maioria das
  máquinas que você vai encontrar.
- **No macOS** — os conceitos todos se aplicam, a maioria dos comandos se aplica, algumas flags
  mudam. Você vai ficar confortável, e vai precisar conferir de vez em quando. Muita gente resolve
  isso instalando as ferramentas GNU ao lado das BSD.
- **No BSD ou num Unix comercial** — os conceitos se aplicam; assuma que as flags mudam e leia o
  manual, que é o que a seção 16 desta aula ensina.
- **No Windows** — nada se aplica nativamente, e tudo se aplica dentro do WSL. A aula 10 cobre o
  PowerShell, que é a boa resposta própria do Windows e uma ideia genuinamente diferente.

Um acordo firmado antes de a maioria de quem lê isto ter nascido é o motivo de uma única habilidade
cobrir tanto terreno. Isso é incomum, e é a razão de este curso valer mais por hora do que o
assunto aparenta.
