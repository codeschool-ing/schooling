---
title: Varrer o plan, onde estão os valores
version: 2
---

Quem revisou o pull request do SSH pediu uma mudança: não escrever a faixa no arquivo, e sim
transformá-la numa variável, para cada ambiente dar a sua. É um pedido razoável, e tem um efeito
colateral que ninguém pediu:

```
ana@laptop:~/shop$ git diff
diff --git a/ssh.tf b/ssh.tf
index b975fc3..bfe7bb9 100644
--- a/ssh.tf
+++ b/ssh.tf
@@ -1,8 +1,13 @@
+variable "admin_cidr" {
+  type        = string
+  description = "The range SSH is allowed from."
+}
+
 resource "aws_vpc_security_group_ingress_rule" "ssh" {
   security_group_id = aws_security_group.web.id
   description       = "SSH for maintenance"
   ip_protocol       = "tcp"
   from_port         = 22
   to_port           = 22
-  cidr_ipv4         = "0.0.0.0/0"
+  cidr_ipv4         = var.admin_cidr
 }
```

A Ana faz essa mudança no `ssh.tf`, faz o commit como *admin_cidr as a variable* e varre de novo:

```
ana@laptop:~/shop$ checkov -d . --skip-download --compact --check CKV_AWS_24

       _               _
   ___| |__   ___  ___| | _______   __
  / __| '_ \ / _ \/ __| |/ / _ \ \ / /
 | (__| | | |  __/ (__|   < (_) \ V /
  \___|_| |_|\___|\___|_|\_\___/ \_/

By Prisma Cloud | version: 3.3.22 

terraform scan results:

Passed checks: 3, Failed checks: 0, Skipped checks: 0

Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	PASSED for resource: aws_security_group.web
	File: /main.tf:26-32
Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	PASSED for resource: aws_vpc_security_group_ingress_rule.https
	File: /main.tf:34-41
Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	PASSED for resource: aws_vpc_security_group_ingress_rule.ssh
	File: /ssh.tf:6-13

ana@laptop:~/shop$ trivy config --skip-check-update -q . | grep -c AWS-0107
0
```

**O Checkov agora aprova a regra de SSH e o Trivy não encontra nada.** Nenhum dos dois foi enganado de
um jeito que pudesse evitar. `cidr_ipv4` agora é `var.admin_cidr`, a variável não tem default, e nada
no diretório diz qual vai ser o valor. Um check que não enxerga um valor não tem por que falhar, e as
duas ferramentas relatam isso como aprovado. *Passed* numa varredura da configuração quer dizer "nada
de errado no que eu consegui ler", o que é menos do que parece.

O valor chega quando alguém roda o plan, de um arquivo passado na linha de comando, o
`maintenance.tfvars`:

```hcl
admin_cidr = "0.0.0.0/0"
```

## O plan tem os valores

Um plan é a configuração com todos os valores preenchidos: variáveis vindas de arquivos, de `-var` e de
`TF_VAR_` no ambiente, os resultados de funções, os outputs de módulos e o que os data sources leram
durante o plan. A aula 9 transforma um plan salvo em JSON com `terraform show -json`, e o Checkov lê
esse JSON como um framework próprio:

```
ana@laptop:~/shop$ terraform plan -no-color -var-file=maintenance.tfvars -out tfplan | grep -E "^  # |Plan:"
  # aws_vpc_security_group_ingress_rule.ssh will be created
Plan: 1 to add, 0 to change, 0 to destroy.
ana@laptop:~/shop$ terraform show -json tfplan > tfplan.json
```

```
ana@laptop:~/shop$ checkov -f tfplan.json --skip-download --quiet --check CKV_AWS_24 --repo-root-for-plan-enrichment .
terraform_plan scan results:

Passed checks: 2, Failed checks: 1, Skipped checks: 0

Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	FAILED for resource: aws_vpc_security_group_ingress_rule.ssh
	File: ssh.tf:6-13

		6  | resource "aws_vpc_security_group_ingress_rule" "ssh" {
		7  |   security_group_id = aws_security_group.web.id
		8  |   description       = "SSH for maintenance"
		9  |   ip_protocol       = "tcp"
		10 |   from_port         = 22
		11 |   to_port           = 22
		12 |   cidr_ipv4         = var.admin_cidr
		13 | }
```

