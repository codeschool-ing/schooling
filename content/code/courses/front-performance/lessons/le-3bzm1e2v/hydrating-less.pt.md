---
title: Hidratando menos da página
version: 1
---

**A maior parte de uma página nunca muda depois de chegar, e hidratá-la é trabalho à toa.** A página
de curso do planner tem um título, duas datas e um link que um script nunca precisa tocar, e dois
botões e um formulário que precisa. As ideias desta seção partem todas dessa observação, e cada uma
traça a linha num lugar diferente.

## Islands

**Uma ilha é uma parte de uma página estática que hidrata sozinha, e tudo em volta é HTML sem script
nenhum.** A página é renderizada no servidor como sempre. Só os componentes marcados como interativos
mandam JavaScript, e cada um hidrata independentemente, então uma ilha lenta não segura uma rápida. O
Astro é o framework mais conhecido por isso; os botões e o formulário do planner seriam duas ilhas
numa página de HTML puro.

## Server components

**Os React Server Components traçam a mesma linha dentro de um app React.** Um server component roda
só no servidor e manda o seu resultado, nunca o seu código; só componentes marcados com
`"use client"` vão para o navegador e são hidratados. O projeto Next.js da aula 2 era feito
inteiramente de server components, então não havia nada do próprio app para hidratar, e ainda assim a
página rodou o React e o roteador do Next.js, que é o preço de poder navegar sem recarregar.

## Hidratar depois

**Algumas partes de uma página podem esperar para ser hidratadas até serem necessárias**: quando
entram na tela, quando o navegador está ocioso, ou quando alguém interage com elas pela primeira vez.
O Angular chama isso de hidratação incremental, escrita como `@defer` com um gatilho `hydrate`, como
`@defer (hydrate on viewport)`, depois que `withIncrementalHydration()` é acrescentado ao lado do event
replay da aula 2. O Nuxt oferece o mesmo com atributos num componente carregado sob demanda, como
`hydrate-on-visible`. Até o gatilho disparar, a parte é HTML do servidor, tão morta quanto na janela de
duas seções atrás, e é por isso que esses recursos andam junto com o event replay.

## Retomar em vez de repetir

**A resumability pula a hidratação de vez.** O servidor escreve na página o bastante sobre o estado de
cada componente para que o navegador nunca precise rodá-los de novo; o código de um tratador só é
buscado quando o seu evento dispara. O Qwik é construído sobre isso. O custo muda de lugar em vez de
sumir: o primeiro clique em cada controle espera o código daquele controle.

## Para o planner

Nada disso precisa de um framework para ser entendido. O planner já hidrata quase nada: um listener no
contêiner, e uma comparação de texto. Um app puro está perto da menor hidratação que existe, e isso é
parte do motivo de ele ser o app que este curso mede.
