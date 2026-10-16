---
title: Grupos reúnem usuários; uma role se veste
version: 1
---

**Um grupo é uma lista de usuários à qual se podem anexar políticas, e nada mais.** Uma role é uma
coisa do tipo oposto: uma identidade com permissões e **sem credenciais próprias**, que um principal
veste por um tempo e depois tira. Os dois se confundem porque ambos carregam permissões para outra
pessoa, então esta seção monta os dois para a loja e depois lê os nomes que a AWS deu a eles.

## Três grupos

As pessoas da loja se dividem em três times, e as permissões acompanham o time, não a pessoa. A
lição 7 anexa as políticas; aqui os grupos só reúnem os usuários:

```
ana@laptop:~/aws$ for g in developers data finance; do aws iam create-group --group-name $g --query Group.Arn --output text; done
arn:aws:iam::123456789012:group/developers
arn:aws:iam::123456789012:group/data
arn:aws:iam::123456789012:group/finance
ana@laptop:~/aws$ aws iam add-user-to-group --group-name developers --user-name bia
ana@laptop:~/aws$ aws iam add-user-to-group --group-name data --user-name caio
ana@laptop:~/aws$ aws iam add-user-to-group --group-name finance --user-name dani
ana@laptop:~/aws$ aws iam get-group --group-name developers --query "Users[].UserName"
[
    "bia"
]
ana@laptop:~/aws$ aws iam list-groups-for-user --user-name caio --query "Groups[].GroupName"
[
    "data"
]
```

`list-groups-for-user` responde à pergunta pelo outro lado, e é o comando a rodar quando alguém
pergunta por que um usuário consegue fazer algo: a resposta costuma ser um grupo de que ninguém se
lembrava.

**A imagem errada é a de um grupo como uma conta compartilhada do time.** Um grupo não tem senha,
nem chave de acesso, nem jeito de assinar nada, então ele nunca faz uma requisição. Daí que um grupo
**não pode ser nomeado como o principal** de uma política, não pode assumir uma role e não pode
conter outro grupo. Um usuário pode estar em até dez grupos, que é o `GroupsPerUserQuota` que a
seção anterior imprimiu e o limite da própria AWS.

O moto é mais tolerante que a AWS aqui, e vale a pena ver isso uma vez:

```
ana@laptop:~/aws$ aws iam create-role --role-name grouptest --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::123456789012:group/developers"},"Action":"sts:AssumeRole"}]}' --query Role.Arn
"arn:aws:iam::123456789012:role/grouptest"
ana@laptop:~/aws$ aws iam delete-role --role-name grouptest
```

**O moto guardou uma política de confiança que nomeia um grupo. A AWS recusa esse documento** como
malformado, porque um grupo não é um principal e a política põe um no lugar do principal. Essa
recusa não foi rodada aqui, já que exige uma conta; é o comportamento documentado da AWS, e o motivo
pelo qual o time `developers` chega a uma role pelas permissões de cada membro.

## Uma role, e a política que diz quem pode vesti-la

A entrega contínua da loja roda como uma role chamada `deployer`. **Uma role carrega duas políticas
de tipos diferentes**: uma **política de confiança** (trust policy), que nomeia quem pode assumi-la,
e políticas de permissão, que dizem o que a sessão pode fazer depois. A lição 7 escreve o segundo
tipo. A política de confiança vem primeiro, porque uma role não pode ser criada sem uma. Por
enquanto ela confia na bia; a próxima seção entrega a role ao GitHub. Salve-a como
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

```
ana@laptop:~/aws$ aws iam create-role --role-name deployer --assume-role-policy-document file://deployer-trust.json
{
    "Role": {
        "Path": "/",
        "RoleName": "deployer",
        "RoleId": "AROARZPUZDIKPPMZN5TQR",
        "Arn": "arn:aws:iam::123456789012:role/deployer",
        "CreateDate": "2026-10-16T16:06:31.226904+00:00",
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "AWS": "arn:aws:iam::123456789012:user/bia"
                    },
                    "Action": "sts:AssumeRole"
                }
            ]
        },
        "MaxSessionDuration": 3600,
        "RoleLastUsed": {}
    }
}
```

O `RoleId` começa com `AROA`, o prefixo da AWS para uma role, e esse o moto acerta.
`MaxSessionDuration` é 3600 segundos, a duração padrão de uma sessão; a lição 9 a muda.

**Uma role não tem chave para criar.** `create-access-key` recebe o nome de um usuário, e uma role
não é um:

```
ana@laptop:~/aws$ aws iam create-access-key --user-name deployer

aws: [ERROR]: An error occurred (NoSuchEntity) when calling the CreateAccessKey operation: The user with name deployer cannot be found.
```

O que uma role dá no lugar é uma sessão. `sts assume-role` pede uma e recebe três valores que
funcionam juntos, e uma validade:

```
ana@laptop:~/aws$ aws sts assume-role --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name bia-deploy --query "{User:AssumedRoleUser,Key:Credentials.AccessKeyId,Expires:Credentials.Expiration}"
{
    "User": {
        "AssumedRoleId": "AROARZPUZDIKPPMZN5TQR:bia-deploy",
        "Arn": "arn:aws:sts::123456789012:assumed-role/deployer/bia-deploy"
    },
    "Key": "ASIARZPUZDIKNJGDRMLO",
    "Expires": "2026-10-16T17:06:32.463668+00:00"
}
```

