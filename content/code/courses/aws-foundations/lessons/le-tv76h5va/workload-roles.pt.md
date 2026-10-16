---
title: Uma role por pod e por tarefa: IRSA, Pod Identity e ECS
version: 1
---

**Um instance profile dá uma role para a máquina inteira; um cluster precisa de uma role por carga
de trabalho.** Um nó Kubernetes no EKS roda pods de várias equipes, e o checkout da loja e o seu job
de relatórios não devem dividir permissões só porque caíram no mesmo nó. A AWS tem três respostas, e
cada uma cai num de dois provedores da cadeia: **um arquivo de token trocado por uma role**, ou um
endereço local que entrega credenciais.

| | o que a carga recebe | provedor na cadeia |
|---|---|---|
| **IRSA**, IAM roles for service accounts (EKS) | um arquivo de token e o ARN de uma role | `assume-role-with-web-identity` |
| **EKS Pod Identity** | um endereço local e um arquivo de token | `container-role` |
| **task role do ECS** | um endereço local | `container-role` |

## IRSA: um token do cluster, trocado no STS

Um cluster EKS é um **emissor OpenID Connect**. Ele assina um token de vida curta para cada pod,
dizendo como qual service account o pod roda, e publica num endereço público as chaves que
verificam a assinatura. O IRSA faz o IAM confiar nesse emissor:

1. a conta registra o emissor do cluster como um provedor de identidade OIDC no IAM;
2. a política de confiança de uma role nomeia esse provedor e diz qual service account pode assumi-la;
3. o pod recebe o token num arquivo, e duas variáveis de ambiente que nomeiam o arquivo e a role;
4. o SDK chama `sts:AssumeRoleWithWebIdentity` com o token, e o STS responde com credenciais
   temporárias da role.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" data-fig=\"l10-irsa\" aria-label=\"O IRSA como sequência, entre quatro partes: o cluster EKS, o pod, o STS e o S3. Um: o cluster dá ao pod um token assinado num arquivo. Dois: o pod manda AssumeRoleWithWebIdentity ao STS com o token e sem assinatura. Três: o STS busca as chaves que o cluster publica e verifica a assinatura. Quatro: o STS avalia a política de confiança, onde sub e aud precisam bater. Cinco: o STS devolve credenciais por uma hora. Seis: o pod chama o S3, assinando com elas. O moto pula os passos três e quatro.\"><defs><marker id=\"l10-irsa-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l10-irsa-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"24.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"39.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o cluster</text><text x=\"90.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">EKS</text><path d=\"M90.0 70.0 L90.0 360.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"200.0\" y=\"24.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"39.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o pod</text><text x=\"270.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">checkout</text><path d=\"M270.0 70.0 L270.0 360.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"380.0\" y=\"24.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">STS</text><path d=\"M450.0 70.0 L450.0 360.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"560.0\" y=\"24.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">S3</text><path d=\"M630.0 70.0 L630.0 360.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M92.0 100.0 L268.0 100.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-irsa-af-ah-phosphor)\"></path><text x=\"179.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">1  um token assinado, num arquivo</text><path d=\"M272.0 150.0 L448.0 150.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-irsa-af-ah-phosphor)\"></path><text x=\"359.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">2  token, sem assinatura</text><path d=\"M448.0 200.0 L92.0 200.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-irsa-af-ah-amber)\"></path><text x=\"271.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">3  busca as chaves, verifica a assinatura</text><path d=\"M448.0 290.0 L272.0 290.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-irsa-af-ah-phosphor)\"></path><text x=\"361.0\" y=\"279.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">5  credenciais por uma hora</text><path d=\"M272.0 340.0 L628.0 340.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-irsa-af-ah-phosphor)\"></path><text x=\"449.0\" y=\"329.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">6  uma chamada assinada com elas</text><text x=\"460.0\" y=\"245.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">4  política de confiança: sub, aud</text><text x=\"160.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" font-style=\"italic\" fill=\"var(--amber)\">o moto pula 3 e 4</text></svg>", "caption": "O pod não precisa de credencial da AWS para conseguir a primeira: o token é a prova, e quem a confere é o STS."}
```

A chamada ao STS, o passo 2 da figura, **não é assinada**. O token é a prova, e é esse o ponto: o pod
não precisa de credencial da AWS nenhuma para conseguir a primeira. Registre o provedor. O endereço
do emissor tem o formato que o EKS dá a um cluster em `sa-east-1`, com um id da documentação da AWS:

```
ana@laptop:~/aws$ aws iam create-open-id-connect-provider --url https://oidc.eks.sa-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE --client-id-list sts.amazonaws.com
{
    "OpenIDConnectProviderArn": "arn:aws:iam::123456789012:oidc-provider/oidc.eks.sa-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
}
```

A política de confiança traz as condições que a tornam uma role de uma só carga. **`sub` é a service
account, no formato `system:serviceaccount:<namespace>:<nome>`; `aud` é para quem o token é**, que no
IRSA é o STS. Sem a condição em `sub`, todo pod do cluster com um token poderia virar esta role.
Salve isto como `~/aws/trust-checkout.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/oidc.eks.sa-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.sa-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE:sub": "system:serviceaccount:shop:checkout",
          "oidc.eks.sa-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam create-role --role-name shop-checkout --assume-role-policy-document file://trust-checkout.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/shop-checkout
