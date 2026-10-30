---
title: Um orçamento, e o que os limites dele querem dizer
version: 1
---

**Um orçamento é um valor e uma lista de limites, presos a uma conta de faturamento, que manda uma mensagem
quando o gasto passa de um deles.** É só isso que ele faz, e a frase que as pessoas mais precisam ouvir
sobre os orçamentos do Google Cloud é a que menos esperam: **um orçamento não para o gasto.** Passar de
100% manda um e-mail e, se pedido, uma mensagem do Pub/Sub. As máquinas continuam rodando. A seção da
conta real na lição 1 pôs o orçamento primeiro por isso: ele é um aviso, e um aviso vale mais enquanto o
valor ainda é pequeno.

## Do que um orçamento é feito

| parte | o que diz | a escolha do planner |
|---|---|---|
| **escopo** | que custos contam: a conta de faturamento inteira, alguns projetos, alguns serviços, alguns rótulos | os três projetos do planner |
| **valor** | uma quantia fixa, ou **o gasto do mês passado**, que acompanha a fatura conforme ela cresce | 300 USD por mês |
| **limites** | porcentagens do valor, cada uma sobre o gasto **real** ou o **previsto** | 50%, 90% e 100% real; 100% previsto |
| **quem ouve** | os administradores da conta de faturamento por e-mail, canais de monitoramento escolhidos, e um tópico do Pub/Sub | e-mail, e o tópico da próxima seção |

**Real e previsto são as duas palavras a separar.** Um limite real dispara quando o dinheiro já foi
gasto. Um limite previsto dispara quando a projeção do Google diz que o mês **vai** terminar acima dele, o
que pode ser no quinto dia do mês, enquanto ainda há tempo de agir. Os dois juntos dizem a uma equipe
tanto "vocês estão a caminho de gastar demais" quanto "vocês gastaram demais".

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l12-month\" aria-label=\"Um mês de gasto contra um orçamento de 300 dólares, com o dia do mês na horizontal e o dinheiro na vertical. Uma linha cheia sobe conforme o dinheiro é gasto: 84,17 dólares no começo do mês, 273,40 mais tarde, 318,92 perto do fim. Uma linha tracejada é a previsão do Google para o fim do mês, que passa dos 300 dólares no dia 5, muito antes da linha cheia. Marcas horizontais em 150, 270 e 300 dólares são os limites reais de 50, 90 e 100 por cento. O limite previsto dispara no dia 5; o de 90 por cento real no dia 26; o de 100 por cento no dia 29.\"><path d=\"M70.0 250.0 L680.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M70.0 250.0 L70.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"70.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"259.3\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><text x=\"469.7\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20</text><text x=\"680.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">30</text><text x=\"364.5\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dia do mês</text><path d=\"M70.0 158.3 L680.0 158.3\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"64.0\" y=\"158.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">150</text><text x=\"684.0\" y=\"158.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">50%</text><path d=\"M70.0 85.0 L680.0 85.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"64.0\" y=\"85.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">270</text><text x=\"684.0\" y=\"85.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">90%</text><path d=\"M70.0 66.7 L680.0 66.7\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"64.0\" y=\"66.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">300</text><text x=\"684.0\" y=\"66.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100%</text><path d=\"M70.0 250.0 L217.2 198.6 L385.5 152.2 L595.9 82.9 L659.0 55.1\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M70.0 250.0 L154.1 213.3 L680.0 42.2\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"6 4\"></path><circle cx=\"154.1\" cy=\"68.7\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"162.1\" y=\"55.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">previsão passa de 300 no dia 5</text><circle cx=\"595.9\" cy=\"82.9\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"587.9\" y=\"98.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">273.40</text><circle cx=\"659.0\" cy=\"55.1\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"651.0\" y=\"45.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">318.92</text><circle cx=\"217.2\" cy=\"198.6\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"225.2\" y=\"202.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">84.17</text><text x=\"448.6\" y=\"213.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">gasto real</text></svg>", "caption": "O limite previsto avisa semanas antes do real."}
```

Um orçamento também **não é instantâneo**. Os custos chegam aos dados de faturamento com atraso de horas,
às vezes mais, então um surto de gasto à tarde pode passar de um limite à noite. A lição 13 volta ao
porquê.

## O orçamento, escrito

Crie um diretório com o arquivo do provider da lição 2:

```sh
mkdir -p ~/gcp/budget && cd ~/gcp/budget
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Salve isto como `budget.tf`:

```hcl
resource "google_billing_budget" "planner" {
  billing_account = "012345-6789AB-CDEF01" # made up for this course
  display_name    = "planner monthly"

  budget_filter {
    projects = ["projects/planner-prod", "projects/planner-staging", "projects/planner-dev"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = "300"
    }
  }

  threshold_rules {
    threshold_percent = 0.5
  }
  threshold_rules {
    threshold_percent = 0.9
  }
  threshold_rules {
    threshold_percent = 1.0
  }
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "FORECASTED_SPEND"
  }

  all_updates_rule {
    pubsub_topic = "projects/planner-dev/topics/budget-alerts"
  }
}
```

```
ana@laptop:~/gcp/budget$ terraform plan -input=false -no-color -out=plan.bin | grep "^Plan:"
Plan: 1 to add, 0 to change, 0 to destroy.
ana@laptop:~/gcp/budget$ terraform show -json plan.bin | jq -c '.resource_changes[0].change.after.threshold_rules[]'
{"spend_basis":"CURRENT_SPEND","threshold_percent":0.5}
{"spend_basis":"CURRENT_SPEND","threshold_percent":0.9}
{"spend_basis":"CURRENT_SPEND","threshold_percent":1}
{"spend_basis":"FORECASTED_SPEND","threshold_percent":1}
```

O segundo comando imprime os limites como o Google os guardaria. O `spend_basis` voltou `CURRENT_SPEND` nos
três limites que não nomeavam nenhum: **o gasto real é o padrão**, e só um limite que diga
`FORECASTED_SPEND` olha para frente. O `all_updates_rule` é a linha que importa para a próxima seção: ela
pede ao Google para publicar toda atualização deste orçamento num tópico do Pub/Sub, várias vezes por dia,
com limite ou sem.

O orçamento é planejado, não criado: orçamentos pertencem à Cloud Billing Budget API, que nenhum emulador
responde, e criar um exige `roles/billing.costsManager` na conta de faturamento.
