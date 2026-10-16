---
title: Permission sets, usuários, grupos e atribuições, montados no moto
version: 1
---

**Tudo o que um administrador faz no Identity Center é uma chamada de API, e o moto responde a
maioria delas.** Esta seção monta o arranjo da loja pela linha de comando: duas contas, dois
permission sets, duas pessoas em dois grupos, e três atribuições. Ela também mede o único passo que
o moto deixa de fora, que é a role que uma atribuição deveria criar.

Reinicie o moto no primeiro terminal (Ctrl+C, depois `moto_server -p 4567`) para que esta lição
comece de uma AWS vazia. Nada aqui precisa da verificação de permissões do moto. Pergunte primeiro
se existe um Identity Center:

```
ana@laptop:~/aws$ aws sso-admin list-instances --query "Instances[].[InstanceArn,IdentityStoreId,Status]" --output text
arn:aws:sso:::instance/ssoins-o3rwaaubjxq19hji	d-2mpgvds33k	ACTIVE
```

**O moto já tem um, antes de qualquer coisa ser criada.** Na AWS, o Identity Center é habilitado uma
vez, na conta de gerenciamento da organização, e isso cria uma **instância de organização**: o ARN
`ssoins-` que todo comando abaixo nomeia, e um **identity store**, o id `d-`, que é o diretório do
Identity Center da seção anterior. Existem também instâncias de conta, que servem aplicações e não
dão acesso a contas da AWS; este curso não as usa.

## Duas contas para dar acesso

As atribuições apontam para contas da organização, então crie a organização e as duas contas em que
as pessoas da loja trabalham. A lição 3 montou a árvore inteira; esta lição precisa de duas folhas
dela:

```
ana@laptop:~/aws$ aws organizations create-organization --feature-set ALL --query Organization.Id --output text
o-3bdzmumold
ana@laptop:~/aws$ aws organizations create-account --account-name shop-prod --email aws+shop-prod@example.com --query CreateAccountStatus.[State,AccountId] --output text
SUCCEEDED	834307267662
ana@laptop:~/aws$ aws organizations create-account --account-name shop-staging --email aws+shop-staging@example.com --query CreateAccountStatus.[State,AccountId] --output text
SUCCEEDED	132607488945
ana@laptop:~/aws$ PROD=$(aws organizations list-accounts --query "Accounts[?Name==\`shop-prod\`].Id" --output text)
ana@laptop:~/aws$ STAGING=$(aws organizations list-accounts --query "Accounts[?Name==\`shop-staging\`].Id" --output text)
ana@laptop:~/aws$ echo $PROD $STAGING
834307267662 132607488945
```

Os ids que o moto inventa vão ser outros na sua execução. **As variáveis os carregam**, então todo
comando seguinte pode ser digitado exatamente como está impresso aqui. Guarde a instância e o store
em mais duas:

```
ana@laptop:~/aws$ INSTANCE=$(aws sso-admin list-instances --query "Instances[0].InstanceArn" --output text)
ana@laptop:~/aws$ STORE=$(aws sso-admin list-instances --query "Instances[0].IdentityStoreId" --output text)
```

## Um permission set é uma role, escrita uma vez

A loja precisa de dois tipos de acesso. `ReadOnly` é para olhar a produção: a política gerenciada
`ReadOnlyAccess` da AWS, mais uma recusa escrita inline, porque os backups guardam dados de clientes
e ler tudo não deve incluí-los. Salve a recusa como `~/aws/no-backups.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::shop-backups/*"
    }
  ]
}
```

```
ana@laptop:~/aws$ READONLY=$(aws sso-admin create-permission-set --instance-arn $INSTANCE --name ReadOnly --session-duration PT4H --description "Read everything, change nothing" --query PermissionSet.PermissionSetArn --output text)
ana@laptop:~/aws$ echo $READONLY
arn:aws:sso:::instance/ssoins-o3rwaaubjxq19hji/ps-4vulirahzinwsp7f
ana@laptop:~/aws$ aws sso-admin attach-managed-policy-to-permission-set --instance-arn $INSTANCE --permission-set-arn $READONLY --managed-policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess
ana@laptop:~/aws$ aws sso-admin put-inline-policy-to-permission-set --instance-arn $INSTANCE --permission-set-arn $READONLY --inline-policy file://no-backups.json
ana@laptop:~/aws$ aws sso-admin describe-permission-set --instance-arn $INSTANCE --permission-set-arn $READONLY --query "PermissionSet.[Name,SessionDuration]" --output text
ReadOnly	PT4H
```

