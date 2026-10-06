---
title: Para onde um evento vai: captura e borbulhamento
version: 1
---

Um clique num botão também é um clique em tudo em que o botão está dentro. **O navegador entrega o
evento a cada ancestral do alvo, duas vezes**: uma na descida, uma na subida. Quatro elementos com
um listener para cada sentido mostram a viagem inteira:

```html
<!doctype html>
<ul id="books">
  <li class="book"><button class="lend">Lend</button></li>
</ul>
<script>
  const say = (where, phase) => (event) =>
    console.log(`${phase.padEnd(7)} ${where.padEnd(8)} target=${event.target.className}`);

  for (const [where, el] of [["document", document], ["ul", document.querySelector("ul")],
                             ["li", document.querySelector("li")], ["button", document.querySelector("button")]]) {
    el.addEventListener("click", say(where, "capture"), { capture: true });
    el.addEventListener("click", say(where, "bubble"));
  }
</script>
```

```
ana@dev:~/js$ page bubble.html --do 'click .lend'
-- click .lend
capture document target=lend
capture ul       target=lend
capture li       target=lend
capture button   target=lend
bubble  button   target=lend
bubble  li       target=lend
bubble  ul       target=lend
bubble  document target=lend
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Um clique no botão Lend viaja em três fases. Na fase de captura ele desce do document, passando por ul e li, até o botão. No botão ele chega ao alvo. Na fase de borbulhamento ele sobe de volta do botão, passando por li e ul, até o document. Um listener roda na fase de borbulhamento a menos que tenha pedido captura.\"><defs><marker id=\"phases-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><defs><marker id=\"phases-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"170\" y=\"14\" width=\"380\" height=\"232\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">document</text><rect x=\"200\" y=\"46\" width=\"320\" height=\"192\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ul#books</text><rect x=\"230\" y=\"78\" width=\"260\" height=\"152\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">li.book</text><rect x=\"290\" y=\"160\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">button.lend</text><path d=\"M110 30 L110 170\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" marker-end=\"url(#phases-ah-phosphor)\"></path><text x=\"100\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">1. captura</text><text x=\"360\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">2. alvo</text><path d=\"M610 170 L610 30\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.8\" marker-end=\"url(#phases-ah-paper)\"></path><text x=\"620\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3. bolha</text></svg>", "caption": "Todo clique visita cada ancestral duas vezes, na descida e na subida."}
```

1. **Captura**: do `document` para baixo, por cada ancestral, até o alvo. Só listeners acrescentados
   com `{ capture: true }` rodam aqui;
2. **alvo**: o elemento que foi clicado, onde os dois tipos de listener rodam;
3. **borbulhamento**: de volta para cima, do alvo até o `document`. **Um listener acrescentado sem
   opções roda aqui**, e é por isso que a maior parte do código nunca pensa em captura.

`target=lend` em toda linha é o ponto: **por mais alto que um listener esteja, `event.target` continua
sendo o botão que foi clicado**. O `currentTarget` é o que muda, dizendo o elemento cujo listener está
rodando.

## Interrompendo a viagem

```html
<!doctype html>
<li class="book">Iracema <button class="lend">Lend</button></li>
<script>
  document.querySelector(".book").addEventListener("click", () => console.log("row opened"));
  document.querySelector(".lend").addEventListener("click", (event) => {
    event.stopPropagation();
    console.log("lent");
  });
</script>
```

```
ana@dev:~/js$ page stop.html --do 'click .lend' --do 'click .book'
-- click .lend
lent
-- click .book
row opened
```

A linha abre quando clicada, e o botão dentro dela empresta o livro. Sem a chamada de
`stopPropagation()`, clicar no botão teria emprestado o livro **e** aberto a linha, porque o clique
teria borbulhado até o listener da linha. Com ela, o primeiro clique imprimiu só `lent`, e a linha
ainda abriu quando foi clicada direto.

**Use `stopPropagation` com parcimônia.** Todo listener acima do elemento perde o evento, inclusive os
que você não escreveu: analytics, um menu que fecha quando você clica fora, o tratamento de um
framework. Conferir `event.target` no listener da linha, o que a próxima seção faz, costuma resolver o
mesmo problema sem esconder o clique de ninguém.
