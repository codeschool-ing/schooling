---
title: Templates de instância, escritos uma vez e nunca editados
version: 1
---

Três máquinas que deveriam ser iguais se afastam no momento em que alguém muda uma delas à mão. **Um
template de instância é a descrição de uma máquina guardada longe de qualquer máquina: o tipo, a
imagem, os discos, a rede e os metadados, escritos uma vez, a partir dos quais um grupo faz quantas
cópias lhe pedirem.** É a primeira metade de tudo que esta lição monta.

## O que um template guarda, e a única coisa que ele não faz

Um template guarda o que você passaria ao `gcloud compute instances create`, menos o nome e a zona,
que o grupo decide. E **um template não pode ser alterado**. Não há edição: uma descrição nova é um
template novo, com um nome novo, e o grupo é avisado para usá-lo. Parece um incômodo e é o contrário.
Um template que pudesse mudar significaria que duas máquinas feitas "do mesmo" template em dois dias
diferentes poderiam diferir, que é justamente a deriva que os templates existem para acabar.

O Terraform precisa contornar essa regra, e o jeito como faz isso merece leitura atenta. Para as
máquinas `web` da loja, numa pasta `group`, comece o arquivo pelo template:

```hcl
# group/main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.9.0"
    }
  }
}

provider "google" {
  project = "planner-dev"
  region  = "southamerica-east1"
}

resource "google_compute_instance_template" "web" {
  name_prefix  = "web-"
  machine_type = "e2-standard-2"

  disk {
    source_image = "projects/planner-dev/global/images/family/shop-web"
    boot         = true
    disk_size_gb = 20
  }

  network_interface {
    network = "default"
  }

  labels = {
    service = "web"
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

Duas linhas carregam o contorno. **`name_prefix`** deixa o Terraform inventar um nome novo para cada
versão nova do template, `web-` seguido de um carimbo de tempo e um contador, porque um template novo
precisa de um nome que nada mais tenha. **`create_before_destroy`** faz o Terraform criar o template
novo antes de apagar o antigo, porque o grupo ainda está usando o antigo e o Compute Engine se recusa
a apagar um template em uso. Juntas, elas transformam "editar o template" em "fazer um novo, apontar
o grupo para ele, depois remover o antigo", que é a única ordem que funciona.

```
ana@laptop:~/gcp/group$ terraform plan -no-color | grep -E '^  #|name_prefix|^      \+ name |machine_type|^Plan'
  # google_compute_instance_template.web will be created
      + machine_type         = "e2-standard-2"
      + name                 = (known after apply)
      + name_prefix          = "web-"
Plan: 1 to add, 0 to change, 0 to destroy.
```

O nome é `(known after apply)` porque ele não existe até o Terraform inventá-lo, e `name_prefix` é o
que você escreveu. A seção 05 mostra o que acontece quando uma linha do template muda.

A imagem é a família `shop-web` da lição 2. Essa escolha tem uma consequência que a lição 2 avisou: o
template nomeia a família, então cada máquina que o grupo cria resolve a família naquele momento.
Duas máquinas criadas com uma semana de diferença podem subir builds diferentes de um mesmo template.
Onde isso não é aceitável, o template nomeia uma imagem datada, e um build novo significa um template
novo.
