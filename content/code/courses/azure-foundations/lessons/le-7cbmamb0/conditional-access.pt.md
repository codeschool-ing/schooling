---
title: Acesso condicional, uma regra avaliada em todo login
version: 1
---

**O acesso condicional é um conjunto de regras se-então que o Entra ID avalia toda vez que alguém faz
login.** Se estes usuários, chegando a estas aplicações, nestas condições, então conceda acesso só com
estes controles, ou bloqueie. Os padrões de segurança são uma regra fixa; o acesso condicional são as
regras que você escreve, e ele precisa de licença, Microsoft Entra ID P1 ou superior, para os usuários
que cobre.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l11-policy\" aria-label=\"Uma política de acesso condicional como uma regra se-então avaliada no login. À esquerda, as atribuições: usuários, incluindo papéis do diretório e exclusões, e os recursos de destino. No meio, as condições: risco, plataforma do dispositivo, local e app cliente. À direita, os controles de acesso: bloquear, ou conceder com segundo fator, força de autenticação ou dispositivo gerenciado. Embaixo, uma nota de que toda política que se aplica é imposta junto, sem ordem.\"><defs><marker id=\"l11-policy-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30.0\" y=\"24.0\" width=\"190.0\" height=\"186.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">se: quem e o quê</text><rect x=\"44.0\" y=\"62.0\" width=\"162.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">usuários e grupos</text><rect x=\"44.0\" y=\"98.0\" width=\"162.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">papéis do diretório</text><rect x=\"44.0\" y=\"134.0\" width=\"162.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">exclusões</text><rect x=\"44.0\" y=\"170.0\" width=\"162.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">recursos de destino</text><rect x=\"265.0\" y=\"24.0\" width=\"190.0\" height=\"186.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">e: em que condições</text><rect x=\"279.0\" y=\"62.0\" width=\"162.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">risco do login</text><rect x=\"279.0\" y=\"98.0\" width=\"162.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">plataforma do dispositivo</text><rect x=\"279.0\" y=\"134.0\" width=\"162.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">local</text><rect x=\"279.0\" y=\"170.0\" width=\"162.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">app cliente</text><rect x=\"500.0\" y=\"24.0\" width=\"190.0\" height=\"186.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">então: o que acontece</text><rect x=\"514.0\" y=\"62.0\" width=\"162.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">bloquear</text><rect x=\"514.0\" y=\"98.0\" width=\"162.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">conceder com segundo fator</text><rect x=\"514.0\" y=\"134.0\" width=\"162.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">força de autenticação</text><rect x=\"514.0\" y=\"170.0\" width=\"162.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">dispositivo gerenciado</text><path d=\"M221.0 117.0 L264.0 117.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-policy-af-ah-paper-dim)\"></path><path d=\"M456.0 117.0 L499.0 117.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-policy-af-ah-paper-dim)\"></path><text x=\"360.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">toda política que se aplica é imposta, junto: sem ordem, sem primeira que casa</text><text x=\"360.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o modo somente relatório avalia e registra, e não impõe nada</text></svg>", "caption": "Uma política: se estes, nestas condições, então isto."}
```

## As partes de uma política

**As atribuições** dizem de quem e do que a política trata:

- **usuários**: todos os usuários, usuários ou grupos escolhidos, ou quem tem **papéis do diretório**
  escolhidos, e as exclusões, que importam tanto quanto as inclusões;
- **recursos de destino**: as aplicações em que se faz login. *Windows Azure Service Management API* é
  a que importa neste curso: a documentação da Microsoft diz que uma política mirada nela cobre o
  Resource Manager e o portal do Azure, e por meio deles a CLI e o PowerShell.

**As condições** estreitam quando ela se aplica: o risco do login, a plataforma do dispositivo, o
**local**, citado por país ou pelas faixas de endereço da própria empresa, e o **app cliente**, que é
como a autenticação legada é isolada.

**Os controles de acesso** dizem o que acontece: **bloquear**, ou **conceder** com a condição de um ou
mais controles, como a autenticação multifator, uma **força de autenticação** que exige um método
resistente a phishing, ou um dispositivo que a empresa gerencia. **Os controles de sessão** moldam o que
vem depois, como a frequência com que um login precisa ser repetido.

**Toda política que se aplica é imposta, todas juntas.** Não há prioridade nem "primeira que casa". Se
uma política exige segundo fator e outra exige dispositivo gerenciado, a pessoa precisa dos dois; se
qualquer política aplicável bloqueia, o login é bloqueado. É por isso que um bloqueio é a política a
escrever por último e testar por mais tempo.

## Primeiro, somente relatório

Uma política tem três estados: **ligada**, **desligada** e **somente relatório**. Em somente relatório,
o Entra ID avalia a política em todo login e escreve no log de logins o que ela *teria* feito, sem
fazer. Uma semana de somente relatório numa política nova mostra exatamente quem ela teria barrado,
inclusive o job noturno que todo mundo esqueceu que faz login como pessoa. A documentação da Microsoft
acrescenta que contas de emergência não precisam ser excluídas de uma política em somente relatório, já
que nada é imposto.

## A primeira política da loja, em Terraform

O acesso condicional mora no Entra ID e não no Resource Manager, então o recurso Terraform dele vem do
provider para o Entra ID, que a lição 6 apresentou. Crie o diretório da lição e salve isto como
`main.tf`:

```sh
mkdir -p ~/azure/access && cd ~/azure/access
```

```hcl
terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.10.0"
    }
  }
}

