---
title: ECE e o escore de Brier
version: 1
---

Um diagrama serve para olhar. Para comparar dois prompts, ou para acompanhar a calibração de uma
versão para a seguinte, você quer um número. O `pl calibrate` imprime dois no pé da tabela, e eles
medem coisas diferentes.

## Erro esperado de calibração

**O ECE é a distância média entre o que foi dito e o que aconteceu**, ponderada por quantas
respostas cada faixa tem. Para cada faixa, pegue a distância entre a média da confiança declarada e
a acurácia, ignore o sinal e multiplique pela fração que a faixa tem do total de respostas. Some as
faixas.

Calcule a faixa de 0,7 a 0,8 da tabela da seção anterior: 7 respostas de 70, média declarada 0,73,
acurácia 0,29.

7 ÷ 70 × (0,73 − 0,29) = 0,1 × 0,44 = **0,044**

O ECE inteiro é 0,088, então sete respostas respondem por metade dele. As 34 respostas acima de 0,9
contribuem com 34 ÷ 70 × (0,96 − 0,94), cerca de 0,010, e as outras duas faixas com o resto. A soma
das quatro, com os números arredondados da tabela, dá cerca de 0,089; o `pl calibrate` soma antes
de arredondar e imprime 0,088.

O ECE diz quanto os números declarados erram em média. Não diz em que direção, e um modelo que é
pouco confiante numa faixa e confiante demais em outra soma as duas distâncias.

A medida já era usada antes, e o artigo que a tornou padrão é *On Calibration of Modern
Neural Networks* (Guo e outros, 2017). Ele viu que os classificadores profundos da época
exageravam a confiança bem mais que redes mais antigas e menores, e mediu isso com ECE e diagramas
de confiabilidade. Mostrou também que um único reescalonamento das saídas, o temperature scaling, corrigia
boa parte. Aquele artigo tratava das probabilidades que um classificador calcula; a confiança desta
aula é um número que um modelo escreve. **A medição é a mesma nos dois casos**: o que foi afirmado,
contra o que aconteceu.

## O escore de Brier

O escore de Brier dispensa as faixas. Para cada resposta, pegue a confiança declarada, subtraia 1
se a resposta estava certa ou 0 se estava errada, eleve ao quadrado e tire a média de todas as
respostas.

`h04` declarou 0,97 e estava errada: (0,97 − 0)² = 0,9409. Dividida entre 70 respostas, essa
resposta sozinha soma 0,013 ao escore. Uma resposta certa declarada com 0,97 soma (0,97 − 1)² =
0,0009, dividido por 70: quase nada.

O escore inteiro é 0,139. Menor é melhor, e 0 exige toda resposta certa declarada com 1 e toda
errada com 0. Como a distância vai ao quadrado, **o escore de Brier pune um erro confiante muito
mais que um tímido**, e recompensa um modelo que tanto separa as respostas certas das erradas quanto
diz isso. O ECE só pergunta se os números batem com a taxa; um modelo que declarasse 0,80 em toda
resposta aqui teria ECE zero, já que 0,80 é exatamente a acurácia dele, e não diria nada sobre em
qual resposta confiar. O escore de Brier cobra por isso: (14 × 0,8² + 56 × 0,2²) ÷ 70 = (8,96 +
2,24) ÷ 70 = 0,16, pior que o 0,139 do substituto.

Relate os dois. O ECE responde *dá para ler o número como uma taxa?* e o Brier responde *o número me
ajuda a separar respostas boas de ruins?*
