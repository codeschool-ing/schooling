---
title: Dos dados a um modelo
version: 1
---

Uma **distribuição de probabilidade** é uma regra que diz quão provável é cada valor possível de alguma
coisa, antes de você vê-lo. É a contraparte de um histograma no mundo dos modelos: um histograma descreve
valores que aconteceram, uma distribuição descreve valores que podem acontecer.

A coisa cujo valor é incerto se chama **variável aleatória**. Quantas das dez entregas de hoje à noite vão
atrasar? Quantas reclamações vão chegar amanhã? Quanto vai pesar o próximo saco de arroz? Cada pergunta tem
uma variável aleatória por trás, e cada tipo de variável aleatória tem um tipo de distribuição que serve
para ela.

## Discreta: uma probabilidade para cada valor

Quando a variável aleatória é uma contagem — entregas atrasadas, reclamações — ela assume valores
separados, 0, 1, 2 e assim por diante, e a distribuição dá a cada um deles uma probabilidade. As
probabilidades ficam todas entre 0 e 1 e **somam 1**, porque algum dos valores precisa acontecer.

Uma distribuição assim se desenha em barras, uma por valor, e a altura de cada barra é uma probabilidade,
não uma contagem.

## Contínua: probabilidade é área

Quando a variável aleatória é uma medida — um peso, um tempo — ela pode assumir qualquer valor numa faixa,
e a chance de um valor exato qualquer é zero. A chance de um saco pesar exatamente 1003,000000 g é nula,
porque há infinitos pesos perto dele.

Então uma distribuição contínua se desenha como uma curva chamada **densidade**, e **uma probabilidade é
uma área sob essa curva**. A chance de um saco pesar menos de 995 g é a área sob a curva à esquerda de 995.
A área inteira sob a curva é 1.

A altura de uma curva de densidade não é uma probabilidade. Ela diz onde os valores se amontoam, como a
altura de uma barra de histograma, mas só uma área entre dois pontos responde uma pergunta do tipo "quão
provável é o valor cair entre aqui e ali?".

## Para que um modelo

Um modelo é uma simplificação, e o valor dele está no que ele permite fazer.

- Ele **responde perguntas que os dados nunca fizeram**. Sessenta dias de reclamações podem nunca ter
  produzido um dia com sete; um modelo diz com que frequência se deve esperar um dia assim.
- Ele **comprime**. Uma distribuição inteira descrita por um ou dois números — uma média, um desvio
  padrão, uma taxa — pode ser comparada, informada e usada num raciocínio.
- Ele **torna a inferência possível**. As aulas 11 a 16 se apoiam em conhecer a distribuição de uma
  estatística, e essa distribuição é quase sempre um dos modelos desta aula.

Um modelo vale tanto quanto o seu ajuste aos dados. A última seção desta aula trata de conferir isso.
