---
title: Uma segunda conta, e o que ela não enxerga
version: 1
---

**Duas contas são dois ambientes AWS separados que por acaso dividem uma fatura.** A imagem errada
de costume é uma pasta: uma AWS grande com uma seção por equipe, onde alguém com a chave certa vê
tudo. Uma segunda conta não é uma pasta. Ela tem as suas próprias identidades, as suas próprias
redes e as suas próprias cotas, e de dentro dela a primeira conta não existe. Esta seção cria uma no
moto e olha em volta.

## Criando a segunda conta

Uma conta é criada a partir de outra conta que mantém uma organização, e a lição 3 trata do que
é essa árvore. Aqui ela só precisa existir, com uma conta-membro dentro, `shop-prod`:

```
ana@laptop:~/aws$ aws organizations create-organization --query "Organization.[Id,MasterAccountId]" --output text
o-6v58xbpx3x	123456789012
ana@laptop:~/aws$ aws organizations create-account --email aws+shop-prod@example.com --account-name shop-prod --query "CreateAccountStatus.[State,AccountId]" --output text
SUCCEEDED	218935875641
ana@laptop:~/aws$ aws organizations list-accounts --query "Accounts[].[Id,Name,Email]" --output text
123456789012	master	master@example.com
218935875641	shop-prod	aws+shop-prod@example.com
```

A conta que criou a organização é a sua conta de gerenciamento, aqui a padrão do moto,
`123456789012`, que o moto lista com o nome `master`. A conta nova ganhou um número próprio,
`218935875641`; o seu terá outros doze dígitos, já que o moto os inventa, então use o seu onde a
lição mostrar este. **O moto responde `SUCCEEDED` na hora. A AWS cria uma conta em segundo plano** e
responde `IN_PROGRESS`, e `describe-create-account-status` é como você espera por ela; essa parte não
foi rodada aqui.

## Trabalhando dentro dela

Nada do que você tem é credencial da `shop-prod`: as chaves `test` do `env.sh` pertencem à conta de
gerenciamento. O que a conta nova tem é uma role, **`OrganizationAccountAccessRole`**, que a AWS cria
em toda conta que uma organização cria e que a conta de gerenciamento tem permissão de assumir.
Assumir uma role é `sts assume-role`, e isso devolve credenciais temporárias que agem dentro da outra
conta; a lição 9 abre esse assunto. A linha de comando faz isso por você se um perfil disser que
role assumir:

```
ana@laptop:~/aws$ aws configure set profile.shop-prod.role_arn arn:aws:iam::218935875641:role/OrganizationAccountAccessRole
ana@laptop:~/aws$ aws configure set profile.shop-prod.credential_source Environment
ana@laptop:~/aws$ aws configure set profile.shop-prod.role_session_name ana
ana@laptop:~/aws$ cat ~/.aws/config
[profile shop-prod]
role_arn = arn:aws:iam::218935875641:role/OrganizationAccountAccessRole
credential_source = Environment
role_session_name = ana
ana@laptop:~/aws$ aws --profile shop-prod sts get-caller-identity
{
    "UserId": "AROATF6MYLA4XZJERJXRZ:ana",
    "Account": "218935875641",
    "Arn": "arn:aws:sts::218935875641:assumed-role/OrganizationAccountAccessRole/ana"
}
```

As três linhas de `configure set` escreveram o perfil em `~/.aws/config`. `credential_source =
Environment` diz que as chaves de partida são as do ambiente, as que o `env.sh` define, e
`role_session_name` põe o seu nome na sessão. **`--profile shop-prod` em qualquer comando agora o roda
dentro da outra conta**: a linha de comando chama `assume-role` antes e usa o que volta. A resposta
para "quem sou eu" mudou de conta, e o ARN dela diz `assumed-role`. A lição 25 fala mais de perfis. O
perfil cita o número de conta desta execução, então depois que o moto reinicia ele aponta para uma
conta que não existe mais; a lição 3 o escreve de novo.

## Olhando em volta lá de dentro

