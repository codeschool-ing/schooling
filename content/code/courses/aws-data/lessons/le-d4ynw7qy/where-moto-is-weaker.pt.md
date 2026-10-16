---
title: Onde a trava do moto é mais fraca que a do S3
version: 1
---

**O moto recusa os deletes que uma trava proíbe, e deixa você tirar a trava.** A seção anterior
mostrou a metade que o moto acerta. Esta mostra a metade que ele não acerta, porque uma trava testada
só contra o moto pode parecer uma garantia e não ser nada disso, e porque os passos abaixo são
exatamente os que o S3 existe para recusar.

No mesmo bucket de arquivo, trave a nota de setembro em modo compliance até outubro de 2027, e depois
tente desfazer a trava:

```
ana@laptop:~/aws$ aws s3api put-object --bucket quitanda-archive-prod --key invoices/2026-09/nf.csv --body nf.csv --object-lock-mode COMPLIANCE --object-lock-retain-until-date 2027-10-16T00:00:00Z --query VersionId --output text
e8fceec3-e2e9-4235-b19a-07c2db180b2c
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-archive-prod --key invoices/2026-09/nf.csv --query '[ObjectLockMode,ObjectLockRetainUntilDate]'
[
    "COMPLIANCE",
    "2027-10-16T00:00:00+00:00"
]
ana@laptop:~/aws$ aws s3api put-object-retention --bucket quitanda-archive-prod --key invoices/2026-09/nf.csv --version-id e8fceec3-e2e9-4235-b19a-07c2db180b2c --retention Mode=GOVERNANCE,RetainUntilDate=2026-10-17T00:00:00Z
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-archive-prod --key invoices/2026-09/nf.csv --query '[ObjectLockMode,ObjectLockRetainUntilDate]'
[
    "GOVERNANCE",
    "2026-10-17T00:00:00+00:00"
]
ana@laptop:~/aws$ aws s3api delete-object --bucket quitanda-archive-prod --key invoices/2026-09/nf.csv --version-id e8fceec3-e2e9-4235-b19a-07c2db180b2c --bypass-governance-retention
{
    "VersionId": "e8fceec3-e2e9-4235-b19a-07c2db180b2c"
}
ana@laptop:~/aws$ aws s3api list-object-versions --bucket quitanda-archive-prod --prefix invoices/2026-09/ --query 'Versions'
null
```

**O moto transformou uma retenção compliance numa governance, um ano mais curta, e depois deixou a
versão ser apagada com o bypass**; a listagem vazia no fim diz que não sobrou versão nenhuma da nota.
Cada um desses três passos é recusado pelo S3. Uma retenção compliance pode ser estendida e nunca
encurtada, o modo dela não pode mudar, e nenhuma permissão, nem a do root, torna apagável uma versão
travada antes da data. Essas três requisições são o que uma trava existe para impedir, mandadas por
quem tiver as chaves da Quitanda, e o S3 as barra na primeira.

O mesmo vale para o versionamento do bucket:

```
ana@laptop:~/aws$ aws s3api put-bucket-versioning --bucket quitanda-archive-prod --versioning-configuration Status=Suspended
ana@laptop:~/aws$ aws s3api get-bucket-versioning --bucket quitanda-archive-prod
{
    "Status": "Suspended"
}
ana@laptop:~/aws$ aws s3api put-object --bucket quitanda-archive-prod --key invoices/2026-11/nf.csv --body nf.csv --query VersionId --output text
None
ana@laptop:~/aws$ aws s3api put-object --bucket quitanda-archive-prod --key invoices/2026-12/nf.csv --body nf.csv --query VersionId --output text
None
```

**O moto suspendeu o versionamento de um bucket com Object Lock.** O S3 também recusa isso, já que uma
trava sem versões não protegeria nada. As duas escritas seguintes voltaram sem id de versão nenhum, o
que a linha de comando imprime como `None`; no S3 a suspensão teria sido recusada e cada uma teria
ganhado uma versão própria.

## Então o que um teste no moto prova?

Que as requisições estão bem formadas: o bucket foi criado com a trava, a retenção padrão foi escrita
do jeito certo, o delete sem bypass foi recusado. Não prova nada sobre se uma trava pode ser desfeita,
porque o moto permite o que o S3 proíbe. **Teste uma trava contra o moto pela forma, e acredite na
documentação da AWS pela força.** Uma verificação real do modo compliance exige uma conta real, e custa
um ano de armazenamento da versão que você travar, já que nada pode removê-la antes.

## MFA delete, descrito e não rodado

Antes de o Object Lock existir, a última defesa de um bucket era o MFA delete, e ele ainda é uma
configuração do versionamento. Com ele ligado, duas coisas exigem, na própria requisição, um código do
dispositivo MFA do usuário root: apagar uma versão de vez e mudar o estado de versionamento do bucket.
Só o usuário root pode ligá-lo, e só pela API ou pela linha de comando, nunca pelo console, com o
código passado como `--mfa` no `put-bucket-versioning`.

Não foi rodado aqui: exige o dispositivo MFA do usuário root, que é exatamente o que este curso nunca
tem. Também raramente é a escolha certa hoje. Ele amarra todo delete permanente a um dispositivo físico
na mão de uma pessoa, e a documentação da AWS diz que um bucket com MFA delete não pode usar uma
configuração de ciclo de vida, então a regra da seção sobre custos não poderia existir ao lado dele.
Object Lock em modo governance, com a permissão de bypass num único papel, faz o mesmo trabalho sem o
dispositivo.
