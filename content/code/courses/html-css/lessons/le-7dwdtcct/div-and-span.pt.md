---
title: Quando div e span estão certos
version: 1
---

Depois de uma aula sobre escolher elementos com significado, vale deixar claro quais são os dois que não significam nada, porque eles não são erros. **`<div>` é um bloco genérico e `<span>` é um pedaço genérico de texto em linha.** Existem para as vezes em que você precisa de um elemento e o conteúdo não tem um significado que um elemento possa expressar, o que acontece o tempo todo, sobretudo para layout e estilo.

Uma fileira de três cartões de evento precisa de um invólucro para o CSS pôr os cartões lado a lado. Os cartões são articles; a fileira não é nada. É uma `<div>`:

```html
<div class="cards">
  <article>…</article>
  <article>…</article>
  <article>…</article>
</div>
```

Um preço numa frase precisa de uma cor. O preço não é enfatizado, não é importante, não é um termo; é só texto que o CSS precisa alcançar:

```html
<p>First edition, <span class="price">R$ 240</span>, in very good condition.</p>
```

Os dois estão certos. Na árvore de acessibilidade eles não deixam rastro, e é assim que deve ser: não há nada a dizer a ninguém.

## O teste

Antes de escrever uma `<div>`, faça a pergunta da aula 1: **o que é isto?** Se a resposta é um título, uma lista, um bloco de navegação, um item que se sustenta sozinho, um botão, use esse elemento. Se a resposta honesta é "uma caixa para o layout", use uma `<div>` e pare de se preocupar.

A falha de que esta aula trata não é usar `<div>`. É usar `<div>` **onde o conteúdo tinha um significado**, como a página sopa fez com o título, o menu e os eventos, de modo que o significado acabou num nome de classe, onde só o CSS e quem lê o arquivo conseguem encontrá-lo.

## Uma nota sobre ARIA

Atributos ARIA, `role` e `aria-*`, conseguem acrescentar significado a uma `<div>`: `role="navigation"`, `role="button"`. Eles existem para componentes que o HTML não tem, como abas ou uma árvore de pastas, e os cursos de `javascript` e de frameworks os usam ali. Para tudo o que o HTML tem, o elemento é mais curto, vem com o comportamento e não tem como ficar pela metade. **Nenhum ARIA é melhor que ARIA ruim**: um papel errado diz algo falso à tecnologia assistiva, o que é pior do que não dizer nada.
