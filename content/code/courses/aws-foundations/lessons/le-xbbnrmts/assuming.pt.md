---
title: Assumir uma role, e as duas políticas que precisam concordar
version: 1
---

**Assumir uma role é uma requisição como qualquer outra, e ela é julgada pelas duas pontas.** As
próprias políticas de quem chama têm de permitir `sts:AssumeRole` naquela role, e a política de
confiança da role tem de nomear quem chama. Se as duas concordam, o STS devolve uma sessão:
credenciais temporárias que agem com as permissões **da role**, não as de quem chamou. A imagem
errada é que uma role soma as permissões dela às suas. **Uma sessão tem as permissões da role e mais
nada**; o que quem chamou podia fazer antes fica fora da sessão.

A lição 6 fez uma sessão com a verificação do moto desligada, e o moto a entregou a quem a política
de confiança não nomeava. Esta lição liga a verificação e mostra a recusa.

## O começo, como na lição 7

Reinicie o moto no primeiro terminal com a contagem, para que esta lição comece de uma AWS vazia que
julga toda requisição:

```sh
INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567
```

No segundo terminal, as três requisições que criam o `admin`, o `export` para a chave do admin, e as
duas funções da lição 8, `with_key` e `with_session`, digitadas de novo:

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

## Uma role, a confiança dela e as permissões dela

A `deployer` de novo, confiando na bia como no começo da lição 6. Salve a política de confiança como
`~/aws/deployer-trust.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS": "arn:aws:iam::123456789012:user/bia"},
      "Action": "sts:AssumeRole"
    }
  ]
}
```

A role recebe a `AmazonS3FullAccess` da AWS como política de permissões, e as duas pessoas da loja
recebem o que precisam do lado delas. **A política da própria bia permite que ela assuma a
`deployer` e nada mais; o caio tem `AdministratorAccess`**, que permite toda ação, `sts:AssumeRole`
inclusive:

```
ana@laptop:~/aws$ aws iam create-role --role-name deployer --assume-role-policy-document file://deployer-trust.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/deployer
ana@laptop:~/aws$ aws iam attach-role-policy --role-name deployer --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-assets --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/shop-assets
ana@laptop:~/aws$ aws iam create-user --user-name bia --query User.Arn --output text
arn:aws:iam::123456789012:user/bia
ana@laptop:~/aws$ aws iam put-user-policy --user-name bia --policy-name assume-deployer --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"sts:AssumeRole","Resource":"arn:aws:iam::123456789012:role/deployer"}]}'
ana@laptop:~/aws$ bia=$(aws iam create-access-key --user-name bia)
ana@laptop:~/aws$ aws iam create-user --user-name caio --query User.Arn --output text
arn:aws:iam::123456789012:user/caio
ana@laptop:~/aws$ aws iam attach-user-policy --user-name caio --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ caio=$(aws iam create-access-key --user-name caio)
```

**O caio é recusado embora a própria política dele permita tudo.** A política de confiança é a
metade da role no acordo e nomeia só a bia, então um administrador da mesma conta não consegue
vestir a role. O moto julga isso exatamente como a AWS. A bia, nomeada dos dois lados, recebe uma
sessão:

```
ana@laptop:~/aws$ with_key "$caio" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name caio-try

aws: [ERROR]: An error occurred (AccessDenied) when calling the AssumeRole operation: User: arn:aws:iam::123456789012:user/caio is not authorized to perform: sts:AssumeRole
ana@laptop:~/aws$ s=$(with_key "$bia" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name bia-deploy)
ana@laptop:~/aws$ with_session "$s" aws sts get-caller-identity --query Arn --output text
arn:aws:sts::123456789012:assumed-role/deployer/bia-deploy
ana@laptop:~/aws$ with_session "$s" aws s3 ls
2026-10-16 13:53:17 shop-assets
ana@laptop:~/aws$ with_session "$s" aws iam list-users

aws: [ERROR]: An error occurred (AccessDenied) when calling the ListUsers operation: User: arn:aws:sts::123456789012:assumed-role/deployer/bia-deploy is not authorized to perform: iam:ListUsers
```

