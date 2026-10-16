---
title: Limites de permissões, políticas de sessão e delegação
version: 1
---

**Um limite de permissões (permission boundary) é uma política gerenciada definida num usuário ou
numa role como teto: a identidade só pode fazer o que as próprias políticas permitem e o limite
permite, os dois ao mesmo tempo.** É a interseção, nunca a soma. A imagem errada é o limite como mais
uma política que acrescenta permissões; um limite de `s3:*` num usuário sem políticas não dá nada a
esse usuário.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l08-boundary\" aria-label=\"Um limite de permissões como uma interseção. As políticas de identidade de uma role permitem S3 e IAM; o limite de permissões dela permite S3 e CloudWatch Logs. Só a sobreposição, o S3, é permitida: s3:GetObject funciona. iam:ListUsers está nas políticas de identidade e não no limite, então é negada. logs:PutLogEvents está no limite e em política nenhuma, então também é negada: um limite não concede nada.\"><rect x=\"60.0\" y=\"30.0\" width=\"360.0\" height=\"170.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><rect x=\"300.0\" y=\"60.0\" width=\"360.0\" height=\"170.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><rect x=\"300.0\" y=\"60.0\" width=\"120.0\" height=\"140.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"180.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">políticas de identidade</text><text x=\"180.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">permitem S3 e IAM</text><text x=\"180.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">iam:ListUsers</text><text x=\"180.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">negada: fora do limite</text><text x=\"550.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">limite de permissões</text><text x=\"550.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">permite S3 e Logs</text><text x=\"550.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">logs:PutLogEvents</text><text x=\"550.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">negada: nada a concede</text><text x=\"360.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">permitida</text><text x=\"360.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s3:GetObject</text></svg>", "caption": "O que um limite deixa é a sobreposição. Ele tira o que fica fora dele e não acrescenta nada."}
```

## Um limite no moto, e o moto ignorando-o

O limite é uma política gerenciada pelo cliente comum. Aqui ela permite S3 e mais nada:

```
ana@laptop:~/aws$ aws iam create-policy --policy-name s3-only-boundary --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:*","Resource":"*"}]}' --query Policy.Arn --output text
arn:aws:iam::123456789012:policy/s3-only-boundary
ana@laptop:~/aws$ aws iam create-user --user-name dani --permissions-boundary arn:aws:iam::123456789012:policy/s3-only-boundary --query User.PermissionsBoundary
null
ana@laptop:~/aws$ aws iam put-user-permissions-boundary --user-name dani --permissions-boundary arn:aws:iam::123456789012:policy/s3-only-boundary

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
```

**Num usuário, o moto nem o guarda.** O `create-user --permissions-boundary` dá certo e a resposta não
traz limite nenhum, e o `put-user-permissions-boundary`, o comando que define um num usuário
existente, não está implementado: o moto responde HTTP 500 e a linha de comando imprime a página de
erro dele. Numa role, o moto guarda o limite, então a medição é feita com uma role. Ela se chama
`app-admin`, tem `AdministratorAccess`, tem o limite só de S3, e confia no `admin`:

```
ana@laptop:~/aws$ aws iam create-role --role-name app-admin --permissions-boundary arn:aws:iam::123456789012:policy/s3-only-boundary --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::123456789012:user/admin"},"Action":"sts:AssumeRole"}]}' --query Role.PermissionsBoundary
{
    "PermissionsBoundaryType": "PermissionsBoundaryPolicy",
    "PermissionsBoundaryArn": "arn:aws:iam::123456789012:policy/s3-only-boundary"
}
ana@laptop:~/aws$ aws iam attach-role-policy --role-name app-admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ r=$(aws sts assume-role --role-arn arn:aws:iam::123456789012:role/app-admin --role-session-name try-boundary)
ana@laptop:~/aws$ with_session "$r" aws sts get-caller-identity --query Arn --output text
arn:aws:sts::123456789012:assumed-role/app-admin/try-boundary
ana@laptop:~/aws$ with_session "$r" aws iam list-users --query "Users[].UserName" --output text
admin	caio	dani
ana@laptop:~/aws$ with_session "$r" aws s3api list-objects-v2 --bucket shop-assets --query "Contents[].Key" --output text
logo.png
```

**A sessão listou todos os usuários. A AWS teria recusado**: `iam:ListUsers` é permitido pelo
`AdministratorAccess` e não pelo limite, então a interseção não o contém, e a resposta seria um
`AccessDenied` apontando o limite como motivo. A chamada ao S3 teria funcionado nos dois. Essa recusa
não foi rodada aqui, já que o moto guarda limites e nunca os aplica; é o comportamento documentado da
AWS, e o motivo de a figura acima ser desenhada como uma interseção.

## Políticas de sessão, testadas

Uma política de sessão é uma política passada ao `assume-role` com `--policy`, e ela limita aquela
sessão do mesmo jeito que um limite limita uma identidade. É como se entrega uma role de forma mais
estreita para um trabalho, sem criar uma segunda role. **Testada aqui com um `Deny` em toda ação do
IAM, o moto também a ignorou**:

```
ana@laptop:~/aws$ r=$(aws sts assume-role --role-arn arn:aws:iam::123456789012:role/app-admin --role-session-name narrowed --policy '{"Version":"2012-10-17","Statement":[{"Effect":"Deny","Action":"iam:*","Resource":"*"}]}')
ana@laptop:~/aws$ with_session "$r" aws iam list-users --query "Users[].UserName" --output text
admin	caio	dani
```

A AWS recusaria esse `list-users` duas vezes, uma pelo limite e uma pela política de sessão.
**Nenhuma das duas camadas foi rodada aqui**; as duas são ensinadas pela documentação da AWS.

## Delegação: deixar um time criar roles com segurança

Os limites existem para um problema acima de todos. Os desenvolvedores da loja precisam criar roles
para as próprias aplicações, e **quem consegue criar uma role e anexar `AdministratorAccess` a ela
consegue se tornar administrador**: cria a role, confia em si mesmo, assume. Negar `iam:CreateRole`
aos desenvolvedores faz do time de plataforma uma fila para todo serviço novo.

O padrão que a AWS documenta é deixá-los criar roles **só com o limite anexado**, e negar a eles
qualquer jeito de afrouxá-lo. A chave de condição `iam:PermissionsBoundary` é o limite nomeado na
requisição. Salve isto como `~/aws/delegate-roles.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CreateAppRolesOnlyWithTheBoundary",
      "Effect": "Allow",
      "Action": ["iam:CreateRole", "iam:AttachRolePolicy", "iam:PutRolePolicy"],
      "Resource": "arn:aws:iam::123456789012:role/app-*",
      "Condition": {
        "StringEquals": {
          "iam:PermissionsBoundary": "arn:aws:iam::123456789012:policy/app-boundary"
        }
      }
    },
    {
      "Sid": "NeverLoosenTheBoundary",
      "Effect": "Deny",
      "Action": ["iam:DeleteRolePermissionsBoundary", "iam:CreatePolicyVersion", "iam:DeletePolicy", "iam:SetDefaultPolicyVersion"],
      "Resource": [
        "arn:aws:iam::123456789012:role/app-*",
        "arn:aws:iam::123456789012:policy/app-boundary"
      ]
    }
  ]
}
```

**A primeira instrução faz do limite o preço de uma role nova**: um `CreateRole` que não nomeia o
`app-boundary` não tem `Allow`, e é recusado. A segunda impede que o preço seja tomado de volta: nada
de tirar o limite de uma role, e nada de editar ou apagar o próprio limite. Seja o que for que um
desenvolvedor anexe a uma role `app-` depois, mesmo `AdministratorAccess`, o limite põe teto.

O moto não consegue julgar esta política, e no laboratório ele erra para o outro lado. Ele compara
chamadas do IAM com o recurso `*` em vez do ARN da role, então uma instrução restrita a `role/app-*`
nunca bate lá, e ele trata a condição como satisfeita. Com o limite, a política e a bia criados, e a
política anexada a ela, a bia é recusada na única chamada que a AWS permitiria:

```
ana@laptop:~/aws$ aws iam create-policy --policy-name app-boundary --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:*","logs:*"],"Resource":"*"}]}' --query Policy.Arn --output text
arn:aws:iam::123456789012:policy/app-boundary
ana@laptop:~/aws$ aws iam create-policy --policy-name delegate-roles --policy-document file://delegate-roles.json --query Policy.Arn --output text
arn:aws:iam::123456789012:policy/delegate-roles
ana@laptop:~/aws$ aws iam create-user --user-name bia --query User.Arn --output text
arn:aws:iam::123456789012:user/bia
ana@laptop:~/aws$ aws iam attach-user-policy --user-name bia --policy-arn arn:aws:iam::123456789012:policy/delegate-roles
ana@laptop:~/aws$ bia=$(aws iam create-access-key --user-name bia)
ana@laptop:~/aws$ with_key "$bia" aws iam create-role --role-name app-web --permissions-boundary arn:aws:iam::123456789012:policy/app-boundary --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}'

aws: [ERROR]: An error occurred (AccessDenied) when calling the CreateRole operation: User: arn:aws:iam::123456789012:user/bia is not authorized to perform: iam:CreateRole
```

**Uma recusa no moto não prova que uma política está errada, assim como um sucesso não prova que ela
está certa.** Para este padrão, as verificações que contam são as que a última seção aponta, rodadas
contra a AWS.
