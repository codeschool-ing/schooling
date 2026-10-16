---
title: Um instance profile, e o serviço de metadados que o entrega
version: 1
---

**Uma máquina no EC2 recebe as permissões de uma role, e a role chega à máquina dentro de um
instance profile.** Ninguém copia uma chave para o disco. A instância pergunta ao serviço de
metadados, o serviço responde com credenciais temporárias da role, e o SDK na base da cadeia as
pega. Os servidores web da loja leem as fotos dos produtos em `shop-assets` assim, como a role
`shop-app`.

A imagem errada é que uma role é anexada a uma instância. **O que se anexa é um instance profile**,
um contêiner que guarda exatamente uma role. O console esconde a diferença: escolher uma role para
uma instância EC2 ali cria, por trás, um profile com o mesmo nome. A linha de comando obriga você a
criar os dois, e esse é o jeito mais claro de ver que são duas coisas.

## Uma role que o EC2 pode vestir

Uma role responde duas perguntas, como a lição 9 mostrou: quem pode assumi-la, na política de
confiança, e o que ela pode fazer, nas políticas de permissão. **Para uma máquina, o principal na
política de confiança é o próprio serviço EC2.** Salve isto como `~/aws/trust-ec2.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }
  ]
}
```

Crie a role, deixe-a ler o S3 e nada mais, e ponha-a num profile:

```
ana@laptop:~/aws$ aws iam create-role --role-name shop-app --assume-role-policy-document file://trust-ec2.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/shop-app
ana@laptop:~/aws$ aws iam attach-role-policy --role-name shop-app --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
ana@laptop:~/aws$ aws iam create-instance-profile --instance-profile-name shop-app --query InstanceProfile.Arn --output text
arn:aws:iam::123456789012:instance-profile/shop-app
ana@laptop:~/aws$ aws iam add-role-to-instance-profile --instance-profile-name shop-app --role-name shop-app
ana@laptop:~/aws$ aws iam create-role --role-name shop-app-reports --assume-role-policy-document file://trust-ec2.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/shop-app-reports
ana@laptop:~/aws$ aws iam add-role-to-instance-profile --instance-profile-name shop-app --role-name shop-app-reports

aws: [ERROR]: An error occurred (LimitExceeded) when calling the AddRoleToInstanceProfile operation: Cannot exceed quota for InstanceSessionsPerInstanceProfile: 1
```

O último comando falhou de propósito. **Um profile guarda uma role, e o moto aplica o limite**
exatamente como a AWS o documenta. Uma instância que precisa de dois conjuntos de permissões precisa
de uma role cujas políticas concedam os dois.

## Lançando uma máquina que a veste

O `run-instances` recebe o profile pelo nome. A imagem é uma Amazon Linux 2023 do catálogo do
próprio moto, e o mesmo id existe no moto de todo aluno:

```
ana@laptop:~/aws$ aws ec2 run-instances --image-id ami-0629d059c178d0eac --instance-type t3.micro --iam-instance-profile Name=shop-app --metadata-options HttpTokens=required,HttpPutResponseHopLimit=1 --query "Instances[0].[InstanceId,IamInstanceProfile.Arn,MetadataOptions.[HttpTokens,HttpPutResponseHopLimit]]" --output text
i-0ee42130b0c3e009d	arn:aws:iam::123456789012:instance-profile/shop-app
required	1
ana@laptop:~/aws$ aws ec2 describe-iam-instance-profile-associations --query "IamInstanceProfileAssociations[].[InstanceId,IamInstanceProfile.Arn,State]" --output text
i-0ee42130b0c3e009d	arn:aws:iam::123456789012:instance-profile/shop-app	associated
```

**O moto não roda máquina nenhuma.** Ele registra uma instância com um id, um estado e um profile, e
nada dá boot; não há Linux por trás de `i-0ee42130b0c3e009d` para entrar. O seu id vai ser
diferente deste. O que o moto guarda de fato é a **associação** entre a instância e o profile, que é
o registro que a AWS também guarda, e que pode ser trocado numa instância em execução sem pará-la.

Numa instância de verdade o resto acontece sem ninguém. O SDK na máquina chega à base da cadeia,
pede `iam/security-credentials/` a `169.254.169.254`, recebe `shop-app` de volta, lê as credenciais
sob esse nome e assina com elas. Quando estão perto de vencer, ele pergunta de novo.

