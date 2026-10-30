---
title: Quem paga o quê
version: 1
---

**Um custo pertence ao projeto dono do recurso, e a conta de faturamento do projeto o paga.** Essa regra
responde à maioria das perguntas, e as exceções são onde as faturas surpreendem. Nada nesta seção foi
rodado: não há fatura no laboratório, e as regras abaixo vêm da documentação de faturamento do Google.

## O caso comum

Uma máquina virtual no `planner-prod` é cobrada do `planner-prod`, e a conta de faturamento do
`planner-prod` paga. Um tópico do Pub/Sub no `planner-dev` é cobrado do `planner-dev`. Os rótulos, da lição
3, dividem então os custos de cada projeto por equipe ou finalidade dentro da fatura. Uma conta de
faturamento pagando vinte projetos dá uma fatura com vinte projetos nela, que é o arranjo que a maioria
das empresas quer: **uma conta por pessoa jurídica que paga**, muitos projetos sob ela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l11-who-pays\" aria-label=\"Uma conta de faturamento, ao lado da árvore e não dentro dela, pagando três projetos em duas pastas diferentes: planner-prod, planner-dev e planner-network. Cada projeto leva os próprios custos: planner-prod as suas máquinas e o tráfego que elas mandam, planner-dev os seus tópicos, planner-network o gateway do Cloud NAT por onde passa o tráfego dos outros projetos. Rótulos dividem os custos de cada projeto por equipe dentro da fatura.\"><rect x=\"270.0\" y=\"16.0\" width=\"180.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">conta de faturamento</text><text x=\"360.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">012345-6789AB-CDEF01</text><path d=\"M360.0 64.0 L110.0 116.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"20.0\" y=\"116.0\" width=\"180.0\" height=\"84.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">planner-prod</text><text x=\"110.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">máquinas, e o tráfego</text><text x=\"110.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">que elas mandam</text><path d=\"M360.0 64.0 L360.0 116.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"270.0\" y=\"116.0\" width=\"180.0\" height=\"84.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">planner-dev</text><text x=\"360.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tópicos</text><path d=\"M360.0 64.0 L610.0 116.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"520.0\" y=\"116.0\" width=\"180.0\" height=\"84.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">planner-network</text><text x=\"610.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o gateway do</text><text x=\"610.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Cloud NAT</text><text x=\"360.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">cada projeto vinculado a uma conta</text><text x=\"360.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dentro de cada projeto, rótulos dividem os custos por equipe</text><text x=\"360.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a conta fica ao lado das pastas, não dentro delas</text></svg>", "caption": "O projeto leva o custo; o vínculo dele diz que conta paga."}
```

## Onde fica interessante

- **O tráfego de rede é cobrado do projeto da máquina que o manda.** A página de preços da lição 1 diz isso
  com essas palavras. Uma máquina no `planner-prod` mandando backups para Santiago paga os 0,14 por GiB, não
  o projeto que os recebe.
- **Uma rede compartilhada divide a fatura.** A lição 18 põe a rede no `planner-network` e as máquinas nos
  projetos que a usam. As máquinas, os discos delas e o tráfego que mandam são cobrados dos projetos em que
  moram; recursos que pertencem à própria rede, como um gateway do Cloud NAT ou um túnel de VPN, são cobrados
  do `planner-network`. Uma equipe que só lê a fatura do próprio projeto não vê o gateway de NAT por onde o
  tráfego dela passa.
- **Algumas cobranças não têm projeto.** Planos de suporte e algumas compras do marketplace são cobrados
  direto da conta de faturamento, e aparecem na fatura fora de todo projeto.
- **Os créditos são aplicados antes do total.** O crédito do período de teste, um crédito promocional e os
  descontos por uso contínuo da lição 13 aparecem como linhas negativas contra os custos que reduzem. Um
  relatório que soma custos sem créditos exagera a fatura; um que soma só o total não sabe dizer o que os
  créditos cobriram.

## Várias contas de faturamento

Há bons motivos para mais de uma: **pessoas jurídicas diferentes**, cada uma pagando a própria fatura; as
**subcontas de um revendedor**, uma por cliente, sob a conta do revendedor; ou uma **conta sandbox** com
orçamento baixo e cartão próprio, para experimentos que nunca deveriam cair na fatura da produção. Há também
um motivo ruim, dividir os custos de uma empresa por equipe, que os rótulos e a exportação da lição 14 fazem
melhor sem mover projeto nenhum.

A pergunta "quem paga isto?" tem portanto duas respostas no Google Cloud: **que conta de faturamento**,
decidida pelo vínculo do projeto, e **que equipe dentro dela**, decidida pelos rótulos. As próximas três
lições são sobre ler essas duas respostas numa fatura real.
