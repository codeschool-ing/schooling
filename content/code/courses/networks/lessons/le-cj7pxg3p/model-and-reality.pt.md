---
title: Onde o modelo é frouxo
version: 1
---

O modelo OSI é um mapa, e os protocolos de verdade nem sempre ficam dentro das linhas dele:

- **O ARP fica entre as camadas 2 e 3.** Ele leva endereços IP num quadro de camada 2, e só existe
  para ligar as duas.
- **O DNS é camada 7**, um protocolo de aplicação como qualquer outro, e mesmo assim quase toda outra
  aplicação depende dele antes de mandar o primeiro byte.
- **O TLS faz o trabalho das camadas 5 e 6**, e roda dentro da aplicação, em cima do TCP.
- O ICMP, que leva o `ping` e as mensagens que o `traceroute` lê, faz parte da camada 3, embora viaje
  dentro de um pacote IP como se fosse camada 4.

Nada disso torna o modelo errado. Ele é um vocabulário, e quem trabalha com redes usa esse
vocabulário todo dia: um *switch de camada 2* encaminha pelo endereço MAC, um *switch de camada 3*
também roteia, um *balanceador de camada 4* distribui conexões por porta, um *firewall de camada 7* lê
o HTTP dentro delas. **Quando alguém diz "é um problema de camada 2", quer dizer o enlace, o MAC ou o
ARP, e nada acima.**

Os protocolos que de fato fazem a internet funcionar foram desenhados com um modelo mais simples, só
deles, com quatro camadas em vez de sete. A aula 2 desenha os dois lado a lado.
