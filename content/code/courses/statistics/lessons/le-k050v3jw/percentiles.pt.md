---
title: Percentis
version: 1
---

A mediana é o valor com metade dos dados abaixo dele. Generalize isso e você obtém os **percentis**: o
percentil 90 é o valor com 90% dos dados nele ou abaixo, o percentil 10 é o valor com 10% nele ou abaixo,
e assim por diante.

## Uma promessa escrita como percentil

Percentis respondem uma pergunta que a média não responde: **até onde as coisas pioram para a maioria
das pessoas?** Por isso promessas de serviço são escritas com eles.

Pegue os doze tempos de entrega da Horta. Dez dos doze levaram 44 minutos ou menos. Então "cinco em cada
seis entregas chegam em até 44 minutos" é verdade nestes dados, e é uma promessa muito mais útil que "a
média é 38,96 minutos", que não diz nada sobre as lentas. O percentil 90 da planilha para os doze é 51,65
minutos: ele deixaria a Horta dizer "nove em cada dez entregas chegam em até uns 52 minutos".

Promessas assim aparecem em todo negócio de serviço. Uma central de atendimento promete atender 80% das
ligações em até 20 segundos; uma equipe de web promete que 99% das páginas carregam em até um segundo.
Em cada caso a promessa é um percentil, porque o cliente se lembra dos casos lentos, e só um percentil
alto os descreve.

## Calculando um

Com os valores ordenados, o percentil *p* fica na posição *p* × (*n* − 1) + 1, contando a partir de 1 — a
regra que a função `PERCENTIL.INC` da planilha usa. Quando essa posição cai entre dois valores, o
percentil fica entre eles, na proporção.

Para o percentil 90 dos doze tempos de entrega: 0,9 × 11 + 1 = 10,9. O 10º valor ordenado é 44,0 e o 11º é
52,5, então o percentil é 44,0 + 0,9 × (52,5 − 44,0) = **51,65**.

```localised
=PERCENTIL.INC(A2:A13; 0,9)      51,65
```

## Percentis precisam de dados suficientes

Com doze valores, o percentil 90 é uma interpolação entre dois deles, e o 99 seria quase o máximo.
Percentis altos precisam de muitos dados para ficarem estáveis: uma promessa sobre 99% das entregas só é
crível quando se apoia em centenas delas. Com poucos valores, informe os percentis que os dados aguentam
e diga quantos valores havia.

Os três percentis que cortam os dados em quartos têm nomes próprios, e são o assunto da próxima seção.
