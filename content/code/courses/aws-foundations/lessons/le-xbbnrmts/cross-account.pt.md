---
title: Entre contas, e com um terceiro
version: 1
---

**Uma role é como uma conta deixa entrar um principal de outra, e é o único jeito que não deixa
credencial de longo prazo para trás.** A role mora na conta em que se entra, e a política de confiança
dela nomeia a outra conta, ou um principal nela. As políticas da própria outra conta decidem quais
dos seus principais podem usar a porta. Os dois lados concedem, como a regra entre contas da lição 8
disse, e aqui a política de confiança é a metade do recurso.

## Da conta de gerenciamento para a shop-prod

A lição 3 montou a organização da loja. Aqui uma conta membro basta:

```
ana@laptop:~/aws$ aws organizations create-organization --feature-set ALL --query Organization.MasterAccountId --output text
123456789012
ana@laptop:~/aws$ aws organizations create-account --account-name shop-prod --email aws+shop-prod@example.com --query "CreateAccountStatus.[AccountName,State,AccountId]" --output text
shop-prod	SUCCEEDED	855386161245
```

Toda conta que o `create-account` cria vem com uma role chamada `OrganizationAccountAccessRole`, cuja
política de confiança nomeia a conta de gerenciamento, `arn:aws:iam::123456789012:root`. **Esse
principal é a conta, não o usuário root dela**: dentro da conta de gerenciamento, uma política de
identidade decide quem pode usar a role. O `AdministratorAccess` do admin permite, e a política da
bia nomeia só a `deployer`. O número da conta nova vai para uma variável, `prod`, porque o seu vai
ser diferente do daqui:

```
ana@laptop:~/aws$ prod=$(aws organizations list-accounts --query "Accounts[?Name==\`shop-prod\`].Id" --output text)
ana@laptop:~/aws$ s=$(aws sts assume-role --role-arn arn:aws:iam::$prod:role/OrganizationAccountAccessRole --role-session-name ana-admin)
ana@laptop:~/aws$ with_session "$s" aws sts get-caller-identity
{
    "UserId": "AROA4OKH5ABOZYSBAWRQ4:ana-admin",
    "Account": "855386161245",
    "Arn": "arn:aws:sts::855386161245:assumed-role/OrganizationAccountAccessRole/ana-admin"
}
ana@laptop:~/aws$ with_session "$s" aws ec2 describe-vpcs

aws: [ERROR]: An error occurred (AccessDenied) when calling the DescribeVpcs operation: User: arn:aws:sts::855386161245:assumed-role/OrganizationAccountAccessRole/ana-admin is not authorized to perform: ec2:DescribeVpcs
ana@laptop:~/aws$ with_key "$bia" aws sts assume-role --role-arn arn:aws:iam::$prod:role/OrganizationAccountAccessRole --role-session-name bia-try

aws: [ERROR]: An error occurred (AccessDenied) when calling the AssumeRole operation: User: arn:aws:iam::123456789012:user/bia is not authorized to perform: sts:AssumeRole
```

**O ARN da sessão leva o número da outra conta**, e tudo o que ela faz acontece lá. Na AWS essa
sessão seria administradora da `shop-prod`, porque a AWS anexa `AdministratorAccess` à role que cria.
O moto cria a role sem política nenhuma, então a sessão é recusada até numa lista de VPCs. A AWS teria
respondido. A bia foi recusada do lado dela, antes de a política de confiança ser lida, e o moto
julga essa metade como a AWS.

**A outra metade, o moto não julga entre contas.** Pedido de uma role numa conta que não existe, ele
entregou uma sessão do mesmo jeito:

```
ana@laptop:~/aws$ aws sts assume-role --role-arn arn:aws:iam::111122223333:role/OrganizationAccountAccessRole --role-session-name nowhere --query AssumedRoleUser.Arn --output text
arn:aws:sts::111122223333:assumed-role/OrganizationAccountAccessRole/nowhere
```

