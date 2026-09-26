---
title: Três jeitos de passar um arquivo
version: 1
---

Um convidado e o host dele são dois computadores, aula 3, e um arquivo vai de um para o outro dos
mesmos jeitos que iria entre quaisquer dois computadores, mais dois que o hypervisor acrescenta:

| jeito | precisa de | serve para |
|---|---|---|
| pela rede: `scp`, um compartilhamento do Windows, um download pela web | uma rede entre eles, aula 11 | qualquer coisa, e funciona igual em qualquer hypervisor |
| uma **pasta compartilhada** | suporte do hypervisor e, normalmente, o agente do convidado | arquivos em que os dois lados continuam trabalhando |
| uma **área de transferência compartilhada**, e arrastar e soltar | o agente do convidado, e uma área de trabalho gráfica | uma linha de texto, um caminho, um arquivo pequeno |

A rede é a que sempre funciona e nunca surpreende ninguém, e para um arquivo só muitas vezes é a mais
rápida: este curso inteiro vem fazendo isso com `ssh`. As outras duas são conveniências e, como a
maioria das conveniências, trocam um pouco de segurança por isso. Esta aula monta uma pasta
compartilhada no laboratório, e mostra as configurações da área de transferência no VirtualBox.
