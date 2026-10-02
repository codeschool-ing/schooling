---
title: Perder o estado, e a segunda rede
version: 1
---

A crença comum é que o estado é um cache: algo que o Terraform guarda para ir mais rápido, e que
poderia reconstruir olhando em volta se precisasse. **Ele não consegue reconstruí-lo.** Sem o estado,
o Terraform não faz ideia de que alguma coisa existe, e faz o que qualquer ferramenta declarativa
faz com uma descrição e um mundo vazio: cria a descrição.

A Ana guarda a configuração no git, e faz o que a maioria dos guias manda: deixa o estado de fora.

```
.terraform/
*.tfstate
*.tfstate.*
```

```
ana@laptop:~/shop$ git ls-files
.gitignore
.terraform.lock.hcl
main.tf
```

Há bons motivos para essa linha, e as próximas seções os dão. Ela tem uma consequência fácil de não
ver: **um checkout deste repositório não tem estado.** Apagar o `terraform.tfstate` sem querer dá
exatamente a mesma situação, e o mesmo vale para o laptop de um colega, uma máquina nova ou um job de
CI. A Ana clona o próprio repositório num segundo diretório, como qualquer um desses faria:

```
ana@laptop:~$ git clone -q shop shop-2
ana@laptop:~/shop-2$ ls -a
.
..
.git
.gitignore
.terraform.lock.hcl
main.tf
```

O mesmo `main.tf`, o mesmo lock file, nenhum `terraform.tfstate`. Depois do `terraform init`, o
plan:

```
ana@laptop:~/shop-2$ terraform plan -no-color | grep -E "^  #|^Plan"
  # aws_security_group.web will be created
  # aws_subnet.a will be created
  # aws_vpc.shop will be created
Plan: 3 to add, 0 to change, 0 to destroy.
```

**Três para adicionar.** A VPC, a sub-rede e o security group estão todos na conta, e o plan quer
criar os três. Do ponto de vista do Terraform não há nada de errado: ele recebeu uma descrição, não
tem registro de nada, então tudo o que está na descrição está faltando. E ele não para no plan:

```
ana@laptop:~/shop-2$ terraform apply -auto-approve | tail -n 1
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
ana@laptop:~/shop-2$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].[VpcId,CidrBlock]" --output text
vpc-10f2b2857589fd959	10.20.0.0/16
vpc-fffe0fd578d4a6fe0	10.20.0.0/16
ana@laptop:~/shop-2$ aws ec2 describe-security-groups --filters Name=group-name,Values=web --query "SecurityGroups[].[GroupId,VpcId]" --output text
sg-3bb7d165786e44657	vpc-10f2b2857589fd959
sg-867bd8138208c328c	vpc-fffe0fd578d4a6fe0
```

**Duas VPCs chamadas `shop`, as duas `10.20.0.0/16`, e dois security groups chamados `web`, um em
cada.** É o mesmo acidente que o `network.sh` teve na aula 1, cometido pela ferramenta que deveria
evitá-lo. Nada falhou no caminho. O nome de um security group só precisa ser único dentro da VPC
dele, e o grupo novo foi criado na VPC nova, então a AWS não tinha por que recusar.

Numa conta real o custo não é só a fatura. A segunda rede tem a mesma faixa que a primeira, o que
importa no dia em que alguém tentar ligar as duas; o que for criado em seguida cai numa delas, e quem
abrir o console tem de descobrir em qual. E os três originais agora não são gerenciados de lugar
nenhum: o estado que os conhecia está no outro diretório.

Aqui a cópia é fácil de remover, porque o diretório que a criou tem um estado que conhece exatamente
aqueles três:

```
ana@laptop:~/shop-2$ terraform destroy -auto-approve | tail -n 1
Destroy complete! Resources: 3 destroyed.
ana@laptop:~/shop-2$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].[VpcId,CidrBlock]" --output text
vpc-10f2b2857589fd959	10.20.0.0/16
ana@laptop:~$ rm -rf shop-2
```

Sobra uma VPC, a original, que o primeiro diretório da Ana continua gerenciando. **Esse `destroy`
funcionou porque a duplicata tinha estado.** Se ela tivesse perdido o estado original, nada saberia
qual das VPCs idênticas era qual, e desembaraçar isso significaria ler ids à mão e trazê-los de
volta à gerência com `terraform import`, que a aula 8 mostra.

Então deixar o estado fora do git não resolve o problema; só impede que o git seja o lugar onde o
estado mora. **Cada pessoa e cada máquina que roda o Terraform nesta rede precisa ler o mesmo
estado**, a única cópia, o serial mais recente. Um arquivo num laptop não pode ser isso, e
três seções adiante o estado vai para um lugar que pode. Antes disso, mais duas coisas para as quais o
arquivo local serve: lê-lo e editá-lo com os comandos do próprio Terraform, e encontrar uma mudança
que alguém fez pelas costas dele.
