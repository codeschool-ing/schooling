---
title: O planner agora
version: 1
---

**O planner começou este curso como uma página desenhada no navegador a partir de um arquivo JSON, e cada aula
desde então lhe acrescentou uma coisa, medida antes e depois.** Lida como lista, ela também é a ordem em que o
trabalho de desempenho de um site de verdade costuma andar:

| aula | o que o planner ganhou | o número que ela mexeu |
|---|---|---|
| 1 | renderização no servidor | a primeira pintura da página de curso, de 948 para 640 milissegundos com toda requisição desacelerada |
| 3 | pré-renderização | uma página servida como arquivo, com o custo de um rebuild que cresce com o site |
| 4 | hidratação a partir da página, streaming | nenhuma segunda requisição pelo plano; a janela morta, medida |
| 5 | o aviso mandado com a página, menos trabalho por clique | um LCP uma ida e volta antes; um INP de 1888 para 88 milissegundos |
| 6 | compressão | o Lighthouse de 75 para 100 na página inicial grande |
| 7 | imagens dimensionadas e escolhidas, fontes com preload, CSS embutido | um LCP de quase quarenta segundos para 1,3, e nenhuma requisição bloqueando a pintura |
| 8 | o gráfico carregado sob demanda | a página de curso de volta a vinte kilobytes de script, de mais de duzentos |
| 9 | cabeçalhos de cache, uma CDN | uma segunda visita sem download, e 304 para o resto |
| 10 | um service worker | o planner abre sem rede nenhuma |
| 11 | um manifesto, ícones, um botão | instalável, e capaz de mostrar uma notificação |

## O que fica

**Meça antes, mude uma coisa, meça de novo nas mesmas condições.** Cada linha acima foi uma medida antes de ser uma
correção, e dois achados do curso foram contra o palpite óbvio: o modelo do Lighthouse foi pessimista em três
segundos numa página, e o script lento do trace da aula 6 não era lento por causa dos dados.

**Números de laboratório acham causas; números de campo dizem se uma correção importou.** Tudo aqui foi medido num
computador, e o planner manda as suas Core Web Vitals para casa desde a aula 5. A última palavra sobre cada linha é
desse endpoint, lido no percentil 75, depois de pessoas de verdade usarem a mudança.

**E uma decisão escrita não é um erro.** O planner ainda embute o plano inteiro em toda página, mantém as fontes num
endereço sem hash, e não pede permissão a ninguém para notificar. Cada uma dessas coisas está na aula que a decidiu,
com a medida que mudaria a decisão.
