---
title: A família dos balanceadores de carga
version: 1
---

**O Google Cloud tem um produto de balanceamento de carga e cerca de uma dúzia de balanceadores**, e os nomes
são a parte mais difícil. Eles se ordenam por três perguntas, e todo balanceador é uma resposta a cada uma:

1. **O que ele entende?** Um **Application Load Balancer** lê HTTP e HTTPS: hosts, caminhos, cabeçalhos,
   cookies. Um **Network Load Balancer** vê conexões TCP e UDP e nada dentro delas.
2. **Quem o alcança?** Os **externos** têm um endereço na internet. Os **internos** têm um endereço dentro de
   uma rede VPC, para tráfego que nunca sai dela.
3. **Onde ele vive?** Os **globais** têm um endereço servido da borda do Google no mundo todo. Os **regionais**
   vivem numa região, com um endereço ali.

E mais uma para os Network Load Balancers: **proxy** ou **passthrough**. Um balanceador proxy termina a conexão
do cliente e abre uma nova para o backend. Um passthrough entrega os próprios pacotes do cliente ao backend,
que portanto vê o endereço real do cliente e responde a ele diretamente.

| | externo | interno |
|---|---|---|
| **Application**, global | o site do planner: um endereço, servido da borda, TLS terminado ali | interno entre regiões, para serviços que várias regiões chamam |
| **Application**, regional | só uma região, para dados que precisam ficar nela | serviços dentro da rede de uma região |
| **Network, proxy** | TCP com o TLS terminado pelo Google, para protocolos que não são HTTP | regional, dentro de uma rede |
| **Network, passthrough** | regional, os pacotes do cliente intactos: jogos, VoIP, qualquer coisa UDP | regional, a entrada interna de um conjunto de máquinas |

## O que um balanceador externo global compra

O site do planner usa o do canto superior esquerdo, e três coisas sobre ele valem saber antes de a próxima
seção montá-lo:

- **Um endereço para o mundo todo.** O mesmo IP é anunciado das localidades de borda do Google em todo lugar;
  um cliente em Lisboa chega a uma borda perto de Lisboa, e a própria rede do Google leva o pedido até onde os
  backends estiverem. Isso é *anycast*, e é por isso que não há truque de DNS para mandar as pessoas à região
  mais próxima.
- **O TLS termina na borda.** O certificado fica no balanceador, o handshake do cliente acontece a poucos
  milissegundos dele, e os backends recebem HTTP simples pela rede do Google, ou HTTPS de novo se o serviço de
  backend for configurado assim.
- **É onde os recursos de borda se prendem.** O Cloud CDN guarda respostas em cache na borda, e o Cloud Armor
  filtra pedidos antes de chegarem a um backend. Os dois são configurações do serviço de backend, o quarto elo
  da próxima seção.

Nenhum dos balanceadores é uma máquina que o cliente opera. Os proxies são do Google, as verificações de saúde
vêm das faixas do Google `35.191.0.0/16` e `130.211.0.0/22`, e a única coisa que a rede do planner precisa saber
sobre eles é a regra da lição 16 que deixa essas faixas alcançarem os backends.
