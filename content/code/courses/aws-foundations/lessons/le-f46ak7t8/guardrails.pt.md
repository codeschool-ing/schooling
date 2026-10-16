---
title: Quatro barreiras, escritas por extenso
version: 1
---

**Uma barreira é um deny que nenhum administrador da conta consegue tirar.** Esse é todo o motivo de
a loja escrever SCPs: os administradores das próprias contas, a `AdministratorAccess` e a
`OrganizationAccountAccessRole` inclusive, podem fazer tudo o que o IAM permite, e estas quatro
coisas não deviam estar entre elas. Cada uma é um arquivo de política, criado uma vez na conta de
gerenciamento e anexado ao galho que protege. Salve cada uma em `~/aws/scp/`, o diretório da seção
anterior, com o nome dado acima dela.

## Ninguém sai da organização

`scp/deny-leaving.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyLeavingTheOrganisation",
      "Effect": "Deny",
      "Action": "organizations:LeaveOrganization",
      "Resource": "*"
    }
  ]
}
```

**Uma conta que sai deixa para trás toda regra anexada à árvore**, as outras três desta seção entre
elas. A lição 3 disse que uma conta criada não pode sair até ter meio de pagamento e plano de
suporte; esta a impede de sair mesmo então, até a conta de gerenciamento removê-la.

## Nada fora de São Paulo

`scp/sa-east-1-only.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyOutsideSaoPaulo",
      "Effect": "Deny",
      "NotAction": [
        "iam:*",
        "sts:*",
        "organizations:*",
        "cloudfront:*",
        "route53:*",
        "budgets:*",
        "ce:*",
        "health:*",
        "support:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": ["sa-east-1"]
        }
      }
    }
  ]
}
```

`aws:RequestedRegion` é a região para onde uma requisição é mandada, e a condição faz o deny valer
para toda requisição que não é para `sa-east-1`. **`NotAction` é a metade que as pessoas erram.** Quer
dizer "toda ação menos estas", e as exceções são os **serviços globais**: IAM, STS, Organizations,
CloudFront, Route 53 e os serviços de faturamento respondem de um lugar só, normalmente `us-east-1`,
seja qual for a região em que quem chama trabalha. Negue-os fora de São Paulo e a loja não
conseguiria mais criar um usuário nem ler a própria fatura. A lista acima é mais curta que a do
exemplo da própria AWS para esta política, que carrega mais serviços globais; uma empresa copia a
lista da AWS e tira o que não usa, nunca o contrário.

**O motivo da loja são os dados, e a fatura.** Nada do que ela roda deveria estar em outro lugar,
então uma máquina iniciada na Virgínia por engano, ou por alguém que roubou uma chave, é recusada em
vez de aparecer na fatura um mês depois.

## Ninguém desliga as câmeras

`scp/protect-security-services.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ProtectCloudTrail",
      "Effect": "Deny",
      "Action": [
        "cloudtrail:StopLogging",
        "cloudtrail:DeleteTrail",
        "cloudtrail:UpdateTrail",
        "cloudtrail:PutEventSelectors"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ProtectGuardDuty",
      "Effect": "Deny",
      "Action": [
        "guardduty:DeleteDetector",
        "guardduty:UpdateDetector",
        "guardduty:DisassociateFromAdministratorAccount"
      ],
      "Resource": "*"
    }
  ]
}
```

**O CloudTrail registra toda chamada de API de uma conta, e o GuardDuty vigia esses registros e a
rede em busca de sinais de um intruso.** A primeira coisa que um intruso com a chave de um
administrador faz é desligar os dois, e a primeira coisa que um engenheiro depurando um alerta
barulhento faz é a mesma. Nenhum dos dois deveria conseguir. A lição 5 posiciona os dois serviços, e
a conta para onde vão os registros deles.

## Ninguém além da plataforma mexe no deployer

`scp/protect-deployer.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ProtectTheDeployerRole",
      "Effect": "Deny",
      "Action": [
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:UpdateAssumeRolePolicy",
        "iam:DeleteRole"
      ],
      "Resource": "arn:aws:iam::*:role/deployer",
      "Condition": {
        "ArnNotLike": {
          "aws:PrincipalArn": "arn:aws:iam::*:role/OrganizationAccountAccessRole"
        }
      }
    }
  ]
}
```

`deployer` é a role que o pipeline da loja usa para publicar software, então **quem pode mudar as
permissões ou a política de confiança dela pode fazer o pipeline fazer qualquer coisa**, ou fazer de
qualquer um o pipeline. `aws:PrincipalArn` é o ARN da identidade que faz a requisição, e a condição
exclui uma: a role por onde a conta de gerenciamento entra. Todos os outros, administradores da
`shop-prod` inclusive, são recusados. O `*` no campo da conta faz uma política só funcionar em toda
conta do galho a que é anexada.

