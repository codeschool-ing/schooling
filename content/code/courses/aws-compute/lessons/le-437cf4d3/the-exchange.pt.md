---
title: "A troca: um token entra, credenciais saem"
version: 1
---

Tudo na seção anterior foi preparação para uma chamada de API. **Um pod com a service account
anotada tem um token que o Kubernetes assinou; o SDK da AWS dentro dele envia esse token ao
`AssumeRoleWithWebIdentity` do STS, e o STS responde com credenciais do role, válidas por uma
hora.** O SDK assina todas as chamadas seguintes com elas, e pede de novo antes que acabem. Nenhuma
chave fica guardada em lugar nenhum, e o próprio token expira em menos de um dia.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Uma sequência em cinco passos entre quatro partes: o pod, o STS, o emissor do cluster e o S3. 1, o pod envia ao STS o token e o role que quer. 2, o STS busca as chaves públicas do emissor. 3, o STS confere a assinatura, o emissor, a audiência e a validade, e depois o sub da política de confiança. 4, o STS devolve credenciais que duram uma hora. 5, o pod chama GetObject no S3 assinando com elas. Uma nota diz que o moto pula os passos 2 e 3 e não lê token nenhum.\"><defs><marker id=\"ex-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"ex-ah-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M90 62 L90 320\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\" fill=\"none\"></path><rect x=\"15\" y=\"14\" width=\"150\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">o pod</text><text x=\"90\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">SDK e arquivo do token</text><path d=\"M310 62 L310 188\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\" fill=\"none\"></path><path d=\"M310 234 L310 320\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\" fill=\"none\"></path><rect x=\"245\" y=\"14\" width=\"130\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">STS</text><text x=\"310\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tokens de segurança</text><path d=\"M520 62 L520 190\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\" fill=\"none\"></path><rect x=\"440\" y=\"14\" width=\"160\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"520\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">o emissor do cluster</text><text x=\"520\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">descoberta e chaves</text><path d=\"M660 62 L660 200\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\" fill=\"none\"></path><path d=\"M660 244 L660 320\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\" fill=\"none\"></path><rect x=\"615\" y=\"14\" width=\"90\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"660\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">S3</text><text x=\"660\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o bucket</text><text x=\"200\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1 · o token e o ARN do role</text><path d=\"M92 98 L306 98\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ex-ah)\"></path><text x=\"415\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2 · busca as chaves do emissor</text><path d=\"M312 134 L516 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ex-ah-dim)\"></path><text x=\"415\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">as chaves, em um JWKS</text><path d=\"M518 170 L314 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ex-ah-dim)\"></path><rect x=\"176\" y=\"188\" width=\"268\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3 · assinatura, emissor, audiência, validade,</text><text x=\"310\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">depois o sub da política de confiança</text><text x=\"200\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4 · credenciais por uma hora</text><path d=\"M308 264 L94 264\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ex-ah)\"></path><text x=\"375\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">5 · GetObject, assinado com essas credenciais</text><path d=\"M92 302 L656 302\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ex-ah)\"></path><rect x=\"452\" y=\"200\" width=\"250\" height=\"44\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"577\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o moto pula os passos 2 e 3:</text><text x=\"577\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">não lê token nenhum</text></svg>", "caption": "A troca no centro do IRSA. O pod prova quem é com um token que o Kubernetes assinou, e o STS só acredita depois de conferir essa assinatura contra as chaves que o emissor publica. No seu laptop o moto faz o papel do STS e executa sozinho os passos 1 e 4.", "same": ["STS", "S3"]}
```

## O que o pod recebe

A anotação da service account é lida por um webhook de mutação que o EKS roda no plano de controle,
o pod identity webhook. Quando um pod que usa essa service account é criado, o webhook acrescenta
três coisas à spec dele, que a AWS documenta e que `kubectl get pod -o yaml` mostra num cluster de
verdade:

- um **volume projetado** com um token de service account para a audiência `sts.amazonaws.com`,
  válido por 86.400 segundos, montado em `/var/run/secrets/eks.amazonaws.com/serviceaccount/token`.
  O kubelet escreve um token novo antes que o antigo acabe;
- **`AWS_ROLE_ARN`**, o role da anotação;
- **`AWS_WEB_IDENTITY_TOKEN_FILE`**, o caminho do token.

É só isso. Não há código da AWS no pod além do SDK que a aplicação já usa, e são essas duas
variáveis que o fazem trocar a busca por chaves pela troca de token. Todo SDK atual da AWS e a linha
de comando as leem, então **a troca pode ser executada no seu laptop exatamente como um pod a
executa**, com o moto no papel do STS.

## Um token, feito à mão

Um token de verdade é um JSON Web Token: três partes separadas por pontos, um cabeçalho, as
declarações e uma assinatura, as duas primeiras em JSON codificado em base64url. Este programa faz
um com o mesmo formato, com as declarações que interessam ao IRSA. Salve como `~/aws/mktoken.py`:

```python
# mktoken.py: an UNSIGNED token shaped like the one Kubernetes puts in a pod
import base64
import json
import sys
import time


