---
title: ECE e o escore de Brier
version: 2
---

Um diagrama é para olhar. Para comparar dois prompts, ou acompanhar a calibração de uma versão para
a próxima, você quer um número. O `calibrate.py` imprime dois no pé da tabela, e eles medem coisas
diferentes.

## Erro de calibração esperado

**O ECE é a diferença média entre o que foi dito e o que aconteceu**, ponderada por quantas
respostas cada faixa tem. Para cada faixa, tome a diferença entre a média da confiança declarada e
a acurácia, ignore o sinal, e multiplique pela fração de todas as respostas que a faixa tem. Some as
faixas.

Da tabela da seção anterior:

- 0,8 a 0,9: 46 ÷ 70 × (0,80 − 0,72) = 0,657 × 0,08 = 0,053
- 0,9 a 1,0: 23 ÷ 70 × (0,90 − 0,78) = 0,329 × 0,12 = 0,039
- abaixo de 0,5: 1 ÷ 70 × (1,00 − 0,00) = 0,014

A soma com os números arredondados dá 0,106; o `calibrate.py` soma antes de arredondar e imprime
0,108. A única resposta declarada com 0,0 responde sozinha por um oitavo disso, porque a diferença
dela é a maior que uma diferença pode ser.

O ECE diz o quanto os números declarados erram em média. Não diz em que direção, e um modelo com
pouca confiança numa faixa e confiança demais em outra soma as duas diferenças.

A medida já era usada antes, e o artigo que a tornou a usual é *On Calibration of Modern Neural
Networks* (Guo e outros, 2017). Ele mostrou que os classificadores profundos da época eram bem mais
confiantes demais que redes mais antigas e menores, e os mediu com ECE e diagramas de
confiabilidade. Também mostrou que um único reescalonamento das saídas, o temperature scaling,
corrigia boa parte disso. Aquele artigo tratava das probabilidades que um classificador calcula; a
confiança desta aula é um número que um modelo escreve. **A medição é a mesma nos dois casos**: o que
foi afirmado, contra o que aconteceu.

## O escore de Brier

O escore de Brier dispensa as faixas. Para cada resposta, tome a confiança declarada, subtraia 1 se
a resposta estava certa ou 0 se estava errada, eleve ao quadrado, e tire a média de todas as
respostas.

O `h03` declarou 0,9 e errou: (0,9 − 0)² = 0,81. Dividida entre 70 respostas, essa resposta soma
0,012 ao escore. Uma resposta certa declarada com 0,9 soma (0,9 − 1)² = 0,01, dividido por 70: quase
nada. O `t35`, certo e declarado com 0,0, soma (0,0 − 1)² = 1, dividido por 70: 0,014.

O escore inteiro é 0,212. Menor é melhor, e 0 exige toda resposta certa declarada com 1 e toda
errada com 0. Como a diferença é elevada ao quadrado, **o escore de Brier pune um erro confiante muito
mais que um tímido**, e recompensa um modelo que ao mesmo tempo separa as respostas certas das
erradas e diz isso.

O ECE só pergunta se os números batem com a taxa. Um modelo que declarasse 0,74 em toda resposta
aqui teria ECE zero, já que 0,74 é a acurácia dele, e não diria nada sobre em qual resposta confiar.
O escore de Brier cobra por isso: (18 × 0,74² + 52 × 0,26²) ÷ 70 = (9,86 + 3,52) ÷ 70 = 0,19. **É
melhor que os 0,212 que o modelo conseguiu com os próprios números.** Dizer a acurácia geral toda
vez, a confiança menos informativa que existe, teria pontuado melhor que o que o `llama3.2:3b`
escreveu.

Relate os dois. O ECE responde *posso ler o número como uma taxa?* e o Brier responde *o número me
ajuda a separar respostas boas de ruins?* Aqui a primeira resposta é mais ou menos, e a segunda é
não.
