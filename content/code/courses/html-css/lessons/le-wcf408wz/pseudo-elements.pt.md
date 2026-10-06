---
title: Partes que não são elementos: pseudo-elementos
version: 1
---

Um **pseudo-elemento** seleciona uma parte de um elemento, ou acrescenta uma, que não tem elemento próprio no HTML. Ele se escreve com dois dois-pontos: `p::first-line`. Aqui estão dois, em `extras.css`:

```css
.featured h2::before { content: "New: "; color: #8a1c1c; }
.note::first-letter { font-weight: bold; }
```

`::before` e `::after` acrescentam uma caixa no começo ou no fim do conteúdo do elemento, e **`content`** diz o que vai nela. Sem uma declaração `content`, eles não existem. Aqui o evento em destaque ganha a palavra *New:* em vermelho na frente do título:

```
ana@laptop:~/site$ probe extras.html style '.featured h2::before' content,color text '.featured h2'
h2::before  content: "New: "
h2::before  color: rgb(138, 28, 28)
h2  "Book swap"
```

O `::before` existe com o conteúdo e a cor, e **o texto do próprio título continua sendo só *Book swap***. Conteúdo gerado não faz parte do documento: é desenhado, não está no DOM, um script lendo o título não o vê, e copiar o texto do título não o copia. Leitores de tela leem a maior parte do texto gerado, e de forma inconsistente. Então a regra é que `::before` e `::after` levam **decoração**, como um ícone, uma aspa ou um divisor, e nunca uma informação de que o leitor precisa; *New:* na verdade está no limite, e uma página que precisa dizer isso deve dizer no HTML.

## O resto

`::first-letter` e `::first-line` estilizam a primeira letra ou a primeira linha de um bloco, que é como se faz uma capitular: a nota da página de eventos ganha a primeira letra em negrito. `::marker` estiliza o marcador ou o número de um item de lista, o marcador que a aula 2 tirou com `list-style: none`. `::placeholder` estiliza o placeholder de um campo, a dica cinza da aula 3. `::selection` estiliza o texto que o leitor selecionou.

Um pseudo-elemento conta na especificidade como um elemento, como a seção 08 mostra, e ele só pode ser o sujeito de um seletor, na ponta direita: `.featured h2::before` está certo, `.featured::before h2` não significa nada.
