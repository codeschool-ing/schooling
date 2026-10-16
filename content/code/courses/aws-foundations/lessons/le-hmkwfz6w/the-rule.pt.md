---
title: Como a AWS decide, numa regra e em dois tipos de camada
version: 1
---

**Toda requisição começa negada. Um `Deny` explícito em qualquer política que se aplique a encerra
ali. Depois, toda camada que só pode limitar tem de permiti-la, e pelo menos uma camada que concede
tem de permiti-la.** A lição 7 mostrou o vocabulário. Esta é a frase para a qual ele foi escrito, e o
resto da lição pega as partes dela uma de cada vez.

A imagem errada é o firewall de novo, agora com um erro a mais: que um `Allow` em algum lugar
sobrepõe um `Deny` em outro, ou que a instrução mais específica vence. **Especificidade não conta
nada.** Um `Deny` em `s3:*` para um bucket vence um `Allow` em `s3:GetObject` para o mesmo bucket, e
vence o `AdministratorAccess`, que permite `*` em `*`.

## Dois tipos de camada

As políticas que podem valer para uma requisição são de dois tipos, e a regra se apoia na
diferença:

| camada | quem a escreve | o que ela pode fazer |
|---|---|---|
| política baseada em identidade (lição 7) | os administradores da conta | **conceder** |
| política baseada em recurso, como a política de um bucket | o dono do recurso | **conceder** |
| service control policy, resource control policy (lição 4) | a organização | só limitar |
| limite de permissões (permission boundary) | um administrador, num usuário ou role | só limitar |
| política de sessão | quem assume uma role, para aquela sessão | só limitar |

**Uma camada que só limita nunca concede nada sozinha.** Uma SCP que permite `s3:*` não dá S3 a
ninguém. Ela diz que o S3 é até onde as políticas da própria conta podem ir. Então uma requisição tem
de passar por toda camada limitadora que existir e encontrar um `Allow` numa camada que concede.
Faltar qualquer um dos dois é uma negação implícita.

