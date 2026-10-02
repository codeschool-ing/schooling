---
title: Soltando um recurso sem destruí-lo
version: 1
---

Às vezes um recurso deveria sair de uma configuração e continuar existindo. O time de dados vai
assumir os logs da loja: eles vão gerir o `shop-logs-dev` a partir da configuração deles, e a aula 8
mostra como vão importá-lo lá. A configuração da Ana precisa parar de gerir o bucket **sem
apagá-lo**, e apagar o bloco é o movimento óbvio e o errado:

```
ana@laptop:~/shop/assets$ terraform plan | grep -E "will|because|Plan:"
Terraform will perform the following actions:
  # aws_s3_bucket.logs will be destroyed
  # (because aws_s3_bucket.logs is not in configuration)
Plan: 0 to add, 0 to change, 1 to destroy.
```

Para o Terraform, um recurso que está no state e falta no arquivo é um recurso que você quer que
suma. É o mesmo mecanismo que passou por cima do `prevent_destroy` duas seções atrás, e aqui ele
apagaria um bucket do qual outro time está prestes a depender.

## O bloco `removed`

O Terraform 1.7 trouxe um bloco que diz a outra coisa. Ele nomeia o endereço que está saindo, e o
`lifecycle` dele diz se o objeto real vai junto:

```
ana@laptop:~/shop/assets$ git diff
diff --git a/main.tf b/main.tf
index b16c15f..111c62c 100644
--- a/main.tf
+++ b/main.tf
@@ -10,6 +10,10 @@ resource "aws_s3_bucket" "assets" {
   }
 }
 
-resource "aws_s3_bucket" "logs" {
-  bucket = "shop-logs-dev"
+removed {
+  from = aws_s3_bucket.logs
+
+  lifecycle {
+    destroy = false
+  }
 }
```

O plan que vem depois tem um símbolo próprio:

```
ana@laptop:~/shop/assets$ terraform plan
aws_s3_bucket.assets: Refreshing state... [id=shop-assets-dev]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:

Terraform will perform the following actions:

 # aws_s3_bucket.logs will no longer be managed by Terraform, but will not be destroyed
 # (destroy = false is set in the configuration)
 . resource "aws_s3_bucket" "logs" {
        id                          = "shop-logs-dev"
        # (15 unchanged attributes hidden)

        # (2 unchanged blocks hidden)
    }

Plan: 0 to add, 0 to change, 0 to destroy.
╷
│ Warning: Some objects will no longer be managed by Terraform
│ 
│ If you apply this plan, Terraform will discard its tracking information for
│ the following objects, but it will not delete them:
│  - aws_s3_bucket.logs
│ 
│ After applying this plan, Terraform will no longer manage these objects.
│ You will need to import them into Terraform to manage them again.
╵
```

**`will no longer be managed by Terraform, but will not be destroyed`**, com um ponto em vez de um
sinal de menos, e um resumo de zero mudanças, porque nada na AWS vai mudar. O aviso diz com todas as
letras a única consequência: daqui em diante o Terraform esqueceu o bucket, e voltar a geri-lo
significa importá-lo.

A Ana aplica e confere os dois lados:

```
ana@laptop:~/shop/assets$ terraform apply -auto-approve | tail -n 1
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
ana@laptop:~/shop/assets$ terraform state list
aws_s3_bucket.assets
ana@laptop:~/shop/assets$ aws s3 ls
2026-10-02 06:53:18 shop-logs-dev
2026-10-02 06:53:18 shop-assets-dev
```

O state lista só o bucket de assets; a AWS ainda tem os dois. A operação inteira é essa: uma
entrada tirada do state, e nada tocado na nuvem.

## Por que um bloco e não um comando

`terraform state rm` faz o mesmo com o state, e a aula 7 o mostra. A diferença é a que separou
`-replace` de `taint` na seção anterior, no sentido contrário: **`state rm` é um comando que alguém
roda no state compartilhado, e ninguém o revisa.** Um bloco `removed` é uma mudança no arquivo. Passa
por um pull request, aparece no plan exatamente como é, e funciona igual para todo colega e todo
pipeline que aplicar a configuração depois.

Depois de aplicado, o bloco cumpriu sua função, e pode ser apagado num commit posterior. Deixá-lo
não faz mal, e registra no arquivo por que o bucket deixou de estar ali.
