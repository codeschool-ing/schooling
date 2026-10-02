---
title: Destroy, e o que fica para trás
version: 1
---

**O `terraform destroy` remove tudo o que o state desta configuração diz que ela criou, e nada
mais.** Ele não esvazia a conta da AWS e não apaga os seus arquivos. Uma VPC que alguém criou à
mão na mesma conta não está no state, então o destroy nem sabe que ela existe. Por baixo, ele é um
plano em que toda ação é `-`, executado contra o grafo de trás para a frente: o que foi criado por
último sai primeiro.

A Ana roda o destroy na rede inteira. O plano acima da pergunta lista os sete recursos com todos os
atributos indo para `null`, e termina assim:

```
Plan: 0 to add, 0 to change, 7 to destroy.

Changes to Outputs:
  - vpc_id                = "vpc-7327c901412b20229" -> null
  - web_security_group_id = "sg-3475d5edf795d5594" -> null
  - web_subnet_id         = "subnet-246685d4ada451bad" -> null

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes
local_file.network_env: Destroying... [id=7e6c26ee85afdb7031fa9435305563d6b82f4623]
local_file.network_env: Destruction complete after 0s
aws_vpc_security_group_ingress_rule.https: Destroying... [id=sgr-dcc6bf0490cd0c301]
aws_subnet.web_a: Destroying... [id=subnet-246685d4ada451bad]
aws_s3_bucket.assets: Destroying... [id=shop-assets-2ef20bf6]
aws_subnet.web_a: Destruction complete after 0s
aws_s3_bucket.assets: Destruction complete after 0s
aws_vpc_security_group_ingress_rule.https: Destruction complete after 0s
random_id.bucket: Destroying... [id=LvIL9g]
aws_security_group.web: Destroying... [id=sg-3475d5edf795d5594]
random_id.bucket: Destruction complete after 0s
aws_security_group.web: Destruction complete after 0s
aws_vpc.shop: Destroying... [id=vpc-7327c901412b20229]
aws_vpc.shop: Destruction complete after 0s

Destroy complete! Resources: 7 destroyed.
```

A pergunta é mais dura que a do apply, e **"There is no undo" é literal**. Os objetos de um bucket
apagado se foram, e uma VPC apagada não volta. O próximo apply criaria outra, com outro id. De
novo, só a palavra exata `yes` deixa seguir.

O log percorre o grafo ao contrário. O arquivo e os recursos das pontas saem primeiro: a sub-rede,
o bucket e a regra, que dependem de coisas mas não têm nada dependendo deles. O security group
espera pela regra, o `random_id` espera pelo bucket batizado com ele, e a VPC sai por último,
quando não sobra nada dentro dela. A ordem entre as pontas muda de uma execução para outra, porque
elas começam juntas.

**O `local_file` também se foi, e isso quer dizer o arquivo**: destruí-lo apagou o `network.env`
do notebook, do mesmo jeito que destruir o bucket apagou o bucket. Então é isto que sobra:

```
ana@laptop:~/shop$ ls
main.tf
outputs.tf
storage.tf
terraform.tfstate
terraform.tfstate.backup
terraform.tfvars
variables.tf
versions.tf
ana@laptop:~/shop$ terraform state list
ana@laptop:~/shop$ jq ".serial, (.resources | length)" terraform.tfstate
22
0
ana@laptop:~/shop$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].VpcId" --output text
ana@laptop:~/shop$ aws s3 ls
```

**A configuração está intacta**, todos os arquivos `.tf` e o `terraform.tfvars`. A AWS não tem mais
nada com as tags da loja, e o `aws s3 ls` não lista bucket nenhum. **E o arquivo de state continua
lá**, registrando zero recursos. Ele não é apagado porque continua sendo o registro de que esta
configuração não gerencia nada agora, o que é um fato e não uma ausência. O `serial` sobe a cada
vez que o state muda; o `terraform.tfstate.backup` é a versão anterior à última gravação. A aula 7
trata dos dois, e de por que um arquivo de state perdido é muito pior que um vazio.

O `.terraform/` e o lock file também ficam, então nada precisa ser instalado de novo, e os arquivos
ainda descrevem a rede inteira:

```
ana@laptop:~/shop$ terraform plan -no-color | grep -E "will be created|^Plan:"
  # aws_s3_bucket.assets will be created
  # aws_security_group.web will be created
  # aws_subnet.web_a will be created
  # aws_vpc.shop will be created
  # aws_vpc_security_group_ingress_rule.https will be created
  # local_file.network_env will be created
  # random_id.bucket will be created
Plan: 7 to add, 0 to change, 0 to destroy.
```

Sete a criar: os mesmos sete, com ids novos da AWS e um sufixo aleatório novo, logo um nome de
bucket novo. **A descrição é o que dura; a infraestrutura é algo que você consegue refazer a partir
dela.** É isso que torna razoável destruir uma cópia de desenvolvimento toda noite, o que a aula 16
faz de olho no custo.

Dois avisos para levar para contas reais. **O destroy é para uma configuração inteira com a qual
você terminou**: uma cópia de desenvolvimento, um teste, cada aula deste curso quando acaba. Para
remover um recurso, apague o bloco dele e aplique, e o plano vai mostrar um `-` e mais nada. E para
o que nunca pode sumir, um banco de dados ou um bucket com arquivos de clientes, a aula 6
acrescenta uma trava, `prevent_destroy`, que faz o Terraform recusar um plano que os apagaria.
