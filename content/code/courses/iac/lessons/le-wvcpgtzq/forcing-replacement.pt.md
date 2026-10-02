---
title: Pedindo uma substituição
version: 1
---

As duas últimas seções foram sobre impedir o Terraform de fazer alguma coisa. Esta é o inverso:
**uma substituição que o Terraform nunca escolheria sozinho**, porque nada nos argumentos do
recurso mudou. A instância está se comportando mal e uma nova resolveria; o script de boot mudou e
só uma máquina nova o executa. O Terraform compara o arquivo com o que existe, e quando os dois
concordam ele não tem motivo para mexer em nada. Você precisa dizer.

## Uma vez: `-replace`

`-replace` recebe o endereço de um recurso e acrescenta uma substituição dele ao plan. Funciona no
`plan` e no `apply`, e aqui passa pelo `plan` primeiro, para a Ana ver o que está prestes a pedir:

```
ana@laptop:~/shop/app$ terraform plan -replace=aws_instance.web | grep -E "replace|Plan:"
+/- create replacement and then destroy
  # aws_instance.web will be replaced, as requested
Plan: 1 to add, 0 to change, 1 to destroy.
```

`will be replaced, as requested` é o Terraform dizendo que o motivo é você, não o arquivo. O símbolo
é `+/-` porque a `web` tem `create_before_destroy` desde a segunda seção, e o resumo conta a única
substituição. Nada do pedido fica salvo em lugar nenhum: o plan seguinte, sem a flag, volta a não
ter mudanças.

**O jeito antigo era `terraform taint`**, que você ainda vai encontrar em runbooks e respostas
antigas. Ele marca o recurso no state, e todo plan depois disso o substitui até alguém aplicar ou
rodar `untaint`:

```
ana@laptop:~/shop/app$ terraform taint aws_instance.web
Resource instance aws_instance.web has been marked as tainted.
ana@laptop:~/shop/app$ terraform plan | grep -E "replace|taint|Plan:"
+/- create replacement and then destroy
  # aws_instance.web is tainted, so must be replaced
Plan: 1 to add, 0 to change, 1 to destroy.
ana@laptop:~/shop/app$ terraform untaint aws_instance.web
Resource instance aws_instance.web has been successfully untainted.
```

O plan diz `is tainted, so must be replaced` em vez de `as requested`, e a diferença é onde a
instrução mora. O `taint` escreve no state, que é compartilhado, então um colega que planeja uma
mudança não relacionada uma hora depois encontra nela uma substituição que não pediu. O `-replace`
vive numa linha de comando e morre com ela, e aparece no plan que é revisado. A documentação da
HashiCorp recomenda `-replace` e chama `taint` de deprecated.

## Toda vez que outra coisa muda: `replace_triggered_by`

A instância da Ana roda um instalador no primeiro boot, para uma release dada numa variável. Ela
acrescenta o user data e a variável, aplica e faz commit:

```
ana@laptop:~/shop/app$ git show --format= -U0
diff --git a/main.tf b/main.tf
index 104bfa6..f9a3266 100644
--- a/main.tf
+++ b/main.tf
@@ -29,0 +30 @@ resource "aws_instance" "web" {
+  user_data     = "#!/bin/sh\n/opt/shop/install ${var.release}\n"
@@ -46,0 +48,5 @@ resource "aws_security_group" "web" {
+
+variable "release" {
+  type    = string
+  default = "2026.10.1"
+}
```

Depois planeja a release seguinte:

```
ana@laptop:~/shop/app$ terraform plan -var release=2026.10.2
aws_vpc.shop: Refreshing state... [id=vpc-620a9a42c64d1b9c4]
aws_subnet.a: Refreshing state... [id=subnet-47e7ab7e19d97ade4]
aws_security_group.web: Refreshing state... [id=sg-7bd9ca389f1f7168d]
aws_instance.web: Refreshing state... [id=i-6deb06a6fc79f194d]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  ~ update in-place

Terraform will perform the following actions:

  # aws_instance.web will be updated in-place
  ~ resource "aws_instance" "web" {
        id                                   = "i-6deb06a6fc79f194d"
        tags                                 = {
            "CostCenter" = "cc-4410"
            "Name"       = "web"
        }
      ~ user_data                            = <<-EOT
            #!/bin/sh
          - /opt/shop/install 2026.10.1
          + /opt/shop/install 2026.10.2
        EOT
        # (40 unchanged attributes hidden)

        # (4 unchanged blocks hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
```

**Um update in-place, e essa é a armadilha.** O provider consegue mudar o user data de uma instância
no lugar, mas uma máquina lê o user data quando dá boot pela primeira vez, então a `web` em execução
ficaria com o texto novo e a release antiga. O plan está certo quanto à API e errado quanto ao que a
Ana quer: uma release nova deveria ser uma máquina nova.

`replace_triggered_by` diz isso. É uma lista de recursos, ou de atributos deles, e quando qualquer
um for atualizado ou substituído, este recurso é substituído também. A release não é um recurso,
então a Ana a embrulha num `terraform_data`, um recurso embutido no Terraform que guarda um valor e
não faz mais nada, para que o valor tenha algo que possa mudar:

```
ana@laptop:~/shop/app$ git show --format= -U0
diff --git a/main.tf b/main.tf
index f9a3266..7260031 100644
--- a/main.tf
+++ b/main.tf
@@ -35,0 +36 @@ resource "aws_instance" "web" {
+    replace_triggered_by  = [terraform_data.release]
@@ -52,0 +54,4 @@ variable "release" {
+
+resource "terraform_data" "release" {
+  input = var.release
+}
```

```
ana@laptop:~/shop/app$ terraform plan -var release=2026.10.2 | grep -E "replace|update|Plan:"
  ~ update in-place
+/- create replacement and then destroy
  # aws_instance.web will be replaced due to changes in replace_triggered_by
  # terraform_data.release will be updated in-place
Plan: 1 to add, 1 to change, 1 to destroy.
```

`terraform_data.release` é atualizado no lugar, e é essa atualização que substitui a `web`: `will
be replaced due to changes in replace_triggered_by`. O plan agora diz o que a Ana quer dizer, e vai
dizer em toda release futura, sem ninguém lembrar de uma flag.

Use-o para uma ligação que a configuração não consegue expressar de outro jeito. Quando um argumento
do recurso já força uma substituição, como `ami` força, o gatilho não acrescenta nada; e um gatilho
apontado para algo que muda muito substitui máquinas muitas vezes, então aponte-o para o único valor
que deve.
