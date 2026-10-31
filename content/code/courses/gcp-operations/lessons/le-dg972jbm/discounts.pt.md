---
title: Quatro formas de pagar menos pela mesma máquina
version: 1
---

**O Compute Engine tem uma tabela de preços e quatro formas de pagar menos que ela, e elas não podem ser
combinadas sobre o mesmo uso.** Duas são automáticas, duas exigem uma decisão; uma não abre mão de nada, as outras
abrem mão de flexibilidade, de garantia de capacidade ou da possibilidade de parar de pagar. As quatro são lidas
aqui na página de preços do Compute Engine, em 30 de outubro de 2026; nenhuma pode ser praticada sem conta, e a
aritmética de escolher entre elas, que pode, é a próxima seção.

| desconto | do que você abre mão | quanto |
|---|---|---|
| **uso contínuo (SUD)** | de nada: é automático | até 30% líquido para um recurso usado o mês inteiro, nos tipos de máquina que o recebem |
| **compromisso por recursos** | de uma quantidade fixa de vCPU e memória, numa região, paga por 1 ou 3 anos usada ou não | até 37% em 1 ano; 55% em 3 anos (70% para tipos otimizados para memória) |
| **compromisso flexível do Compute** (por gasto) | de um gasto por hora fixo, pago por 1 ou 3 anos, utilizável entre famílias de máquina e regiões | 28% em 1 ano, 46% em 3 anos, sobre o gasto comprometido |
| **Spot VMs** | da máquina: o Google pode pará-la a qualquer momento com 30 segundos de aviso | até 91% abaixo do preço sob demanda, variando até uma vez por dia |

Três coisas que a tabela não diz, e que decidem a maioria das escolhas:

- **Um compromisso é pago rodando algo ou não.** É um contrato pelo prazo, e não pode ser cancelado. Um compromisso
  de oito máquinas quando quatro estão rodando paga oito.
- **Os descontos não se somam.** Um recurso coberto por um compromisso não recebe desconto de uso contínuo, então o
  SUD que um time já recebia é subtraído do que um compromisso economiza para ele.
- **Spot é para trabalho que pode ser interrompido**: jobs de batch, executores de teste, a CI da lição 1 em pools
  privados. Uma API que atende clientes não é isso, seja qual for o desconto.

## Para onde vai o dinheiro da loja

A API da loja roda no Cloud Run, que é cobrado por requisição e por segundo de instância, não por máquina. Os
compromissos flexíveis do Compute cobrem o Cloud Run além do Compute Engine, e por isso o tipo por gasto é o que
importa para a loja; o tipo por recursos cobre máquinas do Compute Engine, que a loja só tem para o trabalho de
batch. A frota da próxima seção é esse trabalho de batch, e o raciocínio é o mesmo para qualquer tipo: comprometa o
que sempre está rodando, nunca o pico.
