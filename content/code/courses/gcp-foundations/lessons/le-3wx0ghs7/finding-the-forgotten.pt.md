---
title: Achando o que ninguém declarou
version: 1
---

**Tudo o que o planner roda deveria estar no Terraform, e o inventário é como ele acha o que não está.** O
Terraform sabe exatamente o que fez: o estado dele lista todo recurso que ele gerencia, e nada mais. O inventário
sabe o que existe. Um recurso na segunda lista e não na primeira é um que alguém fez à mão, no console ou com o
gcloud, e é o recurso com mais chance de ser esquecido, mal rotulado ou errado.

O laboratório consegue fazer a comparação de verdade, na escala de um projeto, porque o Terraform consegue
aplicar no emulador: o provider aceita um endereço para o Pub/Sub do jeito que o gcloud aceita.

## Dois tópicos do Terraform, um à mão

Crie um diretório com o arquivo do provider da lição 2, e diga ao provider onde está o Pub/Sub. A linha vai
dentro do bloco `provider "google"`:

```sh
mkdir -p ~/gcp/inventory && cd ~/gcp/inventory
cp ~/gcp/hierarchy/provider.tf .
sed -i 's|  access_token = "placeholder"|  access_token = "placeholder"\n\n  pubsub_custom_endpoint = "http://localhost:8085/v1/"|' provider.tf
terraform init -input=false
```

Salve isto como `topics.tf`:

```hcl
resource "google_pubsub_topic" "orders" {
  name   = "orders"
  labels = { team = "planner" }
}

resource "google_pubsub_topic" "invoices" {
  name   = "invoices"
  labels = { team = "planner" }
}
```

**Este é o primeiro apply do curso**, e ele é real: contra o emulador, que cria os tópicos, e nada mais.

```
ana@laptop:~/gcp/inventory$ terraform apply -input=false -no-color -auto-approve | grep -E "^(Apply|Error)"
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

Agora alguém faz um tópico à mão, do jeito que todo teste rápido começa:

```
ana@laptop:~/gcp/inventory$ gcloud pubsub topics create scratch-2025
Created topic [projects/planner-dev/topics/scratch-2025].
```

## A comparação

O que o Terraform gerencia, e o que existe:

```
ana@laptop:~/gcp/inventory$ terraform state list
google_pubsub_topic.invoices
google_pubsub_topic.orders
ana@laptop:~/gcp/inventory$ gcloud pubsub topics list --format="value(name.basename())"
invoices
orders
scratch-2025
```

Duas listas, e a diferença entre elas é a resposta. O `comm -13` imprime as linhas que só estão na segunda de duas
listas ordenadas:

```
ana@laptop:~/gcp/inventory$ comm -13 <(terraform show -json | jq -r '.values.root_module.resources[].values.name' | sort) <(gcloud pubsub topics list --format="value(name.basename())" | sort)
scratch-2025
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l25-difference\" aria-label=\"Duas listas lado a lado. À esquerda, o que o Terraform declara, lido do estado dele: orders e invoices. À direita, o que existe, lido do inventário ou, no laboratório, do gcloud: orders, invoices e scratch-2025. Uma seta das duas listas para uma terceira caixa dá a diferença, o que existe e ninguém declarou: scratch-2025. Os dois fins possíveis estão escritos embaixo: importado para o Terraform, ou apagado. Uma nota diz que um recurso declarado e mudado à mão aparece nas duas listas, e é o drift da próxima lição.\"><defs><marker id=\"l25-difference-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"200.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">declarado</text><text x=\"120.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">terraform state</text><text x=\"120.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">orders</text><text x=\"120.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">invoices</text><rect x=\"260.0\" y=\"20.0\" width=\"200.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">existente</text><text x=\"360.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o inventário, ou o gcloud</text><text x=\"360.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">orders</text><text x=\"360.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">invoices</text><text x=\"360.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">scratch-2025</text><path d=\"M462.0 85.0 L506.0 85.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l25-difference-af-ah-amber)\"></path><rect x=\"510.0\" y=\"20.0\" width=\"190.0\" height=\"130.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"605.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">existe, sem declarar</text><text x=\"605.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">scratch-2025</text><text x=\"605.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">importar, ou apagar</text><text x=\"360.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o que existe, menos o que está declarado, é o que alguém esqueceu</text><text x=\"360.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um recurso declarado mudado à mão está nas duas listas: isso é drift, lição 26</text></svg>", "caption": "A diferença entre as duas listas é o trabalho."}
```

**O `scratch-2025` existe e ninguém o declarou.** Na escala do planner a segunda lista vem do inventário e não do
gcloud, uma busca em todos os projetos em vez de uma lista por projeto, e a primeira vem do estado de todo
workspace do Terraform. O job noturno que as compara abre um chamado para cada nome na diferença, e o chamado tem
dois fins possíveis: o recurso é escrito no Terraform, com `terraform import`, ou é apagado.

**O que isso não acha** é um recurso que o Terraform gerencia e que alguém mudou à mão. O nome dele está nas duas
listas. Isso é drift, e a próxima lição é sobre ele.
