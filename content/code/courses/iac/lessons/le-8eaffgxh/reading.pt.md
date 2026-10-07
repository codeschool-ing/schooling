---
title: Um bloco que só pergunta
version: 2
---

Tudo na configuração da aula 2 era algo a criar. Um bloco `resource` diz "isto deve existir", e o
Terraform faz existir, guarda no state e destrói quando o bloco sai. **Um bloco `data` é a outra
metade da linguagem: ele faz uma pergunta e guarda a resposta.** Não cria nada, não muda nada e não
destrói nada, seja o que for que você escreva nele.

A imagem errada mais comum é a de que uma fonte de dados (data source) é um tipo mais leve de
recurso, que o Terraform "gerencia um pouco". Ele não gerencia nada. Uma data source é uma consulta
enviada pelo mesmo provider, e o resultado é um conjunto de atributos que você referencia como
qualquer outro. Aqui estão as duas menores perguntas que o provider da AWS sabe responder, quem sou
eu e onde estou, no `main.tf` de um diretório novo, `~/shop/app`:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "sa-east-1"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "region" {
  value = data.aws_region.current.region
}
```

A forma é `data "TIPO" "NOME" { … }`, a mesma de um recurso, e o endereço é `data.TIPO.NOME`; então
`data.aws_caller_identity.current.account_id` lê o número da conta. O nome `current` é só uma
convenção para essas duas. Os argumentos dentro das chaves, quando a data source tem algum, são a
**consulta**; os atributos que voltam são a **resposta**. Nenhuma das duas precisa de argumento,
porque o provider já conhece as próprias credenciais e a própria região.

Um apply dessa configuração roda as consultas e não cria nada:

```
ana@laptop:~/shop/app$ terraform apply -auto-approve
data.aws_region.current: Reading...
data.aws_caller_identity.current: Reading...
data.aws_region.current: Read complete after 0s [id=sa-east-1]
data.aws_caller_identity.current: Read complete after 0s [id=123456789012]

Changes to Outputs:
  + account_id = "123456789012"
  + region     = "sa-east-1"

You can apply this plan to save these new output values to the Terraform
state, without changing any real infrastructure.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

account_id = "123456789012"
region = "sa-east-1"
```

`Reading...` e `Read complete` são as duas linhas que uma data source imprime, e **`0 added, 0
changed, 0 destroyed`** é a prova de que nada na conta se mexeu. O `id` entre colchetes é o que o
provider escolheu para identificar a resposta: aqui o número da conta, ali o nome da região. No
laboratório a conta é o valor de exemplo do moto, `123456789012`; numa conta real, é a sua.

As respostas ficam registradas no state, ao lado dos recursos, com endereços próprios:

```
ana@laptop:~/shop/app$ terraform state list
data.aws_caller_identity.current
data.aws_region.current
```

**Esse registro é um cache, não uma declaração de posse.** A cada plan o Terraform lê as data
sources de novo, porque aquilo que é consultado pertence a outra pessoa e pode ter mudado desde a
última vez. Esse é o contrato inteiro desta aula: um recurso é algo pelo qual o Terraform responde;
uma data source é algo para o qual ele só olha, toda vez, e em que acredita.

Por que uma configuração ia querer saber o número da própria conta? Porque dele se monta um nome que
precisa ser único, e uma policy que dá acesso a "esta conta" precisa dizer qual. As duas coisas
aparecem mais adiante nesta aula, e nenhuma precisa ser digitada: uma configuração que lê a conta e a
região funciona sem mudança na próxima conta e na próxima região.

A documentação do provider lista as data sources ao lado dos recursos, e a maioria dos tipos de
recurso tem uma correspondente: `aws_vpc` e `data "aws_vpc"`, `aws_subnet` e `data "aws_subnet"`.
Algumas só existem como data source, como essas duas, porque não há nada a criar: uma identidade e
uma região são fatos sobre a conexão. Vale conhecer mais uma pelo nome desde já:
**`terraform_remote_state`** lê os outputs do state de outra configuração do Terraform, e a aula 8 a
usa para ligar duas configurações que foram separadas de propósito.