**O id da chave começa com `ASIA`, o prefixo de uma chave temporária**, contra `AKIA` da chave
permanente de um usuário. Ao lado dele, que o `--query` deixou de fora, vêm um segredo e um token de
sessão, e os três são recusados juntos uma hora depois. Ninguém precisa girá-los ou apagá-los, e um
que vaze vale uma hora no máximo. Note também o que o moto não perguntou: se quem chamou era a bia.
Com a verificação desligada ele dá uma sessão a qualquer um, e a lição 9 repete isto com a
verificação ligada para mostrar a política de confiança recusando um principal que ela não nomeia.

## Lendo os nomes

Todo principal até aqui tem dois nomes: um **ARN**, que é o endereço que as políticas usam, e um
**id único**, que a AWS atribui e nunca reutiliza.

| o quê | ARN na loja | o id começa com |
|---|---|---|
| usuário root | `arn:aws:iam::123456789012:root` | o número da conta |
| usuário do IAM | `arn:aws:iam::123456789012:user/bia` | `AIDA` (moto: minúsculas aleatórias) |
| grupo | `arn:aws:iam::123456789012:group/developers` | `AGPA` (moto: minúsculas aleatórias) |
| role | `arn:aws:iam::123456789012:role/deployer` | `AROA` |
| sessão de role | `arn:aws:sts::123456789012:assumed-role/deployer/bia-deploy` | o id da role, dois-pontos, o nome da sessão |
| chave de acesso | não é um ARN | `AKIA` longo prazo, `ASIA` temporária |

**O ARN da sessão pertence ao `sts`, não ao `iam`**, e termina no nome de sessão que quem chamou
escolheu. É esse o nome que um log mostra quando algo foi feito por meio de uma role, e por isso
`bia-deploy` é melhor que `session1`; a lição 9 mostra como o log de auditoria da AWS, o
CloudTrail, o usa.

**O id é o que faz de um usuário recriado um usuário diferente.** Se o usuário da bia for apagado e
criado de novo, o ARN é o mesmo e o id é novo. A documentação da AWS descreve o que isso faz com uma
política de confiança que a nomeia: a política guardada troca o ARN pelo id antigo quando o usuário é
apagado, então a nova bia não é confiável até alguém escrever a política de novo. Isso não foi rodado
aqui, e é uma proteção deliberada: um nome reutilizado por outra pessoa não herda uma permissão
antiga.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l06-principals\" aria-label=\"Os principals da loja e com o que cada um assina as requisições. O usuário root assina com o e-mail, a senha e o MFA, e tem todas as permissões. A usuária do IAM bia está dentro do grupo developers; ela assina com uma senha ou uma chave de acesso AKIA, que dura até alguém apagá-la. O grupo em si não assina nada. A bia, e o GitHub Actions com um token OIDC, podem assumir a role deployer, que não tem credenciais próprias; a sessão que ela dá assina com uma chave ASIA e um token que expiram depois de uma hora.\"><defs><marker id=\"l06-principals-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l06-principals-af-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l06-principals-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l06-principals-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"580.0\" y=\"36.0\" width=\"120.0\" height=\"278.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">API da AWS</text><rect x=\"45.0\" y=\"36.0\" width=\"180.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">usuário root</text><text x=\"135.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">e-mail, senha, MFA</text><path d=\"M227.0 60.0 L577.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l06-principals-af-ah-paper-dim)\"></path><text x=\"408.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">todas as permissões, sempre</text><rect x=\"30.0\" y=\"104.0\" width=\"210.0\" height=\"122.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"135.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">group/developers</text><rect x=\"45.0\" y=\"130.0\" width=\"180.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">usuária do IAM bia</text><text x=\"135.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">senha, chave AKIA</text><text x=\"135.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">o grupo não assina nada</text><path d=\"M227.0 150.0 L240.0 150.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M240.0 150.0 L577.0 150.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l06-principals-af-ah-amber)\"></path><text x=\"408.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">chave AKIA: até alguém apagá-la</text><path d=\"M227.0 178.0 L240.0 187.9\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M240.0 187.9 L298.0 232.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l06-principals-af-ah-paper)\"></path><text x=\"300.0\" y=\"198.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">sts:AssumeRole</text><rect x=\"45.0\" y=\"262.0\" width=\"180.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">GitHub Actions</text><text x=\"135.0\" y=\"298.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">token OIDC</text><path d=\"M227.0 286.0 L298.0 262.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l06-principals-af-ah-paper)\"></path><text x=\"300.0\" y=\"300.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">AssumeRoleWithWebIdentity</text><rect x=\"300.0\" y=\"214.0\" width=\"160.0\" height=\"64.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"380.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">role deployer</text><text x=\"380.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem credenciais próprias</text><path d=\"M462.0 246.0 L577.0 246.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l06-principals-af-ah-phosphor)\"></path><text x=\"520.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">chave ASIA + token</text><text x=\"520.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">expira em uma hora</text></svg>", "caption": "Quatro jeitos de uma requisição ser assinada, e um grupo que não assina nenhuma. Só a sessão da role expira sozinha.", "same": ["GitHub Actions", "role deployer"]}
```
