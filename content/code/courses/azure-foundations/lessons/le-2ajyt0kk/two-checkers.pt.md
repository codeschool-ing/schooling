---
title: Dois verificadores, e o que cada um sabe
version: 1
---

**Um orçamento com um erro de digitação é pior do que nenhum orçamento, porque parece proteção.** Se
`Forecasted` estiver escrito `Forecast`, o alerta de previsão nunca é criado, e ninguém descobre até o
mês em que uma previsão os teria avisado. Então vale saber quais erros o laboratório consegue pegar
antes de o Azure ver o arquivo, e a resposta é diferente para as duas ferramentas.

## O que o Bicep confere

Faça duas cópias quebradas do orçamento: uma com o tipo de limite escrito errado, outra com o valor
escrito como texto. O `sed` escreve cada cópia sem mexer no original:

```
ana@laptop:~/azure/cost$ sed "s/'Forecasted'/'Forecast'/" budget.bicep > typo.bicep
ana@laptop:~/azure/cost$ az bicep build --file typo.bicep --stdout > /dev/null
ana@laptop:~/azure/cost$ sed "s/amount: 50/amount: '50'/" budget.bicep > text.bicep
ana@laptop:~/azure/cost$ az bicep build --file text.bicep --stdout > /dev/null
WARNING: /home/ana/azure/cost/text.bicep(10,13) : Warning BCP036: The property "amount" expected a value of type "int" but the provided value is of type "'50'". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
```

**O tipo de limite escrito errado compilou sem uma palavra.** A segunda cópia também compilou, com um
aviso, `BCP036`: o valor deveria ser um número e recebeu um texto. O Bicep conhece o *tipo* de cada
propriedade a partir da descrição que a Microsoft faz da API: que `amount` é um número, que
`notifications` é um objeto. Onde essa descrição diz que uma propriedade é um texto e não lista
valores permitidos, o Bicep aceita qualquer texto, e `thresholdType` é uma dessas. O template que saiu
é um template ARM perfeitamente válido com um valor dentro que o Resource Manager recusaria, ou, pior,
guardaria.

Note também que o `BCP036` é um **aviso**, não um erro: o `az bicep build` escreveu o template mesmo
assim. A mensagem diz por quê: os tipos do Bicep são gerados a partir da especificação da própria
API, e quando as duas discordam a Microsoft prefere avisar a bloquear. Leia os avisos; um build que
imprime um não passou.

## O que o Terraform confere

O provider do Terraform para o Azure é escrito à mão, por pessoas que acrescentaram a própria
validação a muitos campos. O mesmo orçamento em Terraform, salvo como `main.tf` num diretório próprio:

```sh
mkdir -p ~/azure/cost/tf && cd ~/azure/cost/tf
```

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.12.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_consumption_budget_subscription" "monthly" {
  name            = "budget-shop-monthly"
  subscription_id = "/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff"
  amount          = 50
  time_grain      = "Monthly"

  time_period {
    start_date = "2026-11-01T00:00:00Z"
  }

  notification {
    enabled        = true
    operator       = "GreaterThan"
    threshold      = 80
    threshold_type = "Actual"
    contact_emails = ["billing@shop.example"]
  }

  notification {
    enabled        = true
    operator       = "GreaterThan"
    threshold      = 100
    threshold_type = "Forecasted"
    contact_emails = ["billing@shop.example"]
  }
}
```

A assinatura é nomeada pelo id completo, aquele que a lição 2 desmontou, e a data de início leva um
horário porque o provider pede um. Inicialize, valide, depois cometa o mesmo erro, valide de novo, e
desfaça:

```
ana@laptop:~/azure/cost/tf$ terraform init -input=false
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "5.12.0"...
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
ana@laptop:~/azure/cost/tf$ terraform validate
Success! The configuration is valid.

ana@laptop:~/azure/cost/tf$ sed -i 's/"Forecasted"/"Forecast"/' main.tf
ana@laptop:~/azure/cost/tf$ terraform validate
╷
│ Error: expected notification.0.threshold_type to be one of ["Actual" "Forecasted"], got Forecast
│ 
│   with azurerm_consumption_budget_subscription.monthly,
│   on main.tf line 14, in resource "azurerm_consumption_budget_subscription" "monthly":
│   14: resource "azurerm_consumption_budget_subscription" "monthly" {
│ 
╵
ana@laptop:~/azure/cost/tf$ sed -i 's/"Forecast"/"Forecasted"/' main.tf
ana@laptop:~/azure/cost/tf$ terraform validate
Success! The configuration is valid.
```

O `init` imprimiu o que tinha imprimido na lição 2, e por trás dessas linhas ligou o provider a partir
do cache que a lição 2 encheu em vez de buscá-lo de novo. **Desta vez o erro foi pego, com os valores
permitidos na mensagem.** Os autores do provider escreveram que `threshold_type` é `Actual` ou
`Forecasted`, então o `validate` recusa qualquer outra coisa antes de existir um pedido. Ele chama o
bloco de `notification.0` embora o erro estivesse no segundo: o Terraform guarda esses blocos como um
conjunto, que não tem ordem, e numera o que relata a partir do zero.

Nenhuma das ferramentas é a mais rigorosa em geral. O Bicep conhece cada propriedade de cada versão de
API no dia em que é publicada, e o Terraform só conhece os recursos que o seu provider escreveu; o
provider do Terraform conhece regras sobre valores que os tipos gerados do Bicep não conhecem. **Qual
das duas pega um erro depende do campo**, e a única verificação que sabe tudo é o Resource Manager,
quando o pedido chega.

## Implantando, e fazendo um orçamento agir

Com uma conta, o arquivo Bicep é implantado no escopo da assinatura, como a lição 2 mostrou:
`az deployment sub create --location brazilsouth --template-file budget.bicep`. O arquivo Terraform é
`terraform apply`. **Nenhum dos dois foi executado**: os dois são pedidos ao Resource Manager.

Sozinho, um orçamento só avisa. **Para fazê-lo agir, um orçamento no escopo de uma assinatura ou de um
grupo de recursos pode chamar um action group.** Um action group é a lista de coisas a fazer do Azure
Monitor quando um alerta dispara: mandar uma mensagem de texto, chamar um webhook, iniciar um runbook de automação que
desaloca todas as máquinas de um grupo de recursos. Isso transforma um aviso num freio, e o freio é um
programa que alguém escreveu e testou, não uma configuração. O curso `azure-operations`, nas trilhas
que o incluem, monta action groups na sua lição 12. Aqui a questão é o limite da coisa: **um orçamento
não para o gasto a não ser que você construa a parte que para**, e um orçamento no escopo de um grupo
de gerenciamento ou de uma conta de cobrança nem pode chamar um action group.
