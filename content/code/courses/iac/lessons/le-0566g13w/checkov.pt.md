---
title: Checkov, e como ler um achado
version: 2
---

O Checkov é um programa em Python, publicado pela Prisma Cloud (parte da Palo Alto Networks), e lê
muito mais do que Terraform: CloudFormation, manifestos do Kubernetes, Dockerfiles, workflows do
GitHub Actions. Você aponta um diretório com `-d` e ele descobre quais dos seus frameworks se aplicam.

**Instalando o Checkov.** Ele é instalado com o pipx, que dá a um programa Python um ambiente só dele,
do jeito que o `~/iac-venv` guarda o moto. O `pipx ensurepath` põe no seu `PATH` o diretório onde o
pipx instala, e um terminal só lê o `PATH` quando abre; então abra um terminal novo depois destes três
comandos e leia o `~/iac-env.sh` nele de novo:

```sh
sudo apt-get install -y pipx
pipx ensurepath
pipx install checkov==3.3.22
```

A versão é a mesma com que estas transcrições foram gravadas:

```
ana@laptop:~/shop$ checkov --version
3.3.22
```

## Ele quer a rede, e funciona sem ela

A primeira coisa que o Checkov faz em toda execução é pedir à API da Prisma Cloud as suas
*guidelines*, um mapa de cada check para uma página de documentação. A máquina em que estas aulas
foram gravadas não tinha internet, então o pedido falhou, e o Checkov avisou com um warning e depois
um traceback longo de Python:

```
ana@laptop:~/shop$ checkov -d . 2>&1 | head -n 2
2026-10-02 07:40:56,627 [MainThread  ] [WARNI]  Failed to get the checkov mappings and guidelines from https://api0.prismacloud.io/bridgecrew/api/v2/guidelines. Skips using BC_* IDs will not work.
Traceback (most recent call last):
```

No seu computador o pedido chega à API, então nenhuma das duas linhas aparece: o mesmo comando
imprime o banner do Checkov e segue para o relatório. **A varredura continua depois do traceback**, e
os resultados são os mesmos nos dois casos. O que o download acrescenta é a linha `Guide:` que uma
execução conectada imprime embaixo de cada achado, com um link para a página da regra.
`--skip-download` é a chave do próprio Checkov para não pedir, uma execução offline onde quer que
aconteça, e toda execução desta aula daqui em diante passa essa opção, para que os seus relatórios
batam com a página.

**Severidades são outra história.** Os checks do Checkov não trazem nenhuma própria, e o download
público não as acrescenta: a Prisma Cloud só manda uma severidade para cada check a uma execução que
se autentica com a chave de API de uma conta. Sem ela, conectada ou não, nenhum achado tem
severidade. Guarde isso para a seção de triagem.

## O relatório inteiro

Duas opções deixam o relatório legível: `--quiet` imprime só o que falhou, e `--compact` deixa de fora
o código de cada recurso.

```
ana@laptop:~/shop$ checkov -d . --skip-download --quiet --compact
terraform scan results:

Passed checks: 22, Failed checks: 13, Skipped checks: 0

Check: CKV_AWS_189: "Ensure EBS Volume is encrypted by KMS using a customer managed Key (CMK)"
	FAILED for resource: aws_ebs_volume.data
	File: /main.tf:46-50
Check: CKV_AWS_3: "Ensure all data stored in the EBS is securely encrypted"
	FAILED for resource: aws_ebs_volume.data
	File: /main.tf:46-50
Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	FAILED for resource: aws_vpc_security_group_ingress_rule.ssh
	File: /ssh.tf:1-8
Check: CKV_AWS_18: "Ensure the S3 bucket has access logging enabled"
	FAILED for resource: aws_s3_bucket.assets
	File: /main.tf:42-44
Check: CKV2_AWS_6: "Ensure that S3 bucket has a Public Access block"
	FAILED for resource: aws_s3_bucket.assets
	File: /main.tf:42-44
Check: CKV2_AWS_62: "Ensure S3 buckets should have event notifications enabled"
	FAILED for resource: aws_s3_bucket.assets
	File: /main.tf:42-44
Check: CKV2_AWS_11: "Ensure VPC flow logging is enabled in all VPCs"
	FAILED for resource: aws_vpc.shop
	File: /main.tf:14-17
Check: CKV2_AWS_5: "Ensure that Security Groups are attached to another resource"
	FAILED for resource: aws_security_group.web
	File: /main.tf:26-31
Check: CKV2_AWS_12: "Ensure the default security group of every VPC restricts all traffic"
	FAILED for resource: aws_vpc.shop
	File: /main.tf:14-17
Check: CKV2_AWS_61: "Ensure that an S3 bucket has a lifecycle configuration"
	FAILED for resource: aws_s3_bucket.assets
	File: /main.tf:42-44
Check: CKV_AWS_144: "Ensure that S3 bucket has cross-region replication enabled"
	FAILED for resource: aws_s3_bucket.assets
	File: /main.tf:42-44
Check: CKV_AWS_21: "Ensure all data stored in the S3 bucket have versioning enabled"
	FAILED for resource: aws_s3_bucket.assets
	File: /main.tf:42-44
Check: CKV_AWS_145: "Ensure that S3 buckets are encrypted with KMS by default"
	FAILED for resource: aws_s3_bucket.assets
	File: /main.tf:42-44
```

