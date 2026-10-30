---
title: Três barreiras para o planner, escritas e planejadas
version: 1
---

A equipe do planner quer três regras: recursos só na América do Sul e nos Estados Unidos, produção só em
São Paulo, e nenhuma chave de conta de serviço em lugar nenhum. A terceira é a que mais provavelmente
quebra algo que já funciona, então ela entra primeiro como dry run. Crie um diretório com o arquivo do
provider da lição 2:

```sh
mkdir -p ~/gcp/guardrails && cd ~/gcp/guardrails
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Salve isto como `policies.tf`:

```hcl
locals {
  org        = "organizations/123456789012" # example.com, made up for this course
  production = "folders/345678901234"       # lesson 2's production folder, by a made-up number
}

# Everything the company runs: South America and the United States.
resource "google_org_policy_policy" "locations" {
  name   = "${local.org}/policies/gcp.resourceLocations"
  parent = local.org
  spec {
    rules {
      values {
        allowed_values = ["in:southamerica-locations", "in:us-locations"]
      }
    }
  }
}

# Production replaces the organisation's list rather than merging with it.
resource "google_org_policy_policy" "production_locations" {
  name   = "${local.production}/policies/gcp.resourceLocations"
  parent = local.production
  spec {
    inherit_from_parent = false
    rules {
      values {
        allowed_values = ["in:southamerica-east1-locations"]
      }
    }
  }
}

# No keys, tried as a dry run before it is enforced.
resource "google_org_policy_policy" "no_keys" {
  name   = "${local.org}/policies/iam.managed.disableServiceAccountKeyCreation"
  parent = local.org
  dry_run_spec {
    rules {
      enforce = "TRUE"
    }
  }
}
```

O `name` da política repete o pai e a restrição, `organizations/123456789012/policies/...`, porque esse é
o endereço da própria política na API: uma política por restrição por nó. Escrevê-lo à mão é o que o
provider pede, e o que faz o arquivo dizer exatamente onde cada regra mora.

O plano completo imprime todo campo de toda política, a maioria `(known after apply)`. Dois comandos o
fazem dizer só o que importa aqui: o `-out` salva o plano num arquivo, e o `terraform show -json`
imprime esse arquivo como JSON, que o `jq` reduz aos três campos que decidem o comportamento de cada
política:

```
ana@laptop:~/gcp/guardrails$ terraform plan -input=false -out=plan.bin | tail -1
    terraform apply "plan.bin"
ana@laptop:~/gcp/guardrails$ terraform show -json plan.bin | jq -r '.resource_changes[].change.after | "\(.name)\n  inherit_from_parent: \(.spec[0].inherit_from_parent)\n  allowed_values: \(.spec[0].rules[0].values[0].allowed_values)\n  dry run enforce: \(.dry_run_spec[0].rules[0].enforce)"'
organizations/123456789012/policies/gcp.resourceLocations
  inherit_from_parent: null
  allowed_values: ["in:southamerica-locations","in:us-locations"]
  dry run enforce: null
organizations/123456789012/policies/iam.managed.disableServiceAccountKeyCreation
  inherit_from_parent: null
  allowed_values: null
  dry run enforce: TRUE
folders/345678901234/policies/gcp.resourceLocations
  inherit_from_parent: false
  allowed_values: ["in:southamerica-east1-locations"]
  dry run enforce: null
```

**Três políticas, e o plano mostra a única diferença que decide o comportamento do ambiente**:
`inherit_from_parent: false` na produção. False é o padrão, então a linha não muda nada como está
escrita; ela está lá para que a decisão fique na página, onde alguém que depois a ponha como `true`,
achando que herdar é mais seguro, tenha antes de apagá-la. Com `true`, a lista da pasta se mesclaria com
a da organização e permitiria os Estados Unidos. Ler um plano procurando essa linha vale mais do que ler
todo o resto.

## O que acontece depois, fora do laboratório

Aplicadas numa organização real, por alguém com `roles/orgpolicy.policyAdmin`, as três políticas
valeriam em minutos, e só para o que fosse criado ou mudado depois disso. **O dry run é a parte que
continua trabalhando**: toda criação de chave que ele teria recusado aparece nos logs de auditoria,
atribuída a quem tentou. Depois de uma semana sem violação que importe, a equipe acrescenta um bloco
`spec` ao lado do `dry_run_spec`, com a mesma regra, e planeja de novo; o diff tem quatro linhas, e é o
momento em que a barreira vira um muro.

Esse último passo é o que o laboratório não consegue mostrar, e as violações também não: os dois
precisam do Google. O plano é até onde um notebook enxerga, e é longe o bastante para pegar o erro que
mais importa aqui, uma lista de permissão que mescla quando deveria substituir.
