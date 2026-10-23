---
title: Um scanner também lê
version: 1
---

**Um scanner como o Checkov lê código de infraestrutura e confere cada recurso contra uma biblioteca
de regras, cada uma com um id, antes de qualquer coisa ser planejada ou aplicada.** Ele não precisa de
conta nem de credencial, então roda num notebook, num pull request, em qualquer lugar. O que ele não
consegue é decidir quais das suas descobertas importam para você, e a maior parte desta seção é sobre
isso.

Rode-o no diretório, do jeito que a seção anterior o deixou. `--framework terraform` o limita aos
arquivos `.tf`, `--compact` omite o código que ele citaria embaixo de cada achado, `--quiet` lista só
as falhas, e `--skip-download` o impede de buscar orientações extras nos servidores do fornecedor,
então ele funciona offline. O `echo` depois dele imprime o código de saída que o Checkov deixou:

```
ana@laptop:~/aws/clinic$ checkov -d . --framework terraform --compact --quiet --skip-download; echo "exit status $?"
terraform scan results:

Passed checks: 6, Failed checks: 8, Skipped checks: 0

Check: CKV_AWS_70: "Ensure S3 bucket does not allow an action with any Principal"
	FAILED for resource: aws_s3_bucket_policy.tablet
	File: /main.tf:21-32
Check: CKV2_AWS_6: "Ensure that S3 bucket has a Public Access block"
	FAILED for resource: aws_s3_bucket.exports
	File: /main.tf:16-18
Check: CKV2_AWS_62: "Ensure S3 buckets should have event notifications enabled"
	FAILED for resource: aws_s3_bucket.exports
	File: /main.tf:16-18
Check: CKV_AWS_18: "Ensure the S3 bucket has access logging enabled"
	FAILED for resource: aws_s3_bucket.exports
	File: /main.tf:16-18
Check: CKV_AWS_144: "Ensure that S3 bucket has cross-region replication enabled"
	FAILED for resource: aws_s3_bucket.exports
	File: /main.tf:16-18
Check: CKV2_AWS_61: "Ensure that an S3 bucket has a lifecycle configuration"
	FAILED for resource: aws_s3_bucket.exports
	File: /main.tf:16-18
Check: CKV_AWS_21: "Ensure all data stored in the S3 bucket have versioning enabled"
	FAILED for resource: aws_s3_bucket.exports
	File: /main.tf:16-18
Check: CKV_AWS_145: "Ensure that S3 buckets are encrypted with KMS by default"
	FAILED for resource: aws_s3_bucket.exports
	File: /main.tf:16-18

exit status 1
```

Oito verificações falharam e o código de saída é `1`, e as oito não são do mesmo tipo:

| verificação | o que diz | para este bucket |
|---|---|---|
| `CKV_AWS_70` | uma política permite uma ação a qualquer principal | **o defeito**: a política do tablet |
| `CKV2_AWS_6` | o bucket não tem bloqueio de acesso público | **a proteção que falta**, que teria recusado a política |
| `CKV_AWS_21` | o versionamento está desligado | vale ter: uma exportação sobrescrita ou apagada volta |
| `CKV_AWS_144`, `CKV2_AWS_62`, `CKV2_AWS_61`, `CKV_AWS_18`, `CKV_AWS_145` | sem replicação, notificação de eventos, ciclo de vida, log de acesso ou chave KMS | decisões, cada uma com uma resposta que depende do bucket |

**As duas do topo são o achado; as cinco de baixo são perguntas.** Um scanner aplica as mesmas regras a
um bucket de exportações de pacientes e a um bucket de imagens públicas, e não tem como saber qual
está olhando. Corrigir as oito porque a ferramenta mandou é como uma equipe acaba com replicação de que
ninguém precisava. Ignorar as oito porque cinco eram ruído é como a política vai para produção.

## O arquivo corrigido

O tablet não precisa de um bucket público. Precisa de um arquivo por dia, e a aula 10 mostra como
entregar a um dispositivo um único objeto por tempo limitado sem tornar nada público. Então a política
sai, entram um bloqueio de acesso público e o versionamento, e cada uma das cinco perguntas é
respondida **no arquivo, com um motivo**, como um comentário de exceção que o Checkov lê. Substitua o
`main.tf` por este:

```hcl
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "6.67.0" }
  }
}

provider "aws" {
  region            = "sa-east-1"
  s3_use_path_style = true
}

locals {
  bucket = "clinic-exports"
}

resource "aws_s3_bucket" "exports" {
  #checkov:skip=CKV_AWS_144:a daily export the application can rebuild needs no second region
  #checkov:skip=CKV2_AWS_62:nothing consumes events from this bucket
  #checkov:skip=CKV2_AWS_61:the application deletes each export after 30 days
  #checkov:skip=CKV_AWS_18:access logging is decided for every bucket at once, in lesson 15
  #checkov:skip=CKV_AWS_145:the default SSE-S3 encryption stays until lesson 11 decides on a key
  bucket = local.bucket
}

resource "aws_s3_bucket_public_access_block" "exports" {
  bucket                  = aws_s3_bucket.exports.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "exports" {
  bucket = aws_s3_bucket.exports.id
  versioning_configuration {
    status = "Enabled"
  }
}
```

```
ana@laptop:~/aws/clinic$ checkov -d . --framework terraform --compact --quiet --skip-download; echo "exit status $?"
terraform scan results:

Passed checks: 11, Failed checks: 0, Skipped checks: 5


exit status 0
```

Nenhuma falha, onze aprovações, cinco exceções e código de saída `0`. **Esse código de saída é o que um
pipeline lê**, e a aula 14 monta uma porta de qualidade sobre ele. As exceções não ficam escondidas:
são contadas em toda execução, e cada uma carrega uma frase de que alguém pode discordar numa revisão.
Uma exceção sem motivo é um achado desligado; uma exceção com motivo é uma decisão registrada.

O plano concorda com o scanner. Faça de novo a pergunta da seção anterior:

```
ana@laptop:~/aws/clinic$ terraform plan -out=plan.bin -no-color > /dev/null
ana@laptop:~/aws/clinic$ terraform show -json plan.bin | jq -r '[.resource_changes[].address] | .[]'
aws_s3_bucket.exports
aws_s3_bucket_public_access_block.exports
aws_s3_bucket_versioning.exports
```

Três recursos, e nenhuma política entre eles.

## O que um scanner não vê

O Checkov lê os arquivos, então sabe o que o código pede e nada sobre a conta que o código vai
encontrar. Um bucket tornado público à mão no console, uma política anexada por outra configuração,
uma configuração mudada depois do último apply: nada disso está nestes arquivos. Ler a conta como ela
é, e não como o código a descreve, é o assunto da aula 16. As duas coisas se complementam, e nenhuma
substitui a outra.
