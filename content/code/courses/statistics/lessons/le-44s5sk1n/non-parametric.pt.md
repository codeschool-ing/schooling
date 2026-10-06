---
title: Testes construídos sobre postos
version: 1
---

Os testes t e a ANOVA comparam médias e supõem que as médias se comportam como o teorema central do limite
diz. Com amostras grandes isso costuma ser seguro. Com amostras pequenas de dados assimétricos ou de caudas
pesadas, pode não ser, e um único valor atípico pode mover uma média, e com ela uma estatística t, para
muito longe.

Os testes **não paramétricos** evitam a questão trocando os valores pelos seus **postos**: o menor valor
recebe o posto 1, o seguinte o posto 2, e assim por diante, com valores empatados dividindo a média dos
postos. Postos ignoram quão afastados os valores estão, então um valor atípico é só o maior posto, por mais
extremo que seja.

## Os três mais usados

| em vez de | use | compara |
|---|---|---|
| t de Welch, dois grupos | o teste de Mann-Whitney | se os valores de um grupo tendem a ser maiores |
| o t pareado | o teste de postos sinalizados de Wilcoxon | se as diferenças tendem a ser positivas ou negativas |
| ANOVA | o teste de Kruskal-Wallis | se algum grupo tende a ter valores maiores |

## Nos dados da Horta

**Centro contra Cambuí, Mann-Whitney**: p bilateral = **0,21**. Mesma conclusão que os 0,28 de Welch:
nenhuma diferença clara.

**O curso de rotas, postos sinalizados de Wilcoxon**: p = **0,047**, contra os 0,046 do teste t pareado. Oito
dos dez entregadores ficaram mais rápidos, e os postos das mudanças deles concordam.

**Os quatro bairros, Kruskal-Wallis**: H = 83,5 com 3 graus de liberdade, p cerca de 6 × 10⁻¹⁸. Mesma
conclusão que a ANOVA.

Nestes dados os testes de postos e os de médias concordam, que é o resultado usual quando os dados se
comportam razoavelmente bem. Eles discordam quando valores atípicos ou assimetria forte comandam as médias.

## Quando preferir postos

- **Amostras pequenas de dados assimétricos**, em que o teorema central do limite ainda não fez o trabalho
  dele.
- **Dados ordinais**, como notas em estrelas, em que a aula 2 avisou que médias se apoiam numa suposição.
- **Valores atípicos reais** que não devem dominar a conclusão.

## O preço deles

Testes de postos respondem uma pergunta um pouco diferente — se um grupo tende a ter valores maiores, em vez
de se as médias diferem — e não vêm com um intervalo de confiança simples para o tamanho de uma diferença nas
unidades originais. Quando os dados se comportam bem, eles têm um pouco menos de poder que o teste t. São uma
rede de segurança, não um substituto, e informar os dois, quando concordam, é uma conferência que
tranquiliza.
