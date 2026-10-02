---
title: tfsec, um scanner que parou de aprender, e o Terrascan
version: 1
---

O tfsec é um binário em Go, feito só para o Terraform e o seu HCL. Pergunte a versão e ele responde
primeiro com um aviso:

```
ana@laptop:~/shop$ tfsec --version

======================================================
tfsec is joining the Trivy family

tfsec will continue to remain available 
for the time being, although our engineering 
attention will be directed at Trivy going forward.

You can read more here: 
https://github.com/aquasecurity/tfsec/discussions/1994
======================================================
v1.28.14
```

**O tfsec virou parte do Trivy.** Os checks dele foram levados para os do Trivy, por isso os achados
das duas ferramentas têm títulos tão parecidos, e os autores agora investem o trabalho no Trivy. O
binário ainda roda e imprime esse aviso em toda execução (na saída de erro, então um pipe não o
engole). Aqui está o relatório dele sobre a loja, filtrado para uma linha por resultado e o lugar para
onde ela aponta:

```
ana@laptop:~/shop$ tfsec --no-colour . | grep -E "^(Result|  [a-z]+\.tf)"

======================================================
tfsec is joining the Trivy family

tfsec will continue to remain available 
for the time being, although our engineering 
attention will be directed at Trivy going forward.

You can read more here: 
https://github.com/aquasecurity/tfsec/discussions/1994
======================================================
Result #1 HIGH No public access block so not blocking public acls 
  main.tf:42-44
Result #2 HIGH No public access block so not blocking public policies 
  main.tf:42-44
Result #3 HIGH Bucket does not have encryption enabled 
  main.tf:42-44
Result #4 HIGH No public access block so not ignoring public acls 
  main.tf:42-44
Result #5 HIGH No public access block so not restricting public buckets 
  main.tf:42-44
Result #6 HIGH Bucket does not encrypt data with a customer managed key. 
  main.tf:42-44
Result #7 HIGH EBS volume is not encrypted. 
  main.tf:46-50
Result #8 MEDIUM VPC Flow Logs is not enabled for VPC  
  main.tf:14-17
Result #9 MEDIUM Bucket does not have logging enabled 
  main.tf:42-44
Result #10 MEDIUM Bucket does not have versioning enabled 
  main.tf:42-44
Result #11 LOW Bucket does not have a corresponding public access block. 
  main.tf:42-44
Result #12 LOW EBS volume does not use a customer-managed KMS key. 
  main.tf:46-50
```

Doze resultados, três severidades, e os mesmos temas dos outros dois scanners. Mas leia os lugares:
todos estão no `main.tf`. **A regra de SSH no `ssh.tf`, o achado que os outros dois puseram em
primeiro plano, não está lá.**

## Um recurso que ninguém ensinou a ele

O tfsec não decidiu que a porta 22 estava bem. O check de entrada pública foi escrito para as formas
que uma regra de security group podia ter quando o check foi escrito, e
`aws_vpc_security_group_ingress_rule` não é uma delas. Escreva a mesma regra na forma antiga, como um
bloco `ingress` dentro do grupo, e o tfsec a encontra na hora:

```hcl
resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"

  ingress {
    description = "SSH for maintenance"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

```
ana@laptop:~/legacy$ tfsec --no-colour . | sed -n "/^Result/,/^  Resolution/p"

======================================================
tfsec is joining the Trivy family

tfsec will continue to remain available 
for the time being, although our engineering 
attention will be directed at Trivy going forward.

You can read more here: 
https://github.com/aquasecurity/tfsec/discussions/1994
======================================================
Result #1 CRITICAL Security group rule allows ingress from public internet. 
────────────────────────────────────────────────────────────────────────────────
  main.tf:10
────────────────────────────────────────────────────────────────────────────────
    1    resource "aws_security_group" "web" {
    .  
   10  [     cidr_blocks = ["0.0.0.0/0"]
   ..  
   12    }
────────────────────────────────────────────────────────────────────────────────
          ID aws-ec2-no-public-ingress-sgr
      Impact Your port exposed to the internet
  Resolution Set a more restrictive cidr range
```

Então os mesmos nove caracteres, `0.0.0.0/0` na porta 22, são `CRITICAL` numa grafia e invisíveis na
outra. Nada imprimiu um aviso. Um scanner relata o que as regras dele casam, e um tipo de recurso que
nenhuma regra menciona produz silêncio, que tem a mesma cara de um resultado aprovado.

**Esse é o custo de uma ferramenta que ninguém mais desenvolve**, e ele cresce. O provider da AWS
continua ganhando recursos e argumentos, e um catálogo congelado cobre uma parte menor da configuração
a cada um. É também um motivo para manter no repositório um exemplo sabidamente ruim, como o
`legacy/main.tf`, e varrê-lo no pipeline: se uma atualização do scanner ou uma reescrita do seu código
fizer o achado sumir, você descobre pelo build, e não por um incidente. Se você tem tfsec num pipeline
hoje, o passo que o próprio aviso sugere é ir para o `trivy config`, que leva os mesmos checks adiante
e conhece o recurso mais novo.

## Terrascan

O Terrascan, da Tenable, é uma quarta ferramenta do mesmo tipo, com as políticas escritas em Rego como
as do Trivy. Ele não está instalado neste laboratório:

```
ana@laptop:~/shop$ which terrascan; echo "exit $?"
exit 1
```

e nada nesta aula diz como é a saída dele, porque nada aqui o executou. O que você já sabe vale para
ele: lê arquivos, compara recursos com regras, e o que relata depende de quais tipos de recurso essas
regras conhecem.

## Qual usar

Os três que rodaram aqui concordam sobre quase toda a loja e discordam nas bordas. Uma tabela do que
cada um relatou, tirada das capturas acima:

| | Checkov | Trivy | tfsec |
|---|---|---|---|
| achados sobre a loja | 13 | 12 | 12 |
| a regra de SSH no `ssh.tf` | encontrada | encontrada | não encontrada |
| severidade offline | nenhuma | em todo achado | em todo achado |
| regras próprias | Python ou YAML | Rego | (não mostrado aqui) |

O Checkov e o Trivy são mantidos, e rodar os dois custa pouco: nenhum precisa de credenciais, e os dois
relataram todos os achados num laboratório sem rede. O tfsec está nesta aula porque você vai
encontrá-lo em pipelines que já existem, e agora sabe o que conferir antes de confiar no silêncio dele.
