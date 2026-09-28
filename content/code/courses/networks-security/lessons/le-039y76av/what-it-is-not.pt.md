---
title: O que Zero Trust não é
version: 1
---

Zero Trust é mais vendido do que explicado, e três leituras erradas causam dano de verdade.

**Não é um produto.** Um fornecedor pode vender um ponto de aplicação de política, um provedor de
identidade ou um gateway de acesso remoto, e cada um pode fazer parte de um projeto Zero Trust. Nenhum
deles é um. O projeto é a decisão de autenticar e autorizar toda requisição pela identidade, aplicada
serviço por serviço, e pode ser construído, como esta aula fez, com TLS e uma autoridade certificadora.

**Não é o fim dos controles de rede.** O laboratório manteve o firewall. A porta da aplicação está
aberta só a partir do lado dos servidores, a DMZ continua alcançando só o que precisa, e a LAN da
equipe continua sem poder tocar o banco de dados. Se uma verificação de identidade tiver uma falha, a
rede limita quem consegue sequer tentá-la. As duas camadas respondem a perguntas diferentes, *este
pacote pode chegar aqui* e *este sujeito pode fazer isto*, e um projeto que abandona a primeira fica
com um controle onde tinha dois.

**Não se faz uma vez só.** Todo serviço que passa para o acesso baseado em identidade é uma migração:
emitir identidades, mudar os clientes, remover o caminho antigo, que é a parte que as pessoas pulam. A
mudança de firewall desta aula que apagou as duas regras para a 8080 é o passo que deu sentido à nova
verificação; enquanto a porta antiga fica aberta, a verificação de identidade é uma porta da frente ao
lado de uma janela aberta.

Uma ordem de trabalho prática, que a maioria das organizações segue de alguma forma:

| passo | o que cobre |
|---|---|
| inventário | todo serviço, quem o usa e como essas pessoas se autenticam hoje |
| identidades | pessoas por login único (*single sign-on*) com múltiplos fatores; máquinas por certificados |
| os serviços mais valiosos primeiro | interfaces de administração, finanças, os dados cuja perda mais doeria |
| remover o caminho só de rede | a porta antiga, a rota de VPN que contornava a verificação |
| registrar toda decisão com a identidade | para que o próximo incidente comece por *quem* |
