---
title: A conta, e a decisão
version: 1
---

**Qual plano, se algum, é aritmética primeiro e julgamento depois.** Este curso não conseguiu ler a lista de preços (a lição 1,
seção 03), então a conta usa **valores redondos ilustrativos** com o formato certo, que você troca pelos de hoje na sua região:

- Network Protection: **3.000 USD por mês** por um plano que cobre até **100** IPs públicos, mais um valor por IP acima disso;
- IP Protection: **200 USD por mês** por IP protegido.

A 200 USD cada, o IP Protection custa o mesmo que o plano em 3.000 ÷ 200 = **15 IPs protegidos**. Abaixo disso, o IP Protection
sai mais barato; acima, o plano sai, e o plano ainda traz resposta rápida e proteção de custo, que nem têm preço no nível por IP.

Depois, o julgamento, em três perguntas:

1. **Quais IPs públicos seriam protegidos?** O tráfego dos clientes da loja entra pelo Front Door, que tem proteção própria na
   borda e não é um IP público na rede virtual da loja. Os IPs públicos regionais dela são o endereço de saída de um NAT gateway e
   um bastion host: nenhum é como os clientes chegam.
2. **Quanto custa uma hora fora do ar?** O orçamento de erro da lição 14 pôs preço nas falhas; se uma inundação contra um IP
   regional derrubasse os pedidos, esse preço é a comparação.
3. **Quem atenderia às 03:00?** A resposta rápida vale mais para uma equipe sem engenheiro de rede de plantão.

Para a loja, hoje, a resposta é **nenhum plano**: a entrada dos clientes é o Front Door, e os IPs regionais não carregam nada de
que os clientes dependam. Isso muda no dia em que ela puser um Application Gateway público em `brazilsouth`, e a decisão fica
escrita com essa condição, para a próxima pessoa saber quando perguntar de novo.
