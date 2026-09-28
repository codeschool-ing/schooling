---
title: Onde o QoS para
version: 1
---

Toda captura desta aula foi feita no roteador do provedor, e todas mostraram a marcação chegando intacta.
Esse roteador leu `tos 0xb8`, imprimiu e tratou o pacote como qualquer outro. **O DSCP é um comportamento
por salto** (per-hop behaviour): cada roteador decide sozinho o que uma marcação significa, e um roteador
sem classes configuradas decide que ela não significa nada.

Na internet pública esse é o caso normal. Um provedor que respeitasse as marcações dos clientes estaria
dando prioridade de graça a quem escrevesse `0xb8`, que é o problema de confiança da seção anterior na
escala de um continente, então os provedores ignoram o byte ou o zeram na borda. A exceção é um serviço
comprado como tal: a VPN MPLS de um provedor entre os sites de uma empresa pode levar algumas classes por
contrato, e aí o que a empresa paga é o contrato, não a marcação.

Então o QoS funciona onde a fila é sua. No uplink de `hq` a fila é de `hq`, e tudo nesta aula funcionou.
**O tráfego que desce pelo mesmo enlace é outra história**: a fila dele fica na ponta do provedor, antes de
os pacotes chegarem ao seu roteador, e um download grande enche uma fila que você não consegue configurar.
A resposta de sempre é fazer o shaping do seu lado um pouco abaixo da velocidade real da linha, para que a
fila se forme no seu roteador, onde estão as suas classes, e não no do provedor. Esse é o assunto da aula 20.

| onde está a fila | dá para dar classes a ela? |
|---|---|
| no uplink do seu roteador, na saída | sim, nesta aula |
| nos switches da sua LAN | sim, com a fronteira de confiança na porta de acesso |
| na ponta do provedor da sua linha, na entrada | não, só com shaping do seu lado abaixo da taxa dela (aula 20) |
| na internet entre dois sites | não, a menos que um contrato diga que sim |

Mais uma ferramenta merece nome, porque ataca o problema pela outra ponta. **Uma fila mais curta ajuda
todo mundo, com classes ou sem.** Gerenciadores ativos de fila como o `fq_codel` descartam ou marcam
pacotes cedo, antes de a fila crescer para centenas de milissegundos, e dão a cada fluxo uma fila própria;
eles não foram executados neste laboratório, cuja fila era um `pfifo` simples de propósito, para que o
estrago ficasse visível. As classes decidem quem sofre com o que sobra, e num enlace cuja fila nunca cresce
sobra muito menos para decidir.
