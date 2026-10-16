---
title: Object Lock, retenção e retenção legal
version: 1
---

**O Object Lock torna uma versão impossível de apagar ou sobrescrever até uma data, para todo mundo,
inclusive a conta dona dela.** O versionamento protege contra acidentes, porque o marcador pode ser
removido; não protege nada contra alguém que age de propósito, porque quem pode apagar um marcador
também pode apagar as versões. O Object Lock é para o segundo caso: um ataque de ransomware com chaves
roubadas, um funcionário encobrindo algo, uma regra que manda guardar notas fiscais por anos. O último
caso é a razão de a Quitanda ter um bucket de arquivo.

A trava mora em cada versão, como duas coisas separadas:

- **um período de retenção**, uma data até a qual a versão não pode ser apagada nem sobrescrita, num de
  dois modos, governance ou compliance;
- **uma retenção legal** (legal hold), uma chave liga-desliga sem data, que segura a versão até alguém
  desligá-la.

## Um bucket que pode travar

O Object Lock precisa ser ligado quando o bucket é criado, e liga o versionamento junto. O `aws s3 mb`
das lições anteriores não tem opção para isso, então aqui é o `s3api create-bucket`, que também exige
a região por extenso:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket quitanda-archive-prod --create-bucket-configuration LocationConstraint=sa-east-1 --object-lock-enabled-for-bucket
{
    "Location": "/quitanda-archive-prod"
}
ana@laptop:~/aws$ aws s3api get-bucket-versioning --bucket quitanda-archive-prod
{
    "Status": "Enabled"
}
ana@laptop:~/aws$ aws s3api get-object-lock-configuration --bucket quitanda-archive-prod
{
    "ObjectLockConfiguration": {
        "ObjectLockEnabled": "Enabled"
    }
}
```

**O bucket foi criado versionado**, e o `get-object-lock-configuration` confirma que a trava está
ligada, ainda sem padrão. Uma retenção padrão vale para toda versão escrita dali em diante, a menos que
a requisição diga outra coisa. As notas fiscais da Quitanda ganham um ano em modo compliance:

```
ana@laptop:~/aws$ aws s3api put-object-lock-configuration --bucket quitanda-archive-prod --object-lock-configuration '{"ObjectLockEnabled":"Enabled","Rule":{"DefaultRetention":{"Mode":"COMPLIANCE","Years":1}}}'
ana@laptop:~/aws$ aws s3api get-object-lock-configuration --bucket quitanda-archive-prod
{
    "ObjectLockConfiguration": {
        "ObjectLockEnabled": "Enabled",
        "Rule": {
            "DefaultRetention": {
                "Mode": "COMPLIANCE",
                "Days": 0,
                "Years": 1
            }
        }
    }
}
```

## Compliance: ninguém, por motivo nenhum

A nota de outubro entrou sem opções de trava na requisição, e o padrão lhe deu uma:

```
ana@laptop:~/aws$ printf 'invoice,total_cents\nnf-2026-10-0001,4590\n' > nf.csv && aws s3api put-object --bucket quitanda-archive-prod --key invoices/2026-10/nf.csv --body nf.csv --query VersionId --output text
337702ea-3c36-4ad8-b8cc-c80abafdfcbc
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-archive-prod --key invoices/2026-10/nf.csv --query '[ObjectLockMode,ObjectLockRetainUntilDate]'
[
    "COMPLIANCE",
    "2027-10-16T16:11:31+00:00"
]
ana@laptop:~/aws$ aws s3api delete-object --bucket quitanda-archive-prod --key invoices/2026-10/nf.csv --version-id 337702ea-3c36-4ad8-b8cc-c80abafdfcbc