A sessão é `assumed-role/deployer/bia-deploy`, e carrega as permissões da role: S3, que a
`AmazonS3FullAccess` dá, e não IAM, que nada na role dá. **A política da própria bia não tem papel
nenhum dentro da sessão**: ela permitiu que a bia assumisse a role, e foi só isso que fez.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l09-two-sides\" aria-label=\"Uma requisição AssumeRole julgada pelas duas pontas. À esquerda, a usuária bia, cuja própria política permite que ela assuma a deployer, e o usuário caio, cujo AdministratorAccess permite tudo. No meio, o STS. À direita, a role deployer, com uma política de confiança que nomeia só a bia e a política de permissões AmazonS3FullAccess. A requisição da bia passa nas duas verificações e devolve a sessão assumed-role/deployer/bia-deploy, que pode usar S3 e não IAM. A requisição do caio é recusada, porque a política de confiança não o nomeia.\"><defs><marker id=\"l09-two-sides-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l09-two-sides-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l09-two-sides-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"200.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">user/bia</text><text x=\"120.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a política dela: pode assumir a deployer</text><rect x=\"20.0\" y=\"170.0\" width=\"200.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">user/caio</text><text x=\"120.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a política dele: permite tudo</text><rect x=\"290.0\" y=\"95.0\" width=\"140.0\" height=\"90.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">STS</text><text x=\"360.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">AssumeRole</text><rect x=\"500.0\" y=\"30.0\" width=\"200.0\" height=\"124.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">role/deployer</text><rect x=\"515.0\" y=\"62.0\" width=\"170.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"600.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">confiança: só a bia</text><rect x=\"515.0\" y=\"106.0\" width=\"170.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">AmazonS3FullAccess</text><rect x=\"500.0\" y=\"196.0\" width=\"200.0\" height=\"74.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">assumed-role/deployer/</text><text x=\"600.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">bia-deploy</text><text x=\"600.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">S3 sim, IAM não</text><path d=\"M222.0 80.0 L288.0 118.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-two-sides-af-ah-phosphor)\"></path><path d=\"M222.0 202.0 L288.0 166.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-two-sides-af-ah-amber)\"></path><text x=\"300.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">caio: recusado,</text><text x=\"300.0\" y=\"230.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">fora da confiança</text><path d=\"M432.0 118.0 L498.0 92.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l09-two-sides-af-ah-paper-dim)\"></path><path d=\"M432.0 165.0 L498.0 222.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-two-sides-af-ah-phosphor)\"></path></svg>", "caption": "A política de quem chama permite pedir; a política de confiança da role decide quem é atendido.", "same": ["STS"]}
```

## A conta como principal, e onde o moto difere

Uma política de confiança muitas vezes nomeia uma conta inteira em vez de uma pessoa: `"AWS":
"arn:aws:iam::123456789012:root"`. **Na AWS isso não quer dizer o usuário root.** Quer dizer qualquer
principal daquela conta cujas próprias políticas permitam `sts:AssumeRole` na role. Os
administradores da conta decidem, pelas políticas de identidade, quem pode vesti-la. É o jeito
habitual de confiar em outra conta, como a última seção desta lição mostra.

**O moto não lê assim.** Ele compara o ARN de quem chama com o principal como duas strings.
`user/admin` não bate com `root`, então o admin é recusado numa role cuja política de confiança nomeia a
própria conta dele:

```
ana@laptop:~/aws$ aws iam create-role --role-name readonly --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::123456789012:root"},"Action":"sts:AssumeRole"}]}' --query Role.Arn --output text
arn:aws:iam::123456789012:role/readonly
ana@laptop:~/aws$ aws sts assume-role --role-arn arn:aws:iam::123456789012:role/readonly --role-session-name admin-try

aws: [ERROR]: An error occurred (AccessDenied) when calling the AssumeRole operation: User: arn:aws:iam::123456789012:user/admin is not authorized to perform: sts:AssumeRole
```

A AWS teria dado essa sessão ao admin, já que o `AdministratorAccess` permite a chamada. A mesma
comparação de strings faz com que **uma política de confiança que nomeia uma role não bata com as
sessões dessa role** no moto, o que a próxima seção encontra ao encadear duas roles. No laboratório,
nomeie o usuário ou o ARN de sessão exato numa política de confiança quando quiser que o moto diga
sim.
