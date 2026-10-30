---
title: ScrollView, porque uma tela não rola sozinha
version: 1
---

**Uma página web rola quando o conteúdo é mais alto que a janela. Uma tela de celular não.** O conteúdo
que passa do fim de uma `View` é simplesmente cortado, sem barra de rolagem e sem gesto para alcançá-lo.
Rolar é um componente, a `ScrollView`, e tudo o que pode crescer além da altura da tela vai dentro de uma.

## O que ela faz

A `ScrollView` é uma `View` cujo conteúdo pode ser mais alto (ou, com `horizontal`, mais largo) que ela.
Ela vira uma scroll view nativa, então o embalo, o quique nas bordas no iOS e o brilho de fim de rolagem no
Android são os da própria plataforma, sem código nenhum seu.

Duas props de estilo, e a diferença entre elas confunde todo mundo uma vez:

| prop | se aplica a | use para |
|---|---|---|
| `style` | a própria scroll view, a janela por onde você olha | o tamanho e o fundo dela |
| `contentContainerStyle` | a view interna que guarda os filhos, que é o que se move | padding, espaços e alinhamento do conteúdo |

Padding em `style` é padding em volta da janela, e o conteúdo rola por baixo dele. Padding em
`contentContainerStyle` é padding em volta do conteúdo, e rola junto com ele, que é quase sempre o que se
queria. A tela do planner usa o segundo.

## O que ela custa

**Uma ScrollView renderiza todos os filhos, de uma vez**, esteja cada um na tela ou dois mil pixels abaixo
dela. Para uma tela de algumas dezenas de elementos, isso está exatamente certo: tudo fica pronto, e a
rolagem nunca precisa esperar. Para uma lista de centenas de itens, não, porque cada um deles é criado
como view nativa antes de a tela aparecer pela primeira vez. A aula 7 é sobre o componente feito para isso,
a `FlatList`, que cria só o que está perto da tela; os três cursos do planner ainda não precisam dela.

## O teclado e a rolagem

Um campo de texto perto do fim de uma `ScrollView` fica coberto pelo teclado quando ele abre, que é o
assunto da aula 11. O `keyboardShouldPersistTaps="handled"` deve estar em toda `ScrollView` que guarda um
formulário: sem ele, o primeiro toque num botão com o teclado aberto só fecha o teclado, e o botão precisa
ser apertado duas vezes. É um daqueles padrões certos para leitura e errados para formulários.