def part(data):
    return base64.urlsafe_b64encode(json.dumps(data).encode()).rstrip(b'=').decode()


issuer = sys.argv[1]
audience = sys.argv[2] if len(sys.argv) > 2 else 'sts.amazonaws.com'
claims = {
    'iss': issuer,
    'sub': 'system:serviceaccount:shop:photos',
    'aud': [audience],
    'exp': int(time.time()) + 86400,
}
print(part({'alg': 'none'}) + '.' + part(claims) + '.', end='')
```

`iss`, `sub` e `aud` são as três que a política de confiança e o provedor testam, e `exp` fica a um
dia de agora, como ficaria a do kubelet. Um token de verdade também traz o nome e o uid do pod e um
identificador de chave no cabeçalho. **A diferença que importa é a última parte: aqui ela está
vazia, e o cabeçalho diz `none`.** Ninguém assinou este token, e nenhum STS de verdade o aceitaria.
Ele termina sem quebra de linha, porque o SDK envia o conteúdo do arquivo como está e uma quebra de
linha não é permitida ali.

## Executando a troca

No terminal onde `ISSUER` está definido, escreva um token e dê à linha de comando as duas variáveis
que o webhook dá a um pod. As chaves de teste precisam sair: **o SDK procura chaves no ambiente antes
de procurar um token**, então com elas presentes ele nunca tentaria a troca. Um pod de verdade não
tem chaves no ambiente, e é esse o objetivo.

```
ana@laptop:~/aws$ python3 mktoken.py "$ISSUER" > token
ana@laptop:~/aws$ export AWS_ROLE_ARN=arn:aws:iam::123456789012:role/photos-reader
ana@laptop:~/aws$ export AWS_WEB_IDENTITY_TOKEN_FILE=~/aws/token AWS_ROLE_SESSION_NAME=photos-pod
ana@laptop:~/aws$ unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
ana@laptop:~/aws$ aws sts get-caller-identity
{
    "UserId": "AROARZPUZDIKCYCGLBJ3Q:photos-pod",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:assumed-role/photos-reader/photos-pod"
}
```

Quem chama não é mais o usuário do moto. É o role `photos-reader`, numa sessão chamada
`photos-pod`, e toda chamada que este terminal fizer daqui em diante é assinada com as credenciais
temporárias desse role. `AWS_ROLE_SESSION_NAME` é opcional; sem ele o SDK inventa um nome com um
horário dentro, e dar nome à sessão é o que permite ao CloudTrail dizer qual carga de trabalho foi.

## No que o moto acreditou, e a AWS não acreditaria

Agora troque o token por uma palavra e pergunte de novo. A linha de comando guarda as credenciais de
um role que assumiu em `~/.aws/cli/cache` até que expirem, então o cache sai primeiro, ou a resposta
viria dele e não do moto:

```
ana@laptop:~/aws$ echo not-a-token > token
ana@laptop:~/aws$ rm -rf ~/.aws/cli/cache
ana@laptop:~/aws$ aws sts get-caller-identity --query Arn
"arn:aws:sts::123456789012:assumed-role/photos-reader/photos-pod"
ana@laptop:~/aws$ AWS_ROLE_ARN=arn:aws:iam::123456789012:role/no-such-role aws sts get-caller-identity --query Arn
"arn:aws:sts::123456789012:assumed-role/no-such-role/photos-pod"
```

**O moto entregou credenciais para `not-a-token`, e depois para um role que não existe.** Ele não lê
nem o token nem o role, e nem abre a política de confiança. Isso não é um bug a contornar; é a linha
entre o que este laboratório consegue mostrar e o que não consegue. Na AWS, o STS recusa cada um
destes:

- um token cuja assinatura não confere com as chaves do emissor, ou cujo emissor não tem provedor
  OIDC do IAM na conta, com `InvalidIdentityToken`;
- um token depois do seu `exp`, com `ExpiredToken`;
- um token válido cujo `sub` ou `aud` não bate com a política de confiança, digamos um para
  `system:serviceaccount:shop:default`, com `AccessDenied` em `sts:AssumeRoleWithWebIdentity`.

Nenhuma dessas três recusas foi executada aqui, e nenhuma aparece como saída, porque o moto não
consegue produzi-las. Elas estão na referência da API do STS, que é onde ler a redação exata.

Ponha as chaves de teste de volta antes de seguir:

```
ana@laptop:~/aws$ unset AWS_ROLE_ARN AWS_WEB_IDENTITY_TOKEN_FILE AWS_ROLE_SESSION_NAME
ana@laptop:~/aws$ export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test
```

## As permissões do role são as permissões do pod

O que o moto consegue conferir, quando se pede, é a outra metade: o que as credenciais podem fazer
depois de emitidas. O `moto_server` lê `INITIAL_NO_AUTH_ACTION_COUNT` do seu ambiente, deixa passar
essa quantidade de pedidos sem conferir e avalia as políticas do IAM em todo pedido depois deles.
Pare o moto com Ctrl+C e inicie de novo no terminal dele, com a conferência ligada depois de cinco
pedidos:

```sh
INITIAL_NO_AUTH_ACTION_COUNT=5 ~/aws/venv/bin/moto_server -p 4567
```

Ele está vazio de novo, então os cinco pedidos sem conferência montam o cenário: o bucket, uma foto
nele, o role e a sua permissão, e a própria troca, feita de forma explícita desta vez e guardada em
três variáveis. **A troca precisa ficar dentro dos cinco por um motivo do moto**: com a conferência
ligada ele não consegue responder a um pedido sem assinatura, e o `AssumeRoleWithWebIdentity` não é
assinado por definição, já que a ideia toda é que quem chama ainda não tem credenciais.

```
ana@laptop:~/aws$ printf "hi\n" > photo.jpg
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-photos-123456789012 --create-bucket-configuration LocationConstraint=sa-east-1 --query Location
"/shop-photos-123456789012"
ana@laptop:~/aws$ aws s3api put-object --bucket shop-photos-123456789012 --key cat.jpg --body photo.jpg --query ETag
"\"764efa883dda1e11db47671c4a3bbd9e\""
ana@laptop:~/aws$ aws iam create-role --role-name photos-reader --assume-role-policy-document file://trust.json --query Role.Arn
"arn:aws:iam::123456789012:role/photos-reader"
ana@laptop:~/aws$ aws iam put-role-policy --role-name photos-reader --policy-name read-photos --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:GetObject","Resource":"arn:aws:s3:::shop-photos-123456789012/*"}]}'
ana@laptop:~/aws$ read AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN < <(aws sts assume-role-with-web-identity --role-arn arn:aws:iam::123456789012:role/photos-reader --role-session-name photos-pod --web-identity-token file://token --query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" --output text)
ana@laptop:~/aws$ export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
ana@laptop:~/aws$ aws sts get-caller-identity --query Arn
"arn:aws:sts::123456789012:assumed-role/photos-reader/photos-pod"
ana@laptop:~/aws$ aws s3api get-object --bucket shop-photos-123456789012 --key cat.jpg cat.jpg --query ContentLength
3
ana@laptop:~/aws$ aws s3api put-object --bucket shop-photos-123456789012 --key dog.jpg --body photo.jpg

aws: [ERROR]: An error occurred (AccessDenied) when calling the PutObject operation: Access Denied
```

O role pode ler a foto e não pode escrever uma, exatamente como `read-photos` diz. **Na AWS essa
recusa é o caso de todo dia, não um truque de laboratório**: um pod recebe as permissões do role e
nada mais, então é a política, e não o código do pod, que decide o que um redimensionador
comprometido conseguiria fazer.

Antes da próxima seção, pare este moto e inicie-o do jeito normal, sem variável na frente.
