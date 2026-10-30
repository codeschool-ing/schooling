---
title: Uma política de segurança é uma lista ordenada de regras
version: 1
---

**O Cloud Armor é uma política anexada ao serviço de backend de um balanceador de carga, e toda requisição passa
por ela antes de chegar à loja.** Uma política é uma lista de regras, cada uma com uma prioridade, um casamento e
uma ação; o Cloud Armor as avalia do menor número de prioridade para cima e aplica a primeira que casa, e a última
regra, no maior número possível, é o padrão. Ele só funciona atrás do Application Load Balancer externo do Google
(e de alguns outros balanceadores), então um serviço do Cloud Run acessado direto pelo próprio endereço `run.app`
o contorna por inteiro. **Nada nesta lição rodou contra o Cloud Armor**, que não tem emulador: o que roda é o plano
do Terraform da política, e o plano mostra onde ele deixa de ser prova.

A política da loja, em `~/gcp/tf/armor/main.tf`:

```hcl
# tf/armor/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project = "planner-dev"
}

resource "google_compute_security_policy" "shop" {
  name        = "shop-edge"
  description = "In front of the shop's load balancer"

  rule {
    priority    = 1000
    action      = "deny(403)"
    preview     = true
    description = "SQL injection, OWASP CRS, sensitivity 1"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('sqli-v33-stable', {'sensitivity': 1})"
      }
    }
  }

  rule {
    priority    = 2000
    action      = "rate_based_ban"
    description = "More than 60 checkouts a minute from one address"
    match {
      expr {
        expression = "request.path.startsWith('/checkout')"
      }
    }
    rate_limit_options {
      conform_action   = "allow"
      exceed_action    = "deny(429)"
      enforce_on_key   = "IP"
      ban_duration_sec = 600
      rate_limit_threshold {
        count        = 60
        interval_sec = 60
      }
    }
  }

  rule {
    priority    = 2147483647
    action      = "allow"
    description = "Everything else"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }
}
```

```
ana@laptop:~/gcp/tf/armor$ terraform plan -input=false -no-color | grep -E "^  # |priority |action |preview |Plan:"
  # google_compute_security_policy.shop will be created
          + action      = "allow"
          + preview     = (known after apply)
          + priority    = 2147483647
          + action      = "deny(403)"
          + preview     = true
          + priority    = 1000
          + action      = "rate_based_ban"
          + preview     = (known after apply)
          + priority    = 2000
              + conform_action      = "allow"
              + exceed_action       = "deny(429)"
Plan: 1 to add, 0 to change, 0 to destroy.
```

O plano lista as regras na ordem dele; o Cloud Armor vai avaliá-las pela prioridade: 1000, depois 2000, depois o
padrão em 2147483647.

## Regra 1000: uma regra de WAF, em preview

`evaluatePreconfiguredWaf('sqli-v33-stable', …)` é um dos conjuntos de regras pré-configurados do Google,
construído a partir do OWASP Core Rule Set, que casa os formatos de tentativas de injeção de SQL numa requisição. A
**sensibilidade** escolhe quantas das assinaturas dele se aplicam: 1 é o mínimo e o menos propenso a casar uma
requisição legítima, 4 o máximo.

**`preview = true` é como toda regra de WAF começa.** Em preview, a regra é avaliada e o veredito escrito no log de
requisições do balanceador, `jsonPayload.previewSecurityPolicy`, e a requisição passa. Uma semana de preview mostra
que requisições legítimas a regra teria bloqueado, uma caixa de busca com uma aspa, um produto chamado *O'Reilly*,
antes de qualquer cliente ser recusado. Ligar uma regra de WAF sem preview é como uma loja bloqueia o próprio
checkout numa sexta.

## O que o plano não pegou

Mude a ação da regra de `deny(403)` para `deny(418)` e pergunte de novo:

```
ana@laptop:~/gcp/tf/armor$ terraform validate -no-color 2>&1 | head -6
Success! The configuration is valid.
ana@laptop:~/gcp/tf/armor$ terraform plan -input=false -no-color 2>&1 | grep -E "Error|418|Plan:" | head -4
          + action      = "deny(418)"
Plan: 1 to add, 0 to change, 0 to destroy.
```

Os dois aceitam. A ação deny do Cloud Armor só aceita **403, 404 e 502** (e 429 no `exceed_action` de um limite de
taxa, como a regra 2000 usa), e o Google recusa `deny(418)` quando a política é criada. O schema do provider diz
que `action` é uma string, e qualquer string passa; a regra sobre quais strings é do Google. É o aviso da lição 1
na forma mais afiada: um plano limpo não é uma mudança aceita, e numa política de segurança a diferença é achada no
apply, ou por alguém lendo a documentação.
