---
title: Elementos pelas relações entre eles
version: 2
---

A seção 07 da aula 1 nomeou as relações na árvore: pai, filho, irmão, descendente. **Combinadores** são como um seletor as usa. São quatro:

| combinador | escrito | quer dizer |
| --- | --- | --- |
| descendente | `main p` | um `p` em qualquer lugar dentro de um `main`, em qualquer profundidade |
| filho | `main > p` | um `p` cujo pai é o `main` |
| irmão seguinte | `h2 + p` | o `p` logo depois de um `h2`, com o mesmo pai |
| irmãos posteriores | `h2 ~ p` | todo `p` depois de um `h2`, com o mesmo pai |

A diferença entre os dois primeiros é a que morde. Na página de eventos:

```
ana@laptop:~/site$ probe events.html match 'main p' match 'main > p'
main p  matches 5
  p.intro  "Everything here is free unless it s…"
  p  "Thursday 8 October, 7 pm."
  p.note  "Bring a poem of your own."
  p  "Saturday 10 October, from 10 am."
  p  "Cancelled: the teacher is ill."
main > p  matches 1
  p.intro  "Everything here is free unless it s…"
ana@laptop:~/site$ probe events.html match 'h2 + p' match 'h2 ~ p'
h2 + p  matches 3
  p  "Thursday 8 October, 7 pm."
  p  "Saturday 10 October, from 10 am."
  p  "Cancelled: the teacher is ill."
h2 ~ p  matches 4
  p  "Thursday 8 October, 7 pm."
  p.note  "Bring a poem of your own."
  p  "Saturday 10 October, from 10 am."
  p  "Cancelled: the teacher is ill."
```

`main p` encontrou **cinco** parágrafos: o de introdução, que é filho do `<main>`, e os quatro dentro dos articles, que são netos. `main > p` encontrou **um**, o de introdução, porque só ele tem o `<main>` como pai; os outros têm um `<article>` como pai.

`h2 + p` encontrou o primeiro parágrafo depois de cada título: três, um por article. `h2 ~ p` encontrou todo parágrafo depois de um título dentro do mesmo article, então acrescentou *Bring a poem of your own*, que segue o título com outro parágrafo no meio.

## Lendo um seletor da direita para a esquerda

Um seletor é mais fácil de ler de trás para frente. `.event > p.note` é "um parágrafo com a classe `note`, cujo pai é algo com a classe `event`". A parte da direita, o **sujeito**, é o que recebe o estilo; tudo à esquerda é uma condição sobre o entorno. Os navegadores casam seletores do mesmo jeito, pela direita, e é por isso que uma corrente comprida à esquerda custa pouco.

**Mantenha os seletores curtos.** `main article.event p.note` e `.note` selecionam o mesmo elemento nesta página; o primeiro quebra no dia em que a nota sai de um article, e é mais difícil de sobrescrever, pelo motivo da seção 08. Um seletor deve dizer o necessário para escolher os elementos certos, e nada mais.
