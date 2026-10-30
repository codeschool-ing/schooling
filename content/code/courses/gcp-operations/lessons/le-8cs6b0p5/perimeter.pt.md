---
title: Um perímetro em volta dos dados
version: 1
---

**O IAM decide quem pode chamar uma API; o VPC Service Controls decide de onde, e para onde os dados podem ir.** A
falha para a qual ele existe é uma credencial válida nas mãos erradas: uma chave de conta de serviço copiada de um
laptop, um token roubado de um log de CI. Com essa credencial, o IAM diz sim, e o ladrão pode copiar as exportações
de pedidos da loja para um bucket no projeto dele. Um **perímetro de serviço** traça uma linha em volta de projetos e
dos serviços dentro deles: uma requisição a um serviço restrito vinda de fora da linha é recusada, e também uma
requisição de dentro que tenta escrever num projeto fora dela, **sejam quais forem as permissões de IAM de quem
chama**. Nada nesta lição foi executado: o VPC Service Controls precisa de uma organização, e não tem emulador. O que
roda é um plano do Terraform, com números fictícios para a organização e os projetos.

O perímetro da loja, em `~/gcp/tf/vpcsc/main.tf`:

```hcl
# tf/vpcsc/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {}

resource "google_access_context_manager_access_policy" "org" {
  parent = "organizations/123456789012"
  title  = "planner organisation"
}

resource "google_access_context_manager_access_level" "office" {
  parent = "accessPolicies/${google_access_context_manager_access_policy.org.name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.org.name}/accessLevels/office"
  title  = "office"
  basic {
    conditions {
      ip_subnetworks = ["203.0.113.0/24"]
    }
  }
}

resource "google_access_context_manager_service_perimeter" "shop_data" {
  parent = "accessPolicies/${google_access_context_manager_access_policy.org.name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.org.name}/servicePerimeters/shop_data"
  title  = "shop data"

  use_explicit_dry_run_spec = true
  spec {
    resources           = ["projects/111111111111"]
    restricted_services = ["storage.googleapis.com", "bigquery.googleapis.com"]
    access_levels       = [google_access_context_manager_access_level.office.name]

    egress_policies {
      egress_from {
        identities = ["serviceAccount:shop-exports@planner-dev.iam.gserviceaccount.com"]
      }
      egress_to {
        resources = ["projects/222222222222"]
        operations {
          service_name = "storage.googleapis.com"
          method_selectors {
            method = "google.storage.objects.create"
          }
        }
      }
    }
  }
}
```

```
ana@laptop:~/gcp/tf/vpcsc$ terraform plan -input=false -no-color | grep -E "^  # |restricted_services|use_explicit_dry_run_spec|Plan:" 
  # google_access_context_manager_access_level.office will be created
  # google_access_context_manager_access_policy.org will be created
  # google_access_context_manager_service_perimeter.shop_data will be created
      + use_explicit_dry_run_spec = true
          + restricted_services = [
Plan: 3 to add, 0 to change, 0 to destroy.
```

Três objetos, todos no nível da organização, não do projeto:

- **Uma política de acesso** (access policy), o contêiner da organização para perímetros e níveis de acesso. Uma
  organização tem uma, e criá-la exige um papel no nível da organização; um owner de projeto não consegue.
- **Um nível de acesso** (access level), `office`: requisições vindas da faixa de endereços do escritório,
  `203.0.113.0/24`. Um nível de acesso é uma condição sobre a origem da requisição (endereços, estado do dispositivo,
  identidade), nomeada para que perímetros possam usá-la.
- **O perímetro**, `shop_data`: o projeto que guarda as exportações de pedidos, com Cloud Storage e BigQuery
  restritos. Dentro dele, essas duas APIs só respondem a requisições que se originam dentro do perímetro ou que
  satisfazem o nível de acesso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Um perímetro tracejado em volta do projeto 111111111111 com Cloud Storage e BigQuery dentro. Quem chama de fora do perímetro com uma credencial válida é recusado. Uma cópia de dentro para um bucket em outro projeto é recusada, exceto por uma regra de saída: a conta de serviço shop-exports pode criar objetos no projeto 222222222222.\"><defs><marker id=\"ah8\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"200\" y=\"30\" width=\"260\" height=\"180\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"330\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">perímetro</text><text x=\"330\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">projects/111111111111</text><rect x=\"230\" y=\"95\" width=\"200\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"330\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">storage.googleapis.com</text><rect x=\"230\" y=\"150\" width=\"200\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"330\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bigquery.googleapis.com</text><rect x=\"20\" y=\"95\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">de fora</text><text x=\"85\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">chave válida</text><line x1=\"152\" y1=\"120\" x2=\"228\" y2=\"113\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#ah8)\"></line><text x=\"176\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">recusado</text><rect x=\"530\" y=\"40\" width=\"170\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"615\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">outro projeto</text><text x=\"615\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">recusado</text><rect x=\"530\" y=\"150\" width=\"170\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"615\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">projects/222222222222</text><text x=\"615\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">regra de saída: liberado</text><line x1=\"432\" y1=\"108\" x2=\"528\" y2=\"70\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#ah8)\"></line><line x1=\"432\" y1=\"118\" x2=\"528\" y2=\"170\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah8)\"></line></svg>", "caption": "O IAM disse sim aos três. O perímetro diz sim a um."}
```

## O que ele impede, concretamente

| a requisição | IAM | o perímetro |
|---|---|---|
| a conta de serviço da API, a partir do Cloud Run dentro do projeto, lê uma exportação | permitida | permitida: está dentro |
| uma pessoa no escritório, com o papel, baixa uma exportação | permitida | permitida: o nível de acesso |
| o token roubado dessa mesma pessoa, usado de outro país | permitida | **recusada**: fora, sem nível de acesso |
| um script dentro do projeto copia exportações para um bucket em outro projeto | permitida | **recusada**: dados saindo do perímetro |
| o job de exportação escreve no bucket do parceiro no projeto 222222222222 | permitida | permitida: a regra de saída |

A terceira e a quarta linhas são o motivo do perímetro. O IAM não distingue uma pessoa do token roubado dela, e não
distingue uma cópia legítima de uma exfiltração; o perímetro decide pelo onde, que nem o ladrão nem o script
conseguem mudar.

## A regra de saída

O perímetro também impediria o trabalho legítimo do job de exportação, escrever um arquivo diário no bucket de um
parceiro. A política de saída (egress) permite exatamente isso: esta conta de serviço, para aquele projeto, para
`storage.objects.create` e nada mais. Leia-a como um buraco aberto de propósito do tamanho de um job. **Cada regra de
saída é um caminho para fora dos dados**, então cada uma nomeia uma identidade, um destino e uma operação, nunca `*`.
