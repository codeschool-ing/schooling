---
title: Um template do Packer
version: 1
---

**O Packer constrói imagens de máquina a partir de um template**, e a ideia é a mesma para qualquer
tipo de imagem: ligar uma máquina temporária a partir de uma imagem base, rodar passos dentro dela,
salvar o resultado como imagem nova e jogar a máquina temporária fora. O que muda de um destino para
outro é só o que "máquina" e "imagem" querem dizer. Na AWS a máquina temporária é uma instância EC2
e o resultado é uma AMI; no Docker é um contêiner, e o resultado é uma imagem de contêiner.

O laboratório não tem uma AWS que rode máquinas (o moto guarda registros, não computadores), então
esta aula constrói imagens Docker, que são reais e rodam no notebook. O template é HCL, a linguagem
de todos os arquivos Terraform deste curso, num arquivo cujo nome termina em `.pkr.hcl`. A Ana o
guarda num repositório próprio, `~/shop/image`:

```hcl
packer {
  required_plugins {
    docker = {
      source  = "github.com/hashicorp/docker"
      version = "~> 1.1"
    }
  }
}

source "docker" "web" {
  image  = "ubuntu:24.04"
  pull   = false
  commit = true
  changes = [
    "CMD [\"nginx\", \"-g\", \"daemon off;\"]",
    "EXPOSE 80",
  ]
}

build {
  sources = ["source.docker.web"]

  provisioner "shell" {
    inline = [
      "apt-get update -qq",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx > /dev/null",
      "echo 'shop web 1.0.0' > /var/www/html/index.html",
    ]
  }

  post-processor "docker-tag" {
    repository = "shop-web"
    tags       = ["1.0.0"]
  }
}
```

Ele tem três blocos de topo, e cada um tem um único trabalho.

**`packer`** diz de quais plugins o template precisa. O Packer em si não conhece nenhuma nuvem nem
contêiner, do mesmo jeito que o Terraform não conhece a AWS sem o provider. Cada builder é um
plugin, aqui `github.com/hashicorp/docker`, com uma restrição de versão escrita exatamente como a de
um provider.

**`source "docker" "web"`** diz de onde vem a máquina temporária. O primeiro rótulo é o builder, o
segundo um nome escolhido pela Ana. `image` é a base de partida. `commit = true` pede que o
contêiner seja salvo como imagem no fim, que é o que faz disto um build e não só uma execução.
`changes` são configurações gravadas na imagem nova: o comando que ela roda ao ligar e a porta em
que escuta.

`pull = false` está ali por causa deste laboratório. Por padrão o Packer pede ao Docker Hub o
`ubuntu:24.04` mais novo antes de cada build, e enquanto esta aula era gravada o Docker Hub respondeu
a esses pedidos com `429 Too Many Requests`. Com `pull = false` o build usa a cópia que já está no
notebook. Deixar a linha de fora é o normal; a seção sobre reprodutibilidade, no fim desta aula,
explica por que a imagem base deve ser fixada de qualquer jeito.

**`build`** diz o que acontece. `sources` aponta os blocos source de onde partir, e um build pode
listar vários para produzir a mesma imagem para vários destinos de uma vez. Dentro dele:

- um **provisioner** é um passo rodado dentro da máquina temporária. `shell` roda comandos; `file`
  copia arquivos para dentro; um provisioner `ansible`, de outro plugin, roda um playbook como o da
  aula 18 contra a máquina em construção. Eles rodam em ordem, e qualquer passo que falhe interrompe
  o build.
- um **post-processor** age sobre a imagem depois que ela é salva. `docker-tag` dá a ela o nome
  `shop-web:1.0.0`.

O mesmo template para a AWS mudaria no bloco `source` e em pouco mais. Este aqui é **ilustrativo,
não foi rodado**: o plugin `amazon-ebs` não está instalado no laboratório, e o moto não liga
máquina nenhuma para provisionar.

```hcl
source "amazon-ebs" "web" {
  region        = "sa-east-1"
  instance_type = "t3.micro"
  ssh_username  = "ubuntu"
  ami_name      = "shop-web-1.0.0"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"]
    most_recent = true
  }
}
```

`source_ami_filter` é a mesma busca que a aula 5 fez com `data "aws_ami"`, e `099720109477` é a
conta de onde a Canonical publica as imagens do Ubuntu. Os provisioners e os post-processors seriam
os de cima, menos a tag; a AMI recebe o nome de `ami_name`.
