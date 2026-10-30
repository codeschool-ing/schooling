---
title: Proteção contra DDoS, e quanto custa o Cloud Armor
version: 1
---

**A borda do Google absorve os grandes ataques de rede antes de qualquer coisa sua vê-los.** Uma inundação de
pacotes mirando o endereço do balanceador da loja (do tipo medido em centenas de gigabits) cai na borda do Google,
que descarta tráfego que não é uma conexão válida a um application load balancer. Essa proteção vem com o
balanceador e não é configurada; nada na política da loja trata disso. **O que o Cloud Armor acrescenta são os
ataques que parecem requisições reais**: um `GET /products` bem formado mandado um milhão de vezes por minuto é
HTTP válido, e só uma regra que conta e recusa o para. Esta seção vem da documentação do Google e da página de
preços, e nada foi executado.

## Standard e Enterprise

O Cloud Armor vem em dois níveis. O **Standard** é pago pelo uso: políticas, regras e requisições são cobradas, e
tudo nesta lição está disponível nele. O **Enterprise** acrescenta proteção adaptativa (um modelo que aprende o
tráfego normal de cada backend e propõe uma regra quando começa um ataque na camada 7), listas de inteligência de
ameaças com endereços maliciosos conhecidos, e acesso à equipe de resposta a DDoS do Google durante um ataque, por
um preço mensal por projeto ou por conta de faturamento.

Pela página de preços, lida em 30 de outubro de 2026, para políticas de escopo global no nível Standard:

| item | preço | por mês (730 horas) |
|---|---|---|
| uma política de segurança | 0,006849315 USD por hora | 5,00 USD |
| uma regra | 0,001369863 USD por hora | 1,00 USD |
| requisições avaliadas | 0,75 USD por milhão | |

O Enterprise pago pelo uso custa 0,273972603 USD por hora por projeto, 200 USD por mês, incluindo dois recursos
protegidos; a assinatura anual custa 4,109589041 USD por hora, 3.000 USD por mês, incluindo até 100.

## A conta da loja

Uma política e três regras: 5 + 3 × 1 = 8 USD por mês. Requisições: a loja atende cerca de 400.000 por dia (lição
13), uns 12 milhões num mês, a 0,75 USD por milhão, cerca de 9 USD. Então **cerca de 17 USD por mês** pela política
desta lição. Durante um ataque a cobrança de requisições cresce com o ataque, já que toda requisição avaliada é
cobrada, inclusive as recusadas; uma inundação de 100 milhões de requisições são 75 USD. Esse é o caso para o qual
o preço do Enterprise foi pensado: as requisições dele estão incluídas, e ele oferece proteção na fatura para
ataques documentados.

Para a loja, o Standard é o nível certo. O Enterprise começa a fazer sentido quando a receita por hora de queda de
um negócio é maior que a assinatura, e quando alguém às três da manhã ia querer a equipe do Google na chamada.