ana@laptop:~/aws$ aws iam attach-role-policy --role-name shop-checkout --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
```

Do lado do cluster, a service account traz o ARN da role numa anotação, e o EKS põe o token e as
duas variáveis em todo pod que roda como ela. **Isto não foi executado**, já que não há cluster no
laboratório; é o formato que o EKS documenta:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: checkout
  namespace: shop
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/shop-checkout
```

## Um token, feito à mão

O token de um pod é um JWT: três pedaços em base64 unidos por pontos, um cabeçalho, um conjunto
de claims e uma assinatura. Este programa escreve um com as claims que um token do EKS traz, e um
terceiro pedaço que **não é assinatura nenhuma**. Basta para mover a cadeia, e a seção seguinte mede
o que isso diz sobre o moto. Salve-o como `~/aws/make-token.py`; um arquivo chamado `token.py` em
`~/aws` esconderia o módulo `token` do próprio Python de todo programa rodado ali, o boto3 inclusive:

```schooling-example
{"language": "python", "file": "make-token.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Prints a token shaped like the one EKS gives a pod. It is NOT signed.\n\n    python3 make-token.py SERVICE-ACCOUNT > token\n\"\"\"\nimport base64\nimport json\nimport sys\nimport time\n\n", "note": "Só a biblioteca do próprio Python. A service account vem da linha de comando, então o mesmo programa escreve um token para a carga certa e para a errada."}, {"code": "ISSUER = 'https://oidc.eks.sa-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE'\n\n\ndef piece(d):\n    raw = json.dumps(d, separators=(',', ':')).encode()\n    return base64.urlsafe_b64encode(raw).rstrip(b'=').decode()\n\n\n", "note": "Um JWT codifica cada pedaço em base64 na forma segura para URL, sem o preenchimento `=`. `ISSUER` é o endereço registrado como provedor OIDC."}, {"code": "now = int(time.time())\nclaims = {'iss': ISSUER, 'sub': sys.argv[1], 'aud': ['sts.amazonaws.com'],\n          'iat': now, 'exp': now + 3600}\n", "note": "As claims que o STS compara com a política de confiança: quem emitiu o token, que service account ele nomeia, para quem ele é. `exp` o torna inútil uma hora depois de feito. O token de um pod de verdade também vence, e o kubelet o troca antes disso."}, {"code": "print(piece({'alg': 'RS256', 'kid': 'lab'}) + '.' + piece(claims) + '.not-a-signature')\n", "note": "O cabeçalho diz RS256, uma assinatura RSA, e o terceiro pedaço é um marcador. A AWS buscaria as chaves publicadas pelo emissor, não acharia nenhuma que o verificasse, e recusaria o token."}]}
```

Escreva um token para a service account do checkout, tire as chaves do ambiente e dê à cadeia as
duas variáveis que um pod receberia. `AWS_ROLE_SESSION_NAME` é opcional; ele fixa o nome que a
sessão tiraria do relógio:

```
ana@laptop:~/aws$ python3 make-token.py system:serviceaccount:shop:checkout > token
ana@laptop:~/aws$ unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
ana@laptop:~/aws$ export AWS_ROLE_ARN=arn:aws:iam::123456789012:role/shop-checkout AWS_WEB_IDENTITY_TOKEN_FILE=~/aws/token AWS_ROLE_SESSION_NAME=checkout-pod
ana@laptop:~/aws$ aws configure list
NAME       : VALUE                    : TYPE             : LOCATION
profile    : <not set>                : None             : None
access_key : ****************QGVI     : assume-role-with-web-identity : 
secret_key : ****************B/rN     : assume-role-with-web-identity : 
region     : sa-east-1                : env              : ['AWS_REGION', 'AWS_DEFAULT_REGION']
ana@laptop:~/aws$ aws sts get-caller-identity
{
    "UserId": "AROARZPUZDIKGSK3B22RF:checkout-pod",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:assumed-role/shop-checkout/checkout-pod"
}
```

**`assume-role-with-web-identity` respondeu**, o terceiro provedor da cadeia, e a identidade é a
role com o nome de sessão que a variável deu.

## O que o moto verifica, medido

Agora a mesma cadeia com um token para uma service account que a política de confiança não nomeia,
e depois com uma role que não existe:

