---
title: Qual, e quando
version: 1
---

**Shared VPC e peering respondem a duas perguntas diferentes.** O Shared VPC responde *como várias equipes de
uma empresa usam uma rede sem dividir um projeto*. O peering responde *como duas redes que pertencem a donos
diferentes conversam*. A maioria das empresas do tamanho do planner usa os dois, para vizinhos diferentes.

| | Shared VPC | Peering de VPC |
|---|---|---|
| quantas redes | **uma**, no projeto host | **duas**, cada uma com seu dono |
| organizações | a mesma | qualquer |
| quem opera o firewall | a equipe de rede do host, para todos | cada lado, para as próprias máquinas |
| quem concorda | o Shared VPC Admin prende um projeto | **os dois** lados criam o peering |
| faixas sobrepostas | impossível: é uma rede | recusadas |
| transitivo | não se aplica: todos estão numa rede | **não** |
| cobrança | cada projeto de serviço paga pelas próprias máquinas e pelo tráfego delas | cada lado paga pelas próprias máquinas e pelo tráfego que elas mandam |

## O ambiente do planner, decidido

- **Produção e staging** são projetos de serviço do `planner-network`. Uma equipe de rede, um conjunto de regras
  de firewall, uma lista de faixas, a regra prática da lição 15 guardada num lugar só.
- **Desenvolvimento** mantém uma rede própria no `planner-dev`, a que este curso vem planejando, para os
  desenvolvedores mudarem as regras dela sem pedir à equipe de rede. Ela não tem peering com a produção de
  propósito: nada em desenvolvimento deve conseguir alcançar um banco de produção, e um peering seria o
  primeiro passo para isso.
- **O parceiro** tem peering com o `planner-network`, com rotas personalizadas nem exportadas nem importadas, e
  regras de firewall do lado do planner que deixam o parceiro alcançar um serviço numa porta.
- **A empresa comprada** espera. A faixa de São Paulo dela se sobrepõe à do planner, então ela é renumerada
  primeiro e recebe o peering depois, ou é alcançada por algo que traduza endereços, que nenhum dos dois faz.

## Quando nenhum basta

A recusa do peering em ser transitivo vira problema lá pela quinta rede, quando todo par que precisa conversar
precisa de um peering próprio e a lista cresce com o quadrado das redes. A resposta do Google a isso é o
**Network Connectivity Center**, um hub a que as redes se prendem como raios e pelo qual se alcançam, e é onde
uma empresa com muitas redes acaba chegando. Ele é nomeado aqui para que o momento de precisar dele seja
reconhecido; o planner, com dois vizinhos, não precisa.
