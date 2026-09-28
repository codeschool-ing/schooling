---
title: Sinal, ruído e a regra prática de −67 dBm
version: 1
---

Um survey registra dois números em cada ponto, e um projeto é julgado por um terceiro feito com eles.

| | o que é | faixa típica em ambiente interno |
|---|---|---|
| **sinal** (RSSI) | a potência recebida de um AP, em dBm | −30 perto de um AP, −80 numa borda de célula ruim |
| **piso de ruído** | tudo o que é recebido e não é o sinal | por volta de −90 a −95 dBm num canal de 20 MHz tranquilo |
| **SNR** | sinal menos ruído, em dB | quanto maior, mais rápida a taxa de dados que o enlace sustenta |

**A SNR é o que decide a taxa de dados.** Um cliente escolhe a taxa pela nitidez com que separa o sinal do
ruído, e cada degrau acima exige alguns decibéis a mais. Um sinal forte ao lado de um micro-ondas, com o
piso de ruído levantado para −75 dBm, pode dar um enlace pior que um sinal mais fraco num canal
tranquilo.

## Os alvos

Os alvos de projeto vêm dos guias dos fabricantes e da prática, não da norma 802.11, e variam um pouco
de um guia para outro. Estes são os valores mais citados, todos medidos na borda da célula, o pior ponto
em que se espera que um cliente fique:

| uso | sinal na borda da célula | SNR |
|---|---|---|
| e-mail e web | −70 a −72 dBm | 20 dB |
| chamadas de voz e vídeo | −67 dBm | 25 dB |
| áreas densas, de alta vazão | −65 dBm ou melhor | 25 a 30 dB |

**−67 dBm é o número que vive aparecendo**, e os motivos por trás dele são o que o torna útil. Ele deixa
espaço para o que o adaptador de survey não viveu: a antena menor de um celular, uma mão ou um corpo em
volta dele (3 a 5 dB na tabela de perdas), e a flutuação do próprio sinal de um instante para outro. E ele
mantém a borda da célula acima dos limiares de roaming da aula 9, por volta de −70 a −75 dBm, para que o
celular encontre o próximo AP antes de a chamada começar a sofrer. Para voz, os guias também pedem **um
segundo AP num nível utilizável em todo ponto**, para que haja para onde fazer roaming.

## O sentido que o survey não mede

Um adaptador de survey mede o que o AP envia. O AP também precisa ouvir o cliente, e **o transmissor do
cliente é o mais fraco**, a assimetria da aula 7: um AP transmite mais alto que um celular. Uma célula
desenhada pelo sinal do AP pode, então, ser mais larga do que um celular na borda consegue responder. É
mais um motivo para dimensionar as células pelas necessidades do cliente mais fraco, e não aumentando a
potência do AP até o mapa ficar verde.

O adaptador também importa. **Dois adaptadores podem ler o mesmo ponto com vários dB de diferença**, e
nenhum deles bate com o celular no bolso de alguém. Um survey que vale a leitura diz qual adaptador usou e
como ele se comparou com os aparelhos que vão usar a rede, e a última seção volta a isso.
