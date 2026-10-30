---
title: Um grupo gerenciado de instâncias
version: 1
---

Um template descreve uma máquina. **Um grupo gerenciado de instâncias, um MIG, é o que mantém vivo
um número de máquinas feitas a partir desse template: você diz quantas, e ele cria, substitui e
apaga máquinas até a conta fechar.** Você para de cuidar de máquinas e passa a cuidar de um número.

## Zonal ou regional

Um MIG **zonal** põe todas as máquinas numa zona. Um MIG **regional** as espalha pelas zonas de uma
região, então a perda de uma zona deixa as outras servindo. Para qualquer coisa que responde a
usuários, o regional é o padrão, e é o que a loja usa. Acrescente-o ao `group/main.tf`, abaixo do
template:

```hcl
# group/main.tf, continued
resource "google_compute_region_instance_group_manager" "web" {
  name               = "web"
  base_instance_name = "web"
  region             = "southamerica-east1"

  distribution_policy_zones = [
    "southamerica-east1-a",
    "southamerica-east1-b",
    "southamerica-east1-c",
  ]

  version {
    instance_template = google_compute_instance_template.web.id
  }

  target_size = 3

  named_port {
    name = "http"
    port = 8080
  }
}
```

```
ana@laptop:~/gcp/group$ terraform plan -no-color | grep -E '^  #|^      \+ target_size +=|base_instance_name|^Plan'
  # google_compute_instance_template.web will be created
  # google_compute_region_instance_group_manager.web will be created
      + base_instance_name               = "web"
      + target_size                      = 3
Plan: 2 to add, 0 to change, 0 to destroy.
```

**`target_size` é o número que o grupo defende.** Apague à mão uma das três máquinas e o grupo cria
outra, porque três continua sendo a meta. Essa é a primeira surpresa para quem está acostumado a
cuidar de máquinas: num grupo, apagar uma máquina não é como você se livra dela. Você muda o número,
ou apaga o grupo.

`base_instance_name` é o começo do nome de cada máquina: o grupo acrescenta um sufixo aleatório
curto, `web-` e quatro caracteres, para máquinas irem e virem sem colidir. `named_port` dá um nome à
porta, `http`, que é como um balanceador de carga na frente do grupo, assunto da lição 20 do
`gcp-foundations`, se refere a ela.

## Sem estado, que é a condição

Um grupo só consegue fazer isso porque trata toda máquina como intercambiável. **Quando ele substitui
uma máquina, a nova parte do template, e o que estava no disco de boot da antiga se perde.** Então o
que roda num grupo não pode guardar na máquina nada que não possa perder: sessões num armazenamento
compartilhado, uploads no Cloud Storage, dados num banco de dados. O banco `orders` da lição 3, com o
disco de dados dele, é o oposto desse tipo de máquina e não pertence a um grupo como este.

O Compute Engine tem um recurso para a exceção, os **MIGs com estado**, que mantêm um disco ou um
endereço nomeado com uma máquina específica através da substituição. Ele existe para software que de
fato não pode ficar sem estado, como alguns bancos mais antigos, e devolve parte do que um grupo
ganhava. Recorra a ele por último.
