---
title: Duas perguntas, e o que as responde
version: 1
---

Quem responde por um time ouve duas perguntas mais do que qualquer outra: **"quando fica pronto?"** e **"como estamos indo?"** A maioria dos times responde as duas com uma opinião. A opinião costuma vir de boa-fé, de alguém perto do trabalho, e costuma errar sempre para o mesmo lado: as coisas demoram mais do que acredita quem está mais perto delas.

Este curso responde as duas com outra coisa: **o registro que o time já guarda**. Um quadro registra quando cada item começou e quando terminou. Um pipeline registra cada deploy e se ele falhou. Uma ferramenta de incidentes registra quando um problema começou e quando acabou. Nada neste curso pede que um time colete um tipo novo de dado. Pede que leia o que já tem, e que pare de responder de memória.

## O que o curso cobre

As vinte aulas se dividem em cinco partes, e cada parte se apoia na anterior.

| aulas | o assunto | a pergunta que responde |
|---|---|---|
| 1 a 4 | **fluxo**: trabalho em andamento, tempo de ciclo, fluxo cumulativo, limites | para onde vai o tempo? |
| 5 a 8 | **as quatro métricas DORA**, o que elas não veem e como são manipuladas | quão boa é a nossa entrega? |
| 9 a 12 | **previsão**: estimativas, Monte Carlo, roadmaps, capacidade | quando fica pronto? |
| 13 a 18 | **incidentes e plantão**: severidade, comando, postmortems, orçamentos de erro, o pager | o que acontece quando quebra? |
| 19 e 20 | **relatórios**, e para que os números podem servir | o que dizemos para quem está acima de nós? |

O curso supõe `process-management`, então quadro, limite de trabalho em andamento e story point não são explicados de novo. O que aquele curso apresentou numa aula, este mede em vinte.

## O time que você vai medir

Todo número do curso vem de um time, e **o time não existe**. É o time de Billing de uma empresa que vende um sistema de ponto de venda para lojas pequenas: cinco devs, Caio, Duda, Inês, Rafa e Téo, e uma tech lead, Bia. Eles cuidam de faturas, cobranças no cartão e do extrato mensal, o que quer dizer que, quando quebram alguma coisa, um lojista é cobrado duas vezes.

O histórico deles vai de 1º de junho a 30 de setembro de 2026, e quem o escreve é um programa curto que você vai rodar no seu computador na quinta seção desta aula. O programa simula o quadro do time um dia útil por vez, com números aleatórios fixos, então a sua cópia do histórico é idêntica à que as aulas citam. Como o time é simulado, você também pode mudar o jeito como ele trabalha e ver o que acontece com os números, e a aula 4 pede exatamente isso.

Em junho e julho o time trabalhou como muitos times trabalham. Cada dev mantinha até três itens abertos e alternava entre eles, e a Bia revisava tudo antes da integração. Em **3 de agosto** eles mudaram duas regras: um item por dev, e revisar o trabalho de um colega vem antes de começar qualquer coisa nova. Boa parte do curso é sobre o que essa mudança fez, o que não fez, e como você saberia.

## Por que histórico ganha de opinião

Um histórico não é um palpite melhor. É outro tipo de resposta. Uma estimativa diz o que alguém espera; um histórico diz o que o sistema de fato produziu, incluindo cada interrupção, cada revisão que esperou um dia e cada item que acabou tendo o dobro do tamanho que todo mundo achava. **Nada disso está numa estimativa, e tudo isso está nas datas.**

Esse também é o limite do método. Um histórico descreve o sistema que o produziu. Se o time muda o jeito de trabalhar, o histórico antigo descreve um time que não existe mais, e o 3 de agosto do time de Billing é exatamente esse tipo de mudança. Saber que parte do registro ainda vale é metade da habilidade, e isso começa nesta aula.
