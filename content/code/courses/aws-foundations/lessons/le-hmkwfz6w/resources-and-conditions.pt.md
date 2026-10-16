---
title: Políticas de recurso, condições, e as ferramentas que verificam de verdade
version: 1
---

**Uma política baseada em recurso é anexada à coisa usada em vez de a quem a usa**, e por isso nomeia
um `Principal`: quem, de onde, pode fazer o quê com este bucket, esta fila, esta chave. É uma camada
que concede, como uma política de identidade, e um `Deny` explícito nela encerra uma requisição como
um `Deny` em qualquer outro lugar. A política de confiança de uma role, da lição 6, é uma delas: o
recurso é a role, e a ação é assumi-la.

## Uma política de bucket, e o moto sem lê-la

A loja quer que o `shop-assets` nunca seja apagado por acidente, seja quem for que tenha as chaves.
Um `Deny` para todo principal faz isso na AWS. Salve-a como `~/aws/keep-assets.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "NobodyDeletesTheAssetsBucket",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:DeleteBucket",
      "Resource": "arn:aws:s3:::shop-assets"
    }
  ]
}
```

```
ana@laptop:~/aws$ aws s3api put-bucket-policy --bucket shop-assets --policy file://keep-assets.json
ana@laptop:~/aws$ aws s3api get-bucket-policy --bucket shop-assets --query Policy --output text
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "NobodyDeletesTheAssetsBucket",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:DeleteBucket",
      "Resource": "arn:aws:s3:::shop-assets"
    }
  ]
}

ana@laptop:~/aws$ aws s3api delete-object --bucket shop-assets --key logo.png
ana@laptop:~/aws$ aws s3api delete-bucket --bucket shop-assets
ana@laptop:~/aws$ aws s3 ls
2026-10-16 13:39:04 shop-backups
```

O logo vai primeiro, porque um bucket com objetos dentro não pode ser apagado nem na AWS nem no moto,
e a política do bucket nega só a exclusão do próprio bucket. **Depois o bucket some. A AWS teria
recusado**, `admin` e o `AdministratorAccess` dele inclusive, porque um `Deny` explícito em qualquer
lugar encerra a requisição, e uma política de bucket é um lugar qualquer. O moto guarda políticas de
bucket e nunca as consulta quando julga. Essa recusa não foi rodada aqui.

**Entre contas, uma política de recurso é metade da resposta.** Se a conta `log-archive` da loja é
dona do `shop-logs` e uma role em `shop-prod` grava nele, a política do bucket tem de permitir essa
role **e** a própria política de identidade da role tem de permitir `s3:PutObject` no bucket.
Qualquer uma sozinha é uma negação implícita. A lição 9 encontra a mesma regra nas roles, em que a
política de confiança é o lado do recurso.

## Condições

Uma condição estreita uma instrução a algumas requisições. Dentro de `Condition`, cada **operador**
guarda **chaves** e os valores que elas têm de bater; várias chaves têm de bater todas, e vários
valores para uma chave são alternativas. Quatro chaves aparecem em quase toda conta:

| chave | o que é | um uso típico |
|---|---|---|
| `aws:SourceIp` | o endereço público de onde a requisição veio | `IpAddress` com `203.0.113.0/24`: só do escritório |
| `aws:MultiFactorAuthPresent` | se as credenciais foram obtidas com MFA | `BoolIfExists` com `false`, num `Deny`: nenhuma ação sensível sem MFA |
| `aws:PrincipalTag/team` | uma tag no usuário ou na role que chama | `StringEquals` entre `aws:ResourceTag/team` e `${aws:PrincipalTag/team}`: cada time com as suas coisas |
| `aws:RequestedRegion` | a região para a qual a requisição vai | `StringNotEquals` com `sa-east-1`, num `Deny`: nada fora de São Paulo |

Duas delas têm uma armadilha que a documentação da AWS explica. **`aws:SourceIp` não existe quando a
requisição chega por um VPC endpoint**, que tem chave própria, então um `IpAddress` de permissão
escrito para o escritório falha de dentro da VPC. **`aws:MultiFactorAuthPresent` não existe, em vez de
valer `false`, numa requisição assinada com uma chave de acesso de longo prazo**, e por isso o deny
usa `BoolIfExists`: um `Bool` simples não bateria com a chave ausente, e a chave que nunca teve MFA
passaria.

**O moto trata toda condição como satisfeita**, e isso pode errar para os dois lados. Um `Deny`
restrito a outras regiões negou ao caio uma requisição na própria `sa-east-1`:

```
ana@laptop:~/aws$ aws iam put-user-policy --user-name caio --policy-name only-sao-paulo --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Deny","Action":"*","Resource":"*","Condition":{"StringNotEquals":{"aws:RequestedRegion":"sa-east-1"}}}]}'
ana@laptop:~/aws$ echo $AWS_DEFAULT_REGION
sa-east-1
ana@laptop:~/aws$ with_key "$caio" aws s3 ls

aws: [ERROR]: An error occurred (AccessDenied) when calling the ListBuckets operation: Access Denied
ana@laptop:~/aws$ aws iam delete-user-policy --user-name caio --policy-name only-sao-paulo
ana@laptop:~/aws$ with_key "$caio" aws s3 ls
2026-10-16 13:39:04 shop-backups
```

E um `Allow` que exige MFA deixou a dani passar com uma chave de acesso comum:

```
ana@laptop:~/aws$ aws iam put-user-policy --user-name dani --policy-name buckets-with-mfa --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:ListAllMyBuckets","Resource":"*","Condition":{"Bool":{"aws:MultiFactorAuthPresent":"true"}}}]}'
ana@laptop:~/aws$ dani=$(aws iam create-access-key --user-name dani)
ana@laptop:~/aws$ with_key "$dani" aws s3 ls
2026-10-16 13:39:04 shop-backups
ana@laptop:~/aws$ aws iam list-mfa-devices --user-name dani
{
    "MFADevices": []
}
```

**A AWS teria permitido a primeira e recusado a segunda.** Nenhuma das duas foi rodada contra a AWS.
A única condição que o moto compara é `sts:ExternalId` na política de confiança de uma role, que a
lição 9 mede.

## As ferramentas que respondem de verdade

Todo limite do laboratório nesta lição tem o mesmo remédio: perguntar à AWS. Duas ferramentas existem
para isso, e **nenhuma roda no moto**, que responde às duas com HTTP 500, então nada abaixo foi rodado
aqui.

- **O simulador de políticas do IAM**, `aws iam simulate-principal-policy`, recebe um principal, uma
  lista de ações e, opcionalmente, recursos e chaves de contexto, e diz para cada ação se ela seria
  permitida, e qual instrução decidiu. Ele lê as políticas reais do principal, limites inclusive, sem
  fazer a requisição.
- **O IAM Access Analyzer** faz três trabalhos. O `aws accessanalyzer validate-policy` confere um
  documento contra a gramática e as boas práticas da AWS antes de ele ser salvo, e teria apontado o
  `Principal` numa política de identidade da lição 7. Um analisador criado para a conta ou a
  organização lista todo recurso cuja política deixa entrar alguém de **fora** dela, como um bucket
  compartilhado com outra conta. E ele informa acessos concedidos e nunca usados, que é onde começa um
  menor privilégio que sobrevive a uma auditoria.

**Rode o validador em toda política antes de ela chegar a uma conta**, e o analisador de acesso
externo em toda conta da organização. Neste curso, uma política que o moto obedeceu passou num teste,
e é o mais fraco dos três.
