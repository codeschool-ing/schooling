---
title: Distância precisa de uma escala comum
version: 1
---

As linhas *raw* do `knn.py` são as que merecem atenção. Sem padronizar, o modelo com 15 vizinhos
manda 120 créditos e faz R$ 96; padronizado, manda 332 e faz R$ 7.744. **Mesmas linhas, mesmo k,
oitenta vezes o dinheiro.** A única coisa que mudou foi a unidade dos eixos.

Uma distância soma diferenças entre colunas. Em unidades brutas, `price_month` vai de uns R$ 180 a
R$ 760, então dois assinantes cujos preços diferem em R$ 100 estão a 100 de distância nesse eixo. Os
pulos nos últimos 90 dias, o sinal isolado mais forte depois da avaliação, diferem no máximo por um
punhado. **A vizinhança é decidida quase toda pelo preço**, porque o preço é medido nos números
maiores, e pulos, avaliações e reclamações quase não contam. O modelo está achando assinantes com
conta parecida e chamando-os de parecidos.

O `StandardScaler` põe toda coluna em desvios-padrão, então uma diferença típica de preço e uma
diferença típica de pulos contam o mesmo. Isso é uma escolha, não um fato neutro: diz que toda coluna
importa igualmente para "parecido", o que também não é verdade, mas é muito menos errado que deixar a
unidade de cada coluna decidir.

É a mesma lição dos pesos da aula 5, numa forma mais aguda. As previsões de um modelo linear não
dependem das unidades a menos que ele seja penalizado; as previsões de um modelo baseado em distância
não dependem de mais nada. **Tudo o que é construído sobre distância precisa das colunas numa escala
comum**: vizinhos mais próximos, as máquinas de vetores de suporte mais adiante nesta aula, e o
k-means da aula 16.

## Dois custos práticos

**A previsão é lenta, e cresce com os dados.** Cada previsão compara a linha nova com toda linha
guardada, ou com um índice esperto delas. O `knn.py` passa quase o minuto inteiro prevendo. Um modelo
que precisa responder no caixa, em milissegundos, contra milhões de linhas guardadas, precisa de um
índice aproximado, que é uma engenharia à parte.

**Lacunas não têm distância.** Uma avaliação que falta não se subtrai de nada, então o programa
preenche as lacunas com as medianas de treino antes, como o `logistic.py` fez. Um vizinho preenchido
assim fica *parecido* com todo mundo de avaliação mediana, uma ficção que vale lembrar quando a parte
de lacunas é grande.
