---
title: Quando tudo é prioridade
version: 1
---

Na reunião de planejamento do próximo semestre, quatro trabalhos chegam à mesa do Davi, e cada um
chega com a etiqueta de prioridade. Júlia Sato, head de produto, traz o **Pix parcelado**: os
compradores vivem pedindo para dividir um ingresso em parcelas mensais no Pix, e o time de vendas
ouve isso toda semana. Os organizadores de festivais querem **mapas de assentos para festivais**,
para que o comprador escolha um lugar num gramado do jeito que escolhe uma poltrona num teatro.
Revendedores de ingressos esperam uma **API de parceiros** para vender o estoque da Coreto nos
próprios sites. E o Davi tem a **correção das reservas**, a fatia primeira e mais urgente da dívida a
que as aulas 1 e 5 voltaram tantas vezes: a mudança que impede uma reserva de assento de bloquear
linhas durante uma abertura de vendas.

Os quatro precisam das mesmas pessoas. Todos mexem no caminho do checkout e das reservas, e os
engenheiros que conhecem esse caminho bem o bastante para mudá-lo com segurança são um grupo só.
**A pergunta não é qual dos quatro importa**, porque todos importam. É em que ordem fazê-los, e essa é
uma pergunta diferente, com outro tipo de resposta.

## Três jeitos como a reunião costuma decidir

**Algumas reuniões decidem pela importância.** Cada patrocinador argumenta que o seu item é o mais
importante, e o item com o patrocinador mais graduado ou mais insistente vai primeiro. Importância
não ordena uma fila, porque todo item na sala é importante para alguém; foi assim que ele chegou à
sala.

**Algumas decidem pelo cliente que reclama mais alto.** Vai primeiro o item de que alguém reclamou
por último. Uma reclamação recente é evidência de um custo, e não é medida do tamanho dele: os
compradores que pediram o Pix parcelado estão à vista, e as casas que perdem aberturas de vendas em
silêncio por causa do código das reservas não estão.

**E algumas fazem os quatro ao mesmo tempo.** Ninguém precisa perder, então o grupo se divide em
quatro e cada item recebe uma parte das pessoas. É a resposta mais popular e a mais cara, e a conta
mostra por quê.

## Por que "tudo ao mesmo tempo" custa mais

Os quatro itens somam 25 semanas do tempo do grupo: 6, 12, 3 e 4. Feitos um depois do outro, o
primeiro fica pronto em poucas semanas e começa a render; o último espera até a semana 25. Rode os
quatro em paralelo, cada um com a sua parte das pessoas, e **os quatro terminam juntos, na semana
25**. Nenhum entrega nada até o finalzinho.

Cada semana em que um item não está pronto custa alguma coisa à Coreto — a próxima seção põe reais
nisso — e os quatro juntos custam R$ 108.000 por semana enquanto esperam. Em paralelo, os
R$ 108.000 inteiros correm pelas 25 semanas: R$ 2.700.000 de atraso (108.000 × 25). A seção
depois da próxima compara três ordens, e a mais cara delas chega a R$ 1.794.000; feitos um de cada
vez, todos os itens menos o último terminam antes da semana 25, então qualquer ordem custa menos do
que rodá-los juntos. **Dividir o time em quatro é o jeito mais caro de fazer o mesmo trabalho**, e o
custo real é ainda maior, porque alternar entre quatro trabalhos deixa todo mundo mais lento, que é
o assunto da aula 4 de delivery-metrics.

## A pergunta que ordena uma fila

Dois fatos sobre cada item decidem o seu lugar, e nenhum deles é a importância:

| fato | a pergunta | quem sabe melhor |
|---|---|---|
| custo de atraso | quanto custa à Coreto cada semana em que isto não está pronto? | produto e o negócio, com a engenharia conferindo |
| duração | quantas semanas do tempo do grupo isto vai levar? | engenharia |

Você já viu esse par. A aula 12 de process-management apresentou o custo de atraso, os quatro
perfis de urgência e o WSJF, que divide o custo de atraso pelo tamanho, e estimou os dois em pontos
relativos. **Esta aula faz a mesma conta em reais e semanas.** O dinheiro acrescenta duas coisas que
os pontos não dão: o custo de uma ordem inteira pode ser somado e comparado com outra ordem, e o
resultado pode ficar ao lado de qualquer outra coisa em que a empresa gasta dinheiro, como as linhas
do orçamento da aula 11.

A próxima seção estima o custo de atraso dos quatro itens da Coreto.
