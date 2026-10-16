---
title: Políticas gerenciadas, as da AWS e as da própria loja
version: 1
---

**Uma política gerenciada é uma política que existe por conta própria, com um ARN, e é anexada a
quantos usuários, grupos e roles precisarem dela.** Há dois donos. As políticas **gerenciadas pela
AWS** são escritas e editadas pela AWS e são as mesmas em toda conta. As **gerenciadas pelo
cliente** são escritas por você e moram numa conta. As duas são anexadas em vez de embutidas, as
duas guardam versões, e mudar uma muda as permissões de tudo a que ela está anexada, de uma vez.

## Gerenciadas pela AWS: uma biblioteca que outra pessoa mantém

A variável `MOTO_IAM_LOAD_MANAGED_POLICIES=true` do `env.sh` é o que faz o moto carregar a
biblioteca da AWS. Ela é grande:

```
ana@laptop:~/aws$ aws iam list-policies --scope AWS --query "length(Policies)"
1544
```

**O ARN de uma política gerenciada pela AWS tem `aws` onde estaria a conta**, e é assim que uma
política em qualquer conta consegue nomeá-la. `ReadOnlyAccess` é uma escolha comum para um auditor
ou um painel, e a versão padrão dela diz com que frequência a AWS edita essas políticas:

```
ana@laptop:~/aws$ aws iam get-policy --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess --query "Policy.[DefaultVersionId,CreateDate,UpdateDate]" --output text
v188	2015-02-06T18:39:48+00:00	2026-07-21T18:42:30+00:00
```

**Versão 188**, de uma política criada em 2015 e alterada pela última vez em julho de 2026. Todo
serviço novo da AWS acrescenta linhas a ela, e as contas que a anexaram as recebem sem fazer nada. A
versão padrão, resumida:

```
ana@laptop:~/aws$ aws iam get-policy-version --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess --version-id v188 --query "PolicyVersion.Document.Statement[].{Sid:Sid,Actions:length(Action),Resource:Resource}" --output table
-----------------------------------------------------------------
|                       GetPolicyVersion                        |
+---------+-----------+-----------------------------------------+
| Actions | Resource  |                   Sid                   |
+---------+-----------+-----------------------------------------+
|  1510   |  *        |  ReadOnlyActionsGroup1                  |
|  1403   |  *        |  ReadOnlyActionsGroup2                  |
|  1      |  *        |  S3ExpressReadOnlySessionObjectAccess   |
+---------+-----------+-----------------------------------------+
ana@laptop:~/aws$ aws iam get-policy-version --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess --version-id v188 --query "PolicyVersion.Document.Statement[1].Action[?starts_with(@, \`s3:\`)]"
[
    "s3:DescribeJob",
    "s3:Get*",
    "s3:List*"
]
```

Quase três mil padrões de ação, em todo recurso. **"Somente leitura" é uma promessa sobre gravar,
não sobre ler**. As linhas do S3 são `s3:Get*` e `s3:List*`, então quem tem esta política lê todo
objeto de todo bucket da conta, os backups inclusive. Uma política gerenciada pela AWS é um ponto
de partida escrito para todo mundo, e não serve exatamente a ninguém.

## Gerenciadas pelo cliente: as da própria loja

