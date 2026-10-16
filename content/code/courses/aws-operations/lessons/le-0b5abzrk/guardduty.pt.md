---
title: O GuardDuty, e os achados que ele levantaria
version: 1
---

O GuardDuty é ligado por conta e por região criando um **detector**. Trabalhe em `~/aws/findings`
(`mkdir -p ~/aws/findings && cd ~/aws/findings`):

```
ana@laptop:~/aws/findings$ aws guardduty create-detector --enable --finding-publishing-frequency FIFTEEN_MINUTES --query DetectorId --output text
5374de5f88855167531a59bc4dc21987
ana@laptop:~/aws/findings$ DETECTOR=$(aws guardduty list-detectors --query "DetectorIds[0]" --output text)
ana@laptop:~/aws/findings$ aws guardduty get-detector --detector-id $DETECTOR --query '[Status,FindingPublishingFrequency,DataSources.CloudTrail.Status]' --output text
ENABLED	FIFTEEN_MINUTES	DISABLED
```

O detector está ativo e publica atualizações dos seus achados a cada quinze minutos em vez das seis horas
padrão, o que importa quando os achados vão para uma pessoa. O moto informa a fonte CloudTrail como
`DISABLED`; na AWS as fontes básicas, eventos de gerenciamento do CloudTrail, VPC Flow Logs e logs de DNS,
estão sempre ligadas com o detector, e as proteções opcionais aparecem como **features**.

## Como é um achado

Um achado tem um **tipo**, escrito `ThreatPurpose:ResourceType/ThreatFamily`, uma severidade de 1 a 10, e
o recurso e as evidências. Alguns tipos que vale reconhecer, da documentação da AWS:

| tipo | o que diz |
|---|---|
| `UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration.OutsideAWS` | as credenciais temporárias de uma instância foram usadas de um endereço fora da AWS |
| `CryptoCurrency:EC2/BitcoinTool.B!DNS` | uma instância está resolvendo nomes de pools de mineração de criptomoeda |
| `Recon:EC2/PortProbeUnprotectedPort` | algo na internet está sondando uma porta aberta de uma instância |
| `Policy:IAMUser/RootCredentialUsage` | o usuário root foi usado |
| `Discovery:S3/AnomalousBehavior` | um padrão incomum de listagem e leitura no S3, para este principal |

A severidade é um número em faixas: **baixa** abaixo de 4, **média** de 4 a 6,9, **alta** a partir de 7. A
primeira linha é alta e urgente, porque uma credencial que saiu da instância está nas mãos de outra pessoa
agora. A terceira é baixa e constante: toda instância com porta aberta na internet é sondada o dia todo.

## Supressão, com motivo

Um achado que a equipe decidiu ser esperado, o scanner de segurança do escritório sondando as próprias
instâncias da loja toda noite, não deve chegar a uma pessoa. Um **filtro** com a ação `ARCHIVE` é uma regra
de supressão: os achados que casam são arquivados ao chegar.

```
ana@laptop:~/aws/findings$ aws guardduty create-filter --detector-id $DETECTOR --name office-scanner --action ARCHIVE --rank 1 --finding-criteria '{"Criterion":{"type":{"Eq":["Recon:EC2/PortProbeUnprotectedPort"]},"service.action.networkConnectionAction.remoteIpDetails.ipAddressV4":{"Eq":["198.51.100.10"]}}}' --query Name
"office-scanner"
```

O filtro nomeia o tipo **e** o endereço do scanner. Uma supressão só pelo tipo arquivaria toda sondagem de
qualquer um, e é assim que uma sondagem real fica escondida. A regra da supressão é a mesma da lição 14
para alarmes: estreita, escrita, e com um motivo que alguém consiga ler.

## O que o moto não faz

```
ana@laptop:~/aws/findings$ aws guardduty list-findings --detector-id $DETECTOR 2>&1 | grep -m1 -o "Not Found"
Not Found
ana@laptop:~/aws/findings$ aws inspector2 enable --resource-types ECR EC2 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the Enable operation (reached max retries: 2): <!doctype html>
```

O moto não tem `list-findings` para o GuardDuty nem um Inspector para ligar: o primeiro é um 404, o segundo
um 500. Na AWS, `create-sample-findings` cria um achado de exemplo de cada tipo, que é o jeito honesto de
testar a rota de um achado até um telefone antes de chegar um de verdade. A próxima seção põe achados no
Security Hub, onde o moto os guarda.
