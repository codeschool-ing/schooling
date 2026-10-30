---
title: O Advisor, a mesma pergunta feita pelo Azure
version: 1
---

**O Azure Advisor faz essas verificações por você, continuamente, e lista o que acha** como recomendações de custo: *redimensionar ou
desligar máquinas virtuais subutilizadas*, *apagar discos desanexados*, *apagar IPs públicos sem associação*, e várias outras para
bancos, App Service e reservas. Ele é gratuito, e lê os mesmos sinais: métricas de plataforma para CPU e rede, o Resource Graph para o
que está ligado a quê.

A regra de VMs do Advisor é documentada como um limite configurável: uma VM cuja CPU fica abaixo de uma porcentagem que você escolhe,
numa janela que você escolhe, é marcada, e o Advisor sugere um tamanho menor da mesma família, com uma economia estimada. Ele também
propõe **reservas**, a compra da lição 22, a partir do uso recente. Nada disso foi executado aqui: o Advisor mora numa assinatura.

Dois motivos para a loja ainda escrever as próprias consultas. **Ela consegue lê-las**: uma recomendação do Advisor é uma conclusão, e
uma consulta é o raciocínio, o que importa quando o dono da VM discorda. E **ela consegue acrescentar o que o Advisor não sabe**, como a
tag `owner` ou uma lista de VMs que precisam manter o tamanho por causa de uma licença. O Advisor é por onde começar; uma consulta é
como argumentar.

Mais uma consulta explica a `vm-reports`:

```
ana@laptop:~/azure/kusto$ python3 kql.py 'Perf | where Computer == "vm-reports" | summarize max_cpu = max(CounterValue), hours_over_5 = countif(CounterValue > 5)'
max_cpu  hours_over_5
2.0      0
```

A CPU dela nunca passou de 2% em duas semanas. O Advisor diria *desligue*, e estaria certo para essas duas semanas. A dona, quando for
achada, vai dizer que ela roda os relatórios de fim de mês nos dois últimos dias do mês, que essas duas semanas não contêm. É o motivo
de a próxima seção existir.
