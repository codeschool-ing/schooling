---
title: TCP e UDP: garantir ou não esperar
---

A camada de transporte tem duas escolhas, e a diferença é o que cada uma promete.

**TCP** garante entrega, ordem e integridade: confirma cada pedaço, reenvia o que se perdeu e remonta na sequência certa. Custa uma conexão para estabelecer e espera pelo que faltou. É o que HTTP usa — uma página com metade do HTML não serve para nada.

**UDP** não promete nada: manda e segue. Custa quase nada e não espera ninguém. É o que chamada de vídeo e jogo usam, porque num vídeo ao vivo o quadro atrasado já não tem serventia — melhor perder do que travar a imagem esperando por ele.

A regra de bolso: se o dado incompleto é inútil, TCP. Se o dado atrasado é inútil, UDP.
