---
title: O desconto
version: 1
---

O Google tem máquinas que ninguém está alugando num dado momento, e vende essa capacidade sobrando
com desconto sob uma condição: **ele pode pegar a máquina de volta sempre que precisar da capacidade,
com trinta segundos de aviso.** Uma Spot VM é uma máquina comum, de um tipo comum, com essa condição
anexada. Tudo que esta lição ensina decorre da condição, e o preço é o motivo de aguentá-la.

## O que se economiza

A tabela da lição 1 mostra o preço Spot ao lado do sob demanda para os tipos que a página de Spot
listava:

```
ana@laptop:~/gcp$ python3 prices.py vm | grep -E "Spot|0\.0[0-9]*$"
                                    per hour   per month   Spot/hour
  e2-standard-2   2 vCPU   8 GiB    0.06701142       48.92    0.040212
  n4-standard-2   2 vCPU   8 GiB        0.0907       66.21    0.053652
  n2-standard-2   2 vCPU   8 GiB      0.097118       70.90    0.058256
  c4-standard-2   2 vCPU   7 GiB      0.096866       70.71    0.057979
  c4a-standard-2  2 vCPU   8 GiB        0.0898       65.55    0.044388
```

Divida uma coluna pela outra e o desconto fica em cerca de **40% na E2, N2, N4 e C4**, e cerca de
**51% na C4A**: a `e2-standard-2` cai de 0,067 para 0,040 por hora, a `c4a-standard-2` de 0,0898
para 0,0444. A página de Spot do Google anuncia descontos de até 91% em alguns tipos, e o tamanho do
desconto depende do tipo e da região. Estes cinco, em Iowa, em 30 de outubro de 2026, ficavam todos
entre 40% e 51%.

**Os preços Spot mudam.** Os preços sob demanda mudam raramente e com aviso; os preços Spot são
revistos pelo Google conforme muda a capacidade sobrando, e é por isso que as páginas de preço os
listam à parte. Um orçamento feito sobre um preço Spot está feito sobre um número que não vai ser o
mesmo no próximo trimestre, então vale refazer a conta em vez de decorá-la.

## Spot e preemptível

Documentações e Terraform mais antigos falam de máquinas **preemptíveis**. São a mesma ideia com mais
um limite: uma máquina preemptível é parada depois de no máximo 24 horas mesmo que ninguém precise da
capacidade. As máquinas Spot as substituíram e não têm esse limite; uma Spot pode rodar por semanas
se o Google nunca precisar dela de volta. No Terraform as duas são escritas no bloco `scheduling`, e
Spot é a que se escreve hoje. A ajuda do gcloud descreve os modelos de provisionamento numa frase
cada:

```
ana@laptop:~/gcp$ gcloud compute instances create --help | sed -n '/^         SPOT/,/^$/p'
         SPOT
            Compute Engine may stop a Spot VM instance whenever it needs
            capacity. Because Spot VM instances don't have a guaranteed
            runtime, they come at a discounted price.
         STANDARD
            The default option. The STANDARD provisioning model gives you full
            control over your VM instances' runtime.
```

**"Don't have a guaranteed runtime"**, não ter um tempo de execução garantido, é o contrato inteiro, e
não é uma probabilidade que alguém publique. Uma máquina Spot pode rodar um mês ou ser retomada na
primeira hora, e o resto desta lição é sobre construir trabalho que não se importa com qual dos dois.
