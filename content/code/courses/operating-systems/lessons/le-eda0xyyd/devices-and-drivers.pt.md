---
title: Dispositivos e drivers
version: 1
---

Um teclado, uma impressora, um disco, uma placa de rede: cada um fala a própria língua, definida por
quem o fabricou. O kernel não tem como conhecer todas, então cada dispositivo vem com um **driver**,
um pedaço de código que traduz entre os pedidos gerais do kernel (*escreva estes bytes*) e os
detalhes daquele dispositivo.

Os drivers são o motivo de uma impressora nova precisar de *alguma coisa instalada* antes de
funcionar, e de um scanner antigo parar de funcionar depois de uma atualização do sistema: o driver
dele foi escrito para o kernel antigo e ninguém escreveu um novo. A aula 16 é exatamente sobre isso.

## Dispositivos como arquivos, no Linux

O Linux (e o macOS, que herdou a ideia do Unix) mostra os dispositivos como arquivos especiais em
`/dev`:

```
ana@server:~/office$ ls /dev | head -12
char
fd
full
hugepages
initctl
log
mqueue
net
null
ptmx
pts
random
ana@server:~/office$ ls -l /dev/null /dev/tty
crw-rw-rw- 1 root root 1, 3 Sep 25 09:59 /dev/null
crw-rw-rw- 1 root root 5, 0 Sep 25 09:59 /dev/tty
```

O `c` no começo das permissões quer dizer *dispositivo de caracteres*: algo lido e escrito como uma
sequência de bytes. O `/dev/null` é um dispositivo que engole tudo o que se escreve nele; o
`/dev/tty` é o terminal em que você está digitando. Um disco apareceria como *dispositivo de blocos*,
com um `b`. O ponto não são os nomes. É que um programa pode escrever num dispositivo com o mesmo
`write` que usou num arquivo na seção anterior, e o driver faz o resto.

A lista aqui é curta porque este é um servidor sem tela, impressora ou som. Num computador de mesa, o
`/dev` também tem os discos, a webcam e a placa de som.

## Dispositivos no Windows

O Windows não mostra dispositivos como arquivos. Ele os mostra no **Gerenciador de Dispositivos**,
agrupados por tipo, cada um com o nome e a versão do driver. Um triângulo amarelo num dispositivo
quer dizer que o driver está faltando ou não conseguiu iniciar, e em geral é o primeiro lugar a olhar
quando um dispositivo *está ligado e não faz nada*. No macOS, a ferramenta é o **Informações do
Sistema**, em que os drivers se chamam *extensões do kernel*, e a Apple vem tirando essas extensões de
dentro do kernel por segurança.

## Por que isso importa no suporte

A maioria dos chamados de "parou de funcionar" sobre hardware é, na verdade, sobre drivers: faltando
depois de uma reinstalação, trocados por um genérico numa atualização, ou incompatíveis com uma
versão nova do sistema. Saber que o dispositivo, o driver e o kernel são três coisas diferentes é o
que permite fazer a pergunta certa primeiro.
