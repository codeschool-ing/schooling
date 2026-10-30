---
title: Um segredo, as versões dele, e quem pode lê-las
version: 1
---

**O Secret Manager guarda um segredo como um contêiner de versões numeradas, e toda leitura nomeia uma versão.** O
segredo `shop-db-password` não guarda valor sozinho; a versão 1 guarda a primeira senha, a versão 2 a que a
substituiu, e `latest` é um apelido para a mais nova habilitada. Uma versão pode estar **habilitada**,
**desabilitada** (guardada, ilegível, e reabilitável em segundos) ou **destruída** (sumiu de vez). Ler é uma
permissão de IAM no segredo, `roles/secretmanager.secretAccessor`, concedida à conta de serviço que precisa e a mais
ninguém. **Nada nesta lição chega ao Secret Manager**, que não tem emulador. O que roda é um plano do Terraform, um
contêiner lendo um arquivo montado, e uma demonstração, só com o Terraform, de por que o valor não pode passar pelo
Terraform.

O segredo da loja, em `~/gcp/tf/secrets/main.tf`:

```hcl
# tf/secrets/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project = "planner-dev"
}

resource "google_pubsub_topic" "rotation" {
  name = "shop-secret-rotation"
}

resource "google_secret_manager_secret" "db_password" {
  secret_id = "shop-db-password"

  replication {
    user_managed {
      replicas {
        location = "southamerica-east1"
      }
    }
  }

  rotation {
    rotation_period    = "2592000s"
    next_rotation_time = "2026-12-01T09:00:00Z"
  }

  topics {
    name = google_pubsub_topic.rotation.id
  }
}

resource "google_secret_manager_secret_iam_member" "api_reads" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:shop-api@planner-dev.iam.gserviceaccount.com"
}
```

```
ana@laptop:~/gcp/tf/secrets$ terraform plan -input=false -no-color | grep -E "^  # |location|rotation_period|role|Plan:"
  # google_pubsub_topic.rotation will be created
  # google_secret_manager_secret.db_password will be created
                  + location = "southamerica-east1"
          + rotation_period    = "2592000s"
  # google_secret_manager_secret_iam_member.api_reads will be created
      + role      = "roles/secretmanager.secretAccessor"
Plan: 3 to add, 0 to change, 0 to destroy.
```

Três decisões estão escritas nele:

- **Replicação `user_managed` só em São Paulo.** O padrão, `auto`, deixa o Google guardar cópias onde ele escolher;
  um segredo cuja localização faz parte de uma resposta de conformidade nomeia as regiões.
- **Rotação a cada 30 dias** (`2592000s`), começando em 1º de dezembro. O Secret Manager não muda a senha: ele
  publica uma mensagem no tópico quando a rotação vence, e algo que a loja roda faz a troca. A última seção é sobre
  esse algo.
- **Um leitor**, a própria conta de serviço da API, neste segredo. Conceder o papel no projeto deixaria a API ler
  todos os segredos dele, inclusive os que não são da conta dela.

**Não há `google_secret_manager_secret_version` aqui, e é de propósito.** A versão, o próprio valor, é acrescentada
fora do Terraform, pelo motivo que a terceira seção desta lição mostra:

```sh
printf '%s' "$NEW_PASSWORD" | gcloud secrets versions add shop-db-password --data-file=-
```

Esse comando não foi executado: não há Secret Manager aqui. O valor vem da entrada padrão, então nunca aparece na
linha de comando, no histórico do shell ou num arquivo.

## Quanto custa

Pela página de preços, lida em 30 de outubro de 2026, por conta de faturamento por mês: as primeiras **6 versões
ativas** são grátis, depois 0,000082192 USD por versão por hora, cerca de 0,06 USD por mês cada; os primeiros
**10.000 acessos** são grátis, depois 0,03 USD por 10.000; as primeiras 3 notificações de rotação são grátis, depois
0,05 USD cada. Uma versão destruída não custa nada, uma desabilitada custa o mesmo que uma habilitada, o que é um
motivo para destruir versões antigas quando nada mais as lê.