Então uma sessão entre contas no laboratório prova que o lado de quem chama permitiu a chamada, e
nada sobre a política de confiança do outro lado. A AWS teria respondido a esse pedido com um erro;
isso não foi rodado contra a AWS.

**Confiar numa conta inteira é largo.** Qualquer um cujas políticas de identidade permitam
`sts:AssumeRole` na role entra, então a role é tão estreita quanto a política mais larga da conta de
gerenciamento. A forma mais apertada nomeia uma role lá, `arn:aws:iam::123456789012:role/platform-admin`,
para que só sessões dessa role passem. Essa forma não foi rodada aqui.

## Um terceiro, e o confused deputy

Uma empresa de monitoramento lê as métricas da loja a partir da própria conta AWS, `444455556666`,
por meio de uma role na conta da loja. **O perigo não é a empresa; são os outros clientes dela.** A
empresa assume roles em centenas de contas, por instrução dos clientes. Se outro cliente descobre o
ARN da role da loja e o digita no console da empresa como se fosse dele, a empresa assume a role da
loja em nome desse cliente. A empresa é o **confused deputy** (o representante confuso): ela tem a
permissão, e outra pessoa escolheu como usá-la.

**O external id é a correção**: um valor que a empresa gera para cada cliente e envia em todo
`AssumeRole` que faz para aquele cliente. A política de confiança da loja só aceita a empresa quando o
valor é o da própria loja. Outro cliente não consegue fazer a empresa enviar o id da loja, porque a
empresa envia o id de quem a está configurando.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l09-confused-deputy\" aria-label=\"O confused deputy, e o external id que o impede. À esquerda, outro cliente da empresa de monitoramento. No meio, a conta da empresa de monitoramento 444455556666. À direita, a conta da loja 123456789012 com a role monitoring, que só aceita a empresa com o external id shop-7f3k92. Passo 1: o outro cliente dá à empresa o ARN da role da loja como se fosse dele. Passo 2: a empresa assume essa role enviando o external id do próprio outro cliente, e é recusada. Passo 3: quando quem configurou é a loja, a empresa envia shop-7f3k92 e é permitida.\"><defs><marker id=\"l09-confused-deputy-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l09-confused-deputy-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"150.0\" height=\"110.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">outro cliente</text><text x=\"95.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">digita o ARN</text><text x=\"95.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">da role da loja</text><rect x=\"290.0\" y=\"40.0\" width=\"130.0\" height=\"230.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">empresa de</text><text x=\"355.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">monitoramento</text><text x=\"355.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">444455556666</text><rect x=\"560.0\" y=\"40.0\" width=\"140.0\" height=\"230.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a loja</text><text x=\"630.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">123456789012</text><rect x=\"572.0\" y=\"100.0\" width=\"116.0\" height=\"64.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">role/monitoring</text><text x=\"630.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">exige o id</text><text x=\"630.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">shop-7f3k92</text><path d=\"M172.0 100.0 L288.0 100.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-confused-deputy-af-ah-amber)\"></path><text x=\"230.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">1 · o ARN da loja</text><path d=\"M422.0 125.0 L570.0 125.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-confused-deputy-af-ah-amber)\"></path><text x=\"496.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">2 · o id deles</text><text x=\"496.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">recusado</text><path d=\"M422.0 220.0 L560.0 187.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M560.0 187.0 L600.0 166.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-confused-deputy-af-ah-phosphor)\"></path><text x=\"491.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">3 · shop-7f3k92</text><text x=\"491.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">quando a loja configurou</text></svg>", "caption": "A empresa tem a permissão. O external id garante que é a loja quem escolhe como ela é usada."}
```

Num arranjo real o principal é a conta da empresa, `arn:aws:iam::444455556666:root`, e o laboratório
não tem essa conta com alguém dentro para assinar. Então o laboratório faz o papel da empresa com um
usuário chamado `vendor` na própria conta da loja, e a política de confiança nomeia esse usuário.
Salve-a como `~/aws/monitoring-trust.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS": "arn:aws:iam::123456789012:user/vendor"},
      "Action": "sts:AssumeRole",
      "Condition": {"StringEquals": {"sts:ExternalId": "shop-7f3k92"}}
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam create-role --role-name monitoring --assume-role-policy-document file://monitoring-trust.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/monitoring
ana@laptop:~/aws$ aws iam create-user --user-name vendor --query User.Arn --output text
arn:aws:iam::123456789012:user/vendor
ana@laptop:~/aws$ aws iam put-user-policy --user-name vendor --policy-name assume-monitoring --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"sts:AssumeRole","Resource":"arn:aws:iam::123456789012:role/monitoring"}]}'
ana@laptop:~/aws$ vendor=$(aws iam create-access-key --user-name vendor)
ana@laptop:~/aws$ with_key "$vendor" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/monitoring --role-session-name for-another-customer --external-id other-9q2m11 --query AssumedRoleUser.Arn --output text

