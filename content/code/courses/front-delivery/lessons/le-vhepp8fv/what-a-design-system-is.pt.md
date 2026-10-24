---
title: O que é um design system, e o que ele não é
version: 1
---

**Um design system é o conjunto de decisões de que a interface de um produto é feita, escrito para que
pessoas e código possam reutilizá-las em vez de tomá-las de novo.** Ele tem três camadas, e equipes que
dizem ter um em geral têm a primeira e se referem às três:

1. **tokens**: as menores decisões, com nome. Uma cor, um tamanho, um espaço, um raio. Esta aula.
2. **componentes**: botões, campos, cartões, construídos só com tokens, documentados em todo estado em
   que podem estar. Aulas 6 e 8.
3. **as regras em volta deles**: quem pode mudar um token, como uma mudança chega aos produtos que o usam,
   e como um produto fica sabendo que um componente que ele usa está para sair. Aula 7.

A imagem comum é a de um design system como uma biblioteca de componentes bonitos, muitas vezes comprada
ou copiada de uma empresa que publicou a sua. Isso é um **kit de UI**, e é a ponta visível da coisa. Um
kit sem tokens é um conjunto de componentes com cores fixas no código, que um tema escuro ou uma troca de
marca precisa editar um por um; um kit sem regras é uma pasta que cinco equipes copiam em cinco direções
em menos de um ano.

## Por que é um problema de entrega

Este curso é sobre publicar, e estas quatro aulas estão nele por um motivo. O valor de um design system
não é parecer consistente no dia em que é escrito. É que **uma mudança feita uma vez chega a toda tela que
a usa, e a nada mais**: o verde da marca muda numa terça e todo botão, link e anel de foco em três
produtos muda junto, por uma versão nova e um build, sem nenhuma tela editada à mão. Isso é um pipeline de
entrega, de decisões em vez de código.

## O que o planner ganha

O planner é pequeno o bastante para mostrar cada camada disso sem o ruído de um produto de verdade:

- nesta aula, **os tokens dele**, como um arquivo JSON e o CSS gerado a partir dele, com um tema claro e
  um escuro e uma conferência de que todo par de cores é legível;
- na aula 6, **os componentes dele** documentados no Storybook;
- na aula 7, **os tokens e os componentes como um pacote** com versão, publicado num registry;
- na aula 8, **um componente como Web Component**, usável a partir de qualquer framework.

Nada disso depende de framework, e é de propósito: um design system serve todos os produtos de uma
empresa, e esses produtos raramente concordam num só.
