---
title: O que quebra o build, e o que só avisa
version: 1
---

**Uma porta que bloqueia em todo achado acaba desligada, e uma porta que não bloqueia em nada é um
relatório que ninguém lê. A linha útil passa entre os achados que expõem algo ou concedem tudo, que
bloqueiam, e os achados de higiene, que são impressos e deixam a mudança passar.** A lista no topo do
`gate.sh` é onde a clínica traçou essa linha, e ela é curta de propósito.

## Os sete que bloqueiam

| verificação | o que pega | por que bloqueia |
|---|---|---|
| `CKV_AWS_70` | uma política de bucket permitindo uma ação a qualquer principal | o erro da aula 1: dados legíveis por qualquer um |
| `CKV_AWS_20`, `CKV_AWS_57` | uma ACL de bucket concedendo leitura ou escrita públicas | a mesma exposição pelo caminho mais antigo que a aula 9 descreve |
| `CKV2_AWS_6` | um bucket sem bloqueio de acesso público | a proteção que recusaria os dois acima |
| `CKV_AWS_24` | um security group aberto à internet na porta 22 | um prompt de login oferecido à internet inteira, o exemplo da aula 3 |
| `CKV_AWS_62` | uma política do IAM permitindo toda ação em todo recurso | direitos de administrador distribuídos num pull request |
| `CKV_SECRET_2` | uma chave de acesso da AWS no código | o vazamento da aula 12, pego antes de o push ser aceito |

Cada um é um achado em que o dano acontece no momento em que a mudança é aplicada, e em que nenhuma
leitura das circunstâncias o torna aceitável para a clínica. Esse é o teste para pôr uma verificação
na lista: **você pararia uma entrega por causa dela às cinco da tarde de uma sexta?** Se a resposta
honesta é "depende", ela fica entre os avisos, onde quem revisa pondera.

## Uma mudança que avisa

O caio tenta de novo. Desta vez o tablet ganha um bucket só dele, privado, com bloqueio de acesso
público, e mais nada. Salve-o como `tablet.tf`:

```hcl
# A bucket of its own for the file the reception's tablet reads.
resource "aws_s3_bucket" "tablet" {
  bucket = "clinic-tablet"
}

resource "aws_s3_bucket_public_access_block" "tablet" {
  bucket                  = aws_s3_bucket.tablet.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}
```

```
ana@laptop:~/aws/clinic$ bash gate.sh; echo "exit status $?"
== format
== validate
== scan
terraform scan results:

Passed checks: 20, Failed checks: 6, Skipped checks: 5

Check: CKV2_AWS_62: "Ensure S3 buckets should have event notifications enabled"
	FAILED for resource: aws_s3_bucket.tablet
	File: /tablet.tf:2-4
Check: CKV_AWS_18: "Ensure the S3 bucket has access logging enabled"
	FAILED for resource: aws_s3_bucket.tablet
	File: /tablet.tf:2-4
Check: CKV2_AWS_61: "Ensure that an S3 bucket has a lifecycle configuration"
	FAILED for resource: aws_s3_bucket.tablet
	File: /tablet.tf:2-4
Check: CKV_AWS_144: "Ensure that S3 bucket has cross-region replication enabled"
	FAILED for resource: aws_s3_bucket.tablet
	File: /tablet.tf:2-4
Check: CKV_AWS_145: "Ensure that S3 buckets are encrypted with KMS by default"
	FAILED for resource: aws_s3_bucket.tablet
	File: /tablet.tf:2-4
Check: CKV_AWS_21: "Ensure all data stored in the S3 bucket have versioning enabled"
	FAILED for resource: aws_s3_bucket.tablet
	File: /tablet.tf:2-4

== plan
Plan: 2 to add, 0 to change, 0 to destroy.
plan.bin waits for a reviewer
exit status 0
```

Seis achados, todos impressos, nenhum na lista: sem log, sem notificação de eventos, sem ciclo de vida,
sem replicação, sem versionamento, sem chave KMS. A porta segue para o plano, e **os seis avisos vão
para quem revisa** junto com ele. Alguns merecem resposta antes da aprovação: um bucket que o tablet lê
todo dia provavelmente quer uma regra de ciclo de vida, para o arquivo de ontem não ficar para sempre.
Outros ganham uma exceção com motivo, como o bucket da aula 12. De um jeito ou de outro, uma pessoa
decide, com o achado na frente.

## Exceções, e o prazo delas

Cedo ou tarde um achado que bloqueia tem um motivo. A integração de um fornecedor precisa, por um mês,
de um bucket que ela consiga ler sem assinar. A resposta errada é apagar `CKV_AWS_70` da lista, o que
desliga a verificação para toda mudança futura também. A certa é uma exceção **para aquele recurso, com
motivo, responsável e data de fim**:

```hcl
resource "aws_s3_bucket_policy" "vendor_import" {
  #checkov:skip=CKV_AWS_70:vendor import, approved by ana until 2026-11-30, ticket SEC-114
  bucket = aws_s3_bucket.vendor.id
  policy = data.aws_iam_policy_document.vendor_import.json
}
```

O Checkov lê o comentário como uma exceção, então a porta passa. O Checkov não lê a data. **Uma exceção
com data de fim só vale o que vale aquilo que olha a data**: um lembrete na agenda do responsável, uma
linha na lista de exceções da equipe que é lida todo mês, ou uma verificação própria. O bloco acima não
foi executado: ele cita um bucket e um documento de política que este laboratório não tem.

## Quem move a linha

A lista do `gate.sh` é código, então muda do jeito que código muda: num pull request, revisado por
alguém que não é quem pede. Uma porta cuja lista de bloqueio pode ser editada no mesmo pull request que
ela está julgando não guarda nada. Os pipelines protegem o arquivo com uma regra de que mudanças nele
precisam da aprovação do responsável por segurança. O GitHub chama essa regra de code owner, e o GitLab
tem a mesma ideia com o mesmo nome.

::: track devsecops
A aula 7 do curso `secure-pipeline` traçou essa linha para achados da aplicação, com severidades e
orçamentos. A diferença aqui é que um achado de infraestrutura é uma configuração, então o dano chega
com o apply e não com um esforço posterior de um atacante, e a lista de bloqueio é mais curta e mais
estrita por isso.
:::

::: track *
A mesma pergunta, quando quebrar o build e quando avisar, aparece para achados no código da aplicação,
onde notas de severidade e orçamentos combinados costumam decidir. Um achado de infraestrutura é
diferente num ponto: é uma configuração, então o dano chega com o apply, e a lista de bloqueio pode ser
curta e estrita.
:::

Remova o `tablet.tf` antes da próxima seção, ou guarde-o para aplicar depois; nada mais nesta aula
depende dele.
