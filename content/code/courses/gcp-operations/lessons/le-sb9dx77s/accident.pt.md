---
title: O acidente do estado perdido, e a versão que o salva
version: 1
---

**O estado some mais vezes do que se espera**: alguém arruma o bucket, um script apaga o prefixo errado,
uma migração copia por cima do arquivo errado. Os recursos continuam rodando; só a memória que o
Terraform tem deles se foi. Abaixo, o objeto do estado é apagado. Contra o Google o comando seria
`gcloud storage rm gs://planner-dev-tfstate/shop/default.tfstate`; aqui é o mesmo pedido feito
diretamente à API JSON do Cloud Storage com `curl`, porque o `fake-gcs-server` responde à exclusão do
`gcloud` com uma mensagem de erro mesmo quando apagou o objeto, e esse erro é da imitação, não do Google:

```
ana@laptop:~/gcp/tf/shop$ curl -s -X DELETE localhost:4443/storage/v1/b/planner-dev-tfstate/o/shop%2Fdefault.tfstate
null
```

Depois o plano:

```
ana@laptop:~/gcp/tf/shop$ terraform plan -input=false -no-color 2>&1 | grep -E "^  # |Plan:|Error|already exists"
  # google_pubsub_topic.orders will be created
  # google_storage_bucket_object.prices will be created
Plan: 2 to add, 0 to change, 0 to destroy.
```

**Os dois recursos existem, e o Terraform propõe criá-los.** Aplicado, o tópico falharia com "already
exists" e a lista de preços seria sobrescrita; numa configuração maior, alguns recursos seriam duplicados
com nomes novos e outros falhariam no meio. O plano é o aviso, e ele não diz nada alarmante: lê-se
exatamente como o plano de um projeto novo.

## As versões

O bucket foi criado com versionamento, então todo estado que o Terraform já escreveu continua lá como
versão não atual. `gcloud storage ls --all-versions` as lista no Google; a imitação responde a esse comando
só com a versão mais nova, então no seu computador a mesma pergunta vai à API JSON:

```
ana@laptop:~/gcp/tf/shop$ curl -s 'localhost:4443/storage/v1/b/planner-dev-tfstate/o?prefix=shop/default.tfstate&versions=true' | jq -r '.items[] | [.generation, .updated] | @tsv' | sort
1793386572668836	2026-10-30T18:56:12.668831Z
1793386572687355	2026-10-30T18:56:12.6873Z
1793386592437916	2026-10-30T18:56:32.437887Z
1793386596547680	2026-10-30T18:56:36.547653Z
1793386597092596	2026-10-30T18:56:37.092587Z
```

Cinco versões, e **a mais nova não é a que você quer.** Olhe dentro de cada uma: `serial` é o número que o
Terraform incrementa a cada escrita, e o número de recursos diz o que cada versão conhece:

```
ana@laptop:~/gcp/tf/shop$ for g in $(curl -s 'localhost:4443/storage/v1/b/planner-dev-tfstate/o?prefix=shop/default.tfstate&versions=true' | jq -r '.items[].generation' | sort); do printf '%s ' $g; curl -s "localhost:4443/storage/v1/b/planner-dev-tfstate/o/shop%2Fdefault.tfstate?generation=$g&alt=media" | jq -c '[.serial, (.resources | length)]'; done
1793386572668836 [1,0]
1793386572687355 [4,2]
1793386592437916 [5,3]
1793386596547680 [6,2]
1793386597092596 [1,0]
```

Leia de cima para baixo. Serial 1 sem nada é o estado vazio de onde a migração partiu; 4 com dois recursos
é o estado que ela copiou; 5 com três é o apply com `slow.tf`; 6 com dois é o apply que o removeu de novo.
**A última linha, serial 1 e nada, foi escrita pelo plano depois do acidente**: sem achar estado nenhum, o
backend criou um vazio. Restaurar "a versão mais recente" restauraria isso, e deixaria o Terraform tão
perdido quanto antes.

## Pondo de volta

A versão com serial 6 é baixada e enviada como estado atual. `terraform state push` a escreve pelo backend,
pegando a trava como qualquer outra escrita; `-force` é necessário porque o serial que ela substitui, 1,
pertence a outra linhagem de estado:

```
ana@laptop:~/gcp/tf/shop$ curl -s -o restored.tfstate 'localhost:4443/storage/v1/b/planner-dev-tfstate/o/shop%2Fdefault.tfstate?generation=1793386596547680&alt=media'
ana@laptop:~/gcp/tf/shop$ terraform state push -force restored.tfstate
ana@laptop:~/gcp/tf/shop$ terraform plan -input=false -no-color | grep -E "^  # |No changes|Plan:"
No changes. Your infrastructure matches the configuration.
ana@laptop:~/gcp/tf/shop$ rm restored.tfstate
```

**No changes** é a frase que diz que o estado e o mundo concordam de novo. Contra o Google,
`gcloud storage cp 'gs://planner-dev-tfstate/shop/default.tfstate#GENERATION' restored.tfstate` baixa uma
versão num passo; o resto é igual.
