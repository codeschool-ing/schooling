---
title: Trivy, e de onde vêm os checks dele
version: 1
---

O Trivy, da Aqua Security, é um scanner para imagens de contêiner, sistemas de arquivos e
repositórios, e `trivy config` é a parte dele que lê código de infraestrutura. Os checks são escritos
em Rego, a linguagem de políticas do Open Policy Agent, e **a versão que você instala carrega uma cópia
deles dentro do binário**. O laboratório tem esta:

```
ana@laptop:~/shop$ trivy --version
Version: 0.75.0
```

## Um conjunto de checks mais novo, se ele alcançar um

Por padrão, o Trivy não confia na cópia embutida. A cada execução ele procura um *checks bundle* mais
novo num registro de contêineres e o baixa se o que está no cache estiver desatualizado. No
laboratório o download falha e o Trivy diz o que faz no lugar:

```
ana@laptop:~/shop$ trivy config . 2>&1 | head -n 5
2026-10-02T07:41:08-03:00	INFO	[misconfig] Misconfiguration scanning is enabled
2026-10-02T07:41:08-03:00	INFO	[checks-client] Need to update the checks bundle
2026-10-02T07:41:08-03:00	INFO	[checks-client] Downloading the checks bundle...
2026-10-02T07:41:08-03:00	ERROR	[misconfig] Falling back to embedded checks	err="failed to download checks bundle: download error: OCI repository error: 1 error occurred:\n\t* Get \"https://mirror.gcr.io/v2/\": dial tcp: lookup mirror.gcr.io on 127.0.0.1:53: server misbehaving\n\n"
2026-10-02T07:41:09-03:00	INFO	[terraform scanner] Scanning root module	file_path="."
```

`Falling back to embedded checks` é a linha que importa. A varredura segue com os checks compilados na
0.75.0. `--skip-check-update` impede a tentativa de vez:

```
ana@laptop:~/shop$ trivy config --skip-check-update . 2>&1 | head -n 4
2026-10-02T07:41:10-03:00	INFO	[misconfig] Misconfiguration scanning is enabled
2026-10-02T07:41:10-03:00	INFO	[checks-client] No downloadable checks were loaded as --skip-check-update is enabled, loading from existing cache...
2026-10-02T07:41:10-03:00	ERROR	[misconfig] Falling back to embedded checks	err="failed to check cache: cache does not exist at \"/home/ana/.cache/trivy/policy/content\""
2026-10-02T07:41:11-03:00	INFO	[terraform scanner] Scanning root module	file_path="."
```

O `ERROR` continua lá, agora porque o cache está vazio, e o recurso de reserva é o mesmo. As duas
execuções usam os checks embutidos, então todo resultado do Trivy nesta aula é o que esses checks
dizem. Numa máquina com rede o bundle é baixado e pode ser mais novo que o binário, **então o mesmo
binário sobre o mesmo código pode relatar outra coisa na semana que vem**, porque os checks mudaram.
Num pipeline que falha por achados, decida se você quer isso. `--skip-check-update` prende os checks à
versão que você escolheu, e atualizar o Trivy vira o momento em que regras novas chegam.

## A severidade vem com todo achado

`-q` tira as linhas de log. O relatório completo imprime o código de cada achado, então aqui ele vai
filtrado para o cabeçalho de cada arquivo, a contagem e o título de cada achado:

```
ana@laptop:~/shop$ trivy config --skip-check-update -q . | grep -E "^(AWS-|Failures|[a-z]+\.tf )"
main.tf (terraform)
Failures: 11 (UNKNOWN: 0, LOW: 3, MEDIUM: 2, HIGH: 6, CRITICAL: 0)
AWS-0026 (HIGH): EBS volume is not encrypted.
AWS-0027 (LOW): EBS volume does not use a customer-managed KMS key.
AWS-0086 (HIGH): No public access block so not blocking public acls
AWS-0087 (HIGH): No public access block so not blocking public policies
AWS-0089 (LOW): Bucket has logging disabled
AWS-0090 (MEDIUM): Bucket does not have versioning enabled
AWS-0091 (HIGH): No public access block so not blocking public acls
AWS-0093 (HIGH): No public access block so not restricting public buckets
AWS-0094 (LOW): Bucket does not have a corresponding public access block.
AWS-0132 (HIGH): Bucket does not encrypt data with a customer managed key.
AWS-0178 (MEDIUM): VPC does not have VPC Flow Logs enabled.
ssh.tf (terraform)
Failures: 1 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 1, CRITICAL: 0)
AWS-0107 (HIGH): Security group rule allows unrestricted ingress from any IP address.
```

Ao contrário da execução offline do Checkov, todo achado do Trivy tem severidade, porque a severidade
faz parte do check que vem no binário: `UNKNOWN`, `LOW`, `MEDIUM`, `HIGH` ou `CRITICAL`. A linha
`Failures:` conta os achados por arquivo. São doze ao todo, e o formato bate com o relatório do
Checkov sem ser a mesma lista. O Trivy relata a falta do bloqueio de acesso público cinco vezes, uma
pelo bloqueio e uma por cada uma das quatro configurações que ele teria, e não diz nada sobre
replicação nem sobre ciclo de vida.

## Um achado completo

```
ana@laptop:~/shop$ trivy config --skip-check-update -q . | sed -n "/^ssh.tf/,\$p"
ssh.tf (terraform)
==================
Tests: 1 (SUCCESSES: 0, FAILURES: 1)
Failures: 1 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 1, CRITICAL: 0)

AWS-0107 (HIGH): Security group rule allows unrestricted ingress from any IP address.
════════════════════════════════════════
Security groups provide stateful filtering of ingress and egress network traffic to AWS
resources. It is recommended that no security group allows unrestricted ingress access to
remote server administration ports, such as SSH to port 22 and RDP to port 3389.


See https://avd.aquasec.com/misconfig/aws-0107
────────────────────────────────────────
 ssh.tf:7
   via ssh.tf:1-8 (aws_vpc_security_group_ingress_rule.ssh)
────────────────────────────────────────
   1   resource "aws_vpc_security_group_ingress_rule" "ssh" {
   2     security_group_id = aws_security_group.web.id
   3     description       = "SSH for maintenance"
   4     ip_protocol       = "tcp"
   5     from_port         = 22
   6     to_port           = 22
   7 [   cidr_ipv4         = "0.0.0.0/0"
   8   }
────────────────────────────────────────
```

As partes são as que o Checkov tinha, em outra arrumação. O id é `AWS-0107` e a severidade fica ao
lado. O parágrafo é a explicação do próprio check, e **o link aparece mesmo offline**, porque faz parte
do check e não de um download. Depois vem o lugar, mais preciso que o do Checkov: `ssh.tf:7` é a linha
com o valor problemático, e as linhas `via` sobem dela até o recurso que a contém. O código repete o
recurso com a linha 7 marcada.

Repare do que a explicação diz que a regra trata: *remote server administration ports, such as SSH to
port 22 and RDP to port 3389*, portas de administração remota. A porta 443 vinda de `0.0.0.0/0` é a
regra de HTTPS, é a razão de ser de um servidor web, e o Trivy não a relatou.
