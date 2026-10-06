---
title: Quanto um control plane custa em dinheiro
version: 1
---

Comece pelos números que a lição 6 leu das listas de preço, e transforme-os em meses. Um mês de 730
horas é a média que um ano de 8.760 horas dá:

| | por hora | por mês de 730 horas | por ano |
|---|---|---|---|
| control plane EKS ou GKE, suporte padrão | 0,10 dólar | 73,00 dólares | 876 dólares |
| o mesmo, em suporte estendido | 0,60 dólar | 438,00 dólares | 5.256 dólares |
| free tier do GKE, por conta de cobrança | | um crédito de 74,40 dólares | |

**Um control plane gerenciado custa 73 dólares por mês**, e no GKE o primeiro cluster zonal ou
Autopilot não custa nada. A linha do suporte estendido é a que merece atenção:
um cluster deixado numa versão antiga custa seis vezes mais, que é o jeito dos provedores de dizer
"atualize".

## Rodando o control plane você mesmo

Um control plane seu precisa de máquinas próprias. **Para sobreviver à perda de uma máquina, o etcd
precisa de três membros**, como a lição 4 explicou: a maioria de três é dois. Então o custo em máquinas
é

`3 × (preço de uma máquina por hora) × 730`

e o preço por hora é o que o seu provedor cobra pelo tamanho que você escolher. Este curso não leu uma
lista de preços de máquinas virtuais, então nenhum valor é dado aqui; ponha o seu. A qualquer preço
acima de uns 0,033 dólar por hora por máquina, três máquinas já custam mais que a taxa de 73 dólares,
antes de alguém gastar uma hora com elas.

Os nós workers nem entram na comparação. **Eles custam o mesmo seja o control plane seu ou do
provedor**, porque são as mesmas máquinas pelo mesmo preço, e quase sempre são a maior linha da conta.

::: track cloud-engineering
O curso `cloud`, antes na sua trilha, definiu orçamentos e alertas de gasto na lição 10. A conta de um
cluster merece um: um pool de nós esquecido ou um cluster deixado no suporte estendido é exatamente o
que eles pegam.
:::

::: track *
Seja qual for o jeito de rodar, defina um orçamento e um alerta de gasto na conta em que o cluster é
cobrado: um pool de nós esquecido ou um cluster deixado no suporte estendido é exatamente o que eles
pegam.
:::
