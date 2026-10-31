---
title: A trava, e a pré-condição por trás dela
version: 1
---

**Dois applies contra um mesmo estado ao mesmo tempo escreveriam cada um a sua versão dele, e o segundo
apagaria o primeiro.** O backend `gcs` evita isso com uma trava: antes de uma operação que possa escrever
o estado, o Terraform cria um objeto `default.tflock` ao lado dele, e o cria com uma **pré-condição** de que
o objeto ainda não pode existir. O Cloud Storage recusa a escrita se ele existir. Um apply fica com a
trava; o outro ouve que ela está ocupada.

Para ver, a loja precisa de um apply que demore. Este recurso não faz nada além de esperar quinze segundos
enquanto é criado:

```hcl
# tf/shop/slow.tf
resource "terraform_data" "slow" {
  provisioner "local-exec" {
    command = "sleep 15"
  }
}
```

Ponha-o em `~/gcp/tf/shop/slow.tf` e inicie `terraform apply -auto-approve` num **segundo terminal**, com
as mesmas variáveis. Enquanto ele espera, peça um plano no primeiro, com `-lock-timeout=0s` para que ele
também não espere pela trava:

```
ana@laptop:~/gcp/tf/shop$ terraform plan -lock-timeout=0s -input=false -no-color 2>&1 | head -12

Error: Error acquiring the state lock

Error message: writing "gs://planner-dev-tfstate/shop/default.tflock" failed:
googleapi: Error 412: Precondition failed, Precondition Failed
Lock Info:
  ID:        1793386576193180
  Path:      gs://planner-dev-tfstate/shop/default.tflock
  Operation: OperationTypeApply
  Who:       root@vm
  Version:   1.16.4
  Created:   2026-10-30 18:56:16.188547796 +0000 UTC
```

**Error 412, Precondition Failed** é o Cloud Storage se recusando a criar um objeto que já existe, e é o
mecanismo inteiro. O Terraform então lê a trava e informa quem a tem. `Who` é o usuário e a máquina que
pegaram a trava, aqui o computador em que o curso foi gravado. A trava é um objeto comum, e pode ser lida
como um:

```
ana@laptop:~/gcp/tf/shop$ gcloud storage cat gs://planner-dev-tfstate/shop/default.tflock; echo
{"ID":"f8bd2b2d-a594-2165-a8b5-caa6c6aac82e","Operation":"OperationTypeApply","Info":"","Who":"root@vm","Version":"1.16.4","Created":"2026-10-30T18:56:16.188547796Z","Path":"gs://planner-dev-tfstate/shop/default.tflock"}
```

Quando o apply do outro terminal termina, ele apaga a trava:

```
ana@laptop:~/gcp/tf/shop$ gcloud storage ls gs://planner-dev-tfstate/shop/
gs://planner-dev-tfstate/shop/default.tfstate
```

Apague o `slow.tf` e aplique de novo, para o estado voltar aos dois recursos reais.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Dois terminais e um objeto de trava no bucket de estado. O terminal um cria default.tflock com a pré-condição de que ele não exista, e o Cloud Storage responde 200. O terminal dois faz o mesmo pedido um instante depois e recebe 412 Precondition Failed, então o apply dele para antes de ler ou escrever o estado.\"><defs><marker id=\"ah2\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"180\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">terminal 1</text><rect x=\"20\" y=\"120\" width=\"180\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">terminal 2</text><rect x=\"470\" y=\"70\" width=\"230\" height=\"60\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"585\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">default.tflock</text><text x=\"585\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no bucket de estado</text><line x1=\"202\" y1=\"55\" x2=\"468\" y2=\"88\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah2)\"></line><text x=\"330\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">create if absent → 200</text><line x1=\"202\" y1=\"145\" x2=\"468\" y2=\"114\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#ah2)\"></line><text x=\"330\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">create if absent → 412</text></svg>", "caption": "Só uma criação pode dar certo, então só um apply roda. Quem garante é o bucket, não o Terraform.", "same": ["terminal 1", "terminal 2"]}
```

## Uma trava esquecida

Um apply morto no meio (um laptop fechado, um job de esteira cancelado) deixa a trava no lugar, e toda
operação depois dele é recusada com a mensagem acima. `terraform force-unlock` com o `ID` da trava a
remove:

```sh
terraform force-unlock 1793386576193180
```

Ele não foi executado aqui, e **é o comando para digitar mais devagar de toda esta lição**. Antes dele,
descubra se a operação em `Who` e `Created` está mesmo morta: um job de esteira ainda rodando, ou o apply
de um colega em andamento, é exatamente o que a trava está protegendo, e removê-la deixa dois escritores
entrarem de uma vez. O `ID` da mensagem do Terraform é o que o `force-unlock` recebe; ele é a geração do
objeto, por isso difere do `ID` dentro do arquivo.

## Sem backend, sem trava

`-lock=false` desliga a trava para um comando, e aparece em tutoriais como a correção para "Error
acquiring the state lock". Não é correção. Uma esteira que roda o Terraform com isso é uma esteira em que
dois merges no mesmo minuto podem escrever um estado cada, e o segundo vence.