## Criando e anexando

Com os quatro arquivos salvos, crie as políticas e anexe-as, achando cada id com a função `policy`
da seção anterior:

```
ana@laptop:~/aws$ for p in deny-leaving sa-east-1-only protect-security-services protect-deployer; do aws organizations create-policy --name $p --type SERVICE_CONTROL_POLICY --description "shop guardrail: $p" --content file://scp/$p.json --query Policy.PolicySummary.Id --output text; done
p-zwlh2zo3
p-44m2vi13
p-yj6ovjex
p-p6z711fr
ana@laptop:~/aws$ for p in deny-leaving sa-east-1-only protect-security-services; do aws organizations attach-policy --policy-id $(policy $p) --target-id $root; done
ana@laptop:~/aws$ aws organizations attach-policy --policy-id $(policy protect-deployer) --target-id $workloads
ana@laptop:~/aws$ aws organizations list-policies-for-target --target-id $root --filter SERVICE_CONTROL_POLICY --query "Policies[].Name" --output text
FullAWSAccess	deny-leaving	sa-east-1-only	protect-security-services
ana@laptop:~/aws$ aws organizations list-targets-for-policy --policy-id $(policy protect-deployer) --query "Targets[].[Name,Type]" --output text
Workloads	ORGANIZATIONAL_UNIT
```

As três primeiras vão na raiz, então cobrem toda conta-membro; a proteção do deployer vai em
`Workloads`, onde a role deployer mora. **A conta de gerenciamento não é tocada por nenhuma das
quatro**, que é o motivo da lição 3 para ela não rodar nada.

## O que o moto faz com elas: nada

A organização agora proíbe à `shop-prod` toda região menos `sa-east-1`. Peça à `shop-prod` uma rede
na Virgínia, pelo perfil da lição 2, escrito de novo para a conta deste moto:

```
ana@laptop:~/aws$ aws configure set profile.shop-prod.role_arn arn:aws:iam::$(account shop-prod):role/OrganizationAccountAccessRole
ana@laptop:~/aws$ aws configure set profile.shop-prod.credential_source Environment
ana@laptop:~/aws$ aws configure set profile.shop-prod.role_session_name ana
ana@laptop:~/aws$ aws --profile shop-prod ec2 create-vpc --cidr-block 10.99.0.0/16 --region us-east-1 --query Vpc.VpcId --output text
vpc-2c9aa2ce3234ff9c3
```

**O moto criou a VPC. A AWS a teria recusado**, e a documentação dela diz como: a chamada falha com
`AccessDenied`, e a mensagem diz que a requisição foi negada por um deny explícito numa service
control policy. **Essa recusa não foi rodada aqui.** O moto guarda SCPs, anexa e lista, e não decide
nada com elas. Este curso conferiu isso também com a verificação de permissões do moto ligada, que a
lição 7 explica: com uma política do IAM permitindo a chamada, a VPC na Virgínia continua sendo
criada. Tudo o que esta lição diz sobre o que uma SCP recusa vem da documentação da AWS, e o
laboratório só consegue mostrar a forma.

O moto também não verifica nenhum dos limites. Testado para este curso e não mostrado: ele aceitou
uma política que não era JSON válido, uma sexta política num mesmo alvo e uma política de 9.771
caracteres. A AWS recusa as três, já que uma SCP tem de ser linguagem de política válida, um alvo
recebe no máximo cinco SCPs e uma política tem no máximo 5.120 caracteres.

## As políticas ao lado das SCPs

O Organizations tem mais tipos de política que as SCPs, e dois deles valem ser reconhecidos aqui.

As **resource control policies**, RCPs, chegaram em 2024 como a outra metade de uma SCP. Uma SCP
limita o que as identidades de uma conta podem fazer; uma RCP limita o que pode ser feito com os
recursos de uma conta, por qualquer um, inclusive identidades de fora da organização. O uso clássico
é "nenhum bucket nosso pode ser lido por uma conta que não é nossa", o que nenhuma SCP consegue
dizer, já que quem lê não está sob a SCP. Uma RCP é um filtro do mesmo jeito: não concede nada.

As **políticas declarativas** definem uma configuração de um serviço para a organização inteira,
começando pelo EC2, como recusar tornar imagens de máquina públicas. O próprio serviço aplica a
configuração, então ela vale até para uma requisição que nenhuma SCP previu. Os dois tipos aparecem
na CLI como valores de `--policy-type`, `RESOURCE_CONTROL_POLICY` e `DECLARATIVE_POLICY_EC2`; este
curso não vai além disso com eles.
