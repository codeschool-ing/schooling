---
title: O provider, o projeto e a região
version: 1
---

O `iac` ensinou Terraform desde a primeira lição: providers, recursos, estado, um plano antes de cada
apply. Esta lição e as duas seguintes são sobre a parte que só aparece quando o provider aponta para o
Google Cloud: em que projeto um recurso cai, com a identidade de quem o Terraform age, e onde o estado
vive. O Terraform vai para `~/.local/bin`, na versão que o `iac` usou:

```sh
cd ~/gcp
curl -sS -o terraform.zip https://releases.hashicorp.com/terraform/1.16.4/terraform_1.16.4_linux_amd64.zip
unzip -o -q terraform.zip terraform -d ~/.local/bin && rm terraform.zip
```

Num computador Arm o arquivo é `terraform_1.16.4_linux_arm64.zip`.

```
ana@laptop:~/gcp/tf/shop$ terraform version
Terraform v1.16.4
on linux_amd64
```

## O provider da loja

Crie `~/gcp/tf/shop` e escreva este arquivo nele:

```hcl
# tf/shop/main.tf
terraform {
  required_version = "1.16.4"
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project = "planner-dev"
  region  = "southamerica-east1"

  default_labels = {
    team       = "shop"
    managed-by = "terraform"
  }

  storage_custom_endpoint = "http://localhost:4443/storage/v1/"
}

resource "google_storage_bucket" "assets" {
  name                        = "planner-dev-shop-assets"
  location                    = "SOUTHAMERICA-EAST1"
  uniform_bucket_level_access = true
}
```

Quatro coisas no bloco do provider, e a última é só para este curso:

- **`project`** é para onde um recurso vai quando não diz. Todo recurso do provider google aceita um
  argumento `project` próprio, e um recurso que define um cai ali. Uma configuração que gerencia dois
  projetos nomeia o projeto em cada recurso, ou usa dois blocos de provider com um `alias` cada; deixar
  para o padrão é como um bucket de produção acaba no projeto de desenvolvimento.
- **`region`** é o mesmo para recursos regionais. Um bucket tem uma `location` própria, por isso o recurso
  a repete.
- **`default_labels`** põe os mesmos rótulos em todo recurso que o provider cria e que aceita rótulos, sem
  nada escrito por recurso. A lição 23 é sobre por que todo recurso precisa de um dono rastreável; este
  bloco é a forma mais barata de ter um.
- **`storage_custom_endpoint`** manda as chamadas de Cloud Storage do provider para o `fake-gcs-server` no
  seu computador. Contra o Google ele fica de fora, e todos os outros serviços continuam apontando para o
  Google, que é por que só buckets podem ser criados neste curso.

`version = "8.9.0"` é exato de propósito. Um provider é um programa que muda o que o `plan` significa, e o
arquivo de lock que o `terraform init` escreve, `.terraform.lock.hcl`, registra os checksums do que ele
baixou, para que todo mundo que roda esta configuração rode o mesmo provider. O arquivo de lock vai no
commit com o código.

```
ana@laptop:~/gcp/tf/shop$ terraform init -input=false -no-color | grep -E "Installing|Installed|successfully"
- Installing hashicorp/google v8.9.0...
- Installed hashicorp/google v8.9.0 (signed by HashiCorp)
Terraform has been successfully initialized!
```

O `init` buscou o provider no Terraform Registry e o pôs em `.terraform/`, ao lado do arquivo.
