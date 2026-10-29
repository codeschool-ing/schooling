---
title: O que o Svelte custa, e o que ele dá
version: 1
---

**As vantagens do Svelte são as que este curso ficou medindo**: pouco JavaScript enviado, um componente
que se lê como o HTML que produz, estado que é uma variável e, com o SvelteKit, formulários que
funcionam antes de qualquer script chegar. Elas são reais, e o contador desta aula pôs um número na
primeira.

**Os custos dele são igualmente reais, e uma escolha honesta os pesa:**

- **Um ecossistema menor.** O React tem uma biblioteca para quase tudo, e a maioria delas supõe o React.
  Um seletor de datas, um editor de texto rico, um gráfico, as telas prontas de um serviço de
  autenticação: para o React costuma haver várias, para o Svelte pode haver uma, ou uma biblioteca
  escrita para JavaScript puro que você mesmo embrulha, o que os stores da aula 10 e o contexto da aula
  11 facilitam, mas não tornam de graça.
- **Menos gente que o conhece.** Uma equipe que contrata para React busca num grupo bem maior, e a
  maioria dos desenvolvedores de front-end já passou pelo React, seja lá o que mais conheçam. Isso
  importa mais para uma empresa do que para um projeto.
- **Mudança.** O Svelte 5 trocou a reatividade do Svelte 3 e 4 pelas runes, e a aula 4 existe porque
  muito código, documentação e respostas na web ainda descrevem a antiga. O SvelteKit 3 renomeou coisas
  de novo, `$lib` e `$app/stores` entre elas. O React teve as suas próprias reviravoltas, os hooks e
  depois os Server Components, e o Angular passou de zones para signals; nenhum dos quatro fica parado.

**Escolher, então, depende mais da situação do que do framework.** Uma equipe que já conhece um deles
costuma ser mais bem servida por ele. Um projeto que depende de uma biblioteca em particular é servido
pelo framework para o qual ela foi escrita. Um site em que o primeiro carregamento num celular lento
decide se as pessoas ficam, ou um formulário que precisa funcionar em todo lugar, é onde os padrões do
Svelte e do SvelteKit rendem mais. Uma aplicação que uma organização grande vai manter por uma década, com
muitas equipes e convenções fortes, é onde a estrutura do Angular, tudo num só framework e um só jeito de
fazer, rende mais.

**O que se leva adiante é a maior parte do que este curso ensinou.** Componentes com props e filhos,
estado que é derivado em vez de copiado, o endereço como o lugar do que a pessoa está vendo, uma função
load que roda no servidor, um formulário que faz POST, a checagem que roda no servidor seja lá o que o
navegador tenha conferido, o teste com JavaScript desligado: cada um dos outros três tem o seu nome para
cada uma dessas coisas, e o planner pode ser construído em cada um. Os cursos deles o constroem, do lado
de cada um.
