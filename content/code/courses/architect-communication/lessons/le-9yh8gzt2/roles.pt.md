---
title: Piloto e navegador
version: 1
---

**Programação em par é duas pessoas trabalhando numa tarefa diante de uma tela, uma digitando e a
outra pensando adiante, trocando de papel com frequência.** A imagem que a maioria tem é a de um
engenheiro sênior olhando um júnior digitar e corrigindo cada passo. É a versão menos útil, e é ela
que dá ao pareamento a fama de ser exaustivo.

## Os dois papéis

- O **piloto** fica com o teclado e cuida da linha à sua frente: a sintaxe, o próximo teste, o nome
  desta variável.
- O **navegador** trabalha um nível acima: para onde essa função vai, quais são os próximos três
  passos, o que pode quebrar, se o teste está testando a coisa certa. O navegador não dita teclas.

**Eles trocam a cada quinze a trinta minutos**, ou num ponto natural, como cada teste que passa. Um
par que nunca troca é uma pessoa programando e outra assistindo, e a atenção de quem assiste se
dispersa em poucos minutos.

## Pareamento no estilo forte

Llewellyn Falco, que ensina pareamento e mob programming, descreve uma versão mais rígida que ele
chama de pareamento *strong-style*, ou no estilo forte, resumida numa regra: **"para uma ideia ir da
sua cabeça para o computador, ela tem de passar pelas mãos de outra pessoa".** Quem tem a ideia
navega; a outra pessoa digita.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Três caixas da esquerda para a direita: o navegador, que tem a ideia e fala; o piloto, que tem o teclado e digita; o código. Abaixo, a regra de Llewellyn Falco: para uma ideia ir da sua cabeça para o computador, ela tem de passar pelas mãos de outra pessoa.\"><defs><marker id=\"strongstyl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"190\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"115\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\">navegador</text><text x=\"115\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tem a ideia,</text><text x=\"115\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fala</text><rect x=\"265\" y=\"50\" width=\"190\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\">piloto</text><text x=\"360\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tem o teclado,</text><text x=\"360\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">digita</text><rect x=\"510\" y=\"50\" width=\"190\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"605\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">o código</text><path d=\"M212 95 L262 95\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#strongstyl-ah)\"></path><path d=\"M457 95 L507 95\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#strongstyl-ah)\"></path><text x=\"20\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">\"para uma ideia ir da sua cabeça para o computador, ela tem de passar pelas mãos de outra pessoa\"</text><text x=\"20\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Llewellyn Falco</text></svg>", "caption": "Programação em par no estilo forte. Quem tem a ideia nunca a digita, então um sênior com uma ideia precisa explicá-la bem o bastante para as mãos do júnior.", "same": ["Llewellyn Falco"]}
```

Parece uma mudança pequena, e ela inverte o padrão de sempre. Quando a ideia é do sênior, o júnior
pilota: as mãos do júnior aprendem a mudança, e o sênior precisa explicar a ideia bem o bastante para
outra pessoa digitá-la. Quando a ideia é do júnior, o sênior pilota e tem de segui-la. É o jeito mais
rápido de uma pessoa sênior ouvir uma ideia que, de outro modo, ela teria atropelado.

## Conversar é o trabalho

Um par em silêncio não está pareando. O navegador pensa em voz alta ("acho que vamos precisar do
horário de fechamento aqui, mas primeiro vamos fazer o teste passar"), e o piloto diz o que está
fazendo quando não é óbvio. **A conversa é onde a transferência de conhecimento acontece**, a mesma
descoberta do estudo sobre revisão da aula 11, só que em tempo real em vez de em comentários.

Isso também explica por que parear cansa. Duas pessoas se concentrando em voz alta por duas horas
gastam mais esforço do que uma pessoa concentrada em silêncio, e pares que tentam parear oito horas
por dia se esgotam. A maioria dos times que pareiam bem faz isso algumas horas por dia, com pausas, e
não em toda tarefa.