**`--session-duration` é quanto a sessão dura depois de aberta**, escrito como uma duração ISO 8601:
`PT4H` são quatro horas, e a AWS aceita de uma a doze. Um permission set leva os mesmos três tipos de
política que uma role, como a lição 7 os descreveu: as gerenciadas pela AWS como `ReadOnlyAccess`,
as gerenciadas pelo cliente referidas pelo nome, e uma política inline. O segundo permission set é
`Developer`, a `PowerUserAccess` da AWS, por oito horas em staging:

```
ana@laptop:~/aws$ DEVELOPER=$(aws sso-admin create-permission-set --instance-arn $INSTANCE --name Developer --session-duration PT8H --query PermissionSet.PermissionSetArn --output text)
ana@laptop:~/aws$ aws sso-admin attach-managed-policy-to-permission-set --instance-arn $INSTANCE --permission-set-arn $DEVELOPER --managed-policy-arn arn:aws:iam::aws:policy/PowerUserAccess
```

A `PowerUserAccess` permite tudo menos gerenciar o IAM e a organização, que é a linha de costume
entre construir numa conta e governá-la.

## Pessoas e grupos no identity store

O identity store é uma API separada, `identitystore`, e não sabe nada de contas nem de políticas:
só de usuários, grupos e de quem pertence a qual. **Atribua a grupos, nunca a pessoas uma a uma**,
para que um desenvolvedor novo seja uma associação a um grupo em vez de três atribuições:

```
ana@laptop:~/aws$ BIA=$(aws identitystore create-user --identity-store-id $STORE --user-name bia --display-name "Bia" --name GivenName=Bia,FamilyName=Lima --emails Value=bia@example.com,Type=work,Primary=true --query UserId --output text)
ana@laptop:~/aws$ CAIO=$(aws identitystore create-user --identity-store-id $STORE --user-name caio --display-name "Caio" --name GivenName=Caio,FamilyName=Souza --emails Value=caio@example.com,Type=work,Primary=true --query UserId --output text)
ana@laptop:~/aws$ DEVS=$(aws identitystore create-group --identity-store-id $STORE --display-name developers --query GroupId --output text)
ana@laptop:~/aws$ DATA=$(aws identitystore create-group --identity-store-id $STORE --display-name data --query GroupId --output text)
ana@laptop:~/aws$ aws identitystore create-group-membership --identity-store-id $STORE --group-id $DEVS --member-id UserId=$BIA --query MembershipId --output text
492337fd-2fa7-45a1-8ba3-42c28d572501
ana@laptop:~/aws$ aws identitystore create-group-membership --identity-store-id $STORE --group-id $DATA --member-id UserId=$CAIO --query MembershipId --output text
0d28d709-e5ee-4cb5-bae4-d1355bd8570f
ana@laptop:~/aws$ aws identitystore list-users --identity-store-id $STORE --query "Users[].[UserName,UserId]" --output text
bia	25741175-c2a9-4054-83e8-0354a8048314
caio	aa4a644c-4e4e-4278-aae3-5b7c94f2b655
ana@laptop:~/aws$ aws identitystore list-groups --identity-store-id $STORE --query "Groups[].[DisplayName,GroupId]" --output text
developers	67306502-6c80-4049-951f-a3687c3539c9
data	cdcd7a46-ca7b-4c2a-a37b-31a63fa15b16
```

Com um provedor de identidade externo e SCIM, nenhum desses comandos seria digitado: os usuários,
os grupos e as associações chegariam do Google. Tudo daqui em diante é igual nos dois casos.

## Três atribuições

Uma atribuição é a trinca da seção anterior: **um principal, um permission set, uma conta**. Os
developers recebem `Developer` em staging e `ReadOnly` em produção; o grupo data recebe `ReadOnly`
em produção:

