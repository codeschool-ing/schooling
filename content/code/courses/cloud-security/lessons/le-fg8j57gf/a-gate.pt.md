---
title: Uma porta é um código de saída
version: 1
---

**Uma porta de qualidade é uma verificação cujo código de saída decide se a mudança segue. Zero a deixa passar; qualquer outro valor a para.** É tudo o que um pipeline entende, e é por isso que toda
ferramenta da aula 12 rodou com um `echo` do código de saída depois dela. Esta seção escreve as portas
num script só, roda-o na configuração da clínica e depois o observa parar uma mudança.

Trabalhe em `~/aws/clinic`, o diretório que a aula 12 deixou, com o `main.tf` corrigido da seção sobre
varredura daquela aula: o bucket de exportação, o bloqueio de acesso público, o versionamento e cinco
exceções com motivo. O Terraform e o Checkov são os que a aula 12 instalou. Inicie o moto vazio.

## O script

Salve isto como `gate.sh` nesse diretório:

```schooling-example
{"language": "bash", "file": "gate.sh", "parts": [
 {"code": "#!/usr/bin/env bash\n# gate.sh: the checks a change to the clinic's infrastructure passes before anybody applies it.\n# Run it in the Terraform directory. It stops at the first gate that fails.\nset -uo pipefail\n\n", "note": "Um script de shell simples, então o mesmo arquivo roda num notebook e em qualquer pipeline. Cada porta passa ou encerra o script com um código de saída diferente de zero, e esse código é todo o contrato com quem o executa."},
 {"code": "# The findings that stop a change. Every other finding is printed and lets it through.\nBLOCKING=CKV_AWS_70,CKV_AWS_20,CKV_AWS_57,CKV2_AWS_6,CKV_AWS_24,CKV_AWS_62,CKV_SECRET_2\n\n", "note": "A lista dos achados que bloqueiam, escrita no topo, onde quem revisa o script a vê. A próxima seção diz por que estes sete e não o catálogo inteiro do scanner."},
 {"code": "gate() { printf '== %s\\n' \"$1\"; }\n\n", "note": "Um título antes de cada porta, para que um log lido na manhã seguinte diga qual porta parou a mudança."},
 {"code": "gate format\nterraform fmt -check || exit 1\n\ngate validate\nterraform validate -no-color > /dev/null || exit 1\n\n", "note": "As portas mais baratas primeiro. `fmt -check` não muda nada e falha se algum arquivo não estiver no formato padrão do Terraform; `validate` falha se a configuração não fizer sentido nenhum para o Terraform."},
 {"code": "gate scan\ncheckov -d . --compact --quiet --skip-download --hard-fail-on \"$BLOCKING\" || exit 1\n\n", "note": "A varredura da aula 12, agora sobre todos os frameworks que o Checkov conhece, segredos incluídos. `--hard-fail-on` faz só as verificações listadas decidirem o código de saída; toda outra falha continua impressa."},
 {"code": "gate plan\nterraform plan -input=false -no-color -detailed-exitcode -out=plan.bin > plan.txt\ncase $? in\n  0) echo \"no changes: nothing to approve\" ;;\n  2) grep '^Plan:' plan.txt; echo \"plan.bin waits for a reviewer\" ;;\n  *) cat plan.txt; exit 1 ;;\nesac\n", "note": "`-detailed-exitcode` dá ao plano três respostas em vez de duas: 0 para nenhuma mudança, 2 para mudanças, 1 para erro. O plano é salvo, porque o apply precisa usar o plano que quem revisou leu."}
]}
```

Um pipeline de verdade roda os mesmos passos, um job cada, e mostra cada porta como uma linha que fica
verde ou vermelha. Escrevê-lo primeiro como um script tem uma utilidade além deste laboratório: **a
porta que a pessoa desenvolvedora consegue rodar no próprio notebook é a porta que ela roda antes do
push**, então o pipeline raramente encontra algo novo.

## Uma mudança que passa

```
ana@laptop:~/aws/clinic$ bash gate.sh; echo "exit status $?"
== format
== validate
== scan
terraform scan results:

Passed checks: 11, Failed checks: 0, Skipped checks: 5


== plan
Plan: 3 to add, 0 to change, 0 to destroy.
plan.bin waits for a reviewer
exit status 0
```

Quatro títulos, nenhuma falha e as cinco exceções da aula 12, e um plano de três recursos esperando
quem revise. Quando a revisora aprova, o apply usa **o plano salvo**, então o que é criado é
exatamente o que foi lido:

```
ana@laptop:~/aws/clinic$ terraform apply -no-color plan.bin | tail -1
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
ana@laptop:~/aws/clinic$ bash gate.sh; echo "exit status $?"
== format
== validate
== scan
terraform scan results:

Passed checks: 11, Failed checks: 0, Skipped checks: 5


== plan
no changes: nothing to approve
exit status 0
```

Se o apply parar com `lookup 123456789012.localhost` e `no such host`, sua máquina não resolve sozinha
nomes debaixo de `localhost`, o que o Ubuntu faz e o WSL pode não fazer. O provider alcança o moto por
esse nome quando lê as tags de um bucket, e uma linha no `/etc/hosts` resolve:
`echo '127.0.0.1 123456789012.localhost' | sudo tee -a /etc/hosts`.

Rodado de novo sem nada mudado, o plano responde `0`, e a porta diz que não há nada a aprovar. **Essa
segunda execução é também a verificação de desvio mais barata que existe**: se alguém tivesse mudado o
bucket no console depois do apply, o plano mostraria a mudança necessária para colocá-lo de volta.

## Uma mudança que para

O pull request do caio traz o tablet de volta do jeito rápido, num arquivo próprio. Salve-o como
`tablet.tf`, ao lado do `main.tf`:

```hcl
# The reception's tablet reads the day's export.
resource "aws_s3_bucket_policy" "tablet" {
  bucket = aws_s3_bucket.exports.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "arn:aws:s3:::${local.bucket}/*"
    }]
  })
}
```

```
ana@laptop:~/aws/clinic$ bash gate.sh; echo "exit status $?"
== format
== validate
== scan
terraform scan results:

Passed checks: 12, Failed checks: 1, Skipped checks: 5

Check: CKV_AWS_70: "Ensure S3 bucket does not allow an action with any Principal"
	FAILED for resource: aws_s3_bucket_policy.tablet
	File: /tablet.tf:2-13

exit status 1
```

A varredura nomeia a política, o script para, e **o plano nunca roda**, então ninguém é chamado a
revisar uma mudança que uma máquina já recusou. O pull request mostra uma linha vermelha e o motivo no
log.

Numa conta real o apply também teria falhado, mais tarde e de um jeito mais confuso: o bloqueio de
acesso público do bucket, com `block_public_policy` ligado, faz a AWS recusar uma política pública. O
moto não aplica esse bloqueio, como mostra a aula 9, então o laboratório não consegue mostrar essa
recusa, e a afirmação vem da documentação da AWS. Uma porta que a pega em segundos, com o nome da
regra, é um lugar melhor para descobri-la do que um erro no meio de um apply.

Remova o arquivo antes da próxima seção:

```sh
rm tablet.tf
```