```
ana@laptop:~/aws$ aws --profile shop-prod ec2 describe-vpcs --query "Vpcs[].[VpcId,CidrBlock,IsDefault,OwnerId]" --output text
vpc-39203323c199f8aeb	172.31.0.0/16	True	218935875641
ana@laptop:~/aws$ aws ec2 describe-vpcs --filters Name=is-default,Values=true --query "Vpcs[].[VpcId,CidrBlock,IsDefault,OwnerId]" --output text
vpc-546fc35409a21e400	172.31.0.0/16	True	123456789012
ana@laptop:~/aws$ aws --profile shop-prod sns list-topics --query "Topics[].TopicArn"
[]
ana@laptop:~/aws$ aws --profile shop-prod iam list-users --query "Users[].UserName"
[]
```

**Cada conta tem a sua própria VPC padrão, e as duas usam `172.31.0.0/16`.** As duas redes têm os
mesmos endereços e ids diferentes, e a última coluna diz quem é dono de cada uma. Nada as liga: um
endereço numa não tem significado na outra até alguém conectar as duas de propósito, o que as lições
19 e 20 fazem. Os mesmos endereços dos dois lados também são o motivo de uma conexão dessas ter de
ser planejada, e de a loja dar à sua rede de produção `10.20.0.0/16` em vez da padrão.

A `shop-prod` não vê **nenhum tópico e nenhum usuário**. O tópico `shop-alerts` e o usuário `bia` da
seção anterior continuam lá, na conta de gerenciamento; daqui eles não existem. E a `shop-prod` tem
uma VPC, então as seis VPCs que a conta de gerenciamento criou não usaram nada da cota dela.

## Os nomes que atravessam as paredes

**Um tipo de nome não é da conta: o de um bucket do S3.** Nomes de bucket vivem num espaço de nomes
dividido por todas as contas da AWS, então um nome ocupado em qualquer lugar está ocupado em todo
lugar:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-assets --create-bucket-configuration LocationConstraint=sa-east-1
{
    "Location": "/shop-assets"
}
ana@laptop:~/aws$ aws --profile shop-prod s3api list-buckets --query "Buckets[].Name"
[]
ana@laptop:~/aws$ aws --profile shop-prod s3api create-bucket --bucket shop-assets --create-bucket-configuration LocationConstraint=sa-east-1

aws: [ERROR]: An error occurred (BucketAlreadyExists) when calling the CreateBucket operation: The requested bucket name is not available. The bucket namespace is shared by all users of the system. Please select a different name and try again
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-assets --create-bucket-configuration LocationConstraint=sa-east-1