```
ana@laptop:~/aws$ aws sso-admin create-account-assignment --instance-arn $INSTANCE --target-type AWS_ACCOUNT --target-id $STAGING --permission-set-arn $DEVELOPER --principal-type GROUP --principal-id $DEVS --query AccountAssignmentCreationStatus.Status --output text
SUCCEEDED
ana@laptop:~/aws$ aws sso-admin create-account-assignment --instance-arn $INSTANCE --target-type AWS_ACCOUNT --target-id $PROD --permission-set-arn $READONLY --principal-type GROUP --principal-id $DEVS --query AccountAssignmentCreationStatus.Status --output text
SUCCEEDED
ana@laptop:~/aws$ aws sso-admin create-account-assignment --instance-arn $INSTANCE --target-type AWS_ACCOUNT --target-id $PROD --permission-set-arn $READONLY --principal-type GROUP --principal-id $DATA --query AccountAssignmentCreationStatus.Status --output text
SUCCEEDED
ana@laptop:~/aws$ aws sso-admin list-account-assignments --instance-arn $INSTANCE --account-id $PROD --permission-set-arn $READONLY --query "AccountAssignments[].[PrincipalType,PrincipalId]" --output text
GROUP	67306502-6c80-4049-951f-a3687c3539c9
GROUP	cdcd7a46-ca7b-4c2a-a37b-31a63fa15b16
```

Na AWS essa chamada é assíncrona: ela responde `IN_PROGRESS`, e
`describe-account-assignment-creation-status` informa `SUCCEEDED` quando a role já existe na conta.
O moto responde `SUCCEEDED` na hora. A listagem nomeia os dois grupos pelos ids, os mesmos que o
`list-groups` imprimiu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l11-assignments\" aria-label=\"As três atribuições como uma grade de grupos contra contas. Developers, com a Bia: ReadOnly em shop-prod e Developer em shop-staging. Data, com o Caio: ReadOnly em shop-prod e nada em shop-staging. Cada célula preenchida é uma atribuição, e uma role que o Identity Center cria naquela conta.\"><text x=\"140.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">grupo</text><rect x=\"265.0\" y=\"24.0\" width=\"190.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">shop-prod</text><rect x=\"485.0\" y=\"24.0\" width=\"190.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">shop-staging</text><rect x=\"40.0\" y=\"82.0\" width=\"200.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">developers</text><text x=\"140.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bia</text><rect x=\"40.0\" y=\"162.0\" width=\"200.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">data</text><text x=\"140.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">caio</text><rect x=\"265.0\" y=\"82.0\" width=\"190.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ReadOnly</text><text x=\"360.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma atribuição</text><rect x=\"485.0\" y=\"82.0\" width=\"190.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"580.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Developer</text><text x=\"580.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma atribuição</text><rect x=\"265.0\" y=\"162.0\" width=\"190.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ReadOnly</text><text x=\"360.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma atribuição</text><rect x=\"485.0\" y=\"162.0\" width=\"190.0\" height=\"56.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"580.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">sem acesso</text><text x=\"360.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">cada célula preenchida: um grupo, um permission set, uma conta, e uma role lá</text></svg>", "caption": "Uma atribuição é uma célula desta grade. Um novo desenvolvedor entra numa linha, e recebe todas as células dela."}
```

## O passo que o moto deixa de fora

Se a atribuição funcionasse como na AWS, `shop-prod` teria agora uma role chamada
`AWSReservedSSO_ReadOnly_…`. Olhe dentro da conta, pela role que a lição 3 mostrou que o moto cria
em toda conta nova. O `--query` transforma as três credenciais que o `assume-role` devolve em três
palavras `NOME=valor`, e o `env` roda o `list-roles` com elas:

```
ana@laptop:~/aws$ env $(aws sts assume-role --role-arn arn:aws:iam::$PROD:role/OrganizationAccountAccessRole --role-session-name ana --query "Credentials.[join(\`=\`,[\`AWS_ACCESS_KEY_ID\`,AccessKeyId]),join(\`=\`,[\`AWS_SECRET_ACCESS_KEY\`,SecretAccessKey]),join(\`=\`,[\`AWS_SESSION_TOKEN\`,SessionToken])]" --output text) aws iam list-roles --query "Roles[].RoleName" --output text
OrganizationAccountAccessRole
ana@laptop:~/aws$ aws sso-admin list-permission-sets-provisioned-to-account --instance-arn $INSTANCE --account-id $PROD
{
    "PermissionSets": []
}
```

**O moto registra as atribuições e não provisiona nada.** A conta guarda só a role que o moto criou
quando a conta foi criada, e o `list-permission-sets-provisioned-to-account` responde uma lista
vazia onde a AWS nomearia `ReadOnly`. Então o laboratório consegue montar e inspecionar todo o lado
administrativo do Identity Center, e não consegue mostrar uma pessoa usando-o: a role, o portal e o
login são comportamento documentado da AWS, descrito na seção anterior e na próxima.
