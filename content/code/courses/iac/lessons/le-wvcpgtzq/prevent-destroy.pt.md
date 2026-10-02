---
title: prevent_destroy, e o que ele não impede
version: 1
---

Alguns recursos são baratos de perder e outros não. Uma instância substituída volta a partir da
imagem; um bucket destruído leva junto todos os objetos dentro dele. **`prevent_destroy` é um
argumento de lifecycle que faz o Terraform recusar qualquer plan que destruiria o recurso.** É um
cinto de segurança para o punhado de coisas cuja perda estraga o dia: o bucket com as imagens dos
produtos da loja, um banco de dados, o bucket de state que a aula 7 cria.

A Ana mantém os buckets da loja numa configuração própria, `~/shop/assets`. O bucket de assets tem a
configuração; o bucket de logs, assunto da última seção desta aula, não tem:

```hcl
provider "aws" {
  region = "sa-east-1"
}

resource "aws_s3_bucket" "assets" {
  bucket = "shop-assets-dev"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "shop-logs-dev"
}
```

## A recusa

Um `terraform destroy` aqui planeja a destruição dos dois buckets, imprime esse plan inteiro e
para antes de perguntar qualquer coisa:

```
Plan: 0 to add, 0 to change, 2 to destroy.
╷
│ Error: Instance cannot be destroyed
│ 
│   on main.tf line 5:
│    5: resource "aws_s3_bucket" "assets" {
│ 
│ Resource aws_s3_bucket.assets has lifecycle.prevent_destroy set, but the
│ plan calls for this resource to be destroyed. To avoid this error and
│ continue with the plan, either disable lifecycle.prevent_destroy or reduce
│ the scope of the plan using the -target option.
╵
```

**A execução inteira é recusada, não só o recurso protegido.** O bucket de logs, que não tem
proteção nenhuma, também não foi destruído: o Terraform não aplica parte de um plan que rejeitou.

Uma renomeação é pega do mesmo jeito, porque o nome de um bucket não muda no lugar. A Ana tenta
`shop-assets-prod`:

```
-/+ destroy and then create replacement

Terraform planned the following actions, but then encountered a problem:

  # aws_s3_bucket.assets must be replaced
-/+ resource "aws_s3_bucket" "assets" {
      + acceleration_status         = (known after apply)
      + acl                         = (known after apply)
      ~ arn                         = "arn:aws:s3:::shop-assets-dev" -> (known after apply)
      ~ bucket                      = "shop-assets-dev" -> "shop-assets-prod" # forces replacement
```

O mesmo erro vem em seguida, palavra por palavra. É esse o caso que faz a configuração valer a pena:
a mudança parece a edição de uma string, o plan a chama de substituição, e um revisor que lesse só o
diff aprovaria. `prevent_destroy` transforma uma substituição que ninguém notou num plan que não
pode rodar.

## O que ele não impede

**A configuração mora no bloco do recurso, então só protege o recurso enquanto o bloco estiver no
arquivo.** Apague o bloco inteiro e a proteção vai junto:

```
ana@laptop:~/shop/assets$ git diff --stat
 main.tf | 8 --------
 1 file changed, 8 deletions(-)
ana@laptop:~/shop/assets$ terraform plan | grep -E "will|because|Plan:"
Terraform will perform the following actions:
  # aws_s3_bucket.assets will be destroyed
  # (because aws_s3_bucket.assets is not in configuration)
Plan: 0 to add, 0 to change, 1 to destroy.
```

Oito linhas removidas, e o plan destrói o bucket sem reclamar, `because aws_s3_bucket.assets is not
in configuration`. Uma refatoração descuidada, ou um merge que perde um arquivo, passa por
`prevent_destroy` sem nem tentar.

Ele também não alcança nada fora do Terraform. Alguém com as permissões certas ainda apaga o bucket
pelo console ou pela CLI; o Terraform percebe no plan seguinte e se oferece para criar um vazio. As
proteções contra isso ficam do lado da AWS: permissões do IAM que negam apagar o bucket, e
versionamento no bucket para que um objeto apagado possa ser recuperado. A aula 7 liga o
versionamento no bucket de state pelo mesmo motivo.

E a própria mensagem de erro aponta a saída de emergência: tirar a configuração, ou estreitar o plan
com `-target`. As duas são edições deliberadas, feitas de propósito, e esse é o ponto. Quando o
bucket precisa mesmo sumir, a mudança que remove o `prevent_destroy` é um commit separado, revisado
sozinho, antes do commit que remove o bucket.
