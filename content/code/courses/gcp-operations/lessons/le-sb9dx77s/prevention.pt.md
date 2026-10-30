---
title: Quando não há versão para onde voltar
version: 1
---

**Se o estado sumiu e nenhuma versão dele sobreviveu, os recursos ainda existem e o Terraform não os
conhece mais.** Um plano então propõe criar tudo, e um apply criaria duplicatas ou falharia em nomes já
ocupados. O caminho de volta é dizer ao Terraform, recurso por recurso, qual objeto real cada um é: um
**import**.

O jeito mais rápido de ver essa situação sem destruir nada é um backend com um prefixo que ninguém usou.
Mude o `backend.tf` para o estado morar em outro lugar, como faria um erro de digitação no prefixo:

```hcl
# tf/shop/backend.tf
terraform {
  backend "gcs" {
    bucket                  = "planner-dev-tfstate"
    prefix                  = "shop-v2"
    storage_custom_endpoint = "http://localhost:4443/storage/v1/"
  }
}
```

```
ana@laptop:~/gcp/tf/shop$ terraform init -reconfigure -input=false -no-color | grep -E "Successfully"
Successfully configured the backend "gcs"! Terraform will automatically
```

O estado sob `shop-v2` está vazio; o tópico e a lista de preços estão onde estavam. Um bloco `import` nomeia
um endereço de recurso e o id do objeto real, e o plano lê o objeto e o adota:

```hcl
# tf/shop/imports.tf
import {
  to = google_pubsub_topic.orders
  id = "projects/planner-dev/topics/shop-orders"
}
```

```
ana@laptop:~/gcp/tf/shop$ terraform plan -input=false -no-color | grep -E "^  # |^Plan:|import"
google_pubsub_topic.orders: Preparing import... [id=projects/planner-dev/topics/shop-orders]
  # google_pubsub_topic.orders will be updated in-place
  # (imported from "projects/planner-dev/topics/shop-orders")
  # google_storage_bucket_object.prices will be created
Plan: 1 to import, 1 to add, 1 to change, 0 to destroy.
```

Três linhas para ler. O tópico é **importado**: o plano o achou pelo id e vai registrá-lo no estado. Ele
também é **atualizado no lugar**, e o próximo comando mostra por quê:

```
ana@laptop:~/gcp/tf/shop$ terraform plan -input=false -no-color | sed -n "/pubsub_topic.orders will be/,/^    }/p" | grep -E "^ +[~+-] "
  ~ resource "google_pubsub_topic" "orders" {
      ~ terraform_labels           = {
          + "goog-terraform-provisioned" = "true"
```

O tópico foi criado pelo Terraform, mas o rótulo que o provider acrescenta nunca foi guardado pelo
emulador, então o import o encontra faltando e o acrescenta. Contra o Google o rótulo estaria lá e a linha
não apareceria. **E a lista de preços será criada**, porque o provider google não consegue importar um
objeto de bucket: nenhum bloco `import` é possível para ele, e a única proposta do plano é escrevê-lo de
novo. Aqui isso não faz mal, porque o conteúdo é o mesmo. Para um recurso cuja criação faz mal, um tipo de
recurso sem import é motivo para guardar as versões do estado, e não um detalhe.

## Quatro hábitos que mantêm esta lição na teoria

1. **Versionamento no bucket de estado**, sempre, e uma regra de ciclo de vida em vez de nenhum histórico.
2. **Nenhum estado local para nada compartilhado.** Uma configuração começa pelo backend, não depois do
   primeiro apply.
3. **Um prefixo por configuração, escrito uma vez**, e revisado como código quando muda: um prefixo mudado
   é um estado novo e vazio que parece exatamente um estado funcionando até o plano dizer "create".
4. **Um plano que propõe criar coisas que existem é um sinal de pare.** Significa que o Terraform perdeu o
   rastro delas, e aplicá-lo transforma um problema de contabilidade num problema de produção.
