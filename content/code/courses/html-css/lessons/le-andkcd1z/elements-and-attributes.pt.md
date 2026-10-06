---
title: Elementos, tags e atributos
version: 1
---

Um arquivo HTML é texto, e o texto é de dois tipos: **conteúdo**, que é o que o leitor lê, e **marcação**, que diz o que o conteúdo é. A marcação se escreve em tags, e vale acertar exatamente o vocabulário para falar delas, porque o resto do curso o usa o tempo todo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 206\" role=\"img\" aria-label=\"Um elemento de link, &lt;a href=&quot;events.html&quot; class=&quot;nav&quot;&gt;Events&lt;/a&gt;, desmontado. A tag de abertura traz o nome do elemento e dois atributos, cada um com nome, sinal de igual e valor entre aspas. A palavra Events é o conteúdo. A tag de fechamento repete o nome depois de uma barra. Tudo junto é o elemento.\"><rect x=\"20\" y=\"42\" width=\"680\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"60\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\">&lt;a</text><text x=\"96\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--amber)\">href</text><text x=\"144\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\">=</text><text x=\"156\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\">&quot;events.html&quot;</text><text x=\"324\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--amber)\">class</text><text x=\"384\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\">=</text><text x=\"396\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\">&quot;nav&quot;</text><text x=\"456\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\">&gt;</text><text x=\"468\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\">Events</text><text x=\"540\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\">&lt;/a&gt;</text><path d=\"M60 100 v8 H468 v-8\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"264\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tag de abertura</text><text x=\"264\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nome e atributos</text><path d=\"M468 100 v8 H540 v-8\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"504\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">conteúdo</text><path d=\"M540 100 v8 H588 v-8\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><line x1=\"564\" y1=\"110\" x2=\"564\" y2=\"136\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"564\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tag de fechamento</text><path d=\"M96 40 v-6 H312 v6\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><text x=\"204\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">atributo: nome=&quot;valor&quot;</text><path d=\"M324 40 v-6 H456 v6\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><text x=\"390\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">atributo</text><path d=\"M60 166 v8 H588 v-8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><text x=\"324\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">o elemento: tudo do primeiro &lt; ao último &gt;</text></svg>", "caption": "Um elemento é a coisa inteira; uma tag é só uma das pontas."}
```

**Uma tag** é o que se escreve entre sinais de menor e maior. `<a href="events.html">` é uma tag de abertura e `</a>` é a tag de fechamento correspondente, o mesmo nome depois de uma barra.

**Um elemento** é a coisa inteira: a tag de abertura, a tag de fechamento e tudo o que está entre elas. "O elemento de link" quer dizer todo o `<a href="events.html" class="nav">Events</a>`, incluindo a palavra *Events*. As pessoas dizem "a tag `a`" querendo dizer o elemento o tempo todo, e numa conversa ninguém se importa; quando a diferença importa, e nesta aula importa, o elemento é a coisa na árvore e as tags são como ele foi escrito.

**Um atributo** é uma informação a mais escrita dentro da tag de abertura, como um nome, um sinal de igual e um valor entre aspas: `href="events.html"` diz ao link para onde ele vai, `class="nav"` dá a ele um nome pelo qual o CSS o encontra. Um elemento pode ter vários, em qualquer ordem, separados por espaços. Alguns atributos não precisam de valor nenhum, porque estar ali já é a informação: `<input required>` é um campo obrigatório, e escrever `required="false"` continuaria tornando-o obrigatório, já que o navegador só verifica se o atributo está presente.

## Elementos dentro de elementos

Elementos se aninham, e a regra do aninhamento é rígida: **um elemento fecha antes de o pai dele fechar**. Isto está certo, porque o `<em>` abre e fecha dentro do `<p>`:

```html
<p>Open <em>every</em> day.</p>
```

Isto está errado, porque o `<em>` continua aberto quando o `<p>` fecha:

```html
<p>Open <em>every day.</p></em>
```

O navegador mostra o segundo sem reclamar, e a seção 07 mostra o que ele monta a partir de uma marcação assim. Essa tolerância é a razão de um erro desses sobreviver por anos num site de verdade.

## Elementos sem nada dentro

Alguns elementos não podem ter conteúdo, então não têm tag de fechamento. Eles se chamam **elementos vazios** (*void elements*), e são poucos os que você vai encontrar com frequência: `<img>` para uma imagem, `<input>` para um campo de formulário, `<br>` para uma quebra de linha, `<hr>` para uma quebra temática, e `<meta>` e `<link>` no head. Você pode vê-los escritos `<img />`, com uma barra antes do sinal de maior; é um hábito herdado do XHTML que o HTML tolera e ignora, e este curso não usa.

## Caracteres que significam algo

Como `<` começa uma tag, uma página que precisa mostrar um sinal de menor literal tem de escrevê-lo de outro jeito: `&lt;`. São as **referências de caractere**, e quatro valem a pena saber: `&lt;` para `<`, `&gt;` para `>`, `&amp;` para `&` e `&quot;` para aspas duplas dentro do valor de um atributo. Uma página que lista *Pride & Prejudice* escreve o e comercial como `&amp;` no HTML, e o leitor vê `&`. Qualquer outro caractere, um `ã` ou um `€`, você simplesmente digita, desde que o arquivo declare que é UTF-8, o que é a seção 08.

O HTML não diferencia maiúsculas de minúsculas nos nomes dos elementos, então `<P>` e `<p>` são o mesmo elemento. Escreva em minúsculas: todo guia de estilo faz assim, e o resto deste curso também.
