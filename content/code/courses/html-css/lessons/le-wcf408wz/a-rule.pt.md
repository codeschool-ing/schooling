---
title: Uma regra, e onde o CSS mora
version: 2
---

A aula 2 transformou os subtítulos da página de horários em `<h2>` e prometeu que, se ficassem grandes demais, isso era CSS. Aqui está esse CSS, a primeira regra desta aula:

```css
h2 { font-size: 1.1rem; }
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 224\" role=\"img\" aria-label=\"Uma regra CSS, .event h2 { font-size: 1.1rem; }, desmontada. .event h2 é o seletor, que escolhe os elementos. Dentro das chaves está o bloco de declarações. font-size: 1.1rem; é uma declaração: font-size é a propriedade, 1.1rem o valor, e um ponto e vírgula a encerra.\"><rect x=\"20\" y=\"30\" width=\"680\" height=\"110\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"60\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\">.event h2</text><text x=\"180\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\">{</text><text x=\"84\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--amber)\">font-size</text><text x=\"192\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\">:</text><text x=\"216\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\">1.1rem</text><text x=\"288\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\">;</text><text x=\"60\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\">}</text><path d=\"M60 22 v6 H168 v-6\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"114\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">seletor: quais elementos</text><path d=\"M84 150 v8 H192 v-8\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><text x=\"138\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">propriedade</text><path d=\"M216 150 v8 H288 v-8\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"252\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">valor</text><path d=\"M84 188 v8 H300 v-8\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"192\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">declaração</text><text x=\"440\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">as chaves guardam o bloco de declarações:</text><text x=\"440\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">quantas declarações você quiser,</text><text x=\"440\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cada uma terminando em ponto e vírgula</text></svg>", "caption": "Uma regra é um seletor e um bloco de declarações; uma declaração é uma propriedade e um valor."}
```

Uma **regra** é um **seletor**, aqui `h2`, que escolhe os elementos a que ela se aplica, seguido de um **bloco de declarações** entre chaves. Dentro do bloco, cada **declaração** é uma **propriedade**, dois-pontos, um **valor** e um ponto e vírgula. Uma regra pode ter quantas declarações quiser; esta tem uma.

A regra mora em `events.css`, e a página a referencia como a seção 12 da aula 1 mostrou. A página é a de eventos do sebo, `events.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Events · Andorinha Books</title>
    <link rel="stylesheet" href="events.css">
  </head>
  <body>
    <main id="events">
      <h1>Events</h1>
      <p class="intro">Everything here is free unless it says otherwise.</p>
      <article class="event">
        <h2>Poetry reading: Hilda Hilst</h2>
        <p>Thursday 8 October, 7 pm.</p>
        <p class="note">Bring a poem of your own.</p>
      </article>
      <article class="event featured">
        <h2>Book swap</h2>
        <p>Saturday 10 October, from 10 am.</p>
        <a href="swap.html" class="more">How the swap works</a>
      </article>
      <article class="event cancelled">
        <h2>Bookbinding class</h2>
        <p>Cancelled: the teacher is ill.</p>
      </article>
    </main>
  </body>
</html>
```

Toda página desta aula é esta, ligada a outra folha de estilos. Salve uma cópia para cada folha de estilos que uma seção mostrar, com o nome dela, e mude o `<link>`: `cascade.html` liga o `cascade.css`, `states.html` liga o `states.css`, e o mesmo vale para `extras`, `order` e `inherit`. Aqui está o que o `events.css` fez com os títulos:

```
ana@laptop:~/site$ probe events.html rules h2 font-size
h2 (0,0,1)  font-size: 1.5em                browser default
h2 (0,0,1)  font-size: 1.1rem               events.css
computed font-size: 17.6px
```

Duas regras definem `font-size` nesse `<h2>`. A primeira é a **folha de estilos padrão do navegador**, a que deixava os títulos grandes e em negrito antes de você escrever qualquer CSS, dizendo `1.5em`. A segunda é a sua, dizendo `1.1rem`. A sua venceu, e o título tem **17,6 pixels**: `rem` é um múltiplo do tamanho de fonte da raiz, que é 16 pixels por padrão, e 1,1 vezes 16 dá 17,6. A aula 6 é sobre unidades. Por que a sua venceu é o assunto da maior parte desta aula.

## Três lugares para escrever CSS

**Numa folha de estilos referenciada no head**, como acima. É aqui que quase todo CSS deve morar: um arquivo serve a todas as páginas, o navegador o baixa uma vez e guarda no cache, e o HTML continua tratando de conteúdo.

**Num elemento `<style>` no head**, que funciona do mesmo jeito para uma página. É útil para uma página só, para uma demonstração como as páginas deste curso, e para pequenos trechos de CSS que precisam chegar junto com o HTML.

**Num atributo `style` num elemento**, `<p style="color: grey">`. Isso se aplica só àquele elemento, não usa seletores, não se reaproveita e é difícil de sobrescrever, como a seção 09 mede. Evite-o no que você escreve à mão; você vai encontrá-lo em código que um script ou um framework gera.

## Comentários, e o que acontece com um erro

Um comentário em CSS se escreve `/* assim */`, e pode ocupar várias linhas. Não existe comentário `//` em CSS. **Uma declaração que o navegador não entende é pulada, em silêncio**, e o resto da regra continua valendo: um `colr: green;` com erro de digitação não muda nada e não diz nada. Essa tolerância é de novo o parser da aula 1, e de novo é o DevTools que a mostra: o painel Styles desenha uma propriedade desconhecida com um sinal de aviso e a risca.