aws: [ERROR]: An error occurred (AccessDenied) when calling the DeleteObject operation: Access Denied
ana@laptop:~/aws$ aws s3api delete-object --bucket quitanda-archive-prod --key invoices/2026-10/nf.csv
{
    "DeleteMarker": true,
    "VersionId": "a67d44d8-66ad-4ea5-9935-c366bcba79ad"
}
ana@laptop:~/aws$ aws s3api list-object-versions --bucket quitanda-archive-prod --query '{versions: Versions[].[VersionId,IsLatest], markers: DeleteMarkers[].[VersionId,IsLatest]}'
{
    "versions": [
        [
            "337702ea-3c36-4ad8-b8cc-c80abafdfcbc",
            false
        ]
    ],
    "markers": [
        [
            "a67d44d8-66ad-4ea5-9935-c366bcba79ad",
            true
        ]
    ]
}
```

**A versão não pode ser apagada, e a chave pode.** O `delete-object` com o id da versão foi recusado
com `AccessDenied`. O `delete-object` sem id deu certo, porque num bucket versionado isso só acrescenta
um marcador de exclusão; a versão travada continua lá embaixo, como mostra o `list-object-versions`.
Uma trava protege versões, não chaves: a nota pode ser escondida, e não pode ser destruída.

Na AWS, uma retenção em modo compliance não pode ser encurtada, não pode virar governance e não pode
ser tirada por usuário nenhum, nem pelo root da conta, até a data passar. O único jeito de se livrar
dela antes é fechar a conta da AWS. A próxima seção mostra que o moto não é tão rígido.

## Governance: ninguém sem uma permissão

O modo governance recusa os mesmos deletes, a menos que a requisição leve
`--bypass-governance-retention`, e na AWS o bypass só funciona para uma identidade cuja política
permita `s3:BypassGovernanceRetention`. Escreva uma versão com retenção governance definida na própria
requisição, o que passa por cima do padrão do bucket:

```
ana@laptop:~/aws$ aws s3api put-object --bucket quitanda-archive-prod --key drafts/nf-draft.csv --body nf.csv --object-lock-mode GOVERNANCE --object-lock-retain-until-date 2026-11-16T00:00:00Z --query VersionId --output text
6f7e8dae-f86b-4b68-a228-443c24541a9b
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-archive-prod --key drafts/nf-draft.csv --query '[ObjectLockMode,ObjectLockRetainUntilDate]'
[
    "GOVERNANCE",
    "2026-11-16T00:00:00+00:00"
]
ana@laptop:~/aws$ aws s3api delete-object --bucket quitanda-archive-prod --key drafts/nf-draft.csv --version-id 6f7e8dae-f86b-4b68-a228-443c24541a9b

aws: [ERROR]: An error occurred (AccessDenied) when calling the DeleteObject operation: Access Denied
ana@laptop:~/aws$ aws s3api delete-object --bucket quitanda-archive-prod --key drafts/nf-draft.csv --version-id 6f7e8dae-f86b-4b68-a228-443c24541a9b --bypass-governance-retention
{
    "VersionId": "6f7e8dae-f86b-4b68-a228-443c24541a9b"
}
```

**Recusado sem o bypass, aceito com ele.** No moto qualquer um pode usar o bypass, já que nenhuma
política é avaliada; na AWS o segundo delete teria precisado daquela permissão, que a Quitanda não dá a
ninguém além de um papel de emergência. Governance é o modo para experimentar uma trava, e para usar
onde algumas poucas pessoas precisam poder corrigir um erro. Não é proteção contra essas pessoas.

## Retenção legal

```
ana@laptop:~/aws$ aws s3api put-object --bucket quitanda-archive-prod --key disputes/c-17/order.csv --body nf.csv --object-lock-mode GOVERNANCE --object-lock-retain-until-date 2026-10-17T00:00:00Z --query VersionId --output text
b8a79e2e-6826-4e41-a7d0-4a871ec8c76e
ana@laptop:~/aws$ aws s3api put-object-legal-hold --bucket quitanda-archive-prod --key disputes/c-17/order.csv --version-id b8a79e2e-6826-4e41-a7d0-4a871ec8c76e --legal-hold Status=ON
ana@laptop:~/aws$ aws s3api get-object-legal-hold --bucket quitanda-archive-prod --key disputes/c-17/order.csv --version-id b8a79e2e-6826-4e41-a7d0-4a871ec8c76e
{
    "LegalHold": {
        "Status": "ON"
    }
}
ana@laptop:~/aws$ aws s3api delete-object --bucket quitanda-archive-prod --key disputes/c-17/order.csv --version-id b8a79e2e-6826-4e41-a7d0-4a871ec8c76e --bypass-governance-retention

aws: [ERROR]: An error occurred (AccessDenied) when calling the DeleteObject operation: Access Denied
ana@laptop:~/aws$ aws s3api get-object-retention --bucket quitanda-archive-prod --key disputes/c-17/order.csv --version-id b8a79e2e-6826-4e41-a7d0-4a871ec8c76e

aws: [ERROR]: An error occurred (500) when calling the GetObjectRetention operation (reached max retries: 2): Internal Server Error
```

**A retenção legal recusou o delete mesmo com o bypass.** Ela não tem nada a ver com os modos nem com
as datas, e o bypass do governance não a alcança; só desligá-la, o que exige `s3:PutObjectLegalHold`,
torna a versão apagável de novo. É a ferramenta para "guarde tudo sobre este cliente até o tribunal
dizer o contrário", quando ninguém sabe a data do fim.

Uma nota sobre ler uma retenção de volta, que o último comando acima mostra: o
`get-object-retention` responde ao moto 5.2.3 com um erro interno do servidor, um defeito da
imitação, então esta lição lê `ObjectLockMode` e `ObjectLockRetainUntilDate` do `head-object`, que
traz os mesmos dois valores.
