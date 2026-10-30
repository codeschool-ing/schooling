---
title: O que custa, e o que medir
version: 1
---

**Um WAF é cobrado pela política, por cada regra e pelas requisições que inspeciona**, e o formato da conta muda entre os dois
lugares. No Front Door, o WAF vem com o preço do nível Premium e as cobranças por requisição dele; no Application Gateway, o WAF
é um nível do próprio gateway, cobrado por hora e por unidade de capacidade. Este curso não conseguiu ler a lista de preços (a
lição 1, seção 03), então não dá números; o formato é com o que se planeja.

O que uma equipe deveria medir com o WAF rodando não é o número de bloqueios, que conta sobretudo scanners e não diz nada sobre
segurança. São três coisas:

- **falsos positivos**: requisições legítimas bloqueadas, achadas pelas reclamações de clientes e pelos 403 em rotas que os
  clientes usam. Cada uma é uma venda perdida;
- **acertos de regras personalizadas**: com que frequência o `checkoutRateLimit` dispara, e de onde. Uma alta repentina é alguém
  tentando, e vale um olhar mesmo com a regra tendo segurado;
- **regras em Detection**: qualquer coisa que ainda não bloqueia, e por quê. Uma política deixada em Detection por um ano é um
  log, não um firewall.

Nenhum desses números existe no laboratório. Os três são consultas na tabela de log do WAF, escritas no KQL da lição 10 quando
os logs existirem.
