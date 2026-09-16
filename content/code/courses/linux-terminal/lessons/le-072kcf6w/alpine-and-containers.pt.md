---
title: Alpine, e por que seu contêiner se comporta estranho
version: 1
---

Toda outra distribuição desta aula é uma em que você poderia rodar um servidor. **O Alpine é a que
você vai encontrar sem escolher**, porque é dele que a imagem base do tutorial que você está
seguindo foi construída — e é a primeira distribuição que a maioria das pessoas usa sem saber que
está usando.

O `docker` depende deste curso. Esta seção é a parte dessa dependência que pertence aqui.

## Ele é pequeno de propósito, e esse é o projeto inteiro

Uma imagem Alpine tem alguns megabytes onde uma do Debian tem cem ou mais. Num contêiner isso
importa mais do que parece: uma imagem é baixada por toda máquina que a roda, guardada em todo
registro que a mantém, e reconstruída toda vez que o CI roda. Tamanho é banda e dinheiro,
multiplicados por um número que só cresce.

O Alpine chega lá substituindo duas coisas que toda outra distribuição desta aula mantém.

## Ele troca o userland — busybox no lugar do GNU

A aula 1 disse que os comandos são o userland e que o GNU o fornece em quase todo lugar. O Alpine
usa o **busybox**: um programa pequeno que implementa `ls`, `cp`, `grep`, `sed` e outros cem como
modos de si mesmo.

Os comandos estão lá e os usos comuns funcionam. **As extensões não.** O `ls` do GNU tem opções
longas; o do busybox quase não tem. O `sed -i` do GNU aceita o sufixo de outro jeito. O `grep -P`
não existe. O resultado é o formato que você deve reconhecer:

> Um script que funciona na sua máquina Ubuntu falha dentro do contêiner Alpine, numa flag, e a
> flag parece que deveria existir.

Isso não é contêiner quebrado. É um `ls` menor.

**E não existe bash.** O `/bin/sh` no Alpine é o `ash` do busybox, não é o bash e não é o dash. Um
script que começa com `#!/bin/bash` falha direto, e um que começa com `#!/bin/sh` e usa um recurso
do bash falha do jeito confuso que a seção 02 da aula 1 descreveu. Se você precisa de bash numa
imagem Alpine, você instala.

## Ele troca a biblioteca C — musl no lugar da glibc

Essa é a que surpreende, porque falha longe da causa.

Quase todo programa Linux é ligado contra a **glibc**, a biblioteca C do GNU. O Alpine usa a
**musl**, que é menor e mais estrita. Quase todo software compilado do código constrói bem contra
qualquer uma das duas. **Um binário compilado em outro lugar contra a glibc não roda no Alpine** —
ele inicia, não acha a biblioteca para a qual foi construído, e recusa.

Como isso aparece na prática: um runtime de linguagem que baixa módulos nativos pré-compilados —
wheels de Python, addons nativos do Node — instala e depois não consegue carregar, com um erro
sobre um objeto compartilhado. Nada na mensagem diz "musl". A correção é compilá-los no contêiner,
ou usar uma imagem Debian `-slim`.

**Que é a decisão de verdade.** Alpine para um programa que não se importa — um binário Go, um
script de shell, um serviço pequeno — e Debian slim para qualquer coisa arrastando código nativo
pré-compilado atrás de si. A diferença de tamanho é real; a tarde perdida também.

## `apk`, o quinto gerenciador de pacotes

| | Alpine | lado Debian |
|---|---|---|
| instalar | `apk add curl` | `apt install curl` |
| remover | `apk del curl` | `apt remove curl` |
| atualizar índice | `apk update` | `apt update` |
| atualizar tudo | `apk upgrade` | `apt upgrade` |

A flag que você vai copiar sem ler é a `--no-cache`: `apk add --no-cache curl` instala sem deixar o
índice de pacotes em disco, o que mantém a imagem pequena. Está em todo exemplo de Dockerfile
exatamente por isso.

## O que fazer quando você cair num

Três verificações, nesta ordem, e são o reflexo da seção 11 aplicado a um contêiner:

1. `cat /etc/os-release` — `ID=alpine` é a resposta.
2. Se um comando está sem uma flag que você espera, você está no busybox. Leia `comando --help`.
3. Se um binário pré-compilado recusa iniciar, suspeite da musl antes de qualquer coisa.

---

**Uma observação sobre esta seção, porque a regra do próprio curso exige.** Toda outra transcrição
deste curso foi capturada rodando o comando. Estas não: a máquina em que isto foi escrito não
alcança um registro de contêineres, então nada acima é citado como saída — está escrito como prosa.
O `alpine-and-containers.tape`, ao lado deste arquivo, é a sessão exata que produz essas
transcrições numa máquina que alcança, e as afirmações daqui são para serem substituídas pela saída
dele, não para fazerem as vezes dela.