**A mesma regra, sobre o mesmo código, agora falha**, porque no plan `cidr_ipv4` é `0.0.0.0/0`. O
cabeçalho do relatório diz `terraform_plan scan results`. `--repo-root-for-plan-enrichment .` é o que
leva o achado de volta a `ssh.tf:6-13` e imprime o código-fonte; sem isso o Checkov só consegue apontar
para `/tfplan.json`, o que não diz nada a um revisor. Repare que o código impresso ainda diz
`var.admin_cidr`. O código é onde o achado se corrige. O plan é onde o valor foi encontrado.

O Trivy também lê um plan em JSON. Neste plan, em que a regra de SSH é a única mudança, ele não relatou
a regra:

```
ana@laptop:~/shop$ trivy config --skip-check-update -q tfplan.json | grep -c AWS-0107
0
```

Isso é a medida de uma versão sobre um plan, e a aula tira dela uma conclusão só.
**Teste o que o seu scanner faz com um plan** antes de depender disso, com um valor sabidamente ruim como este, do mesmo
jeito que o `legacy/main.tf` testou o tfsec.

## O que o plan custa

Uma varredura da configuração precisa de um checkout. Uma varredura do plan precisa de tudo o que um
plan precisa: providers inicializados, credenciais, uma API de onde ler os recursos atuais (o moto,
neste laboratório) e os arquivos de variáveis certos. Então ela roda mais tarde no pipeline e falha por
motivos que não são de segurança. **O JSON também guarda todos os valores em claro**, inclusive os
marcados como sensitive, que a aula 12 mostrou chegando ao state do mesmo jeito. Trate o
`tfplan.json` como o state: não o anexe a um pull request nem o guarde como artefato de build por mais
tempo do que a revisão precisa.

Quando os valores estão num arquivo que você conhece, há um meio-termo mais barato. O Checkov aceita
`--var-file` e preenche as variáveis antes de verificar:

```
ana@laptop:~/shop$ checkov -d . --skip-download --quiet --compact --check CKV_AWS_24 --var-file maintenance.tfvars --framework terraform
terraform scan results:

Passed checks: 2, Failed checks: 1, Skipped checks: 0

Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	FAILED for resource: aws_vpc_security_group_ingress_rule.ssh
	File: /ssh.tf:6-13
```

Funciona para os valores que você lembra de passar, e só para eles. O plan cobre o resto, inclusive um
valor que ninguém sabia que estava lá.

A Ana troca o arquivo pela faixa do escritório, roda o plan de novo, e a varredura do plan concorda:

```
ana@laptop:~/shop$ echo 'admin_cidr = "203.0.113.0/24"' > maintenance.tfvars
ana@laptop:~/shop$ terraform plan -var-file=maintenance.tfvars -out tfplan > /dev/null && terraform show -json tfplan > tfplan.json
ana@laptop:~/shop$ checkov -f tfplan.json --skip-download --compact --check CKV_AWS_24

       _               _
   ___| |__   ___  ___| | _______   __
  / __| '_ \ / _ \/ __| |/ / _ \ \ / /
 | (__| | | |  __/ (__|   < (_) \ V /
  \___|_| |_|\___|\___|_|\_\___/ \_/

By Prisma Cloud | version: 3.3.22 

terraform_plan scan results:

Passed checks: 3, Failed checks: 0, Skipped checks: 0

Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	PASSED for resource: aws_security_group.web
	File: /tfplan.json:0-0
Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	PASSED for resource: aws_vpc_security_group_ingress_rule.https
	File: /tfplan.json:0-0
Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	PASSED for resource: aws_vpc_security_group_ingress_rule.ssh
	File: /tfplan.json:0-0
```

A correção caiu no `maintenance.tfvars`, o único lugar que uma varredura da configuração nunca
conseguiria ver.
