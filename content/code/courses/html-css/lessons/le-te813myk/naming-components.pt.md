---
title: Dando nome a componentes para ninguém ter de adivinhar
version: 1
---

As classes são onde vive a maior parte dos seletores de uma folha de estilos, e um nome de classe é lido muito mais vezes do que é escrito. Sem uma convenção, o mesmo site acaba com `.card`, `.event-box`, `.eventCard` e `.tile` para quatro versões de uma coisa só, e um seletor como `.card .title` que pega também o título de um cartão dentro de outro cartão. Uma convenção de nomes evita as duas coisas. A que mais equipes conhecem é o **BEM**, de *block, element, modifier* (bloco, elemento, modificador):

```css
.event-card { padding: calc(var(--space) * 2); border-left: 4px solid var(--color-accent); }
.event-card__title { margin: 0; font-size: 1.1rem; }
.event-card--cancelled { --color-accent: #8a1c1c; }
```

- **O bloco** é o componente: `.event-card`. Um nome, um componente, um arquivo.
- **Um elemento** é uma parte que só existe dentro dele, escrita com dois sublinhados: `.event-card__title`. É uma classe própria, então a regra é `.event-card__title`, não `.event-card .title`. É uma classe só, especificidade (0,1,0), e ela não tem como pegar o título de outra coisa.
- **Um modificador** é uma variante, escrita com dois hifens: `.event-card--cancelled`. Vai no bloco, ao lado da classe do próprio bloco, e aqui faz o mínimo possível: redefine `--color-accent`, o padrão da seção 03, e tudo dentro do cartão acompanha.

```
ana@laptop:~/site$ probe site.html style .event-card border-left-color,padding-top style .event-card__title font-size
article.event-card.event-card--cancelled  border-left-color: rgb(138, 28, 28)
article.event-card.event-card--cancelled  padding-top: 16px
h2.event-card__title  font-size: 17.6px
```

A borda do cartão cancelado é vermelha e o padding dele 16px, vindos dos tokens compartilhados; o título tem 17,6px, vindo do arquivo do componente. O HTML diz a que componente cada elemento pertence, e o CSS desse componente está num arquivo com o nome dele.

## Por que a convenção vale a aparência

Os nomes são longos e os sublinhados duplos não são bonitos. O que eles compram: **todo seletor é uma classe**, então a especificidade é uniforme e a ordem decide, que é o conselho da aula 5 feito automático; **os estilos de um componente não vazam** para os de outro, porque nada seleciona por descendente; e **um nome de classe diz onde está a regra dele**. Você não precisa usar BEM. Precisa usar alguma coisa, com consistência, e cada curso de framework traz o próprio jeito de dar escopo aos estilos de um componente, que resolve o mesmo problema no código.
