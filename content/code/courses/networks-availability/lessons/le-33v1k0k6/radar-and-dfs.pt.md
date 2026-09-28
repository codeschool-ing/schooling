---
title: 5 GHz, radar e DFS
version: 1
---

Em 5 GHz o problema de sobreposição do 2,4 GHz desaparece: os números de canal sobem de quatro em
quatro, 36, 40, 44, então cada canal de 20 MHz começa onde o anterior terminou. O que toma o lugar dele é
uma regra que a maioria das pessoas só conhece como mistério: **o ponto de acesso que troca de canal
sozinho** no meio do dia, derrubando todos os clientes por um minuto.

A faixa de 5 GHz é feita de pedaços, e os pedaços têm nome. São os nomes dos Estados Unidos, usados em
toda a indústria, e quais deles um país libera, e com que potência, é decisão do órgão regulador de lá:

| pedaço | frequências | canais (20 MHz) | dividido com radar? |
|---|---|---|---|
| UNII-1 | de 5150 a 5250 MHz | 36 a 48 | não |
| UNII-2A | de 5250 a 5350 MHz | 52 a 64 | sim |
| UNII-2C | de 5470 a 5725 MHz | 100 a 144 | sim |
| UNII-3 | de 5725 a 5850 MHz | 149 a 165 | não |

**Dezesseis desses vinte e cinco canais são divididos com radar**: radar meteorológico, sistemas
militares e de aeroporto, que chegaram primeiro e mantêm a prioridade. O Wi-Fi só pode usá-los com
**DFS**, seleção dinâmica de frequência (dynamic frequency selection), e o DFS é um conjunto de
obrigações com tempos fixos:

- Antes de transmitir num canal de radar, o ponto de acesso escuta por 60 segundos, a verificação de
  disponibilidade do canal, e não envia nada, nem um beacon. Na Europa a verificação é de 10 minutos
  nos canais em torno de 5600 a 5650 MHz, onde ficam os radares meteorológicos.
- Se detectar um pulso de radar em funcionamento, ele tem 10 segundos para parar e levar os clientes para
  outro lugar.
- Ele não pode voltar para aquele canal por 30 minutos.

Então uma rede no canal 100 que funcionou bem a manhã toda pode sumir ao meio-dia, reaparecer no canal 36
e fazer todos os clientes se reconectarem. **Nada está quebrado quando isso acontece; a lei foi
cumprida.** O que vale verificar é com que frequência acontece: um prédio perto de um aeroporto ou de uma
estação meteorológica pode ver isso muitas vezes por dia, e uma detecção falsa, um ruído que o rádio
confundiu com um pulso, aparece exatamente igual no log.

A escolha é uma troca. Deixar de fora os canais de radar sobra nove, nos quais um prédio denso vai pôr
vários pontos de acesso por canal. Mantê-los dá mais dezesseis, e uma mudança súbita de vez em quando.
Uma resposta comum é mantê-los e acompanhar os logs, e pôr o que não pode cair, os telefones de voz de um
hospital por exemplo, numa rede que use só UNII-1 e UNII-3.

## E o 6 GHz

A faixa de 6 GHz não tem nenhum dos dois problemas. Os canais dela são numerados a partir da sua própria
base, 5950 MHz, então o canal 1 fica em 5955 e o canal 233 em 7115, como o programa da seção anterior
imprimiu, e nenhum deles é dividido com radar do jeito que o 5 GHz é. Pontos de acesso internos de baixa
potência não precisam de DFS lá.
