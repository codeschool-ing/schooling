---
title: A estatística de teste
version: 1
---

A **estatística de teste** transforma a amostra num número que diz quão longe os dados estão do que a
hipótese nula prevê, medido em unidades do ruído.

Para um teste sobre uma média, ela é a **estatística t**:

```localised
t = (média amostral − valor sob a nula) ÷ EP
```

Em cima está o **sinal**: a diferença entre o que se observou e o que a nula diz. Embaixo está o **ruído**: o
erro padrão da aula 12, quanto as médias amostrais oscilam por acaso. Um t de 3 significa que a média
amostral está a três erros padrão do valor da nula; um t de 0,5 significa que está a meio erro padrão, bem
dentro da oscilação comum.

## Sinal sobre ruído

A razão é a ideia inteira, e explica três coisas.

- Uma **diferença maior** dá um t maior. Uma média de 35 é evidência mais convincente contra 40 que uma
  média de 39.
- **Dados mais ruidosos** dão um t menor. Se os tempos de entrega variam muito, uma queda de três minutos
  pode facilmente ser acaso.
- **Mais dados** dão um t maior para a mesma diferença, porque o erro padrão encolhe com √*n*. A aula 22
  volta a isso, porque com dados suficientes até uma diferença trivial produz um t grande.

## A distribuição dela sob a nula

Se a hipótese nula é verdadeira, e a amostra é aleatória, a estatística t segue a **distribuição t com *n* −
1 graus de liberdade**: a mesma distribuição que a aula 12 usou para intervalos. É isso que torna o teste
possível: a nula prevê a forma da curva em que a estatística deveria cair, e o teste confere onde ela de
fato caiu.

## Para as entregas da Horta

As 25 entregas no novo sistema de rotas têm média de **38,9 minutos** e desvio padrão de **5,52**, então o
erro padrão é 5,52 ÷ √25 = **1,10**. Contra os 40 da nula:

```localised
t = (38,9 − 40) ÷ 1,10 = −1,00
```

A média amostral está um erro padrão abaixo de 40. Se isso é longe o bastante é a pergunta da próxima seção.
