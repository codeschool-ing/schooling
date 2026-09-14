---
title: As teclas que ninguém te conta
version: 1
---

Esta seção não ensina comando nenhum. Ela é sobre uma dúzia de teclas, e é a diferença entre alguém
que redigita todo caminho e alguém fluente.

Nada disso é conhecimento opcional. **Uma dessas teclas faz aqui algo diferente do que faz em todo
outro programa que você já usou**, e o dia em que você descobre isso por acidente é um dia em que
você perde trabalho.

## Tab, que é a que muda tudo

Aperte Tab e o shell completa o que você estava digitando. Digite o suficiente para não haver
dúvida:

```
ana@vm:~/notas$ ls le
```

…aperte Tab, e a linha vira:

```
ana@vm:~/notas$ ls leiame.txt
```

Se o que você digitou for ambíguo, um Tab não faz nada e um segundo Tab mostra as opções:

```
ana@vm:~/notas$ ls 
-estranho       arquivo/        leiame.txt
.oculto         com espaco.txt
```

Daí saem três hábitos, e vale construí-los de propósito:

- **Nunca digite um caminho inteiro.** Digite três letras e aperte Tab. É mais rápido, e não tem
  como errar de digitação.
- **O Tab também é corretor.** Se ele não completa, a coisa que você está nomeando não está ali —
  diretório errado, nome errado, ou ela não existe. Você acabou de ser avisado, antes de apertar
  enter.
- **Ele completa comandos também**, não só arquivos. Digite `whoa` num prompt vazio e o Tab acha o
  `whoami`.

## O histórico é a segunda maior economia

| tecla | o que faz |
|---|---|
| **↑ / ↓** | anda para trás e para frente nos comandos que você digitou |
| **Ctrl+R** | busca no histórico — comece a digitar e ele acha a ocorrência mais recente; Ctrl+R de novo para a anterior |
| `history` | imprime a lista, numerada |
| `!!` | o comando anterior, de novo. Visto quase sempre como `sudo !!` |

O histórico sobrevive a fechar o terminal, o que surpreende as pessoas. Ele mora num arquivo no seu
diretório pessoal, e isso vale saber por um motivo que ninguém menciona no começo: **tudo o que você
digita num prompt fica escrito.** Uma senha digitada como argumento de um comando está agora dentro
de um arquivo. A aula 4 volta nisso onde importa.

## Ctrl+C não é copiar

Em todo outro programa do seu computador, `Ctrl+C` copia. **Num terminal ele quer dizer pare**, e é
a tecla mais importante desta seção.

```
ana@vm:~$ sleep 30
^C
ana@vm:~$ echo $?
130
```

O `sleep 30` deveria ter segurado o prompt por meio minuto. O `Ctrl+C` o devolveu na hora. O `^C` é
o terminal te mostrando o que você enviou; o `130` é o status de saída, e é especificamente o número
que quer dizer *este programa foi interrompido*. A seção 94 da aula 6 explica de onde vem o 130; por
ora, ele é o recibo.

**Então como se copia?** `Ctrl+Shift+C` e `Ctrl+Shift+V` na maioria dos terminais Linux, `Cmd+C` num
Mac, e selecionar com o mouse muitas vezes já copia sozinho. O shift é o que mantém o `Ctrl+C` livre
para o trabalho de verdade dele.

## Ctrl+D quer dizer "acabou a entrada"

```
ana@vm:~$ cat
ola
ola
ana@vm:~$
```

O `cat` sem arquivo lê o que você digita e devolve — ele nunca termina sozinho. O `Ctrl+D` numa
linha vazia é como se diz que a entrada acabou. Repare que não aparece nenhum `^D` na tela e nenhum
erro: este é um encerramento comum e bem-sucedido, e é por isso que o próximo prompt simplesmente
está ali.

Num prompt vazio, a mesma tecla encerra o próprio shell — o mesmo significado, aplicado à entrada do
shell. É por isso que o `Ctrl+D` te desloga, e por isso que apertá-lo duas vezes sem querer fecha a
sua janela.

**`Ctrl+C` e `Ctrl+D` não são dois jeitos de fazer a mesma coisa.** O `Ctrl+C` interrompe um programa
que está rodando. O `Ctrl+D` avisa um programa que está lendo que não há mais nada para ler. Usar o
primeiro onde você precisa do segundo joga fora o que você digitou.

## Editando a linha em que você está

Você não precisa segurar o backspace. Estas funcionam no prompt, e em um monte de outros lugares
depois que você as conhece:

| tecla | o que faz |
|---|---|
| **Ctrl+A** | pula para o começo da linha |
| **Ctrl+E** | pula para o fim |
| **Ctrl+U** | apaga do cursor até o começo |
| **Ctrl+K** | apaga do cursor até o fim |
| **Ctrl+W** | apaga a palavra antes do cursor |
| **Alt+← / Alt+→** | anda uma palavra por vez |

O `Ctrl+U` é o primeiro a aprender. É como você abandona uma linha pela metade sem executá-la — e é
mais seguro que o `Ctrl+C` para isso, porque não deixa dúvida sobre se algo rodou.

## Mais duas, e uma armadilha

**Ctrl+L limpa a tela.** Nada é apagado e nada para; o texto sai de vista rolando. O `clear` é a
mesma coisa como comando.

**Ctrl+Z suspende.** O programa para onde está e você recebe o prompt de volta — mas *ele continua
lá*, pausado, não terminado. A seção 90 da aula 6 é sobre retomá-lo. Até lá, saiba que usar o
`Ctrl+Z` para "parar" algo deixa a coisa parada e viva, o que normalmente não era o que você queria.

**E o Ctrl+S congela o seu terminal.** Nada do que você digita aparece. A máquina parece morta. Não
está: `Ctrl+S` é uma tecla antiga que significa *pause a saída*, e ela continua esperando nos
teclados desde então. A cura é `Ctrl+Q`, que retoma.

Essa está aqui porque é o alarme falso mais comum que existe. Alguém vai de `Ctrl+S` para salvar —
não há nada para salvar, e nenhum programa está escutando — a tela para de responder, e a pessoa
reinicia a máquina. **Aperte `Ctrl+Q` primeiro, sempre.**

## A lista curta para decorar mesmo

Seis teclas, e o resto você pega por osmose:

1. **Tab** — complete, e confira que existe
2. **↑** — o último comando, de novo
3. **Ctrl+R** — ache um comando da semana passada
4. **Ctrl+C** — pare isso
5. **Ctrl+U** — limpe a linha que estou digitando
6. **Ctrl+Q** — descongele a tela que eu acabei de congelar
