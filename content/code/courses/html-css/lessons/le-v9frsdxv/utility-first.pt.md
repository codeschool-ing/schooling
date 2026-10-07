---
title: Classes utilitárias: o estilo vai no HTML
version: 1
---

A aula 10 deu às classes o nome do **que uma coisa é**: `.event-card`, com as regras em `event-card.css`. O **Tailwind CSS** dá às classes o nome do **que elas fazem**, uma declaração ou poucas cada, e um componente é estilizado combinando-as no atributo `class` dele:

```html
<article class="mt-4 rounded-lg border-l-4 border-emerald-700 bg-white p-4">
  <h2 class="text-lg font-semibold">Poetry reading</h2>
  <p class="mt-1 text-stone-600">Thursday, 7 pm.</p>
</article>
```

`mt-4` é uma margem de cima, `rounded-lg` cantos arredondados, `border-l-4` uma borda esquerda de 4 pixels, `p-4` padding. Essas são **classes utilitárias** (*utility classes*), e construir com elas se chama **utility-first**. O cartão não tem nome nem folha de estilos própria.

## O que isso compra e o que custa

**O que compra.** Ninguém precisa inventar e combinar nomes, o que é mais difícil do que parece e é o que o BEM existe para administrar. Os estilos não vazam: uma classe faz uma coisa onde quer que seja posta, então mudar um cartão não quebra outro, e apagar um cartão apaga os estilos dele junto. Os valores vêm de uma **escala**, como a seção 08 da aula 10 recomendou: `p-4` e `p-6` existem e `p-[13px]` se destaca. E você não alterna entre dois arquivos para mudar uma coisa.

**O que custa.** O HTML fica longo, e uma lista de quinze classes é mais difícil de ler que um bom nome. A mesma lista repetida em vinte cartões é uma repetição com que a seção 10 tem de lidar. E é preciso saber CSS para usá-lo bem: `flex items-center justify-between` é a aula 8, abreviada. Quem aprendeu Tailwind sem CSS consegue escrever as classes e não consegue dizer por que um layout quebrou.

Esse último ponto é por que esta é a última aula do curso, e não a primeira. Toda classe desta aula é traduzida de volta para o CSS que gera, e a tradução é o que há para aprender.
