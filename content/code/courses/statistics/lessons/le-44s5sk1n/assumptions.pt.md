---
title: O que todo teste supõe
version: 1
---

Um p-valor vale tanto quanto as suposições por trás dele. Os testes desta aula compartilham uma lista curta,
e conferi-la faz parte de rodá-los.

## Independência

Todo teste aqui supõe que as observações são **independentes**: o tempo de uma entrega não diz nada sobre o
de outra, além do que os grupos explicam. Essa é a suposição que mais importa e que nenhuma fórmula consegue
conferir.

Ela quebra de jeitos reconhecíveis. Entregas na mesma noite de chuva são lentas juntas. O mesmo cliente
aparecendo muitas vezes numa amostra conta como várias observações de uma pessoa. Medidas tiradas uma depois
da outra derivam juntas. Quando os dados têm uma estrutura assim, um teste que a ignora informa mais
certeza do que os dados têm. O teste pareado é o exemplo mais simples de usar a estrutura em vez de
ignorá-la.

## Forma

Os testes t e a ANOVA supõem médias aproximadamente normais, o que pelo teorema central do limite vale para
amostras grandes o bastante e, para amostras pequenas, exige que os próprios dados sejam mais ou menos
simétricos e sem valores atípicos extremos. As ferramentas da aula 7 são a conferência: um histograma ou um
boxplot de cada grupo. Quando a forma é duvidosa e a amostra pequena, use o teste baseado em postos, ou
informe os dois.

## Dispersão

O teste t com dispersões iguais e a ANOVA clássica supõem que os grupos têm desvios padrão parecidos. O teste
t de Welch abandona essa suposição, e por isso é o padrão para dois grupos. Para vários grupos com dispersões
muito diferentes, existe também uma versão de Welch da ANOVA, e o teste baseado em postos é outra opção.

## Contagens esperadas

O teste qui-quadrado precisa de contagens esperadas de uns 5 ou mais em cada célula. Para tabelas menores, o
**teste exato de Fisher** calcula o p-valor direto das contagens, sem a aproximação.

## A ordem do trabalho

1. Olhe os dados: boxplots por grupo, ou a tabela de contagens.
2. Confira a independência pensando em como os dados foram coletados.
3. Escolha o teste pelas duas perguntas da primeira seção desta aula.
4. Rode-o e, se uma suposição for duvidosa, rode a alternativa também e veja se a conclusão muda.

Um teste que sobrevive a essa ordem é um teste em que quem lê pode confiar. Um teste escolhido porque deu o
menor p-valor é o jardim dos caminhos que se bifurcam da aula 14, com outro portão.
