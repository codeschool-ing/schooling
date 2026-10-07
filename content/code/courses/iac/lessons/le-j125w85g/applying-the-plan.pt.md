---
title: Aplicar exatamente o plan que foi lido
version: 2
---

A aprovação neste pipeline é uma pessoa lendo um plan salvo e dizendo sim a ele. **O que dá sentido
a essa aprovação é o job de apply rodar aquele arquivo e nada mais.** Um job que rodasse
`terraform apply -auto-approve` na `main` faria o plan de novo naquele momento e executaria o plan
novo, que ninguém leu; a aprovação seria a revisão de uma coisa e a permissão para outra.

No GitHub, a espera acontece no environment `production`: com revisores obrigatórios configurados
nele, o job `apply` pausa antes do primeiro passo, e a execução mostra um botão que só essas pessoas
podem apertar. No GitLab, é o job manual `apply`. Nos dois casos, quem revisa lê o log do job de
plan ou o `plan.txt`, e então deixa o próximo job começar.

## O arquivo viaja; o checkout é novo

O plan da execução 1 foi salvo antes, no clone dela. Enquanto ela esperava a aprovação, um pull
request que acrescenta uma tag `Owner` à VPC entrou por merge. Para fazer o merge da mesma mudança no
seu remoto, no `~/shop`:

```sh
sed -i 's/{ Name = "shop", Environment = var.environment }/{ Name = "shop", Environment = var.environment, Owner = "ana" }/' main.tf
terraform fmt
git commit -qam "shop: Owner tag on the VPC" && git push -q origin main
```

A execução 2, o pipeline desse commit, também fez o plan antes de a execução 1 ser aprovada, e a
próxima seção começa com esse plan. Para ver o mesmo plan, digite agora os três primeiros comandos
daquela seção: o clone a partir do seu diretório home, os outros dois no `~/ci/run-2`. Depois volte
para cá.

O job de apply da execução 1 começa num clone novo, recebe o `tfplan` e o aplica. Repare em qual
commit este clone tem:

```
ana@laptop:~$ git clone -q git/shop.git ci/run-1-apply
ana@laptop:~/ci/run-1-apply$ git log --oneline -1
53a4007 shop: Owner tag on the VPC
ana@laptop:~/ci/run-1-apply$ cp ../run-1/tfplan .
ana@laptop:~/ci/run-1-apply$ ./ci.sh apply
```

A tag `Owner` entrou por merge enquanto a execução 1 esperava, então um clone da `main` agora traz esse
commit posterior. O apply segue adiante:

```
+ terraform apply -input=false -lock-timeout=5m tfplan
aws_vpc.shop: Creating...
aws_vpc.shop: Creation complete after 2s [id=vpc-d23fdf50099101ff0]
aws_subnet.a: Creating...
aws_security_group.web: Creating...
aws_subnet.a: Creation complete after 0s [id=subnet-c59b983a250cafb96]
aws_security_group.web: Creation complete after 0s [id=sg-4b1e1bc89d446a519]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

E a VPC que ele criou não tem a tag `Owner`, embora o `main.tf` ao lado do arquivo de plan peça
uma:

```
ana@laptop:~/ci/run-1-apply$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].Tags[].Key" --output text
Name	Environment
ana@laptop:~/ci/run-1-apply$ grep -c Owner main.tf
1
```

**Um plan salvo carrega a configuração a partir da qual foi calculado**, como a aula 9 encontrou
dentro do arquivo, e o `apply` segue o plan, não os arquivos `.tf` em volta dele. Aqui isso está
exatamente certo: quem revisou aprovou um plan sem a tag, e foi isso o que aconteceu. A tag pertence
à execução 2, e passa pelo próprio plan e pela própria aprovação.

O checkout não é irrelevante, porém. O `terraform init` do job de apply lê dele o bloco de backend e
o lock file de dependências, e o Terraform recusa um plan salvo cujas seleções de provider diferem
do lock file que ele encontra. É por isso que o workflow do GitHub deixa a `actions/checkout` no
padrão, o commit que disparou a execução: assim todo job de uma execução vê os mesmos arquivos. O
clone desta aula foi tirado da `main` como ela estava naquele momento, que é o erro de um
workflow que faz checkout de um nome de branch em vez do commit da própria execução. Desta vez não
causou dano, porque só uma tag era diferente.

## Quando o plan não pode mais ser aplicado

Duas coisas aposentam um plan salvo, e as duas são recursos:

| o que aconteceu | o que o Terraform ou o serviço de CI faz | o que fazer |
| --- | --- | --- |
| o state mudou desde que o plan foi feito | `Error: Saved plan is stale`, aula 9 | fazer o plan de novo, ler de novo |
| o artefato expirou, depois do `retention-days` ou do `expire_in` | não há arquivo para baixar | rodar o job de plan de novo |

Nenhuma das duas é falha do pipeline. **Um plan é uma afirmação sobre o mundo num momento**, e as
duas regras impedem que ele seja aplicado depois que esse momento passou. O que o pipeline nunca
deve fazer, diante de qualquer uma, é recorrer a um apply sem arquivo de plan. A próxima seção
mostra a primeira regra disparando no próprio pipeline, e por que disparou.