aws: [ERROR]: An error occurred (BucketAlreadyOwnedByYou) when calling the CreateBucket operation: Your previous request to create the named bucket succeeded and you already own it.
ana@laptop:~/aws$ aws --profile shop-prod s3api create-bucket --bucket 218935875641-shop-assets --create-bucket-configuration LocationConstraint=sa-east-1
{
    "Location": "/218935875641-shop-assets"
}
```

De dentro da `shop-prod` não há bucket nenhum, e ainda assim `shop-assets` não pode ser criado lá.
**As duas recusas dizem coisas diferentes.** `BucketAlreadyExists` quer dizer que outra conta tem o
nome; `BucketAlreadyOwnedByYou` quer dizer que você já o tem. Nenhuma diz que conta é dona do
bucket, e isso é de propósito: um estranho não pode descobrir de quem é um nome. O moto aplica isso
como a AWS, o que faz disso uma das poucas regras entre contas que você vê falhar no laboratório.

**A solução da loja é o número da conta no nome**, `218935875641-shop-assets`, que ninguém mais pode
estar usando, já que ninguém mais tem essa conta. O nome de um bucket também faz parte do endereço
dele na internet, e é por isso que ele precisa ser único e não pode ser renomeado: um bucket que
precisa de nome novo é um bucket novo e uma cópia.

Alguns outros nomes são globais do mesmo jeito, e estes o moto não aplica: o alias da conta, que
substitui os doze dígitos no endereço de entrada do console, e o endereço de e-mail do usuário
root, que a seção anterior disse ser único em toda a AWS. No moto, duas contas podem definir o
mesmo alias e duas contas podem ser criadas com o mesmo endereço; na AWS o segundo alias é recusado, e
a segunda conta falha com o motivo `EMAIL_ALREADY_EXISTS`. **Essas recusas não foram rodadas aqui**,
já que o moto deixa as duas passarem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" data-fig=\"l02-two-accounts\" aria-label=\"Duas contas lado a lado, com o que as transcrições mostraram dentro de cada uma. A conta de gerenciamento, 123456789012, guarda o usuário bia, o tópico shop-alerts, uma VPC padrão 172.31.0.0/16 e seis VPCs em sa-east-1. A conta-membro shop-prod, 218935875641, não tem usuário nem tópico, tem a sua própria VPC padrão com a mesma faixa 172.31.0.0/16, e uma VPC. Acima das duas, um só espaço de nomes para toda a AWS: o nome de bucket shop-assets pertence à conta de gerenciamento, então a shop-prod o teve recusado com BucketAlreadyExists, e ficou com 218935875641-shop-assets.\"><defs><marker id=\"l02-two-accounts-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l02-two-accounts-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"680.0\" height=\"100.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"36.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">nomes de bucket do S3: um só espaço de nomes para toda conta da AWS</text><rect x=\"70.0\" y=\"62.0\" width=\"180.0\" height=\"36.0\" rx=\"17\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-assets</text><rect x=\"430.0\" y=\"62.0\" width=\"240.0\" height=\"36.0\" rx=\"17\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">218935875641-shop-assets</text><rect x=\"20.0\" y=\"160.0\" width=\"320.0\" height=\"222.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">123456789012</text><text x=\"324.0\" y=\"180.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">conta de gerenciamento</text><rect x=\"34.0\" y=\"204.0\" width=\"292.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"46.0\" y=\"220.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">usuários do IAM</text><text x=\"314.0\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">bia</text><rect x=\"34.0\" y=\"248.0\" width=\"292.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"46.0\" y=\"264.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tópicos do SNS</text><text x=\"314.0\" y=\"264.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-alerts</text><rect x=\"34.0\" y=\"292.0\" width=\"292.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"46.0\" y=\"308.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">VPC padrão</text><text x=\"314.0\" y=\"308.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">172.31.0.0/16</text><rect x=\"34.0\" y=\"336.0\" width=\"292.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"46.0\" y=\"352.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">VPCs em sa-east-1</text><text x=\"314.0\" y=\"352.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">6</text><rect x=\"380.0\" y=\"160.0\" width=\"320.0\" height=\"222.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"396.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">218935875641</text><text x=\"684.0\" y=\"180.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">shop-prod</text><rect x=\"394.0\" y=\"204.0\" width=\"292.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"406.0\" y=\"220.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">usuários do IAM</text><text x=\"674.0\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">nenhum</text><rect x=\"394.0\" y=\"248.0\" width=\"292.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"406.0\" y=\"264.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tópicos do SNS</text><text x=\"674.0\" y=\"264.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">nenhum</text><rect x=\"394.0\" y=\"292.0\" width=\"292.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"406.0\" y=\"308.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">VPC padrão</text><text x=\"674.0\" y=\"308.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">172.31.0.0/16</text><rect x=\"394.0\" y=\"336.0\" width=\"292.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"406.0\" y=\"352.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">VPCs em sa-east-1</text><text x=\"674.0\" y=\"352.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><path d=\"M160.0 100.0 L160.0 120.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M160.0 120.0 L160.0 157.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-two-accounts-af-ah-phosphor)\"></path><path d=\"M550.0 100.0 L550.0 120.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M550.0 120.0 L550.0 157.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-two-accounts-af-ah-phosphor)\"></path><path d=\"M470.0 158.0 L435.0 122.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 3\"></path><path d=\"M435.0 120.0 L254.0 90.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l02-two-accounts-af-ah-amber)\"></path><text x=\"330.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">BucketAlreadyExists</text></svg>", "caption": "Dentro das suas paredes, uma conta só vê o que é seu. Um nome de bucket é a exceção."}
```

## O que o moto deixa de fora

A role da `shop-prod` funciona no moto porque o moto ainda não verifica permissão nenhuma: a lição 7
liga isso. Na AWS a role também chega com a política `AdministratorAccess` anexada, e no moto chega
sem nenhuma. A lição 3 olha essa diferença, e a lição 9 as roles em si. E nada acima custou nada, no
moto ou na AWS: **uma conta é de graça**, e o que ela custa é o trabalho de mantê-la em ordem, que é o
assunto da próxima seção e das lições 3 a 5.
