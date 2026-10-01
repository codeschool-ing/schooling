---
title: Qual abrir
version: 1
---

As ferramentas diferem menos em qualidade do que naquilo que respondem. **Escolha pela pergunta que
você está fazendo, não pela ferramenta que você conhece.**

| ferramenta | o que roda dentro | custo e licença | serve para |
|---|---|---|---|
| Packet Tracer | a imitação que a Cisco faz dos próprios dispositivos | gratuito, com conta na Networking Academy | primeiros passos, a forma do IOS, pacotes passo a passo |
| GNS3 | software real de dispositivo, em máquinas virtuais e contêineres | gratuito e de código aberto; imagens licenciadas pelos fabricantes | laboratórios com vários fabricantes, ensaiar uma mudança no software real |
| EVE-NG | o mesmo, servido ao navegador | Community gratuita, Professional paga; imagens licenciadas pelos fabricantes | laboratórios compartilhados, topologias maiores |
| Mininet | a pilha de rede do kernel do Linux | gratuito e de código aberto | redes definidas por software, topologias escritas como programas |
| namespaces, como o `lab.sh` | a pilha de rede do kernel do Linux | gratuito; um script de shell | os próprios protocolos, capturados exatamente |
| equipamento real | o dispositivo real | o dispositivo, o espaço e a energia | cabeamento, energia, rádio, a verificação final |

Quatro perguntas mostram como a escolha cai:

- **"O que um switch faz com um quadro para um MAC desconhecido?"** Qualquer uma. O modo de simulação
  do Packet Tracer mostra como animação; o laboratório mostra como uma captura do `tcpdump`, que é o
  que a aula 18 faz.
- **"Esta configuração funciona no nosso firewall?"** Só o software daquele firewall responde: um
  emulador rodando a imagem do fabricante, sob a licença da empresa, e depois uma janela de manutenção
  no equipamento real.
- **"Quanto tempo o OSPF leva para achar outro caminho depois que um cabo é cortado?"** As ferramentas
  do kernel, com FRR e uma captura, que é como o anel da aula 3 mediu. O número que elas dão é o número
  daquele laboratório; os temporizadores e o hardware de uma rede real dão o dela.
- **"Este cabo está com defeito?"** Nenhum laboratório. Um cabo virtual não tem cobre para quebrar, e
  um simulado também não. Perguntas da camada física — uma crimpagem ruim, a reserva de energia de uma
  porta para um telefone, um canal de Wi-Fi — precisam da coisa física.

Este curso usa o laboratório de namespaces por um motivo que é tanto de honestidade quanto de custo:
cada transcrição nele é algo que um kernel real imprimiu, e qualquer pessoa com uma máquina Linux pode
rodar o `lab.sh` e obter as mesmas linhas. Quando uma aula precisa de um dispositivo que o laboratório
não consegue ser — um modem, um ponto de acesso, a linha de comando de um fabricante — ela diz isso e
não mostra nada.