A política da bia da primeira seção vira uma política gerenciada pelo cliente, anexada ao usuário
dela. Todo comando abaixo roda como `admin`, a identidade do terminal desde a seção anterior.
Primeiro os buckets e um objeto para ler, depois a política:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-assets --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/shop-assets
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-backups --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/shop-backups
ana@laptop:~/aws$ aws s3api put-object --bucket shop-assets --key logo.txt --body logo.txt --query ETag --output text
"98d8d6a239ae64c6f2fc402b7a7847d8"
ana@laptop:~/aws$ aws iam create-policy --policy-name shop-assets-rw --policy-document file://shop-assets-rw.json
{
    "Policy": {
        "PolicyName": "shop-assets-rw",
        "PolicyId": "ANY1RC7G7SWA55JH6P6JQ",
        "Arn": "arn:aws:iam::123456789012:policy/shop-assets-rw",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 0,
        "IsAttachable": true,
        "CreateDate": "2026-10-16T16:23:27.399209+00:00",
        "UpdateDate": "2026-10-16T16:23:27.399211+00:00"
    }
}
```

**O ARN tem a conta da loja**, `123456789012`, e `DefaultVersionId` é `v1`. Agora a bia, a
política dela e uma chave para ela, guardada na variável `bia` para o `with_key`:

```
ana@laptop:~/aws$ aws iam create-user --user-name bia --query User.Arn --output text
arn:aws:iam::123456789012:user/bia
ana@laptop:~/aws$ aws iam attach-user-policy --user-name bia --policy-arn arn:aws:iam::123456789012:policy/shop-assets-rw
ana@laptop:~/aws$ bia=$(aws iam create-access-key --user-name bia)
```

Depois a bia, um comando por vez. **O que a política nomeia funciona, e todo o resto é recusado**:

```
ana@laptop:~/aws$ with_key "$bia" aws sts get-caller-identity --query Arn --output text
arn:aws:iam::123456789012:user/bia
ana@laptop:~/aws$ with_key "$bia" aws s3api list-objects-v2 --bucket shop-assets --query "Contents[].Key" --output text
logo.txt
ana@laptop:~/aws$ with_key "$bia" aws s3 cp s3://shop-assets/logo.txt -
logo
ana@laptop:~/aws$ with_key "$bia" aws s3api put-object --bucket shop-assets --key banner.txt --body logo.txt --query ETag --output text
"98d8d6a239ae64c6f2fc402b7a7847d8"
ana@laptop:~/aws$ with_key "$bia" aws s3api list-objects-v2 --bucket shop-backups

aws: [ERROR]: An error occurred (AccessDenied) when calling the ListObjectsV2 operation: Access Denied
ana@laptop:~/aws$ with_key "$bia" aws s3 ls

aws: [ERROR]: An error occurred (AccessDenied) when calling the ListBuckets operation: Access Denied
ana@laptop:~/aws$ with_key "$bia" aws s3api delete-object --bucket shop-assets --key logo.txt

aws: [ERROR]: An error occurred (AccessDenied) when calling the DeleteObject operation: Access Denied
ana@laptop:~/aws$ with_key "$bia" aws iam list-users

aws: [ERROR]: An error occurred (AccessDenied) when calling the ListUsers operation: User: arn:aws:iam::123456789012:user/bia is not authorized to perform: iam:ListUsers
```

**Leia as recusas, porque elas não são iguais.** O IAM nomeia o usuário e a ação, que é exatamente
o que quem depura precisa. O S3 diz `Access Denied` e mais nada, ao listar `shop-backups`, ao listar
os buckets e ao apagar o logo. A política nunca mencionou `s3:ListAllMyBuckets` nem
`s3:DeleteObject`, então nada os permitiu. O `sts get-caller-identity` responde a qualquer um, o que
a AWS documenta e o moto copia: ele revela apenas quem você é.

`aws s3 ls s3://shop-assets` seria o comando óbvio para listar. Ele não é usado aqui porque **o moto
responde a ele com `SignatureDoesNotMatch` seja quem for que assine**, admin inclusive: o
delimitador `/` que o comando envia atrapalha a verificação de assinatura do moto. O `s3api
list-objects-v2` não envia nenhum e é julgado normalmente:

```
ana@laptop:~/aws$ aws s3 ls s3://shop-assets

aws: [ERROR]: An error occurred (SignatureDoesNotMatch) when calling the ListObjectsV2 operation: The request signature we calculated does not match the signature you provided. Check your key and signing method.
ana@laptop:~/aws$ aws s3api list-objects-v2 --bucket shop-assets --query "Contents[].Key" --output text
banner.txt	logo.txt
```

Contra a AWS os dois funcionam.

## Versões, e o limite de cinco

Editar uma política gerenciada pelo cliente não a sobrescreve. **Cada edição é uma versão nova**, e
uma versão por vez é a padrão, a que a AWS lê. A política da loja ganha mais quatro versões, aqui
idênticas à primeira, e então se tenta uma sexta:

```
ana@laptop:~/aws$ for i in 2 3 4 5; do aws iam create-policy-version --policy-arn arn:aws:iam::123456789012:policy/shop-assets-rw --policy-document file://shop-assets-rw.json --query "PolicyVersion.[VersionId,IsDefaultVersion]" --output text; done
v2	False
v3	False
v4	False
v5	False
ana@laptop:~/aws$ aws iam create-policy-version --policy-arn arn:aws:iam::123456789012:policy/shop-assets-rw --policy-document file://shop-assets-rw.json

aws: [ERROR]: An error occurred (LimitExceeded) when calling the CreatePolicyVersion operation: A managed policy can have up to 5 versions. Before you create a new version, you must delete an existing version.
ana@laptop:~/aws$ aws iam delete-policy-version --policy-arn arn:aws:iam::123456789012:policy/shop-assets-rw --version-id v1

aws: [ERROR]: An error occurred (DeleteConflict) when calling the DeletePolicyVersion operation: Cannot delete the default version of a policy.
```

