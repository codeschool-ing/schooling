---
title: Mesmo canal, canal vizinho, e o que não é Wi-Fi
version: 1
---

Quando dois pontos de acesso ao alcance um do outro dividem um canal, o instinto é mudar um deles para o
canal ao lado, como se um pouco de distância fosse melhor que nenhuma. **Em 2,4 GHz é pior.** Duas redes
no mesmo canal se atrasam educadamente. Duas em canais sobrepostos estragam os quadros uma da outra. A
diferença é se cada uma consegue entender a outra.

Todo rádio Wi-Fi escuta antes de falar. Isso se chama **avaliação de canal livre** (clear channel
assessment), e o padrão dá a ela dois limiares, um para cada coisa que um rádio pode ouvir:

| o que o rádio ouve | trata o canal como ocupado a partir de | típico de |
|---|---|---|
| um preâmbulo Wi-Fi que ele decodifica | −82 dBm, num canal de 20 MHz | outra rede no mesmo canal |
| energia que ele não decodifica | −62 dBm, cem vezes mais forte | um canal sobreposto, um micro-ondas |

Os 20 dB entre os dois são a história inteira. No **mesmo canal**, o quadro de um vizinho é decodificado
em níveis de sinal muito abaixo de qualquer coisa que o atrapalharia, então cada rádio espera o outro
terminar. Isso é **contenção cocanal** (co-channel contention): as duas redes dividem o tempo de ar de um
canal, as duas ficam mais lentas, e nada se perde. Num **canal sobreposto**, o quadro do vizinho não pode
ser decodificado, e a menos que chegue acima de −62 dBm o rádio não espera por ele. Transmite por cima, e
a parte do sinal do vizinho que cai dentro do seu canal chega ao receptor como ruído. Isso é
**interferência de canal adjacente** (adjacent-channel interference), e custa quadros corrompidos,
retransmissões e modulações mais lentas dos dois lados.

Então a regra para 2,4 GHz vem de um limiar, não de gosto: **divida um canal do plano, 1, 6 ou 11, em vez
de ficar entre dois deles.** Uma rede no canal 3 sofre interferência dos dois.

## Transmissores que não são Wi-Fi

2,4 GHz é uma faixa não licenciada, aberta a qualquer coisa dentro dos limites de potência, e o Wi-Fi é
um inquilino entre vários. Nenhum dos outros fala 802.11, então para um rádio Wi-Fi todos são energia
que ele não decodifica, a segunda linha da tabela.

- Um micro-ondas aquece a comida em torno de 2450 MHz, e o pouco que vaza pela porta basta para
  perturbar os canais do meio e de cima da faixa por perto enquanto ele funciona. O padrão, o Wi-Fi da
  copa falhando na hora do almoço, é o diagnóstico.
- O Bluetooth salta entre 79 canais de 1 MHz, 1600 vezes por segundo na forma clássica, e os aparelhos
  modernos evitam as frequências que encontram ocupadas. Um fone faz pouco; uma sala cheia deles soma.
- Sensores Zigbee, babás eletrônicas e transmissores de vídeo sem fio ficam em frequências fixas, alguns
  transmitindo sem parar.
- Telefones sem fio levam a culpa com frequência e costumam ser inocentes: os telefones DECT vendidos no
  Brasil e na Europa trabalham perto de 1,9 GHz, fora de todas as faixas do Wi-Fi.

**As ferramentas do próprio Wi-Fi não conseguem dar nome a nenhum desses.** Um cliente vê
retransmissões e taxa baixa, e um ponto de acesso vê um canal ruidoso. Só um analisador de espectro, que
desenha energia contra frequência sem decodificar nada, mostra a forma do culpado. Muitos pontos de
acesso corporativos conseguem transformar um dos rádios em um. O laboratório não tem rádio de espécie
nenhuma, então esta seção não tem captura de um.