Mais uma permissão protege isso, e é fácil não ver. **Quem lança uma instância com um profile
precisa de `iam:PassRole` na role dele**, além de `ec2:RunInstances`. Sem essa regra, qualquer um
autorizado a ligar máquinas poderia ligar uma vestindo a role mais poderosa da conta e ler as
credenciais lá de dentro. Uma desenvolvedora que pode lançar instâncias recebe `iam:PassRole` em
`shop-app` e nada mais amplo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 370\" role=\"img\" data-fig=\"l10-imds\" aria-label=\"Quem recebe resposta do serviço de metadados da instância no IMDSv2. Dentro de uma instância EC2, a aplicação manda um PUT pedindo um token e a resposta chega, a um salto. Um contêiner atrás de uma bridge do Docker, também na instância, pede também; com limite de saltos 1 a resposta para na bridge, e com 2 chega ao contêiner. Fora da instância, uma requisição forjada vinda da internet faz a aplicação mandar um GET simples, que não leva token e é recusado com 401.\"><defs><marker id=\"l10-imds-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l10-imds-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"450.0\" height=\"230.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"36.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma instância EC2</text><rect x=\"50.0\" y=\"80.0\" width=\"170.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a aplicação</text><rect x=\"250.0\" y=\"150.0\" width=\"200.0\" height=\"105.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"266.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">bridge do Docker</text><rect x=\"275.0\" y=\"188.0\" width=\"150.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">um contêiner</text><rect x=\"580.0\" y=\"80.0\" width=\"120.0\" height=\"175.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"640.0\" y=\"142.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">serviço de</text><text x=\"640.0\" y=\"157.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">metadados</text><text x=\"640.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">169.254.169.254</text><path d=\"M222.0 97.0 L577.0 97.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-imds-af-ah-phosphor)\" marker-start=\"url(#l10-imds-af-ah-phosphor)\"></path><text x=\"345.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">PUT pedindo token: respondido, um salto</text><path d=\"M577.0 212.0 L453.0 212.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-imds-af-ah-amber)\"></path><text x=\"515.0\" y=\"185.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">limite 1:</text><text x=\"515.0\" y=\"198.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">para aqui</text><text x=\"515.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">limite 2: passa</text><rect x=\"50.0\" y=\"305.0\" width=\"170.0\" height=\"46.0\" rx=\"22\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"328.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uma requisição forjada</text><path d=\"M135.0 303.0 L135.0 133.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-imds-af-ah-amber)\"></path><text x=\"145.0\" y=\"290.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">vinda da internet</text><path d=\"M222.0 118.0 L577.0 118.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l10-imds-af-ah-amber)\"></path><text x=\"345.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">um GET simples, sem token: 401</text></svg>", "caption": "O IMDSv2 responde aos processos da própria instância, e a nada que esteja um salto além ou que não faça o PUT."}
```

## O IMDSv2, e contra o que ele defende

O serviço de metadados responde a qualquer coisa que consiga abrir uma conexão de dentro da
instância, e isso inclui a aplicação. **O perigo é uma falsificação de requisição do lado do
servidor, SSRF**: uma aplicação que busca um endereço que o usuário fornece, como uma imagem para
pré-visualizar ou um webhook para chamar, pode receber o endereço de metadados no lugar. No IMDSv1
isso é um único `GET`, e as credenciais voltam na resposta para quem mandou o endereço. Um
vazamento público em 2019 passou exatamente por esse caminho, de um firewall mal configurado na
frente de uma aplicação até a role da máquina por trás dela.

**O IMDSv2 fecha as formas comuns desse buraco com três regras**, todas da documentação da AWS:

- ler qualquer coisa exige um token, e o token só vem de um `PUT` com um cabeçalho próprio, que uma
  requisição forjada por um parâmetro de URL em geral não consegue mandar;
- um `PUT` que traz o cabeçalho `X-Forwarded-For` não recebe token, então um proxy na máquina que
  repassa requisições não repassa esta;
- a resposta com o token sai com um tempo de vida IP igual ao **limite de saltos** (hop limit), 1 por
  padrão, então ela morre depois de um salto e nunca alcança nada atrás de outro dispositivo de rede.

`HttpTokens=required` é o que desliga o IMDSv1, e o lançamento acima o definiu. Aqui a imitação do
moto para. **O moto registra a configuração e não a aplica**: o serviço de metadados dele ainda
responde um `GET` simples sem token, onde a AWS responderia `401 Unauthorized`.

```
ana@laptop:~/aws$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4567/latest/meta-data/iam/security-credentials/
200
```

As próprias imagens da AWS agora pedem o IMDSv2 sozinhas. **As imagens Amazon Linux 2023 trazem
`ImdsSupport` definido como `v2.0`**, o que faz uma instância lançada a partir de uma delas exigir
tokens mesmo quando o lançamento não diz nada. A cópia da imagem no moto não traz o campo:

```
ana@laptop:~/aws$ aws ec2 describe-images --image-ids ami-0629d059c178d0eac --query "Images[0].[Name,ImdsSupport]" --output text
al2023-ami-2023.12.20260727.0-kernel-6.12-x86_64	None
```

Uma conta também pode definir o padrão para toda instância nova numa região com
`aws ec2 modify-instance-metadata-defaults --http-tokens required`. **Esse não foi executado**: o
moto 5.2.3 responde o comando irmão, `get-instance-metadata-defaults`, com um erro interno, então
este curso o descreve pela documentação da AWS.

## O limite de saltos, e os contêineres

Um limite de 1 significa que os processos da própria instância recebem um token e nada além deles
recebe. **Um contêiner na rede bridge padrão do Docker está um salto mais longe**, então numa
máquina que roda contêineres que devem usar a role da instância a documentação da AWS recomenda um
limite de 2. Ponha o id da sua instância no lugar deste:

```
ana@laptop:~/aws$ aws ec2 modify-instance-metadata-options --instance-id i-0ee42130b0c3e009d --http-tokens required --http-put-response-hop-limit 2
{
    "InstanceId": "i-0ee42130b0c3e009d",
    "InstanceMetadataOptions": {
        "State": "applied",
        "HttpTokens": "required",
        "HttpPutResponseHopLimit": 2
    }
}
```

O caso oposto é igualmente comum. Num nó do EKS, a role da instância é a do próprio nó, com as
permissões de que o nó precisa para entrar no cluster e baixar imagens. **Um pod que conseguisse
lê-la teria as permissões do nó**, e é por isso que a orientação do EKS mantém o limite em 1 nos nós
e dá a cada pod uma role própria. Esse é o assunto da próxima seção.
