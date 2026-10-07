---
title: Totais negativos: um valor impossível com causa conhecida
version: 1
---

**A aula 2 achou 137 pedidos com total negativo**, todos com um cupom que vale mais que a cesta e o
frete juntos. Não são valores atípicos no sentido estatístico — alguns reais abaixo de zero ficam
perto do mínimo da distribuição — mas são impossíveis: ninguém recebe para comprar comida.

A causa é conhecida, então a decisão pode ser tomada por regra e não caso a caso. O site subtraiu o
cupom por inteiro; o gateway de pagamento, consultado por Ana, confirma que nunca cobra um valor
negativo, então o que esses clientes pagaram foi zero. **O total vira zero e é marcado**, e a marca diz
por quê: `coupon above basket: charged 0`.

Duas coisas fazem disso a escolha certa e não a conveniente:

- **a troca vem do negócio, não do dado.** Zero é o que foi cobrado, como o time de pagamentos
  afirma; não é estimativa de nada;
- **a regra por trás disso é informada a quem a causa.** Um checkout que deixa um cupom passar da
  cesta vai continuar produzindo essas linhas, e a correção cabe ao site, onde um cupom pode ser
  limitado ao valor da cesta.

O padrão geral: **um valor que quebra uma regra do domínio é inválido, e valores inválidos com causa
conhecida ganham uma regra, uma marca e um aviso a quem é dono da causa.** A aula 1 chamou isso de
validade; aqui é a mesma dimensão encontrada numa coluna numérica.