**Uma política gerenciada guarda no máximo cinco versões**, e o moto aplica isso como a AWS. A
padrão não pode ser apagada, então o caminho é apagar uma antiga, o que abre espaço para a `v6`. Depois
o `set-default-policy-version` move a padrão para lá e para cá:

```
ana@laptop:~/aws$ aws iam delete-policy-version --policy-arn arn:aws:iam::123456789012:policy/shop-assets-rw --version-id v2
ana@laptop:~/aws$ aws iam create-policy-version --policy-arn arn:aws:iam::123456789012:policy/shop-assets-rw --policy-document file://shop-assets-rw.json --set-as-default --query "PolicyVersion.[VersionId,IsDefaultVersion]" --output text
v6	True
ana@laptop:~/aws$ aws iam set-default-policy-version --policy-arn arn:aws:iam::123456789012:policy/shop-assets-rw --version-id v1
ana@laptop:~/aws$ aws iam list-policy-versions --policy-arn arn:aws:iam::123456789012:policy/shop-assets-rw --query "Versions[].[VersionId,IsDefaultVersion]" --output text
v1	True
v3	False
v4	False
v5	False
v6	False
```

**É para isso que servem as versões: uma edição ruim se desfaz movendo a padrão de volta**, sem
documento para reconstruir e sem nada desanexado. O `--set-as-default` no `create-policy-version`
torna a versão nova a ativa na mesma chamada. Sem ele, uma versão nova fica esperando, sem uso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l07-three-kinds\" aria-label=\"Onde mora cada tipo de política. À esquerda, fora da conta da loja, a biblioteca da AWS: a política gerenciada pela AWS ReadOnlyAccess, na versão v188 e editada pela AWS, anexada ao usuário caio dentro da conta da loja. Dentro da conta 123456789012, a política gerenciada pelo cliente shop-assets-rw, com até cinco versões e uma padrão, anexada ao mesmo tempo à usuária bia, ao grupo developers e à role deployer. Embaixo à direita, o usuário edu com uma política inline embutida nele, que não tem ARN e é apagada junto com o edu.\"><defs><marker id=\"l07-three-kinds-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l07-three-kinds-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"200.0\" height=\"120.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"120.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">gerenciada pela AWS</text><rect x=\"40.0\" y=\"70.0\" width=\"160.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ReadOnlyAccess</text><text x=\"120.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">v188, editada pela AWS</text><text x=\"120.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">a mesma em toda conta</text><rect x=\"250.0\" y=\"20.0\" width=\"450.0\" height=\"290.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"266.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">account 123456789012</text><text x=\"365.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">gerenciada pelo cliente</text><rect x=\"280.0\" y=\"72.0\" width=\"170.0\" height=\"66.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"365.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-assets-rw</text><text x=\"365.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">até 5 versões, 1 padrão</text><rect x=\"530.0\" y=\"55.0\" width=\"150.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">user/bia</text><path d=\"M452.0 105.0 L528.0 70.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-three-kinds-af-ah-amber)\"></path><rect x=\"530.0\" y=\"95.0\" width=\"150.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">group/developers</text><path d=\"M452.0 105.0 L528.0 110.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-three-kinds-af-ah-amber)\"></path><rect x=\"530.0\" y=\"135.0\" width=\"150.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">role/deployer</text><path d=\"M452.0 105.0 L528.0 150.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-three-kinds-af-ah-amber)\"></path><rect x=\"280.0\" y=\"175.0\" width=\"170.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"365.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">user/caio</text><path d=\"M120.0 127.0 L120.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M120.0 160.0 L120.0 190.0 L250.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M250.0 190.0 L278.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-three-kinds-af-ah-paper-dim)\"></path><text x=\"185.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">anexada</text><rect x=\"470.0\" y=\"205.0\" width=\"210.0\" height=\"90.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">user/edu</text><rect x=\"490.0\" y=\"236.0\" width=\"170.0\" height=\"46.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"575.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">política inline, sem ARN</text><text x=\"575.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">apagada junto com o edu</text></svg>", "caption": "Uma política gerenciada pela AWS é compartilhada por toda conta, uma gerenciada pelo cliente por tudo a que está anexada, e uma inline por nada."}
```
