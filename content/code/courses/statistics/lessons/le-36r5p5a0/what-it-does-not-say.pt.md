---
title: O que o teorema não diz
version: 1
---

O teorema central do limite é poderoso o bastante para ser citado errado com frequência. Aqui estão as
afirmações que ele **não** faz.

## Ele não torna os dados normais

As cestas são tão assimétricas com 400 delas quanto com 40. O teorema trata das **médias das amostras**, não
dos valores dentro delas. Uma amostra grande tem um histograma cada vez mais parecido com a **população** —
assimétrico, se a população é assimétrica —, enquanto as médias de muitas amostras assim ficam cada vez mais
parecidas com um sino. Confundir as duas coisas leva gente a chamar dados assimétricos de "normais porque o
n é grande", o que está errado.

## "30 basta" não é uma lei

Para as cestas, as médias de 30 ainda tinham assimetria de 0,34. Para populações com caudas muito pesadas —
rendas num país, valores de sinistros de seguro, número de seguidores por conta —, as médias de amostras de
30, ou de 300, ainda podem ser visivelmente assimétricas, e uma aproximação normal pode subestimar quantas
vezes uma média amostral cai longe. Quanto mais pesadas as caudas, maior a amostra precisa ser. Para algumas
distribuições extremas, cujo desvio padrão é infinito, o teorema nem se aplica.

## Ele precisa de observações aleatórias e independentes

O teorema supõe que cada observação é tirada de forma independente da mesma população. Uma amostra por
conveniência das 60 entregas mais próximas tem uma média lindamente estável e estavelmente errada, como a
aula 10 mostrou: o teorema descreve a oscilação em torno do alvo, e não diz nada sobre a amostra estar
mirando o alvo certo. **O viés está fora do alcance dele.** Observações que não são independentes, como
entregas na mesma noite de chuva, também o quebram: elas empurram juntas em vez de se anularem.

## Ele trata da média

O teorema, como enunciado aqui, trata da **média** amostral, e de qualquer coisa construída como ela: uma
proporção é uma média de zeros e uns, então se qualifica, e a aula 12 usa isso. Outras estatísticas também
têm distribuições amostrais, muitas vezes aproximadamente normais para amostras grandes, mas com
dispersões próprias. A mediana de amostras de 30 cestas, por exemplo, tem dispersão de R$ 8,91, menor que os
R$ 10,67 da média, porque a mediana ignora a cauda. A fórmula dela não é σ ÷ √*n*.

## O que ele diz, mais uma vez

Tire uma amostra aleatória grande o bastante, e a média dela tem distribuição aproximadamente normal em
torno da média verdadeira, com dispersão σ ÷ √*n*. Essa frase é o que transforma uma amostra única numa
afirmação com margem de erro, e a aula 12 faz essa transformação.
