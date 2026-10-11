---
title: Um slide
version: 1
---

Uma revisão de estratégia ganha um slide, porque a decisão cabe num só. **Todo o resto é anexo**:
existe para responder a perguntas, e só é aberto quando alguém faz uma. O hábito que isso substitui
é o deck que leva a sala pelo trabalho na ordem em que ele foi feito — contexto, arquitetura,
problema, opções, recomendação — e chega à decisão no último slide, quando o tempo e a atenção já
acabaram.

A aula 5 de `architect-communication` ensina como um slide deve funcionar: uma afirmação, dita como
frase completa no título, com a evidência embaixo. Tome isso como dado. O slide de uma estratégia é
um caso particular disso, com um layout que se repete de uma revisão para a outra: **a afirmação no
título, e quatro caixas embaixo dela** — o que está acontecendo, o dinheiro, a decisão pedida e o
que espera.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 420\" role=\"img\" aria-label=\"O layout do slide único do Davi. Um título no alto: corrigir as reservas de assento antes da temporada, R$ 48.000 uma vez contra R$ 364.800 por ano de perda esperada. Quatro caixas embaixo. O que está acontecendo: grandes aberturas falham no código de reserva de assentos, 12 por ano, 8% de chance cada, R$ 380.000 por falha. O dinheiro: uma barra longa para a perda esperada de R$ 364.800 por ano e uma curta para a correção de R$ 48.000, 7,6 vezes menor. A decisão que precisamos hoje: aprovar um time de Reservas de quatro pessoas a partir de 1º de março, vindo do Checkout e de Pagamentos, sem contratar. O que espera um ano: a migração para microsserviços e o novo framework de front-end. Um rodapé: como vamos saber, e uma nota de que a perda esperada é uma média.\"><rect x=\"20\" y=\"20\" width=\"680\" height=\"380\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"52\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">Corrigir as reservas de assento antes da temporada:</text><text x=\"40\" y=\"76\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">R$ 48.000 uma vez, contra R$ 364.800 por ano de perda esperada</text><rect x=\"40\" y=\"100\" width=\"300\" height=\"115\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"54\" y=\"122\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">o que está acontecendo</text><text x=\"54\" y=\"148\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Grandes aberturas falham no código</text><text x=\"54\" y=\"168\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">de reserva de assentos: 12 por ano,</text><text x=\"54\" y=\"188\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">8% de chance cada, R$ 380.000 por falha.</text><rect x=\"360\" y=\"100\" width=\"320\" height=\"115\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"374\" y=\"122\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">o dinheiro</text><rect x=\"374\" y=\"136\" width=\"280\" height=\"24\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"382\" y=\"152\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--ink)\">perda esperada: R$ 364.800 por ano</text><rect x=\"374\" y=\"172\" width=\"37\" height=\"24\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"420\" y=\"188\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a correção: R$ 48.000 uma vez · 7,6× menor</text><rect x=\"40\" y=\"230\" width=\"300\" height=\"115\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"54\" y=\"252\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">a decisão que precisamos hoje</text><text x=\"54\" y=\"278\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Aprovar um time de Reservas de quatro</text><text x=\"54\" y=\"298\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a partir de 1º de março, vindo do</text><text x=\"54\" y=\"318\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Checkout e de Pagamentos. Sem contratar.</text><rect x=\"360\" y=\"230\" width=\"320\" height=\"115\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"374\" y=\"252\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">o que espera um ano</text><text x=\"374\" y=\"278\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">A migração para microsserviços.</text><text x=\"374\" y=\"298\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">O novo framework de front-end.</text><text x=\"40\" y=\"368\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Como vamos saber: nenhuma grande abertura falha nesta temporada, e um teste de carga reproduz uma abertura.</text><text x=\"40\" y=\"387\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">A perda esperada é uma média ao longo de muitos anos, não uma previsão para este.</text></svg>", "caption": "O slide do Davi para a revisão de estratégia. O layout é a lição; as palavras são da Coreto, e as suas seriam as da sua própria estratégia."}
```

## O título é a decisão

Leia o título sozinho e a revisão já está resumida: o que Davi quer que se faça, até quando, e os
dois números que justificam isso. **Se o slide se perdesse e só o título sobrevivesse, Otávio ainda
conseguiria dizer sim ou não a ele.** Esse é o teste para o título de um slide de estratégia, e ele
é mais rigoroso do que "uma frase completa": uma frase pode ser verdadeira e mesmo assim não pedir
nada.

Compare com o título que Davi escreveu primeiro, "Módulo de reservas: situação atual e proposta".
Ele nomeia um assunto. Não diz a Otávio nada de que ele pudesse discordar, o que, como a aula 1
disse sobre uma lista de metas, significa que não escolheu nada.

## As quatro caixas

O que está acontecendo é o diagnóstico da aula 1, cortado para o que um executivo precisa: onde
está a falha, com que frequência, e quanto custa cada uma. Ele tem de continuar conferível, então
leva números em vez de adjetivos.

O dinheiro é a comparação da seção anterior, desenhada em vez de tabelada. Duas barras, uma 7,6
vezes a outra, não precisam de explicação, e um leitor que não olha mais nada no slide vê o
argumento. **Um gráfico, e o que carrega a decisão**; um segundo gráfico é uma segunda afirmação
disputando o mesmo olhar.

A decisão que precisamos hoje é um verbo, um dono e uma data, e na Coreto ela diz o que a decisão
não custa: os quatro engenheiros já trabalham lá. Essa frase responde à primeira pergunta do Otávio
antes que ele a faça, porque um CFO que lê "um time de quatro" lê "quatro salários" até ouvir o
contrário. O que eles custam é o trabalho que deixam de fazer, que é o custo de oportunidade da aula
13.

**O que espera é a lista da aula 3 do que a estratégia não vai fazer**, e está no slide porque é a
metade da decisão que as pessoas esquecem que estão tomando. Aprovar o time é aprovar que a migração
para microsserviços e o framework de front-end esperem um ano. Pôr isso numa caixa faz disso uma
escolha que Otávio e Helena tomam de olhos abertos, em vez de uma surpresa que dois líderes de time
levam a eles em abril.

O rodapé traz como a empresa vai saber se a estratégia está funcionando — aula 3 de novo — e a
ressalva sobre a perda esperada da seção anterior. Os dois são pequenos, e os dois estão ali para
que ninguém possa dizer depois que não foi avisado.

## O que fica de fora

O diagrama de arquitetura, a fila das travas de linha, a lista de todas as dívidas do `coreto-core`,
os planos de sprint. Nada disso está errado, e tudo isso está no anexo. A ideia errada mais comum
sobre um slide para executivos é que ele é o slide técnico simplificado. **É outro slide**, sobre
consequências em vez de mecanismos, e simplificar o mecanismo produz um slide técnico demais para o
CFO e vago demais para a CTO ao mesmo tempo.

## Testar antes que a sala teste

Cubra tudo menos o título e pergunte se a decisão continua ali. Depois mostre o slide inteiro,
rapidamente, a alguém de fora da engenharia — na Coreto, alguém do time do Otávio — e faça uma
pergunta só: o que este slide está pedindo? Se a resposta não for a caixa da decisão, nas palavras
da pessoa, o slide não está pronto. É o teste de repetir de volta da aula 3, aplicado a uma página
com um leitor em vez de uma organização de engenharia inteira.
