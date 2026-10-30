---
title: "A conta: DBUs, e as máquinas por baixo delas"
version: 1
---

**Uma conta do Databricks tem duas linhas para computação clássica e uma para serverless.** A
computação clássica paga o Databricks em DBUs, Databricks Units, e paga o Azure pelas máquinas
virtuais; a serverless paga só o Databricks, em DBUs que incluem as máquinas. A estrutura vem da
documentação do Databricks e da Microsoft; os preços abaixo são **ilustrativos**, números redondos para
fazer a conta e não a tabela de preços de ninguém, e nada aqui foi cobrado.

## O que é uma DBU

**Uma DBU é uma unidade de processamento por hora, e cada tamanho de máquina consome um número fixo
delas por hora em que roda.** Uma máquina maior consome mais DBUs por hora, e o preço de uma DBU
depende do tipo de computação, all-purpose, jobs, SQL ou serverless, e do tier do workspace. Então o
custo de uma hora de um cluster clássico é, para cada máquina:

```
DBUs per hour of the machine × price per DBU for this kind of compute + Azure's price for the machine
```

**As duas metades crescem com o número de máquinas e com as horas**, e por isso as decisões da seção
anterior, job ou all-purpose, auto termination, pools, são decisões sobre a conta.

## A noite da Quitanda, de três jeitos

O notebook de limpeza precisa de um driver e quatro workers por 30 minutos por noite. Tome, como
números ilustrativos, uma máquina que consome **1 DBU por hora**, o preço do Azure para essa máquina a
**0,20 USD por hora**, e DBUs a **0,30 USD na tarifa de jobs** e **0,55 na tarifa all-purpose**. Cinco
máquinas:

| arranjo | horas por mês | DBUs | custo em DBU | custo das máquinas | USD por mês |
|---|---:|---:|---:|---:|---:|
| cluster de job, 30 minutos por noite | 5 × 0,5 × 31 = 77,5 | 77,5 | 23,25 | 15,50 | 38,75 |
| cluster all-purpose, para depois de 60 minutos ocioso | 5 × 1,5 × 31 = 232,5 | 232,5 | 127,88 | 46,50 | 174,38 |
| cluster all-purpose, nunca parado | 5 × 730 = 3.650 | 3.650 | 2.007,50 | 730,00 | 2.737,50 |

**A mesma meia hora de trabalho custa 38,75, 174,38 ou 2.737,50 por mês com esses números**, e nada
no trabalho mudou. A segunda linha paga a tarifa all-purpose e uma hora ociosa por noite; a terceira é
o cluster que alguém esqueceu. A conta é ilustrativa; as proporções são o que a estrutura garante, e
são o motivo de um job noturno pertencer a um cluster de job e de todo cluster all-purpose ter a auto
termination ligada.

**O serverless muda o formato, não o princípio.** Ele cobra só DBUs, a um preço próprio por DBU, pelo
tempo em que o trabalho roda, sem partida nem hora ociosa para pagar. Se sai mais barato que a
primeira linha depende dos dois preços, que a tabela de preços da lição 1 lê para a metade do Azure e
a página de preços do Databricks dá para as DBUs.

## O que a conta deixa de fora

**O armazenamento e a rede são cobrados pelo Azure como sempre**: as operações e a capacidade do lago
da lição 7, e a própria conta de armazenamento do grupo de recursos gerenciado. E um workspace no tier
`premium` paga o preço premium por toda DBU, rode o que rodar, que é o preço dos controles de acesso e
do catálogo da próxima seção.
