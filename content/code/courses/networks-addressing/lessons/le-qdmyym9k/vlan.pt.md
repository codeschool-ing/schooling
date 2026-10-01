---
title: A VLAN, uma LAN recortada por configuração
version: 1
---

A seção de LAN definiu uma LAN como as máquinas que se alcançam diretamente, sem roteador. Num
escritório pequeno, isso é simplesmente toda máquina no switch. Mas uma empresa muitas vezes quer
**várias LANs num prédio**, separadas: os PCs da contabilidade longe do Wi-Fi dos visitantes, as
impressoras e os telefones cada um no seu canto. Um switch separado para cada grupo, com seus próprios
lances de cabo, funcionaria, e multiplica o equipamento pelo número de grupos.

Uma **VLAN** (*virtual LAN*, LAN virtual) é a resposta: **um switch dividido em várias LANs por
configuração**. Cada porta é atribuída a uma VLAN, e o switch só encaminha um quadro entre portas da
mesma VLAN. Para as máquinas, parece exatamente com switches separados. O pc1 na VLAN 10 e o pc2 na
VLAN 20 podem estar em portas vizinhas do mesmo switch e ainda assim precisar de um roteador para se
alcançar, assim como o pc1 e o pc2 do laboratório desta aula precisam de um.

É a distinção da aula 3 entre o desenho físico e o lógico, aplicada a um switch. **O desenho físico
continua sendo uma estrela. O desenho lógico são várias**, uma por VLAN.

## Por que a palavra está nesta aula

As outras quatro palavras descrevem onde uma rede está e de quem ela é. VLAN descreve outra coisa —
como um conjunto de switches é dividido — e está aqui porque na prática as cinco aparecem juntas:

- a **LAN** de uma empresa costuma ser várias **VLANs**;
- entre dois switches, um cabo leva todas as VLANs de uma vez, cada quadro marcado com uma etiqueta
  (tag) de 4 bytes que diz a qual VLAN ele pertence (a tag 802.1Q, aula 19);
- uma **VPN** pode entregar uma sede remota numa VLAN específica, para que os PCs da contabilidade da
  filial caiam na rede da contabilidade da matriz.

## O que uma VLAN é e o que não é

- **Ela é uma fronteira de broadcast.** Um broadcast na VLAN 10 — uma pergunta ARP, um pedido de DHCP
  — nunca chega à VLAN 20. Isso deixa cada LAN menor e mais quieta (a aula 18 mede domínios de
  broadcast).
- **Ela é um lugar para filtrar.** O tráfego entre VLANs tem de atravessar um roteador, e um roteador
  é onde se escrevem as regras sobre quem pode falar com quem (aula 22).
- **Ela não é um firewall sozinha.** Uma VLAN separa o tráfego só tão bem quanto o switch está
  configurado: uma porta esquecida na VLAN errada, ou um tronco levando mais VLANs do que devia, junta
  o que era para ficar separado. A aula 19 mostra como esses erros aparecem e como se configura um
  switch para recusá-los.

O laboratório desta aula não tem VLANs; o cenário `vlans` da aula 19 monta um switch com duas, e a aula
22 roteia entre elas. Por enquanto, reconheça a palavra: uma VLAN é uma LAN que existe porque alguém a
configurou, não porque alguém passou um cabo.
