---
title: Saúde pública: taxas, e a cidade que só parece mais doente
version: 1
---

Um hospital responde pelos seus pacientes. Uma secretaria de saúde responde por uma população, a
maior parte dela sem doença nenhuma, e as perguntas dela são sobre onde uma doença está mais comum
do que deveria: que cidade precisa de um ambulatório de cardiologia, que bairro uma campanha de
vacinação deve alcançar primeiro. **Comparar lugares é comparar taxas, nunca contagens**, e comparar
taxas com justiça exige um ajuste de que o varejo nunca precisou.

## Taxas por 100 mil

Duas cidades da região do Jacarandá, chamadas aqui de A e B, mandaram ao hospital os seus pacientes
com insuficiência cardíaca em 2025. A cidade A teve 252 internações, e a B, 190. A cidade B é
maior, com 76.000 habitantes contra 52.000 de A, então as contagens não dizem nada até serem
divididas pela população. As estatísticas de saúde usam taxas por 100 mil habitantes, para que os
números fiquem inteiros o bastante para ler:

| | A | B | C | D | E | F |
|---|---|---|---|---|---|---|
| 1 | Idade | A pessoas | A internações | B pessoas | B internações | Padrão |
| 2 | Menos de 65 | 40000 | 36 | 70000 | 70 | 85000 |
| 3 | 65 ou mais | 12000 | 216 | 6000 | 120 | 15000 |

Esqueça a coluna F por enquanto. Na linha 4, os totais de cada coluna, `=SOMA(B2:B3)` copiado até
F. Depois a **taxa bruta** de cada cidade, que é todas as internações sobre todas as pessoas:

```localised
=ARRED(C4/B4*100000;1)      484,6
=ARRED(E4/D4*100000;1)      250
```

**A taxa da cidade A é de 484,6 por 100 mil, quase o dobro dos 250 da cidade B.** Uma secretaria
que lesse só essa linha mandaria o ambulatório para A.

## Taxas por idade

A insuficiência cardíaca é muito mais comum na velhice, e as duas cidades não têm a mesma idade.
Em G1 digite `Taxa A` e em H1 `Taxa B`, e nas linhas 2 e 3 a taxa de cada faixa de idade:

```localised
=ARRED(C2/B2*100000;1)      90
=ARRED(E2/D2*100000;1)      100
```

Copiadas para a linha 3, as pessoas de 65 anos ou mais de A ficam em 1.800 por 100 mil e as de B em
2.000. **Em cada faixa de idade, a cidade B tem a taxa maior.** A cidade A só parece mais doente no
total porque 23,1% da sua população tem 65 anos ou mais, contra 7,9% em B. É o paradoxo de Simpson
da aula 12 numa tabela de saúde pública: cada grupo aponta para um lado, e o total aponta para o
outro porque a composição é diferente.

## A taxa ajustada por idade

A comparação justa pergunta qual seria a taxa de cada cidade se as duas tivessem as mesmas idades.
Essa forma comum é a **população padrão** da coluna F: 100 mil pessoas, 85.000 com menos de 65 e
15.000 com 65 ou mais. Aqui ela é ilustrativa; os órgãos de saúde publicam as suas próprias
populações padrão, e a comparação só é justa quando as duas taxas usam a mesma. Aplique a ela as
duas taxas por idade de cada cidade:

```localised
=ARRED(SOMARPRODUTO(G2:G3;F2:F3)/F4;1)      346,5
=ARRED(SOMARPRODUTO(H2:H3;F2:F3)/F4;1)      385
```

`SOMARPRODUTO` multiplica a taxa de cada idade pelas pessoas do padrão naquela idade e soma as
duas; dividir pelo total do padrão faz do resultado uma média das duas taxas, ponderada pelas
idades do padrão e ainda por 100 mil. **Ajustada por idade, a cidade A fica em 346,5 e a B em
385**, e a ordem se inverteu. O ambulatório pertence a B, ou pelo menos pertence a B a pergunta de
por que os idosos de lá são internados com mais frequência.

## O que publicar

As duas taxas são verdadeiras, e respondem a perguntas diferentes. A taxa bruta diz quanta
insuficiência cardíaca cada cidade de fato tem, que é o que precisa um hospital planejando leitos:
A realmente mandou mais pacientes. A taxa ajustada diz se as pessoas de uma cidade adoecem mais que
pessoas da mesma idade em outro lugar, que é o que precisa uma secretaria decidindo onde agir. **Um
relatório que compara lugares mostra a taxa ajustada, diz qual é a população padrão e mantém a taxa
bruta ao lado**, para ninguém precisar adivinhar qual das duas está lendo.

E nenhuma das duas vale muito com números pequenos. 216 e 120 internações bastam para comparar; uma
cidade de 3.000 habitantes com dois casos não basta, pelos motivos que a aula 12 deu para bases
pequenas, e por mais um, que é o assunto da próxima seção.