```
ana@laptop:~/aws$ python3 make-token.py system:serviceaccount:other:intruder > token
ana@laptop:~/aws$ aws sts get-caller-identity --query Arn --output text
arn:aws:sts::123456789012:assumed-role/shop-checkout/checkout-pod
ana@laptop:~/aws$ AWS_ROLE_ARN=arn:aws:iam::123456789012:role/no-such-role aws sts get-caller-identity --query Arn --output text
arn:aws:sts::123456789012:assumed-role/no-such-role/checkout-pod
```

**O moto não verificou nada.** Nem a assinatura, que não é uma; nem o emissor; nem `sub` ou `aud`
contra as condições; nem mesmo que a role existe. Ele devolveu credenciais todas as vezes. Perguntar
direto ao STS, com `--no-sign-request` porque a chamada não precisa de chave, mostra mais uma lacuna:

```
ana@laptop:~/aws$ aws sts assume-role-with-web-identity --role-arn arn:aws:iam::123456789012:role/shop-checkout --role-session-name checkout-pod --web-identity-token file://token --no-sign-request --query "keys(@)" --output text
Credentials	AssumedRoleUser	PackedPolicySize
```

A resposta da AWS traz também `SubjectFromWebIdentityToken`, `Audience` e `Provider`, que dizem de
quem foi o token aceito, e a do moto não tem nenhum deles.

E com a verificação de permissões do moto ligada, como a lição 7 a inicia
(`INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567`, e depois um usuário `admin` criado em três
requisições), a chamada nem chega lá. A verificação do moto espera que toda requisição traga uma
assinatura, esta não traz nenhuma, e o moto responde com um erro interno, HTTP 500. Isso foi medido
durante a gravação desta lição, e é por isso que a lição deixa a verificação desligada.

Então o laboratório mostra **como as credenciais viajam**, e a documentação da AWS é a única fonte
para o que o STS recusa. Ele verifica a assinatura do token contra as chaves que o emissor
publica, confere que o emissor é um provedor registrado e que o token não venceu, e então avalia a
política de confiança, onde `sub` e `aud` precisam bater. Um token para `other:intruder` é recusado
ali com `AccessDenied`.

## EKS Pod Identity, o jeito mais novo

O **EKS Pod Identity** tira o provedor OIDC do arranjo. Um agente roda em cada nó e responde num
endereço link-local, `169.254.170.23`, e o cluster liga uma service account a uma role com uma
associação, `aws eks create-pod-identity-association`. A política de confiança da role nomeia um
principal de serviço, o mesmo em todo cluster:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"Service": "pods.eks.amazonaws.com"},
      "Action": ["sts:AssumeRole", "sts:TagSession"]
    }
  ]
}
```

Essa é a diferença que pesa na prática: **com o IRSA cada cluster é um provedor a registrar e uma
condição a escrever em cada política de confiança, e com o Pod Identity uma role pode ser reusada
por qualquer cluster da conta** sem editá-la. A documentação da AWS apresenta o Pod Identity como a
escolha mais simples no EKS, e o IRSA fica onde o Pod Identity não chega, como pods no Fargate.
Nenhum dos dois foi executado aqui.

## Task roles do ECS, e o provedor de contêiner

No ECS, uma task role é declarada na definição da tarefa, e o agente do ECS serve as credenciais
dela em `169.254.170.2`. O contêiner recebe uma variável, `AWS_CONTAINER_CREDENTIALS_RELATIVE_URI`,
com o caminho a pedir, e o provedor `container-role` da cadeia pede. A política de confiança da role
nomeia `ecs-tasks.amazonaws.com`.

A resposta tem o mesmo formato JSON da do serviço de metadados, então dá para mostrar o provedor
funcionando apontando a outra variável dele, `AWS_CONTAINER_CREDENTIALS_FULL_URI`, para a resposta de
metadados do moto. Isso é o provedor lendo as credenciais de marcador do moto, não um agente do ECS.
Tire antes as variáveis de web identity, já que esse provedor vem mais cedo na cadeia:

```
ana@laptop:~/aws$ unset AWS_ROLE_ARN AWS_WEB_IDENTITY_TOKEN_FILE AWS_ROLE_SESSION_NAME
ana@laptop:~/aws$ AWS_CONTAINER_CREDENTIALS_FULL_URI=http://localhost:4567/latest/meta-data/iam/security-credentials/default-role aws configure list
NAME       : VALUE                    : TYPE             : LOCATION
profile    : <not set>                : None             : None
access_key : ****************-key     : container-role   : 
secret_key : ****************-key     : container-role   : 
region     : sa-east-1                : env              : ['AWS_REGION', 'AWS_DEFAULT_REGION']
```

**`container-role` respondeu**, antes do `iam-role` na cadeia. Toda carga desta seção, pod ou
tarefa, terminou com credenciais que vencem em horas, e nenhuma chave foi escrita em lugar nenhum.
Leia o `env.sh` de novo para pôr as chaves de teste de volta antes da prática.
