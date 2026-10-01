---
title: Energia pelo mesmo cabo
version: 1
---

Um telefone numa mesa, um ponto de acesso no teto e uma câmera numa parede externa têm uma coisa em
comum: nenhum deles fica perto de uma tomada onde alguém queira uma. **O Power over Ethernet (PoE)
manda a eletricidade pelo mesmo cabo de par trançado que os dados**, então um cabo saindo do switch
é tudo de que o dispositivo precisa. No teto, essa é a diferença entre um eletricista e um cabo de
rede.

**O laboratório desta lição não conseguiu rodar nada disso.** O laboratório são namespaces de rede
num computador, e um cabo virtual carrega quadros e nenhuma eletricidade, então não há saída nesta
seção nem na próxima. O que segue é o padrão, dito como o padrão diz.

## Dois papéis, e uma conferência antes de qualquer energia passar

O dispositivo que fornece energia é o **PSE** (*power sourcing equipment*): em geral um switch PoE,
ou um injetor *midspan* posto entre um switch comum e o dispositivo. O dispositivo que recebe é o
**PD** (*powered device*).

A preocupação óbvia é que um switch empurrando energia por todos os cabos danificaria um notebook
ligado na porta errada. **Um PSE dentro do padrão não põe energia num cabo até encontrar um PD na
outra ponta.** Ele passa por três etapas:

1. **Detecção.** O PSE aplica uma tensão pequena e inofensiva e procura uma *resistência de
   assinatura* de 25 kΩ que o PD apresenta na entrada. A placa de rede de um notebook não a
   apresenta, então ela nunca recebe energia.
2. **Classificação.** O PD anuncia uma **classe**, que diz ao PSE quanta energia ele pode puxar.
   Dispositivos dos padrões mais novos também podem refinar o número depois, via LLDP.
3. **Energização**, e a partir daí o PSE vigia a corrente. Se o PD é desconectado, o PSE percebe e
   tira a energia da porta.

Essa proteção pertence ao padrão. Alguns equipamentos baratos vendem *PoE passivo*, que põe tensão
no cabo permanentemente, sem detecção, e isso pode danificar um dispositivo que não foi feito para
recebê-la. Vale conferir de que tipo é uma porta marcada como PoE.

## Os padrões e quanto cada um entrega

Há dois números para cada padrão, e a diferença entre eles é o ponto. **O PSE tem de fornecer na
porta mais do que é prometido ao PD na outra ponta**, porque um cabo longo transforma parte da
energia em calor. Os padrões dimensionam essa diferença para 100 metros de cabo.

| padrão | tipo | na porta do switch (PSE) | no dispositivo (PD) |
| --- | --- | --- | --- |
| IEEE 802.3af (2003) | Type 1 | 15,4 W | 12,95 W |
| IEEE 802.3at (2009), "PoE+" | Type 2 | 30 W | 25,5 W |
| IEEE 802.3bt (2018) | Type 3 | 60 W | 51 W |
| IEEE 802.3bt (2018) | Type 4 | 90 W | 71,3 W |

O 802.3af e o 802.3at mandam energia por dois dos quatro pares do cabo. **O 802.3bt pode usar os
quatro**, e é assim que chega a 60 e 90 W, e é por isso que ele é o padrão para dispositivos como
câmeras com aquecedor, pontos de acesso grandes e telas pequenas.

Dentro do Type 1 as classes dizem quanto menos que o máximo um dispositivo precisa: **a classe 1
reserva 4 W na porta, a classe 2 reserva 7 W, e a classe 3 os 15,4 W inteiros.** A classe 4 é os
30 W do Type 2, e o 802.3bt acrescenta as classes 5 a 8, até 90 W. Um dispositivo que não anuncia
nada é classe 0 e recebe o máximo do Type 1. Essas reservas são o que a próxima seção soma, porque um
switch não tem 90 W para cada porta.
