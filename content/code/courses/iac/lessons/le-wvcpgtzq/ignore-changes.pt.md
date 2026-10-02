---
title: ignore_changes, para um atributo que é de outra pessoa
version: 1
---

O Terraform supõe que é dono de todo argumento que recebeu. Se o valor real difere do arquivo, o
arquivo vence no apply seguinte. É essa a cura do drift que a aula 1 descreveu, e quase sempre é
exatamente o certo. **Às vezes, porém, um segundo sistema deveria mudar um atributo**, e aí o
Terraform desfazer o trabalho dele a cada apply é o defeito.

O time financeiro da loja roda uma ferramenta de custos que percorre a conta e marca cada instância
que encontra com o centro de custo a que ela pertence. Ela marcou a `web` hoje de manhã. O plan
seguinte da Ana, sobre outra coisa completamente diferente, contém isto:

```
ana@laptop:~/shop/app$ terraform plan
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
      ~ tags                                 = {
          - "CostCenter" = "cc-4410" -> null
            "Name"       = "web"
        }
      ~ tags_all                             = {
          - "CostCenter" = "cc-4410" -> null
            # (1 unchanged element hidden)
        }
        # (39 unchanged attributes hidden)

        # (4 unchanged blocks hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
```

O Terraform planeja apagar a tag `CostCenter`, porque o arquivo diz que as tags são `Name = "web"` e
mais nada. Aplique isso e a ferramenta de custos a põe de volta à noite, e o plan seguinte a remove
de novo. Dois sistemas automáticos discutindo um valor, todo dia, com todo plan carregando uma
mudança que ninguém pediu. Esse ruído é o dano real: um revisor que vê uma mudança de tag em todo
plan para de ler mudanças de tag.

## Dizendo ao Terraform para olhar para o outro lado

`ignore_changes` lista atributos que o Terraform deve deixar em paz depois de criar o recurso. Ele
os lê, guarda no state e para de compará-los com o arquivo:

```
ana@laptop:~/shop/app$ git diff
diff --git a/main.tf b/main.tf
index 0d2ae36..104bfa6 100644
--- a/main.tf
+++ b/main.tf
@@ -31,6 +31,7 @@ resource "aws_instance" "web" {
 
   lifecycle {
     create_before_destroy = true
+    ignore_changes        = [tags["CostCenter"]]
   }
 }
 
ana@laptop:~/shop/app$ terraform plan
aws_vpc.shop: Refreshing state... [id=vpc-620a9a42c64d1b9c4]
aws_security_group.web: Refreshing state... [id=sg-7bd9ca389f1f7168d]
aws_subnet.a: Refreshing state... [id=subnet-47e7ab7e19d97ade4]
aws_instance.web: Refreshing state... [id=i-6deb06a6fc79f194d]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
```

`tags["CostCenter"]` nomeia uma chave do mapa, e não o argumento `tags` inteiro. A Ana continua dona
de `Name`, e uma mudança nela no arquivo continua sendo aplicada; só a chave que a ferramenta de
custos escreve é ignorada.

**Ignore o mínimo possível.** `ignore_changes = [tags]` também teria calado este plan, e calaria
toda mudança futura que a Ana fizesse nas tags no arquivo, que pareceriam aplicadas sem estar.
`ignore_changes = all` também existe, e transforma um recurso em algo que o Terraform cria uma vez e
nunca mais olha. Os dois são um jeito de esconder drift, o contrário do que a ferramenta existe
para fazer.

## Onde ele cabe

Os casos que o justificam têm o mesmo formato: outro sistema é dono do valor, de propósito.

- Um autoscaler muda o `desired_capacity` de um Auto Scaling group o dia todo; o arquivo guarda o
  valor inicial, e ignorá-lo impede que cada apply redefina o tamanho da frota.
- Uma tag escrita por outra ferramenta, como aqui.
- Uma AMI escolhida por um data source com `most_recent` (aula 5): quando aparece uma imagem mais
  nova, o plan substitui a instância. Ignorar `ami` mantém a máquina em execução até alguém
  substituí-la de propósito, com o `-replace` da próxima seção.

O que não cabe é um valor que um colega mudou à mão porque o arquivo atrapalhava. Isso é drift com
autorização assinada. O certo ali é pôr o valor novo no arquivo, ou pôr o antigo de volta, e
conversar com o colega.

Um último detalhe: `ignore_changes` só vale depois da criação. Quando o recurso é criado, ou
substituído por algum outro motivo, os argumentos ignorados recebem o valor do arquivo como
qualquer outro.
