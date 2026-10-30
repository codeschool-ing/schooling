---
title: Uma fatura é uma lista de SKUs
version: 1
---

**Toda linha de uma fatura do Google Cloud é um SKU: uma coisa que o Google vende, a um preço, num lugar.**
Uma máquina virtual não é uma linha. As vCPUs dela são um SKU, a memória outro, o disco um terceiro, o
tráfego que ela manda um quarto, cada um com a sua unidade e o seu preço por unidade. A página de preços do
próprio Google para o Compute Engine diz isso com todas as letras, lida em 30 de outubro de 2026: *each vCPU
and each GB of memory on Compute Engine is billed separately rather than as part of a single machine type*.
Nada nesta lição rodou contra uma fatura; o laboratório não tem nenhuma, e os números dela são ou regras
publicadas pelo Google ou aritmética sobre um preço de exemplo, dito onde aparecem.

Uma linha da fatura, lida da esquerda para a direita:

| campo | exemplo | o que diz |
|---|---|---|
| **serviço** | Compute Engine | que produto |
| **SKU** | N2 Instance Core running in Sao Paulo | o que exatamente, e onde |
| **uso** | 1,460 hour | quanto, na unidade do próprio SKU |
| **custo** | o uso vezes o preço | antes de qualquer desconto |
| **créditos** | um desconto por uso contínuo, uma promoção | valores negativos contra esse custo |
| **projeto**, **rótulos** | `planner-prod`, `team=planner` | de quem é, lições 3 e 11 |

Duas coisas decorrem disso. **O tipo de máquina não está na fatura**: um `n2-standard-4` aparece como quatro
vCPUs de núcleos N2 e dezesseis gigabytes de memória N2, hora a hora, então uma pergunta sobre uma máquina
é respondida filtrando pelos rótulos dela, não procurando o nome. E **o SKU leva a região**, e é por isso
que a mesma máquina custa diferente em São Paulo e em Iowa, e por isso que os preços de rede da lição 1
foram dados por travessia.

## Uma fatura que chegou errada

A maioria das faturas que surpreendem surpreende de um punhado de jeitos, e a ordem de olhar é a ordem
abaixo. Cada um é uma linha que alguém poderia ter achado na tabela de custos do console, agrupada por SKU e
projeto, antes de a fatura chegar.

1. **Algo está rodando de que ninguém se lembra.** Uma máquina de uma demonstração, um balanceador de carga
   de um teste. O SKU dá o nome; o projeto e os rótulos dizem de quem é.
2. **Algo está guardado que ninguém usa.** O disco de uma máquina apagada, um agendamento de snapshots, um
   endereço externo estático preso a nada, cobrado a um preço maior que o de um em uso.
3. **Tráfego.** Saída para a internet ou entre regiões, lição 1, cobrada de quem manda. É a linha que cresce
   com o sucesso, e a que nenhum recurso sozinho explica.
4. **Um desconto parou.** O crédito do teste gratuito acabou, uma promoção terminou, ou um compromisso
   expirou e as mesmas máquinas voltaram ao preço sob demanda. O uso não mudou; a linha de créditos mudou.
5. **Um serviço novo foi ligado.** Alguém habilitou uma API num projeto, lição 3, e ela cobra.

**A cura é a mesma em todos os casos: ache o SKU, ache o projeto, leia os rótulos.** A lição 14 faz isso com
uma consulta em vez do console, que é como se faz quando uma empresa tem mais que uns poucos projetos.
