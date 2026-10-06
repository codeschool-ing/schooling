---
title: Texto que significa algo
version: 1
---

Dentro de um parágrafo, um punhado de elementos diz o que uma palavra ou uma expressão é. A maioria é desenhada de um jeito que você reconheceria, itálico, negrito ou monoespaçado, e esse desenho é um padrão, como o tamanho de um título. O elemento se escolhe pelo significado.

**Ênfase e importância.** `<em>` é ênfase de entonação, a palavra que você diria mais alto: *abrimos **todo** dia*. `<strong>` é importância, a parte que o leitor não pode perder: um aviso, um prazo. Os primos mais velhos, `<i>` e `<b>`, continuam no HTML com significados mais estreitos: `<i>` para texto em outra voz, como o título de um livro ou uma palavra em outra língua, e `<b>` para uma palavra-chave desenhada em negrito sem importância extra. O título de um romance na lista do sebo é `<i>`; *fechado no domingo* num aviso é `<strong>`.

```html
<p>We are <em>always</em> closed on Sunday.</p>
<p><strong>Orders placed after 5 pm ship the next day.</strong></p>
<p>This week: <i>Grande Sertão: Veredas</i>, first edition.</p>
```

**Datas e horas.** `<time>` envolve uma data escrita para pessoas, e o atributo `datetime` dele carrega o mesmo momento escrito para programas, num formato fixo: `<time datetime="2026-10-08T19:00">Thursday 8 October, 7 pm</time>`. Uma extensão de calendário ou um buscador lê o atributo; o leitor lê as palavras. Os eventos da página inicial usaram isso, e a árvore os marcou como **time**.

**Código, teclas e saída.** `<code>` para um trecho de código, `<kbd>` para algo que o usuário digita ou uma tecla que aperta, `<samp>` para o que um programa imprimiu. O próprio texto deste curso está cheio do primeiro.

**Citações.** `<blockquote>` para uma citação destacada como bloco, `<q>` para uma dentro de uma frase (o navegador acrescenta as aspas) e `<cite>` para o título da obra citada ou mencionada.

**Abreviações e endereços.** `<abbr title="Hypertext Markup Language">HTML</abbr>` expande uma abreviação, embora o atributo `title` não apareça para quem usa toque ou teclado, então o primeiro uso no texto ainda deve vir por extenso. `<address>` é a informação de contato do dono da página ou do autor de um artigo; não é para qualquer endereço postal que apareça no texto.

## Quebras de linha e espaçamento não são marcação

`<br>` é uma quebra de linha que pertence ao conteúdo, como os versos de um poema ou as linhas de um endereço postal. Usar várias delas para abrir espaço entre parágrafos põe layout dentro do HTML, e isso é CSS: a aula 6 trata de margens. **Parágrafos vazios e `&nbsp;` para espaçar são o mesmo erro**, e ainda fazem um leitor de tela anunciar linhas em branco.
