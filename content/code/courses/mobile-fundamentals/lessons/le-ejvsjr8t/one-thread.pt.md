---
title: Uma thread desenha a tela e responde ao dedo
version: 1
---

**Um app começa com uma thread, e essa thread tanto desenha a tela quanto recebe cada toque.** A
imagem comum é a oposta: um celular tem vários núcleos de processador, então o app com certeza faz
o trabalho em todos ao mesmo tempo. Ele pode, mas só se pedir. Tudo o que o sistema entrega ao app,
um toque, uma rolagem, uma chamada do ciclo de vida da aula 4, chega por uma thread, e toda mudança
no que aparece na tela precisa ser feita a partir dessa mesma thread. O Android a chama de *main
thread* ou *UI thread*; no iOS ela é a main thread, e o Swift chama a parte de um programa que roda
nela de *main actor*. Aqui ela é a thread principal.

## Um laço que dá uma volta por quadro

A thread principal roda um laço. Ela espera algo acontecer, roda o código que responde, calcula
onde cada coisa fica na tela e desenha. Depois espera de novo. A documentação do Android sobre
processos e threads descreve um toque num botão exatamente nesses
passos. A UI thread passa o toque ao
botão, o botão se marca como pressionado e pede para ser redesenhado, e o pedido entra numa fila
que a mesma thread esvazia na volta seguinte.

**Então o seu código roda nos intervalos entre os quadros.** Um tratador que retorna em um
milissegundo deixa o laço livre para desenhar o próximo quadro na hora. Um tratador que roda por
meio segundo impede o laço de girar por meio segundo: nenhum quadro é desenhado, e os toques que
chegam nesse tempo esperam na fila. O dedo se move, e a lista embaixo dele não.

## Por que existe só uma

Desenhar a partir de duas threads ao mesmo tempo significaria dois trechos de código mudando a
mesma view no mesmo instante, e os kits de interface não foram feitos para isso. **O Android
escreve isso como duas regras**: não bloqueie a UI thread, e não mexa no kit de interface a partir
de nenhuma outra thread. A documentação diz com todas as letras que o kit não é thread-safe. Os
kits da Apple fazem a mesma exigência, e o compilador do Swift consegue conferir: código marcado
como pertencente ao main actor roda na thread principal, e uma chamada vinda de outro lugar
precisa esperar a vez.

As duas regras puxam para lados opostos, e o resto desta aula vive entre elas. O trabalho lento
precisa sair da thread principal, e o resultado dele precisa voltar para ela antes de chegar à
tela.

## O React Native tem duas threads que importam, e cada uma é única

Um app React Native tem a mesma thread principal nativa, que desenha as views nativas e recebe os
toques. O seu JavaScript, os componentes React e o código que responde a um toque, roda numa
**thread de JavaScript separada**. A própria documentação do React Native sobre desempenho diz o que decorre disso. Uma scroll view continua rolando enquanto a thread de JavaScript está
ocupada, porque a rolagem acontece na thread principal. Um botão que muda de aparência em JavaScript
para de responder, porque o toque está esperando uma thread que não está livre.

**E a thread de JavaScript é uma thread só.** O JavaScript roda uma função por vez nela, então um
laço longo num tratador segura todos os outros tratadores, todos os timers e toda renderização. É o
mesmo formato da thread principal de um app nativo, um nível acima. É também por isso que o experimento
desta aula pode rodar no Node.js. O Node roda JavaScript numa thread só, com um laço de eventos, do
mesmo jeito, e uma função síncrona longa para os timers dele exatamente como pararia um quadro. O
Node.js é um modelo da regra aqui, não um celular, e a seção que o roda diz onde o modelo para.
