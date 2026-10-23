---
title: VLANs, visitantes e o estado do dispositivo
version: 1
---

**Sim ou não é a resposta mais simples que um servidor 802.1X pode dar, e redes de verdade raramente
param aí.** O servidor também pode dizer *para onde* o dispositivo vai. Nada nesta seção foi
executado para este curso: depende de switches gerenciáveis com atribuição de VLAN e de um servidor
RADIUS, e é ensinado a partir dos padrões e de como os fabricantes documentam os recursos. Os nomes
abaixo são os comuns; a interface de cada fabricante tem os seus.

## Atribuição dinâmica de VLAN

Junto com o aceite, um servidor RADIUS pode devolver atributos, e três deles (`Tunnel-Type`,
`Tunnel-Medium-Type` e `Tunnel-Private-Group-ID`) dizem ao switch em que **VLAN** pôr a porta. A
mesma tomada então dá a um notebook da equipe a rede da equipe, e à impressora da recepção, que
entrou por MAC authentication bypass, uma rede só de impressoras que alcança o servidor de impressão e
mais nada. A decisão segue a credencial, não a tomada, então mudar uma mesa de lugar não exige
reconfigurar um switch.

## Visitantes e falhas

Mais dois resultados merecem ser configurados de propósito:

- **uma VLAN de visitantes** para um dispositivo que não fala 802.1X, o notebook de um visitante, com
  acesso à internet e nenhuma rota para máquinas internas;
- **uma VLAN de falha de autenticação**, ou simplesmente nada, para um dispositivo que tentou e foi
  recusado.

Os dois são decisões sobre o que um estranho recebe. O padrão seguro é o que a porta do laboratório
mostrou antes de o `desk` fazer login: nada além da conversa de login.

## Postura

A **avaliação de postura** faz uma segunda pergunta depois de "quem é você": "em que estado você
está?". Um agente de NAC no dispositivo informa se o sistema operacional está atualizado, se o disco
está cifrado, se a proteção de endpoint está rodando, e o servidor decide com isso além da credencial.
Um dispositivo que é de alguém da casa, e está desatualizado, pode ir para uma rede de **remediação**
que só alcança os servidores de atualização até ficar conforme.

A postura é o ponto em que o controle de acesso à rede encontra todo o resto deste curso. As
verificações que ela pergunta são a linha de base da aula 2, a proteção das aulas 7 e 8 e os patches
da aula 17. A fraqueza dela é a mesma do relato de qualquer agente: é o dispositivo descrevendo a si
mesmo, o que de novo é uma afirmação, mais forte que um endereço MAC porque o agente é mais difícil de
imitar, e ainda mais fraca que um certificado.

## Onde isto fica

O 802.1X controla quem entra no segmento. Não diz nada sobre o que um dispositivo legítimo faz uma
vez lá dentro, e é por isso que as aulas em volta desta continuam endurecendo as próprias máquinas.
E é um controle entre vários sobre a mesma pergunta: o inventário da aula 18 é a lista com que as
decisões do servidor de NAC deveriam concordar, e um dispositivo que o servidor deixou entrar e que o
inventário não conhece é um achado.
