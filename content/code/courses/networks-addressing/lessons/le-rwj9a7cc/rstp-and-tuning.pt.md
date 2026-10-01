---
title: Spanning tree rápido, e a árvore escolhida de propósito
version: 1
---

Trinta segundos de silêncio depois que um cabo falha é o protocolo original funcionando como foi
projetado. **Os temporizadores são lentos porque o STP clássico não tem como saber que a rede se
acomodou, então ele espera.** A solução, publicada em 2001, não encurta a espera. Ela troca a maior
parte dela por uma conversa.

## RSTP: perguntar em vez de esperar

O **Rapid Spanning Tree** (RSTP, IEEE 802.1w, incorporado ao 802.1D em 2004) mantém a mesma
eleição, os mesmos IDs de ponte e os mesmos custos. Três coisas mudam.

- **Uma porta alternativa é uma porta raiz reserva, escolhida de antemão.** O STP clássico bloqueia
  a porta sobrando e não calcula mais nada para ela. O RSTP a marca como a rota alternativa até a
  raiz, então quando a porta raiz falha a alternativa vira porta raiz na hora, sem listening e sem
  learning. No triângulo do laboratório, a `p3` bloqueada do `sw2` é exatamente essa porta.
- **Num cabo ponto a ponto, dois switches combinam em vez de esperar o tempo esgotar.** Um switch
  que quer encaminhar por uma porta manda uma *proposta*. O switch da outra ponta garante que as
  próprias portas não podem formar um laço e responde com uma *concordância*, e a porta encaminha na
  hora. Essa troca corre de switch em switch a partir da mudança, e numa rede de enlaces ponto a
  ponto isso leva por volta de um segundo, muitas vezes menos.
- **Portas de borda pulam o processo inteiro.** Uma porta marcada como porta de borda (*edge port*)
  dá para um computador, não para outro switch, então vai para forwarding assim que o cabo é
  conectado.

Os estados encolhem para três: **discarding** (blocking e listening juntos, já que nenhum dos dois
encaminha nada), **learning** e **forwarding**. Os papéis crescem: raiz, designada, alternativa e
*backup*, uma segunda porta num cabo em que o switch já tem a porta designada.

O RSTP fala com um switch 802.1D antigo no protocolo antigo, porta por porta, então os dois podem
ser misturados. O preço da mistura é que a troca rápida só funciona onde as duas pontas falam RSTP.

**O laboratório não conseguiu mostrar nada disso.** A bridge do kernel Linux implementa o 802.1D
original, e é por isso que toda captura desta lição tem listening e learning. O RSTP no Linux vem de
um daemon separado, o `mstpd`, que não foi executado aqui, então esta seção não traz saída.

## Uma árvore por grupo de VLANs

Uma árvore única bloqueia o mesmo cabo para todas as VLANs (lição 19), então metade dos cabos de um
projeto redundante não carrega nada. O **MSTP** (*Multiple Spanning Tree*, IEEE 802.1s, hoje parte
do 802.1Q) agrupa VLANs em instâncias e roda uma árvore por instância, cada uma com a sua raiz. Com
duas instâncias e duas raízes, a VLAN 10 pode bloquear um cabo e a VLAN 20 o outro, e os dois cabos
carregam tráfego. Os fabricantes tiveram as próprias versões por VLAN antes, entre elas o PVST+ e o
Rapid PVST+ da Cisco, e elas continuam comuns nesse equipamento.

## Escolher a árvore em vez de herdá-la

Uma rede que roda com os padrões deixa os endereços MAC escolherem a raiz, como mostrou a seção
sobre a eleição. Três decisões evitam isso.

**Defina a raiz.** Dê ao switch de núcleo, o que está no meio do tráfego, a menor prioridade, 4096
ou até 0, e a um segundo switch de núcleo o valor seguinte, 8192, para que, quando o primeiro falhar,
a raiz reserva também seja uma escolha. A mudança de prioridade da seção sobre falhas fez
exatamente isso em escala pequena.

**Marque as portas que dão para computadores como portas de borda.** No STP clássico, um PC que liga
espera uns 30 segundos até o primeiro quadro passar, o que basta para um cliente DHCP (lição 10)
desistir. Em equipamento Cisco a configuração se chama *PortFast*. Uma porta de borda que recebe um
BPDU deixa de ser porta de borda, o que é seguro; a próxima seção trata de fazer mais do que isso.

**Deixe os temporizadores em paz.** Encurtar hello, max age ou forward delay à mão para acelerar o
STP clássico arrisca uma porta encaminhar antes de a árvore se acomodar, que é o laço com que esta
lição começou. Rodar RSTP é o jeito de ganhar a velocidade.
