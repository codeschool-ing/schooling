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
