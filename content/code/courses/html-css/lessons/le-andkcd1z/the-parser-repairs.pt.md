---
title: O que o navegador faz com HTML quebrado
version: 2
---

O parser de HTML do navegador nunca para com um erro. É uma decisão deliberada, escrita no padrão do HTML: para toda sequência possível de caracteres, o padrão diz exatamente que árvore o parser deve montar. Então HTML quebrado não derruba nada. **Ele é consertado, por regras que você não escolheu**, e a árvore consertada é o que o navegador desenha e o que todo script e toda folha de estilos enxergam.

Aqui está uma página com três erros comuns: um `<b>` que nunca é fechado no seu parágrafo, um `</b>` e um `</i>` fechados na ordem errada, e uma `<div>` dentro de um parágrafo. Salve-a como `broken.html`.

```html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Opening hours</title>
</head>
<body>
<p>We are open <b>every day
<p>Closed on <i>public holidays</b></i>
<p>Our shop: <div>Rua dos Pinheiros, 1000</div>
</body>
```

Abra e ela parece certa: três linhas sobre horários de funcionamento. Aqui está a árvore que o navegador de fato montou, impressa por `probe dom`:

```
ana@laptop:~/site$ probe broken.html dom
<html lang="en"><head>
<meta charset="utf-8">
<title>Opening hours</title>
</head>
<body>
<p>We are open <b>every day
</b></p><p><b>Closed on <i>public holidays</i></b>
</p><p>Our shop: </p><div>Rua dos Pinheiros, 1000</div>

</body></html>
```

Leia contra o arquivo e saem três consertos.

**O `<b>` não fechado vazou para o parágrafo seguinte.** O arquivo abre `<b>` no primeiro parágrafo e nunca o fecha ali. Quando o segundo `<p>` começa, o parser fecha o primeiro parágrafo, e com ele o `<b>`, e reabre um `<b>` novo dentro do parágrafo novo, porque o negrito ainda estava "ligado". Então *Closed on public holidays* fica em negrito, o que o autor nunca escreveu.

**O `</b></i>` mal aninhado foi desembaraçado.** O parser fechou o `<i>` dentro do `<b>`, que é o único aninhamento que a árvore consegue guardar.

**A `<div>` partiu o parágrafo em dois.** Um parágrafo não pode conter um bloco como `<div>`, então quando o parser encontra uma, ele fecha o `<p>` antes. *Our shop:* é um parágrafo e o endereço é uma `<div>` depois dele, irmã e não filha. Qualquer CSS escrito para "o endereço dentro do parágrafo" não encontra nada, e o autor não faz ideia do porquê.

## O conserto que esvazia a página

A maioria dos consertos é como esses: a página parece quase certa. Um não é. Salve uma cópia como `unclosed-title.html` com uma única mudança: o título não tem tag de fechamento.

```html
<title>Opening hours
</head>
```

```
ana@laptop:~/site$ probe unclosed-title.html title box body
title: "Opening hours </head> <body> <p>We are open <b>every day <p>Closed on <i>public holidays</b></i> <p>Our shop: <div>Rua dos Pinheiros, 1000</div> </body>"
body  x 8      y 8      width 1008   height 0
```

**A página está em branco.** O body tem 0 pixel de altura. Dentro de `<title>` o parser não procura tag nenhuma: tudo até encontrar os caracteres `</title>` é texto, porque um título não pode conter elementos. Ele nunca os encontra, então o resto inteiro do arquivo, tags incluídas, virou o título. A aba do navegador mostra um título comprido cheio de sinais de menor e maior, e a janela não mostra nada.

`<title>` não é o único elemento que lê assim. `<textarea>`, `<style>` e `<script>` também, e é por isso que um `<textarea>` não fechado num formulário engole todos os campos depois dele.

## O que tirar disso

Não dá para ver consertos olhando para a página, porque a página consertada é o que você vê. Duas ferramentas os mostram. **O painel Elements do DevTools mostra a árvore, não o arquivo**, então uma `<div>` que você escreveu dentro de um `<p>` aparece depois dele ali, e essa diferença entre o que você digitou e o que você vê é a pista. E um validador, seção 13, lê o próprio arquivo e aponta cada lugar onde o parser teve de adivinhar.