**Entre contas, os dois lados têm de conceder.** Quando um principal de uma conta usa um recurso de
outra, duas políticas têm de permiti-lo. A política de identidade de quem chama tem de permitir a
ação, **e** a política do recurso, ou a política de confiança de uma role, tem de permitir quem
chama. Dentro de uma conta, uma camada que
concede basta. Essa regra não foi rodada aqui: o moto não julga políticas baseadas em recurso, como a
última seção mostra.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 510\" role=\"img\" data-fig=\"l08-evaluation\" aria-label=\"Como a AWS julga uma requisição dentro de uma conta, simplificado da documentação dela, com o que o moto verifica marcado à esquerda. A requisição começa negada. Primeiro: há um Deny explícito em alguma política? Se sim, é negada; o moto verifica isso só nas políticas de identidade. Depois: as SCPs e RCPs da organização a permitem? Se não, negada; o moto as ignora. Depois: uma política baseada em identidade ou em recurso a permite? Se não, negada; o moto verifica as de identidade e ignora as de recurso. Depois: o limite de permissões a permite, se houver um? Depois: a política de sessão a permite, se uma foi passada? O moto ignora as duas. Só uma requisição que passa por todos os passos é permitida.\"><defs><marker id=\"l08-evaluation-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08-evaluation-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l08-evaluation-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"85.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">moto</text><rect x=\"170.0\" y=\"30.0\" width=\"300.0\" height=\"40.0\" rx=\"18\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a requisição começa negada</text><rect x=\"560.0\" y=\"98.0\" width=\"130.0\" height=\"324.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"260.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">negada</text><path d=\"M320.0 72.0 L320.0 96.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-evaluation-af-ah-paper-dim)\"></path><rect x=\"170.0\" y=\"98.0\" width=\"300.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um Deny explícito em alguma política?</text><path d=\"M472.0 120.0 L558.0 120.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-evaluation-af-ah-amber)\"></path><text x=\"515.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">sim</text><text x=\"85.0\" y=\"112.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">identidade: verifica</text><text x=\"85.0\" y=\"127.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">recurso: ignora</text><path d=\"M320.0 144.0 L320.0 166.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-evaluation-af-ah-paper-dim)\"></path><text x=\"330.0\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">não</text><rect x=\"170.0\" y=\"168.0\" width=\"300.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">as SCPs e RCPs permitem?</text><text x=\"320.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">numa conta membro</text><path d=\"M472.0 190.0 L558.0 190.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-evaluation-af-ah-amber)\"></path><text x=\"515.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">não</text><text x=\"85.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">ignora</text><path d=\"M320.0 214.0 L320.0 236.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-evaluation-af-ah-paper-dim)\"></path><text x=\"330.0\" y=\"225.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sim</text><rect x=\"170.0\" y=\"238.0\" width=\"300.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"260.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma política de identidade ou de recurso permite?</text><path d=\"M472.0 260.0 L558.0 260.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-evaluation-af-ah-amber)\"></path><text x=\"515.0\" y=\"251.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">não</text><text x=\"85.0\" y=\"252.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">identidade: verifica</text><text x=\"85.0\" y=\"267.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">recurso: ignora</text><path d=\"M320.0 284.0 L320.0 306.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-evaluation-af-ah-paper-dim)\"></path><text x=\"330.0\" y=\"295.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sim</text><rect x=\"170.0\" y=\"308.0\" width=\"300.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"323.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o limite de permissões permite?</text><text x=\"320.0\" y=\"340.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">se houver um</text><path d=\"M472.0 330.0 L558.0 330.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-evaluation-af-ah-amber)\"></path><text x=\"515.0\" y=\"321.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">não</text><text x=\"85.0\" y=\"330.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">ignora</text><path d=\"M320.0 354.0 L320.0 376.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-evaluation-af-ah-paper-dim)\"></path><text x=\"330.0\" y=\"365.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sim</text><rect x=\"170.0\" y=\"378.0\" width=\"300.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"393.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a política de sessão permite?</text><text x=\"320.0\" y=\"410.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">se uma foi passada</text><path d=\"M472.0 400.0 L558.0 400.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-evaluation-af-ah-amber)\"></path><text x=\"515.0\" y=\"391.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">não</text><text x=\"85.0\" y=\"400.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">ignora</text><path d=\"M320.0 424.0 L320.0 452.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-evaluation-af-ah-phosphor)\"></path><text x=\"330.0\" y=\"437.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sim</text><rect x=\"170.0\" y=\"454.0\" width=\"300.0\" height=\"40.0\" rx=\"18\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"320.0\" y=\"474.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">permitida</text></svg>", "caption": "Todo passo só pode recusar; uma requisição é permitida sobrevivendo a todos eles. De todas essas camadas, o moto julga só as políticas de identidade.", "same": ["moto"]}
```

## Os três resultados, no moto

Reinicie o moto no primeiro terminal com a contagem, como a lição 7 fez, para que esta lição comece
de uma AWS vazia com a verificação ligada:

```sh
INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567
```

No segundo terminal, as mesmas três requisições criam o `admin`, e o mesmo `export` passa o terminal
para a chave do admin. A quarta requisição é a prova de que a verificação está ligada:

```
ana@laptop:~/aws$ aws iam create-user --user-name admin --query User.Arn --output text
arn:aws:iam::123456789012:user/admin
ana@laptop:~/aws$ aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ key=$(aws iam create-access-key --user-name admin)
ana@laptop:~/aws$ aws iam list-users

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the ListUsers operation: The security token included in the request is invalid.
ana@laptop:~/aws$ export AWS_ACCESS_KEY_ID=$(echo "$key" | jq -r .AccessKey.AccessKeyId) AWS_SECRET_ACCESS_KEY=$(echo "$key" | jq -r .AccessKey.SecretAccessKey)
ana@laptop:~/aws$ aws sts get-caller-identity --query Arn --output text
arn:aws:iam::123456789012:user/admin
```

Digite de novo o `with_key` da lição 7, e uma segunda função ao lado dele para as sessões de role da
próxima seção. **O `with_session` faz com a resposta do `assume-role` o que o `with_key` faz com a
chave de um usuário**, e leva também o token de sessão:

```sh
with_key() {
  local k=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$k" | jq -r .AccessKey.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$k" | jq -r .AccessKey.SecretAccessKey) "$@"
}
with_session() {
  local c=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$c" | jq -r .Credentials.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$c" | jq -r .Credentials.SecretAccessKey) \
  AWS_SESSION_TOKEN=$(echo "$c" | jq -r .Credentials.SessionToken) "$@"
}
```

O caio, o analista da loja, ganha um usuário, uma chave e mais nada. Dois buckets dão a ele algo para
pedir:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-assets --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/shop-assets
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-backups --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/shop-backups
ana@laptop:~/aws$ aws s3api put-object --bucket shop-assets --key logo.png --query ETag --output text
"d41d8cd98f00b204e9800998ecf8427e"
ana@laptop:~/aws$ aws s3api put-object --bucket shop-backups --key orders-2026-10-15.dump --query ETag --output text
"d41d8cd98f00b204e9800998ecf8427e"
ana@laptop:~/aws$ aws iam create-user --user-name caio --query User.Arn --output text
arn:aws:iam::123456789012:user/caio
ana@laptop:~/aws$ caio=$(aws iam create-access-key --user-name caio)
```

