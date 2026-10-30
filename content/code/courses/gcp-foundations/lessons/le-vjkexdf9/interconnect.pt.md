---
title: Cloud Interconnect, a estrada privada
version: 1
---

**O Cloud Interconnect troca a internet entre o datacenter e o Google por um circuito.** O tráfego não atravessa
a internet pública de jeito nenhum, não é criptografado pelo Google por padrão porque não precisa ser do jeito
que o de uma VPN precisa, e a banda e a latência dele são as do circuito, e não as que o provedor do escritório
resolver entregar naquela tarde. É para onde uma empresa vai quando a VPN enche, ou quando os dados que passam
por ela são grandes o bastante para o preço de transferência menor importar.

Há dois jeitos de ter um:

| | Dedicated Interconnect | Partner Interconnect |
|---|---|---|
| o que é | um cabo físico do roteador da empresa ao do Google, numa instalação de colocation em que os dois estão | uma conexão por um provedor de serviço que já está conectado ao Google |
| capacidade | circuitos de 10, 100 ou 400 Gbps | attachments de 50 Mbps a 50 Gbps |
| quem precisa | uma empresa com equipamento próprio numa das instalações de colocation do Google | todo o resto |

**O attachment de VLAN** é a peça dentro do Google Cloud nos dois casos: ele prende uma conexão a um Cloud Router
numa região de uma rede VPC, e o router fala BGP por ele exatamente como fala por um túnel HA VPN. As rotas do
escritório chegam como rotas dinâmicas, as sub-redes do planner são anunciadas ao escritório, e nada na rede
acima do router sabe se as rotas vieram por VPN ou por circuito.

O **Cross-Cloud Interconnect** é a mesma coisa com outra nuvem na outra ponta do cabo, para a empresa cujos dados
vivem num provedor e cuja computação vive em outro.

## Criptografia sobre um circuito

Um circuito é privado, o que não é o mesmo que criptografado: o tráfego nele pode ser lido por quem tiver acesso
ao cabo ou ao equipamento do provedor. Existem duas respostas, e a equipe de segurança do planner escolhe uma
antes de o primeiro byte de dados de clientes atravessar:

- **MACsec** no Dedicated Interconnect, que criptografa cada quadro no enlace entre o roteador da empresa e o do
  Google;
- **HA VPN sobre o Cloud Interconnect**, que roda túneis IPsec pelo attachment, de modo que o circuito só leva
  tráfego criptografado, ao custo dos próprios limites da VPN por túnel.

## Nada para rodar

O Interconnect não pode ser rodado no laboratório nem planejado de forma útil sem um: uma conexão é pedida, uma
carta de autorização é emitida para a instalação de colocation, e alguém liga um cabo. Os recursos de Terraform
existem, `google_compute_interconnect_attachment` entre eles, e descrevem a metade que é software depois que a
metade física está feita. Essa metade são semanas de prazo, e é a primeira coisa a saber sobre ela quando o
cronograma de um projeto depende dela.
