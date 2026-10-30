---
title: Construindo uma imagem sua
version: 1
---

Uma imagem pública é um sistema operacional limpo, e a loja precisa de mais que isso: um runtime, o
próprio código, um servidor web configurado. **Instalar tudo isso no boot, em cada máquina, é lento
e falha de jeitos novos a cada vez; embutir numa imagem uma vez faz todo boot ser igual.** A lição 7
trata do primeiro caminho, o script de inicialização. Esta seção trata do segundo.

## Três origens para uma imagem

O Compute Engine faz uma imagem a partir de algo que já existe:

- **um disco**, geralmente o disco de boot de uma máquina que você preparou à mão ou por script e
  depois parou;
- **um snapshot** desse disco, assunto da lição 3;
- **um arquivo importado**, um disco virtual feito em outro lugar e enviado ao Cloud Storage.

O primeiro é por onde uma equipe pequena começa. Prepare uma máquina de build, pare-a para o disco
ficar quieto, faça uma imagem do disco, apague a máquina de build. Escrito em Terraform, numa pasta
`image-build`, fica assim:

```hcl
# image-build/main.tf
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

resource "google_compute_instance" "builder" {
  name         = "shop-web-builder"
  machine_type = "e2-standard-2"
  zone         = "southamerica-east1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
  }
}

resource "google_compute_image" "shop_web" {
  name              = "shop-web-v3"
  family            = "shop-web"
  source_disk       = google_compute_instance.builder.boot_disk[0].source
  storage_locations = ["southamerica-east1"]
}
```

```
ana@laptop:~/gcp/image-build$ terraform plan -no-color | grep -E '^  #|^      \+ (name|family|source_disk) |^Plan'
  # google_compute_image.shop_web will be created
      + family             = "shop-web"
      + name               = "shop-web-v3"
      + source_disk        = (known after apply)
  # google_compute_instance.builder will be created
      + name                 = "shop-web-builder"
Plan: 2 to add, 0 to change, 0 to destroy.
```

**`(known after apply)` é a resposta honesta para o disco**: ele não existe até a máquina de build
existir, então nem o Terraform nem ninguém consegue nomeá-lo ainda. A família, o nome e o lugar onde
a imagem fica guardada são seus, e `storage_locations` é o que vale decidir de propósito. Sem ele,
o Google guarda a imagem numa multirregião perto da origem; com ele, ela fica em São Paulo, que é
onde estarão as máquinas que sobem a partir dela.

Falta um passo naquele arquivo, e ele não pode ser escrito ali: **a máquina de build precisa estar
parada antes de a imagem ser tirada**, senão a imagem pega um disco no meio de uma escrita. O
Terraform não tem um passo de "parar, depois copiar". A resposta de costume é fazer a imagem com
`gcloud compute images create shop-web-v3 --source-disk=shop-web-builder --family=shop-web` depois
de parar a máquina, ou deixar uma ferramenta feita para isso cuidar da sequência inteira.

## Packer, a ferramenta feita para isso

O Packer, da HashiCorp, faz exatamente essa sequência: sobe uma máquina temporária a partir de uma
imagem de origem, roda os seus passos de preparação nela, para a máquina, faz a imagem e apaga tudo
que criou. O template da imagem web da loja, escrito a partir da documentação do builder
`googlecompute` do Packer, **é mostrado aqui e não executado**, porque cada passo dele chama o
Google:

```hcl
# shop-web.pkr.hcl
source "googlecompute" "shop_web" {
  project_id          = "planner-dev"
  zone                = "southamerica-east1-a"
  source_image_family = "debian-12"
  image_name          = "shop-web-{{timestamp}}"
  image_family        = "shop-web"
  ssh_username        = "packer"
}

build {
  sources = ["source.googlecompute.shop_web"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx python3-venv",
    ]
  }
}
```

`{{timestamp}}` dá a cada build um nome único e `image_family` o põe na família, então cada `packer
build` publica uma nova imagem mais nova e move o ponteiro da seção 03. Esse é todo o processo de
lançamento de uma imagem de máquina: construir, testar uma máquina feita a partir dela, e depreciá-la
se o teste falhar.

## Quanto custa guardar uma imagem

Uma imagem fica guardada, e o armazenamento é cobrado enquanto ela existir:

```
ana@laptop:~/gcp$ python3 prices.py disks | grep -E "image|snapshot"
Disks and images, per GiB per month
  standard snapshot                                     0.05  per GiB-month
  archive snapshot                                     0.019  per GiB-month
  custom image                                          0.05  per GiB-month
```

Cinco centavos por GiB por mês é pouco para uma imagem. Deixa de ser pouco num build noturno que
ninguém apaga: uma imagem de 10 GiB construída toda noite durante um ano são 365 imagens e cerca de
180 dólares por mês no fim dele. **Depreciar uma imagem não a apaga**, como a seção 03 citou, então
um pipeline de build precisa de um passo que apague as antigas, e a lição 21 encontra o mesmo
problema com imagens de contêiner.

Uma **machine image** é outro objeto, com um nome confusamente parecido. Ela captura uma máquina
inteira: a configuração, os metadados e todo disco anexado a ela, o que a torna o backup de uma
máquina e não um modelo para muitas. Use uma imagem para fazer máquinas novas iguais; use uma machine
image para devolver uma máquina ao que ela era.