Treze de 35 checks falharam, e só um deles é a regra de SSH do pull request. Os outros doze já
estavam lá antes. Entre outras coisas, eles dizem que o bucket não tem bloqueio de acesso público, nem
versionamento, nem log de acesso, nem regras de ciclo de vida, nem cópia em outra região; que o volume
não está criptografado; que a VPC não tem flow logs. O Checkov roda os checks em paralelo, então a
ordem da lista não é estável de uma execução para outra. Ordene ou filtre antes de comparar dois
relatórios.

## Lendo um achado

```
ana@laptop:~/shop$ checkov -d . --skip-download --quiet --check CKV_AWS_24
terraform scan results:

Passed checks: 2, Failed checks: 1, Skipped checks: 0

Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	FAILED for resource: aws_vpc_security_group_ingress_rule.ssh
	File: /ssh.tf:1-8

		1 | resource "aws_vpc_security_group_ingress_rule" "ssh" {
		2 |   security_group_id = aws_security_group.web.id
		3 |   description       = "SSH for maintenance"
		4 |   ip_protocol       = "tcp"
		5 |   from_port         = 22
		6 |   to_port           = 22
		7 |   cidr_ipv4         = "0.0.0.0/0"
		8 | }
```

**Todo achado tem as mesmas quatro partes**, e cada uma responde uma pergunta diferente:

| parte | aqui | o que ela diz |
|---|---|---|
| o check | `CKV_AWS_24` e o título | qual regra, e o id que você vai citar para pulá-la |
| o recurso | `aws_vpc_security_group_ingress_rule.ssh` | o endereço, exatamente como o Terraform escreve |
| o lugar | `/ssh.tf:1-8` | o arquivo e as linhas, relativos ao diretório varrido |
| o código | as oito linhas numeradas | o que a regra examinou |

O id tem um padrão. Os checks `CKV_AWS_` olham um recurso sozinho. Os checks `CKV2_AWS_` olham as
ligações entre recursos, e é assim que o `CKV2_AWS_6` consegue dizer que o bucket não tem bloqueio de
acesso público: ele procurou na configuração um `aws_s3_bucket_public_access_block` apontando para este
bucket e não achou nenhum.

## Uma regra sua

O catálogo não sabe nada da loja. A empresa da Ana só permite SSH a partir do escritório, cuja faixa é
`203.0.113.0/24`, e nenhuma regra embutida tem como saber esse número. O Checkov lê checks extras de um
diretório, e um check pode ser umas poucas linhas de YAML. A Ana salva este como
`~/policies/ssh_office.yaml`, num diretório próprio, fora da configuração:

```yaml
metadata:
  id: "CKV2_SHOP_1"
  name: "SSH is only allowed from the office range"
  category: "NETWORKING"
definition:
  or:
    - cond_type: "attribute"
      resource_types: ["aws_vpc_security_group_ingress_rule"]
      attribute: "from_port"
      operator: "not_equals"
      value: 22
    - cond_type: "attribute"
      resource_types: ["aws_vpc_security_group_ingress_rule"]
      attribute: "cidr_ipv4"
      operator: "equals"
      value: "203.0.113.0/24"
```

Ele aprova uma regra de entrada que não seja para a porta 22, ou que venha do escritório, e reprova
todo o resto:

```
ana@laptop:~/shop$ checkov -d . --skip-download --quiet --compact --external-checks-dir ~/policies --check CKV2_SHOP_1
terraform scan results:

Passed checks: 1, Failed checks: 1, Skipped checks: 0

Check: CKV2_SHOP_1: "SSH is only allowed from the office range"
	FAILED for resource: aws_vpc_security_group_ingress_rule.ssh
	File: /ssh.tf:1-8
```

A regra de HTTPS passou, porque não é a porta 22; a de SSH falhou. Esse é o tipo mais útil de policy
as code: uma decisão que a sua organização tomou, escrita onde toda mudança esbarra nela.