provider "azuread" {}

resource "azuread_conditional_access_policy" "admins_mfa" {
  display_name = "Require MFA for administrators"
  state        = "enabledForReportingButNotEnforced"

  conditions {
    client_app_types = ["all"]

    applications {
      included_applications = ["All"]
    }

    users {
      included_roles = [
        "62e90394-69f5-4237-9190-012177145e10",
        "e8611ab8-c189-46e8-94e1-60213ab1f814",
      ]
      excluded_groups = ["aaaaaaaa-1111-2222-3333-cccccccccccc"]
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }
}
```

A política cobre quem tem dois papéis do diretório, citados pelos ids que a documentação da Microsoft
lista para eles: **Global Administrator** e **Privileged Role Administrator**, os dois que podem
distribuir todos os outros poderes. Ela se aplica a toda aplicação e a todo tipo de cliente, exige um
segundo fator, e exclui um grupo: as contas de emergência da próxima seção, por um object id inventado.
O estado dela é `enabledForReportingButNotEnforced`, a grafia da API para somente relatório.

Rode `terraform init`, depois confira o arquivo, depois cometa o erro mais provável, escrevendo o
estado do jeito que as pessoas falam:

```
ana@laptop:~/azure/access$ terraform validate
Success! The configuration is valid.

ana@laptop:~/azure/access$ sed -i 's/"enabledForReportingButNotEnforced"/"reportOnly"/' main.tf
ana@laptop:~/azure/access$ terraform validate
╷
│ Error: expected state to be one of ["disabled" "enabled" "enabledForReportingButNotEnforced"], got reportOnly
│ 
│   with azuread_conditional_access_policy.admins_mfa,
│   on main.tf line 14, in resource "azuread_conditional_access_policy" "admins_mfa":
│   14:   state        = "reportOnly"
│ 
╵
```

**O provider lista os três estados que aceita**, e a palavra do dia a dia não é um deles. A recusa
aconteceu no seu computador, que é o lugar mais barato para ela. Ponha a grafia longa de volta com
`sed -i 's/"reportOnly"/"enabledForReportingButNotEnforced"/' main.tf`.

```
ana@laptop:~/azure/access$ terraform plan -input=false

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: unable to build authorizer: could not configure AzureCli Authorizer: tenant ID was not specified and the default tenant ID could not be determined: obtaining tenant ID: obtaining account details: running Azure CLI: exit status 1: ERROR: Please run 'az login' to setup account.
│ 
│   with provider["registry.terraform.io/hashicorp/azuread"],
│   on main.tf line 10, in provider "azuread":
│   10: provider "azuread" {}
│ 
╵
```

O `plan` parou no mesmo lugar que todo outro `plan` deste curso: ele precisa de uma identidade logada
antes de poder perguntar ao Entra ID quais políticas existem. **A política não foi criada**, e a semana
em somente relatório dela, que é a parte que ensinaria algo sobre um tenant real, não pôde acontecer
aqui.
