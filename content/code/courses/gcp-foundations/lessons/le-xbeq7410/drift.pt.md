---
title: Drift
version: 1
---

**Drift é a diferença entre o que os arquivos do Terraform declaram e o que existe**, feita por alguém usando outra
porta. Não é um erro em lugar nenhum: a API aceitou toda mudança, o estado do Terraform registrou o que sabia por
último, e os dois agora discordam em silêncio até alguém perguntar. O Terraform pergunta toda vez que planeja,
porque um plano **atualiza** antes: ele lê todo recurso que gerencia, os `GET`s da seção anterior, e compara.

## Alguém apaga um recurso

Em `~/gcp/doors`, onde o Terraform fez o `shipments`, alguém arruma as coisas com o gcloud:

```
ana@laptop:~/gcp/doors$ gcloud pubsub topics delete shipments
Deleted topic [projects/planner-dev/topics/shipments].
```

Pergunte ao Terraform o que ele vê, sem propor nada. O `-refresh-only` relata as diferenças entre o estado dele e o
mundo, e não muda recurso nenhum:

```
ana@laptop:~/gcp/doors$ terraform plan -input=false -no-color -refresh-only 2>&1 | grep -E "has been deleted|^Plan|No changes"
  # google_pubsub_topic.shipments has been deleted
```

**O Terraform percebeu**, e diz isso no passado: o recurso *has been deleted*, por outra pessoa. Agora o plano
comum, que compara os arquivos com esse mundo atualizado:

```
ana@laptop:~/gcp/doors$ terraform plan -input=false -no-color | grep -E "^Plan|will be created"
  # google_pubsub_topic.shipments will be created
Plan: 1 to add, 0 to change, 0 to destroy.
```

**Os arquivos ainda declaram o `shipments`, então o plano o põe de volta.** Isso é o drift sendo corrigido, e é o
resultado certo só se os arquivos estiverem certos. Se a remoção foi proposital, o conserto é tirar o recurso dos
arquivos, e o plano então não propõe nada. De um jeito ou de outro **os arquivos decidem**, e quem usou outra porta
tem de mudá-los também ou ver a mudança desfeita no próximo apply.

## Alguém muda o arquivo

A outra direção é a comum. Ponha o `shipments` de volta primeiro, para os arquivos e o mundo concordarem de novo:

```sh
terraform apply -input=false -auto-approve
```

Depois mude o rótulo no `topics.tf` de `planner` para `platform`, e planeje:

```
ana@laptop:~/gcp/doors$ sed -i 's/team = "planner"/team = "platform"/' topics.tf
ana@laptop:~/gcp/doors$ terraform plan -input=false -no-color | grep -E "^Plan|update in-place|\"team\""
  ~ update in-place
          ~ "team"                       = "planner" -> "platform"
          ~ "team" = "planner" -> "platform"
          ~ "team"                       = "planner" -> "platform"
Plan: 0 to add, 1 to change, 0 to destroy.
```

`~ update in-place`, com o rótulo indo de um valor para o outro. Ele aparece três vezes porque o provider guarda
três visões dos rótulos de um recurso: `labels`, como o arquivo os escreve; `terraform_labels`, esses mais os que o
provider acrescenta por padrão; e `effective_labels`, todo rótulo do recurso, inclusive os definidos por outra
porta.

Isso só é planejado aqui: a lição 3 mostrou que o emulador se recusa a atualizar os rótulos de um tópico, o que é
uma lacuna do emulador, não do Pub/Sub.

## As regras do planner sobre drift

- **Todo workspace do Terraform é planejado toda noite**, por um pipeline que não muda nada e alerta sobre qualquer
  plano que não esteja vazio. Um plano não vazio na manhã depois de um incidente é a lista do que foi mudado à mão
  durante ele, que é a lista que alguém tem de escrever de volta nos arquivos.
- **Uma mudança em produção por outra porta é permitida numa emergência** e é seguida, no mesmo dia, pela mudança
  nos arquivos. As contas de emergência da lição 10 existem exatamente para isso, e o uso delas é auditado.
- **O `-refresh-only` é lido antes de um apply que não deveria fazer nada**: ele diz o que mudou por baixo, em vez
  do que o apply faria a respeito.