aws: [ERROR]: An error occurred (AccessDenied) when calling the AssumeRole operation: User: arn:aws:iam::123456789012:user/vendor is not authorized to perform: sts:AssumeRole
ana@laptop:~/aws$ with_key "$vendor" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/monitoring --role-session-name for-the-shop --external-id shop-7f3k92 --query AssumedRoleUser.Arn --output text
arn:aws:sts::123456789012:assumed-role/monitoring/for-the-shop
ana@laptop:~/aws$ with_key "$vendor" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/monitoring --role-session-name no-id --query AssumedRoleUser.Arn --output text
arn:aws:sts::123456789012:assumed-role/monitoring/no-id
```

**Esta é a única condição que o moto compara, e ele a compara só pela metade.** Um external id errado
é recusado e o certo aceito, como a AWS faz. Uma requisição **sem** external id é aceita, e a AWS a
recusaria, porque um `StringEquals` numa chave que a requisição não traz não bate. Essa última recusa
não foi rodada aqui.

## Um perfil que assume a role por você

Digitar `assume-role` e carregar a resposta por aí é o que um perfil faz por você. Um perfil no
`~/.aws/config` nomeia a role. A linha de comando a assume antes de cada comando, guarda a sessão em
`~/.aws/cli/cache` até ela expirar, e a assume de novo depois. A lição 25 trata de perfis, e esta é a
única linha deles que pertence às roles. Se as lições 2 a 4 deixaram um `~/.aws/config` para trás,
isto o substitui:

```sh
mkdir -p ~/.aws
cat > ~/.aws/config <<EOF
[profile shop-prod]
role_arn = arn:aws:iam::$prod:role/OrganizationAccountAccessRole
credential_source = Environment
role_session_name = ana-admin
EOF
```

`credential_source = Environment` faz a linha de comando assinar a chamada `AssumeRole` com as chaves
do ambiente, as do admin aqui, então nenhuma chave é escrita em arquivo nenhum. A forma habitual,
`source_profile`, nomeia outro perfil cujas credenciais assinam a chamada, e a lição 25 é onde os
perfis são montados direito.

```
ana@laptop:~/aws$ aws sts get-caller-identity --profile shop-prod
{
    "UserId": "AROA4OKH5ABOZYSBAWRQ4:ana-admin",
    "Account": "855386161245",
    "Arn": "arn:aws:sts::855386161245:assumed-role/OrganizationAccountAccessRole/ana-admin"
}
ana@laptop:~/aws$ aws configure list --profile shop-prod
NAME       : VALUE                    : TYPE             : LOCATION
profile    : shop-prod                : manual           : --profile
access_key : ****************BKSM     : assume-role      : 
secret_key : ****************jHAO     : assume-role      : 
region     : sa-east-1                : env              : ['AWS_REGION', 'AWS_DEFAULT_REGION']
ana@laptop:~/aws$ aws sts get-caller-identity --query Arn --output text
arn:aws:iam::123456789012:user/admin
```

**O `--profile shop-prod` é o passo inteiro entre contas**, feito em todo comando. Apague o arquivo ao
terminar, `rm ~/.aws/config`, para que as próximas lições comecem do laboratório como a lição 1 o
deixou.
