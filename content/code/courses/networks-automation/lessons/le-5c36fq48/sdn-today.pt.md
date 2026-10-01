---
title: Para onde foi o SDN
version: 1
---

O OpenFlow do jeito que esta aula o usou, um controlador programando cada switch flow por flow, é
raro hoje em redes de produção. As ideias não desapareceram; mudaram de lugar, e a maioria delas
já está neste curso.

**Os fabrics de data center** são onde os controladores ficaram. Um controlador de fabric recebe a
intenção, quais redes existem e quais servidores pertencem a elas, e configura os switches,
geralmente enviando configuração ou rotas BGP EVPN em vez de flows individuais. Os switches mantêm
um control plane distribuído por baixo, então uma queda do controlador interrompe as mudanças, não
o tráfego.

**Os overlays** põem a parte programável na borda. Túneis VXLAN entre hypervisors transportam as
redes virtuais, e o Open vSwitch, programado por OpenFlow a partir de um controlador, é essa borda
em plataformas como o OpenStack; a rede física por baixo só roteia IP. As redes virtuais dos
provedores de nuvem funcionam do mesmo jeito, com seus próprios controladores.

**O SD-WAN** aplicou a ideia às filiais: um controlador decide por qual link vai o tráfego de cada
aplicação, e os equipamentos das filiais obedecem.

O que todos eles expõem é justamente o assunto deste curso. **Um controlador tem uma API,
geralmente REST, e um modelo da rede**; automatizá-lo é o requests da aula 2, os formatos de dados
da aula 6, a fonte da verdade da aula 12 e o pipeline da aula 14, apontados para um sistema só em
vez de cem caixas. Os roteadores e switches não deixaram de precisar de configuração; o que mudou
é quem a guarda, e em quantos lugares ela precisa ser escrita.
