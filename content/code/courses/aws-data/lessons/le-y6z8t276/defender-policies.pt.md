---
title: Políticas de bucket do lado de quem defende
version: 1
---

**Uma política de bucket é uma política de recurso: ela fica presa ao bucket e diz quem pode fazer o
quê com ele.** Uma política de identidade viaja com um usuário ou um papel; uma política de bucket fica
com os dados, e é o lugar para escrever regras que valem para quem quer que pergunte. O uso de quem
defende é quase sempre `Deny`, porque uma negação explícita vence todo allow em qualquer lugar, como a
lição 8 de `aws-foundations` mostrou. Um `Deny` numa política de bucket é uma regra que a política de
identidade de ninguém consegue contornar.

O bucket curado da Quitanda ganha duas regras assim. A primeira recusa qualquer requisição que não
tenha chegado por TLS. A segunda recusa qualquer identidade de fora da organização da AWS da
Quitanda, para que uma chave de outra conta, que recebeu acesso por um erro em outro lugar, ainda
assim não consiga ler:

`curated-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "OnlyOverTls",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::quitanda-curated-prod",
        "arn:aws:s3:::quitanda-curated-prod/*"
      ],
      "Condition": {"Bool": {"aws:SecureTransport": "false"}}
    },
    {
      "Sid": "OnlyOurOrganisation",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::quitanda-curated-prod",
        "arn:aws:s3:::quitanda-curated-prod/*"
      ],
      "Condition": {"StringNotEquals": {"aws:PrincipalOrgID": "o-quitanda01"}}
    }
  ]
}
```

**`"Principal": "*"` num `Deny` não é acesso público, é o contrário**: diz que a regra vale para todo
mundo. Acesso público é `"Principal": "*"` com `"Effect": "Allow"`, a linha da próxima seção. Cada
instrução cobre dois recursos, o bucket, para ações como listar, e todo objeto dentro dele, para
leituras e escritas. `o-quitanda01` está no lugar do id da organização, que na AWS é `o-` seguido de
dez ou mais caracteres que o Organizations atribui.

Uma terceira regra que vale conhecer substitui a segunda quando o tráfego deve vir só de dentro de
uma VPC: `aws:SourceVpce`, o id de um VPC endpoint, da lição 19 de `aws-foundations`. Um bucket que só
pode ser lido pelo endpoint dele não pode ser lido de um notebook na internet, nem com chaves boas.

## No moto

```
ana@laptop:~/aws$ aws s3api put-bucket-policy --bucket quitanda-curated-prod --policy file://curated-policy.json
ana@laptop:~/aws$ aws s3api get-bucket-policy --bucket quitanda-curated-prod --query Policy --output text | python3 -m json.tool | head -12
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "OnlyOverTls",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::quitanda-curated-prod",
                "arn:aws:s3:::quitanda-curated-prod/*"
            ],
ana@laptop:~/aws$ aws s3 cp s3://quitanda-curated-prod/reports/daily.csv -
download failed: s3://quitanda-curated-prod/reports/daily.csv to - An error occurred (403) when calling the HeadObject operation: Forbidden
```

**O moto guardou a política, e depois recusou a leitura da própria Quitanda.** À primeira vista isso
parece certo: as requisições do laboratório vão ao moto por HTTP simples, então `aws:SecureTransport`
é falso e a primeira instrução deveria negá-las. O jeito de saber se o moto entendeu isso é inverter a
condição, para que a política negue só requisições feitas por TLS, que este laboratório nunca manda:

```
ana@laptop:~/aws$ aws s3api delete-bucket-policy --bucket quitanda-curated-prod
ana@laptop:~/aws$ jq '.Statement |= [.[0] | .Condition.Bool."aws:SecureTransport" = "true"]' curated-policy.json > tls-true.json && jq -c .Statement[0].Condition tls-true.json
{"Bool":{"aws:SecureTransport":"true"}}
ana@laptop:~/aws$ aws s3api put-bucket-policy --bucket quitanda-curated-prod --policy file://tls-true.json
ana@laptop:~/aws$ aws s3 cp s3://quitanda-curated-prod/reports/daily.csv -
download failed: s3://quitanda-curated-prod/reports/daily.csv to - An error occurred (403) when calling the HeadObject operation: Forbidden
ana@laptop:~/aws$ aws s3api delete-bucket-policy --bucket quitanda-curated-prod
ana@laptop:~/aws$ aws s3 cp s3://quitanda-curated-prod/reports/daily.csv -
day,orders,total_cents
2026-10-15,412,5108840
```

**O moto recusou a leitura do mesmo jeito**, sob uma política que na AWS teria deixado passar uma
requisição HTTP simples. Então a recusa de antes não foi o moto lendo a condição; o que quer que o moto
faça com uma `Condition`, não é o que o S3 faz, e uma negação do moto sob uma política condicional não
prova mais do que um sucesso provaria. Apagar a política devolveu a leitura, e o moto deixou o dono
apagá-la mesmo com a política negando `s3:*`.

O que as duas condições fazem na AWS é ensinado pela documentação da AWS sobre as chaves de condição
globais, não por este laboratório. **Um `Deny` com `aws:PrincipalOrgID` também pega serviços da AWS
que agem por você**, como uma entrega de logs ou uma replicação, cuja identidade não está na sua
organização. A correção de costume é uma segunda condição que os deixa passar,
`aws:PrincipalIsAWSService`; uma política que se esquece dela funciona para toda pessoa e quebra o
primeiro serviço que escreve no bucket.
