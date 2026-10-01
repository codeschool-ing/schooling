---
title: Praticar numa rede que não existe
version: 1
---

Aprender redes só pelo livro falha sempre no mesmo lugar: o momento em que algo não funciona e você
nunca viu como é "não funcionar". **Uma rede de prática existe para você quebrar coisas de propósito e
ver o que acontece.** Três motivos fazem valer a pena montar uma:

- **equipamento**: um switch, dois roteadores e um firewall custam dinheiro e uma prateleira, enquanto
  um laboratório de vinte dispositivos custa parte da memória de um notebook;
- **segurança**: uma rota errada numa rede de prática não derruba nada, e no roteador do escritório
  derruba o escritório;
- **ensaio**: uma mudança que você vai fazer em produção — uma VLAN nova, uma rota, uma regra de
  firewall — pode ser testada antes numa cópia da rede, e a cópia sai barato jogar fora.

As ferramentas que montam essas redes são todas chamadas de "simuladores" na conversa, e a palavra
esconde a diferença que mais importa, que é **o que de fato roda dentro de cada caixa**:

| tipo | o que roda dentro de um dispositivo | exemplos |
|---|---|---|
| simulação | um programa que imita o comportamento do dispositivo | Cisco Packet Tracer |
| emulação | o sistema operacional real do dispositivo, numa máquina virtual | GNS3, EVE-NG |
| virtualização no kernel | a pilha de rede real do Linux, dividida em pedaços isolados | Mininet, o laboratório deste curso |

Essa coluna decide o que um resultado significa. Numa simulação, um roteador faz o que os autores da
imitação programaram: um comando que a imitação não conhece não existe, e um comportamento que ela
modela pode diferir em detalhes do roteador real. Numa emulação, o roteador roda o software de verdade
do fabricante, então o comportamento é o real, ao preço de uma imagem licenciada e da memória de uma
máquina virtual para cada dispositivo. Na virtualização no kernel, cada pacote é um pacote real tratado
pelo kernel real do Linux, mas cada dispositivo é Linux: você configura uma bridge do Linux e o FRR, não
a linha de comando de um switch Cisco.

**Nenhum dos três prova o que uma rede real específica vai fazer.** Cada um prova algo mais estreito, e
as próximas quatro seções dizem o quê. Dois erros são comuns, um em cada direção: tomar um resultado de
laboratório como prova de que uma mudança é segura no equipamento real, e desprezar um laboratório
porque os dispositivos dele não são da marca que está no rack. Os protocolos seguem os mesmos padrões em
toda parte — o OSPF num roteador Cisco, num Juniper ou no FRR fala o protocolo que a RFC descreve — e os
protocolos são o que um laboratório ensina melhor.
