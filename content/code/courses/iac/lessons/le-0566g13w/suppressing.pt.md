---
title: Suprimir um achado, com um motivo e uma data
version: 2
---

Todo scanner deixa você silenciar um achado, e a ideia errada sobre isso é que silenciar é o jeito de
deixar o build verde. **Uma supressão é uma decisão**, escrita ao lado do recurso a que se refere, e
vale exatamente o motivo escrito junto com ela. Treze achados é um primeiro relatório normal. Alguns
são problemas reais, alguns são escolhas que a loja fez de propósito, e alguns são o scanner errando
sobre esta configuração. O segundo e o terceiro tipos são para o que servem as supressões. A regra de
SSH é do primeiro tipo, e um comentário não deixaria a porta 22 nem um pouco menos aberta.

A Ana percorre a lista do Checkov e escreve duas supressões com motivo, um ignore do Trivy, e um skip
do Checkov sem motivo nenhum, de propósito, para mostrar o que o relatório faz com ele. Aqui estão como
o revisor os vê, e como você os faz no seu próprio `main.tf`:

```
ana@laptop:~/shop$ git diff
diff --git a/main.tf b/main.tf
index de74f0b..ec8b8f0 100644
--- a/main.tf
+++ b/main.tf
@@ -24,6 +24,7 @@ resource "aws_subnet" "a" {
 }
 
 resource "aws_security_group" "web" {
+  #checkov:skip=CKV2_AWS_5:attached by the instances in the app configuration, not here
   name        = "web"
   description = "web servers"
   vpc_id      = aws_vpc.shop.id
@@ -39,7 +40,11 @@ resource "aws_vpc_security_group_ingress_rule" "https" {
   cidr_ipv4         = "0.0.0.0/0"
 }
 
+# SSE-S3 is enough for product photos; revisit when the shop has a KMS key
+#trivy:ignore:AWS-0132:exp:2027-03-31
 resource "aws_s3_bucket" "assets" {
+  #checkov:skip=CKV_AWS_144:the photos are rebuilt from the repository, a second region is not worth paying for
+  #checkov:skip=CKV2_AWS_62
   bucket = "shop-assets-123456789012"
 }
```

Cada comentário usa a sintaxe do próprio scanner, e cada um fica num lugar preciso:

- `#checkov:skip=ID:motivo` vai **dentro** do bloco do recurso. O texto depois do segundo dois-pontos é
  o motivo, e o Checkov o guarda.
- `#trivy:ignore:ID` vai na linha **acima** do bloco. A sintaxe do Trivy não tem campo de motivo, então
  o motivo é um comentário comum na linha anterior. `:exp:2027-03-31` dá a ele uma data de validade.
- O tfsec tem `#tfsec:ignore:ID`, na mesma posição do Trivy. Ele não lê nenhum dos outros dois, e por
  isso a contagem dele não se mexe nesta aula.

Os dois motivos do Checkov são afirmações de tipos diferentes. O `CKV2_AWS_5` quer o security group
ligado a alguma coisa, e nesta configuração ele não está, porque as instâncias que o usam moram na
configuração da aplicação (a aula 8 dividiu o state desse jeito). O check está certo sobre o arquivo e
errado sobre o sistema, que é o que um falso positivo é. O `CKV_AWS_144` pede uma cópia do bucket em
outra região, e a loja decidiu que as fotos não valem isso: elas são reconstruídas a partir do
repositório. Não há nada de errado aí; um custo foi pesado.

## O que o relatório diz depois

```
ana@laptop:~/shop$ checkov -d . --skip-download --compact --check CKV_AWS_144,CKV2_AWS_5,CKV2_AWS_62

       _               _
   ___| |__   ___  ___| | _______   __
  / __| '_ \ / _ \/ __| |/ / _ \ \ / /
 | (__| | | |  __/ (__|   < (_) \ V /
  \___|_| |_|\___|\___|_|\_\___/ \_/

By Prisma Cloud | version: 3.3.22 

terraform scan results:

Passed checks: 0, Failed checks: 0, Skipped checks: 3

Check: CKV2_AWS_62: "Ensure S3 buckets should have event notifications enabled"
	SKIPPED for resource: aws_s3_bucket.assets
	Suppress comment: No comment provided
	File: /main.tf:45-49
Check: CKV2_AWS_5: "Ensure that Security Groups are attached to another resource"
	SKIPPED for resource: aws_security_group.web
	Suppress comment: attached by the instances in the app configuration, not here
	File: /main.tf:26-32
Check: CKV_AWS_144: "Ensure that S3 bucket has cross-region replication enabled"
	SKIPPED for resource: aws_s3_bucket.assets
	Suppress comment: the photos are rebuilt from the repository, a second region is not worth paying for
	File: /main.tf:45-49
```

Três `SKIPPED`, e o motivo viaja com cada um para dentro do relatório. **O terceiro diz `No comment
provided`**, e é assim que um skip sem motivo aparece um ano depois: idêntico a um skip que alguém
acrescentou às seis da tarde para o build passar. Ninguém consegue discutir com ele, então ninguém o
remove. Um revisor pode contestar *as fotos são reconstruídas a partir do repositório* se isso deixar
de ser verdade. O Checkov não recusa um skip sem motivo, então o hábito tem de vir da revisão.

O ignore do Trivy tirou um achado do `main.tf`:

```
ana@laptop:~/shop$ trivy config --skip-check-update -q . | grep -E "^(AWS-0132|Failures)"
Failures: 10 (UNKNOWN: 0, LOW: 3, MEDIUM: 2, HIGH: 5, CRITICAL: 0)
Failures: 1 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 1, CRITICAL: 0)
```

## Uma validade transforma "depois" numa data

*Revisitar quando a loja tiver uma chave KMS* é o tipo de promessa que ninguém cumpre sem ser lembrado, e a
validade é o lembrete. Para ver funcionar, a Ana põe a data no passado por uma execução:

```
ana@laptop:~/shop$ sed -i "s/exp:2027-03-31/exp:2026-03-31/" main.tf
ana@laptop:~/shop$ trivy config --skip-check-update -q . | grep -E "^(AWS-0132|Failures)"
Failures: 11 (UNKNOWN: 0, LOW: 3, MEDIUM: 2, HIGH: 6, CRITICAL: 0)
AWS-0132 (HIGH): Bucket does not encrypt data with a customer managed key.
Failures: 1 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 1, CRITICAL: 0)
```

O achado voltou, e a contagem com ele. Quando a data real passar, o build volta a falhar por esse
achado e alguém tem de decidir de novo, com o que souber então. O skip em linha do Checkov não tem
campo de validade; o mesmo efeito ali vem de um ticket, ou do baseline da seção 08.

A Ana devolve a data com o mesmo `sed`, as duas datas trocadas,
`sed -i "s/exp:2026-03-31/exp:2027-03-31/" main.tf`, e faz o commit das três supressões como
*suppress three findings*. Se você está lendo isto depois de 31 de março de 2027, essa data já passou
para você também e o achado aparece nas duas execuções; uma data mais adiante mostra a diferença.

## Onde não suprimir

Os scanners também aceitam skips na linha de comando (`checkov --skip-check CKV2_AWS_5`) e nos seus
arquivos de configuração. Esses silenciam uma regra **para todo recurso**, inclusive o que alguém
acrescentar no mês que vem, e ficam longe do código que afetam, então quem revisa o bucket nunca os vê.
Um comentário em linha cobre um recurso e chega no mesmo diff da mudança que ele justifica. Guarde a
forma global para regras que a organização inteira decidiu não rodar.