**Sem política nenhuma, tudo é recusado.** Essa é a negação implícita, e ela não precisa de instrução
em lugar nenhum: é onde toda requisição começa.

```
ana@laptop:~/aws$ with_key "$caio" aws s3 ls

aws: [ERROR]: An error occurred (AccessDenied) when calling the ListBuckets operation: Access Denied
ana@laptop:~/aws$ with_key "$caio" aws iam list-users

aws: [ERROR]: An error occurred (AccessDenied) when calling the ListUsers operation: User: arn:aws:iam::123456789012:user/caio is not authorized to perform: iam:ListUsers
```

**Um `Allow` numa camada que concede abre a porta.** A `AmazonS3ReadOnlyAccess` da AWS no usuário do
caio:

```
ana@laptop:~/aws$ aws iam attach-user-policy --user-name caio --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
ana@laptop:~/aws$ with_key "$caio" aws s3 ls
2026-10-16 13:39:04 shop-assets
2026-10-16 13:39:04 shop-backups
ana@laptop:~/aws$ with_key "$caio" aws s3api list-objects-v2 --bucket shop-backups --query "Contents[].Key" --output text
orders-2026-10-15.dump
```

**Um `Deny` explícito fecha de novo, seja o que for que permita.** Os backups não são assunto de um
analista, então uma política inline os nega, enquanto a política gerenciada que permite todo bucket
continua anexada:

```
ana@laptop:~/aws$ aws iam put-user-policy --user-name caio --policy-name no-backups --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Deny","Action":"s3:*","Resource":["arn:aws:s3:::shop-backups","arn:aws:s3:::shop-backups/*"]}]}'
ana@laptop:~/aws$ with_key "$caio" aws s3api list-objects-v2 --bucket shop-assets --query "Contents[].Key" --output text
logo.png
ana@laptop:~/aws$ with_key "$caio" aws s3api list-objects-v2 --bucket shop-backups --query "Contents[].Key" --output text

aws: [ERROR]: An error occurred (AccessDenied) when calling the ListObjectsV2 operation: Access Denied
```

O `shop-assets` continua listando, porque nada o nega; o `shop-backups` é recusado, porque algo nega.
**Esta parte o moto julga exatamente como a AWS**, e é a parte que mais importa. Um `Deny` é como se
escreve uma barreira de proteção, porque nenhum `Allow` acrescentado depois a desfaz; só remover o
`Deny` desfaz.
