---
title: Security Hub, uma fila num formato
version: 1
---

O Security Hub é ligado uma vez por conta e região. A opção impede que ele ligue os padrões default, cujas
verificações não achariam nada para verificar no moto:

```
ana@laptop:~/aws/findings$ aws securityhub enable-security-hub --no-enable-default-standards
ana@laptop:~/aws/findings$ aws securityhub describe-hub --query '[HubArn,ControlFindingGenerator]' --output text
arn:aws:securityhub:sa-east-1:123456789012:hub/default	SECURITY_CONTROL
```

`SECURITY_CONTROL` quer dizer que um controle reprovado gera **um achado por controle e recurso**, e não
um por padrão: um bucket que falha na mesma verificação em dois padrões é um achado, não dois. Na AWS, os
padrões então rodam suas verificações a cada doze horas ou a cada mudança de configuração, conforme o
controle, e os achados aparecem sem ninguém importá-los.

## Achados, no formato

O laboratório tem de trazer os seus. `mk-findings.py`, em `~/aws/findings`, escreve seis achados
inventados em ASFF, dois no formato que o GuardDuty escreve, dois no do Inspector, dois no do próprio
Security Hub:

```python
# mk-findings.py: six made-up findings in AWS's finding format, for the lab
import json

ACCOUNT = "123456789012"
PRODUCT = f"arn:aws:securityhub:sa-east-1:{ACCOUNT}:product/{ACCOUNT}/default"
# id, imitating, type, severity, title, resource type, resource id, exploit available
rows = [
    ("gd-1", "guardduty", "TTPs/Initial Access/UnauthorizedAccess:IAMUser-InstanceCredentialExfiltration.OutsideAWS",
     "HIGH", "Instance credentials used from outside AWS", "AwsIamRole", "shop-api-task", None),
    ("gd-2", "guardduty", "TTPs/Discovery/Recon:EC2-PortProbeUnprotectedPort",
     "LOW", "Port 22 probed on an instance", "AwsEc2Instance", "i-0lab1", None),
    ("in-1", "inspector", "Software and Configuration Checks/Vulnerabilities/CVE",
     "CRITICAL", "CVE in a library of the api image", "AwsEcrContainerImage", "shop/api:9f1c2ab34de5", "YES"),
    ("in-2", "inspector", "Software and Configuration Checks/Vulnerabilities/CVE",
     "CRITICAL", "CVE in a build tool of the worker image", "AwsEcrContainerImage", "shop/worker:77ad01", "NO"),
    ("sh-1", "security-hub", "Software and Configuration Checks/Industry and Regulatory Standards",
     "HIGH", "S3 bucket allows public read", "AwsS3Bucket", "shop-exports", None),
    ("sh-2", "security-hub", "Software and Configuration Checks/Industry and Regulatory Standards",
     "MEDIUM", "CloudTrail log file validation is off", "AwsCloudTrailTrail", "shop-trail", None),
]
findings = []
for fid, gen, ftype, sev, title, rtype, rid, exploit in rows:
    f = {
        "SchemaVersion": "2018-10-08", "Id": fid, "ProductArn": PRODUCT, "GeneratorId": f"lab-{gen}",
        "AwsAccountId": ACCOUNT, "Types": [ftype], "Title": title, "Description": title,
        "CreatedAt": "2026-10-16T10:00:00Z", "UpdatedAt": "2026-10-16T10:00:00Z",
        "Severity": {"Label": sev}, "Resources": [{"Type": rtype, "Id": rid}],
    }
    if exploit:
        f["Vulnerabilities"] = [{"Id": "CVE-lab", "ExploitAvailable": exploit}]
    findings.append(f)
json.dump(findings, open("findings.json", "w"), indent=1)
print(len(findings), "findings written")
```

Os campos que todo achado tem são os que o programa preenche: um `Id` único dentro do produto, o
`ProductArn` de quem o produziu, os `Types` numa taxonomia de três níveis, um rótulo de `Severity`, um
`Title`, e os `Resources` de que ele trata. Os do Inspector acrescentam `Vulnerabilities`, e ali
`ExploitAvailable` diz se há um exploit publicado para o CVE: dois CVEs críticos, um com exploit e um sem,
que a próxima seção trata de forma bem diferente.

```
ana@laptop:~/aws/findings$ python3 mk-findings.py
6 findings written
ana@laptop:~/aws/findings$ aws securityhub batch-import-findings --findings file://findings.json --query '[SuccessCount,FailedCount]' --output text
6	0
ana@laptop:~/aws/findings$ aws securityhub get-findings --query 'Findings[].[Id,Severity.Label,Title]' --output text
gd-1	HIGH	Instance credentials used from outside AWS
gd-2	LOW	Port 22 probed on an instance
in-1	CRITICAL	CVE in a library of the api image
in-2	CRITICAL	CVE in a build tool of the worker image
sh-1	HIGH	S3 bucket allows public read
sh-2	MEDIUM	CloudTrail log file validation is off
```

Na AWS todo achado também ganha um **status de workflow**, `NEW` até alguém mudá-lo para `NOTIFIED`,
`SUPPRESSED` ou `RESOLVED`, e um record state, `ACTIVE` até quem o produziu arquivá-lo. O moto não
define nenhum dos dois, e não tem `batch-update-findings`, a chamada que move um achado pelo workflow.

## O filtro que não é aplicado

```
ana@laptop:~/aws/findings$ aws securityhub get-findings --filters '{"SeverityLabel":[{"Value":"CRITICAL","Comparison":"EQUALS"}]}' --query 'Findings[].Id' --output text
gd-1	gd-2	in-1	in-2	sh-1	sh-2
```

Um filtro em `CRITICAL` devolveu os seis. **O moto ignora os filtros de `get-findings`**; a AWS os aplica,
e numa conta com milhares de achados eles são o único jeito prático de perguntar. O programa da próxima
seção filtra nos termos da AWS e ordena por conta própria, então lê do mesmo jeito nos dois.
