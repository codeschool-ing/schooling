---
title: Key rings, chaves e criptografia gerenciada pelo cliente
version: 1
---

**O Cloud KMS organiza as chaves em key rings, chaves e versões de chave, e o ring e a chave nunca podem ser
apagados.** Um **key ring** é um grupo nomeado numa localização; uma **chave** é um propósito nomeado dentro dele
(`ENCRYPT_DECRYPT`, assinatura, MAC); as **versões de chave** são o material de chave em si, como os arquivos do
`envelope.py` eram. Rings e chaves são nomes permanentes: depois de criados, existem enquanto o projeto existir, então
um erro de digitação no nome de uma chave é um erro para sempre. Este é o plano da chave da loja, e nada aqui rodou
contra o Cloud KMS.

Tudo o que o Google guarda já é criptografado em repouso com chaves que o Google gerencia. **CMEK, customer-managed
encryption keys**, significa que um serviço como o Cloud Storage criptografa os seus dados com uma chave no *seu*
Cloud KMS, para que você controle quem pode usá-la e possa desabilitá-la. Escreva `~/gcp/tf/kms/main.tf`:

```hcl
# tf/kms/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project = "planner-dev"
}

resource "google_kms_key_ring" "shop" {
  name     = "shop"
  location = "southamerica-east1"
}

resource "google_kms_crypto_key" "orders" {
  name            = "orders"
  key_ring        = google_kms_key_ring.shop.id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "7776000s"

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "SOFTWARE"
  }

  lifecycle {
    prevent_destroy = true
  }
}

data "google_storage_project_service_account" "gcs" {}

resource "google_kms_crypto_key_iam_member" "gcs_uses_key" {
  crypto_key_id = google_kms_crypto_key.orders.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs.email_address}"
}

resource "google_storage_bucket" "order_exports" {
  name                        = "planner-dev-order-exports"
  location                    = "SOUTHAMERICA-EAST1"
  uniform_bucket_level_access = true

  encryption {
    default_kms_key_name = google_kms_crypto_key.orders.id
  }

  depends_on = [google_kms_crypto_key_iam_member.gcs_uses_key]
}
```

```
ana@laptop:~/gcp/tf/kms$ terraform validate -no-color
Success! The configuration is valid.
ana@laptop:~/gcp/tf/kms$ terraform plan -input=false -no-color 2>&1 | grep -E "Error|^  # |Plan:" | head -6
  # google_kms_crypto_key.orders will be created
  # google_kms_key_ring.shop will be created
Plan: 2 to add, 0 to change, 0 to destroy.
Error: Error when reading or editing GCS service account not found: googleapi: Error 401: Invalid Credentials, authError
```

**O plano parou com um erro, e é a primeira vez no curso que um plano para.** A configuração é válida; o que falhou
foi `data "google_storage_project_service_account"`, que pergunta ao Google, na hora do plano, o endereço de e-mail
do agente de serviço do Cloud Storage do projeto. Um **data source é lido durante o plano**, então um plano que
contém um precisa de uma resposta real, e o token fake recebe `401 Invalid Credentials`. Recursos só são propostos,
e por isso todos os planos anteriores funcionaram; o primeiro data source é onde planejar sem conta termina.

## Lendo a configuração

- **`location = "southamerica-east1"`**: uma chave usada para CMEK precisa estar na mesma localização dos dados que
  protege. Um bucket de São Paulo precisa de uma chave de São Paulo; uma chave em `global` não serve.
- **`rotation_period = "7776000s"`**, 90 dias: uma nova versão primária a cada trimestre, com as versões antigas
  mantidas, como a seção anterior mostrou.
- **`protection_level = "SOFTWARE"`**: a chave é protegida pelo software do Google. `HSM` a guarda num módulo de
  segurança de hardware, a um preço maior, para quando uma regra de conformidade exige hardware.
- **`prevent_destroy = true`**: o Terraform se recusa a planejar a destruição da chave. Uma chave não pode ser
  apagada no Cloud KMS de qualquer jeito; o que o destroy do Terraform faria é agendar toda versão para destruição,
  que é o `rm` da seção anterior, para todos os dados de uma vez.
- **O membro de IAM** deixa o agente de serviço do Cloud Storage, a conta do próprio Google agindo pelo Cloud Storage
  no seu projeto, usar a chave. Sem ele, toda escrita no bucket falha, porque o Cloud Storage não consegue mais
  embrulhar as chaves dos objetos que guarda. `depends_on` garante que a permissão existe antes do bucket que precisa
  dela.

## O que o CMEK compra, e quanto custa

Desabilitar a chave torna todo objeto do bucket ilegível de uma vez, por qualquer um, inclusive o Google; reabilitá-la
os traz de volta. Esse é o controle para o qual o CMEK existe, e ele vem com o risco correspondente: **quem pode
desabilitar ou destruir a chave pode fazer os dados sumirem**, então `roles/cloudkms.admin` no key ring fica com tão
poucas pessoas quanto `roles/owner` no projeto.
