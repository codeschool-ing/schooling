---
title: Quando o laboratório não funciona
version: 1
---

Quase toda falha neste laboratório é uma de cinco, e cada uma tem uma mensagem que dá para
reconhecer. Leia-as agora, uma vez, para que no dia em que uma delas aparecer seja uma frase que você
já viu.

**A instalação para no meio.** O `setup-iac.sh` começa com `set -e`, então para no primeiro comando
que falha. A última coisa que ele imprimiu é o passo que quebrou: um `apt-get` que não alcançou o
repositório, uma chave que o `curl` não conseguiu baixar, um `pip install` que não encontrou rede.
Conserte isso e rode o script inteiro de novo; todo passo dele pode ser repetido com segurança.

**O shell não conhece `aws`.** Cada terminal novo começa sem o ambiente do laboratório:

```
ana@laptop:~$ aws sts get-caller-identity
bash: aws: command not found
```

O comando está em `~/iac-venv`, e nada pôs esse diretório no `PATH` ainda. Leia o ambiente,
`. ~/iac-env.sh`, e tente de novo. Se o Ubuntu oferecer instalar um pacote `aws` para você, recuse:
seria um segundo AWS CLI, fora do ambiente, e não conserta o terminal em que você está.

**O CLI é encontrado, mas não tem credenciais.** Este é o terminal em que só o ambiente Python foi
ativado, e as quatro variáveis não foram definidas:

```
ana@laptop:~$ . ~/iac-venv/bin/activate
ana@laptop:~$ aws sts get-caller-identity
Unable to locate credentials. You can configure credentials by running "aws configure".
```

Isso também quer dizer que o CLI não sabia onde está o moto, e estava prestes a perguntar à AWS de
verdade. O remédio é a mesma linha, `. ~/iac-env.sh`, que faz as duas coisas.

**Nada responde no endpoint.** Com o moto parado, ou escutando numa porta diferente da que a variável
diz, o CLI avisa numa linha:

```
ana@laptop:~$ AWS_ENDPOINT_URL=http://localhost:4567 aws sts get-caller-identity

Could not connect to the endpoint URL: "http://localhost:4567/"
```

Olhe o terminal do moto: se ele mostra um prompt em vez de um servidor rodando, inicie-o de novo. Se
estiver rodando, compare a porta que ele imprimiu ao iniciar com a de `AWS_ENDPOINT_URL`.

**Existe algo que você não fez nesta aula.** Um moto deixado rodando desde uma aula anterior ainda
guarda o que aquela aula fez. O primeiro sinal costuma ser uma busca que encontra duas coisas onde a
aula esperava uma. Aqui o script de rede da loja, desta aula, rodou duas vezes, e uma configuração
pede então *a* VPC chamada `shop`:

```
ana@laptop:~/lookup$ terraform plan
data.aws_vpc.shop: Reading...

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: multiple EC2 VPCs matched; use additional constraints to reduce matches to a single EC2 VPC
│ 
│   with data.aws_vpc.shop,
│   on main.tf line 5, in data "aws_vpc" "shop":
│    5: data "aws_vpc" "shop" {
│ 
╵
```

Não há nada de errado com a configuração. Reinicie o moto, rode o `fresh-lesson.sh` e comece a aula
de novo pelo primeiro comando.

**Mais duas, que só alguns computadores encontram.** O provider da AWS do Terraform chama um bucket
de `<bucket>.localhost`, e no Ubuntu Server o resolvedor do sistema, o systemd-resolved, responde a
todo nome terminado em `.localhost` com o seu próprio computador. Alguns outros sistemas não fazem
isso; neles, criar um bucket falha com um erro dizendo que esse nome não pôde ser resolvido.
Acrescente `s3_use_path_style = true` ao bloco `provider "aws"`, e `use_path_style = true` a qualquer
bloco `backend "s3"`, e o provider põe o bucket no caminho em vez de no nome. E se o
`terraform init` disser que não alcança `registry.terraform.io`, o problema é a sua rede, não o
laboratório: a aula 10 mostra como essa falha aparece e o que ela quer dizer.
