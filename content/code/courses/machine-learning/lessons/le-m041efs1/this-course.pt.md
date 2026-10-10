---
title: O que é este curso, e a ordem em que ele vai
version: 1
---

**A maioria dos cursos de machine learning começa pela regressão linear.** Este começa com quatro
aulas em que nada que você guardaria é ajustado, e essa é a decisão em que todo o resto se apoia.
Ajustar um modelo são três linhas de scikit-learn. O que decide se o modelo serve para alguma coisa
é tudo em volta dessas três linhas: para que ele existe, o que ele tem de superar, como é testado e
se o teste foi honesto.

Por isso o curso vai nesta ordem:

| aulas | do que tratam |
|---|---|
| 1 a 4 | **o problema antes do modelo**: o que o modelo decide e quanto custa um erro (1), a regra trivial que ele tem de superar (2), a divisão que o testa com honestidade (3) e os vazamentos que fazem um teste mentir (4) |
| 5 a 9 | **os algoritmos**: regressão linear e logística, vizinhos mais próximos, naive Bayes e máquinas de vetores de suporte, árvores, florestas e boosting, e como ajustar os botões deles |
| 10 a 13 | **medir os modelos**: as métricas de um classificador e de uma regressão, o limiar que transforma uma probabilidade em ação, e o que acontece quando uma classe é rara |
| 14 e 15 | **as variáveis e o pipeline** que as mantém honestas |
| 16 a 18 | **sem rótulo**: agrupamento, redução de dimensionalidade e recomendação |
| 19 e 20 | **explicar um modelo e conferir a quem ele prejudica** |
| 21 e 22 | **depois do notebook**: um modelo atrás de um endereço, escorado em lote e vigiado |

**As aulas 1 a 4 são as fáceis de pular e caras de ter pulado.** Um modelo que não supera nada,
testado numa divisão que vaza e medido com uma métrica da qual nenhuma decisão depende, produz um
número que parece exatamente um número bom. A aula 4 mostra um modelo com nota 0,95 que não vale
nada, e a única coisa errada nele é uma coluna.

## O que ele supõe

**`python-data` e `statistics`.** Você já usa pandas e NumPy sem consultar nada: um `DataFrame`,
`groupby`, uma máscara booleana, `merge`. Este curso nunca os explica de novo. E você já pensa em
amostras e incerteza: uma média tem dispersão, uma diferença pode ser acaso, e um conjunto de teste
é uma amostra como qualquer outra. A aula 2 se apoia nisso quando pergunta se um modelo superou de
verdade a linha de base.

## O que ele deixa para outros cursos

- **Redes neurais** são o `deep-learning`, o próximo curso da trilha. Tudo aqui roda num
  processador em segundos; essa é a linha entre os dois.
- **A maquinaria de produção** — feature store, retreino agendado, registro de modelos e pipelines
  de implantação — é o `ml-mlops`. As aulas 21 e 22 põem um modelo atrás de um endereço e o vigiam,
  que é o que um cientista de dados faz com as próprias mãos. A plataforma que faz isso para cem
  modelos é trabalho de outra pessoa.
- **Limpar os dados** foi o `data-cleaning`. Os arquivos aqui são arrumados de propósito, fora as
  lacunas com que um modelo tem de lidar, para a atenção ficar no modelo.

## Como funciona uma aula

Toda aula usa a mesma pasta e os mesmos dados, que você monta nas duas próximas seções. **Cada
programa que uma aula roda está impresso inteiro naquela aula**, e cada transcrição é o que aquele
programa imprimiu quando o curso foi gravado. Você salva o programa, roda e deve ver os mesmos
números. Quando um número seu difere, a causa quase sempre é uma versão, e a aula 15 explica por que
isso importa mais do que parece.

A última seção de cada aula é um exercício. As perguntas ali não valem nota, e cada resposta errada
diz que crença levaria a ela, que é o motivo para responder com honestidade em vez de depressa.
