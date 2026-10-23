---
title: Um token em vez de uma chave
version: 1
---

**A cura para uma chave que atravessa a emenda é parar de mandar uma chave através dela. O job prova
quem é com um token de curta duração que o próprio provedor assina, e a AWS troca esse token por
credenciais que vencem em até uma hora.** Nada fica guardado em nenhum dos lados que ainda funcione
na semana que vem. O mecanismo se chama **federação de identidade de workload**, e todo provedor
grande o oferece nas duas direções.

A aula 7 do curso `cloud` apresentou a federação para pessoas, que entram uma vez e recebem
credenciais temporárias. Esta é a mesma ideia para um programa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" data-fig=\"l04-exchange\" aria-label=\"Federação de identidade de workload, passo a passo, com quatro participantes: o job no Google Cloud, o Google, o AWS STS e o bucket S3. Um: o job pede ao Google um token de identidade, e o Google devolve um assinado por ele. Dois: o job manda o token ao AWS STS, chamando AssumeRoleWithWebIdentity. Três: o STS confere a assinatura com as chaves que o Google publica, a validade, e a condição da política de confiança que nomeia uma conta de serviço; o moto não confere nada disso. Quatro: o STS devolve uma chave temporária começando com ASIA, com um token de sessão, que vence em uma hora. Cinco: o job lê o bucket com ela. Nenhum segredo fica guardado em nenhum dos lados.\"><defs><marker id=\"l04-exchange-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l04-exchange-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o job</text><text x=\"90.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">no Google Cloud</text><path d=\"M90.0 66.0 L90.0 360.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"200.0\" y=\"20.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Google</text><text x=\"270.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">assina tokens</text><path d=\"M270.0 66.0 L270.0 360.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"380.0\" y=\"20.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">AWS STS</text><text x=\"450.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">troca tokens</text><path d=\"M450.0 66.0 L450.0 212.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M450.0 270.0 L450.0 360.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"560.0\" y=\"20.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">S3</text><text x=\"630.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">clinic-exports</text><path d=\"M630.0 66.0 L630.0 360.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M94.0 100.0 L266.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-exchange-af-ah-paper-dim)\"></path><text x=\"180.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1  pede um token de identidade</text><path d=\"M266.0 140.0 L94.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-exchange-af-ah-paper-dim)\"></path><text x=\"180.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um token assinado pelo Google</text><path d=\"M94.0 190.0 L446.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-exchange-af-ah-paper-dim)\"></path><text x=\"270.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2  AssumeRoleWithWebIdentity</text><path d=\"M446.0 290.0 L94.0 290.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-exchange-af-ah-phosphor)\"></path><text x=\"270.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">4  chave ASIA + token de sessão, 1 hora</text><path d=\"M94.0 340.0 L626.0 340.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-exchange-af-ah-phosphor)\"></path><text x=\"360.0\" y=\"330.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">5  lê o bucket</text><rect x=\"330.0\" y=\"214.0\" width=\"240.0\" height=\"54.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">3  confere a assinatura, a validade</text><text x=\"450.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">e a condição que nomeia uma conta</text><text x=\"450.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">o moto não confere nada disso</text></svg>", "caption": "Um token prova quem o job é; as credenciais que ele compra vencem sozinhas. Nada copiado de um lado ainda funcionaria amanhã.", "same": ["AWS STS", "Google", "S3"]}
```

## O moto, desta vez sem a contagem

Pare o moto no primeiro terminal e inicie-o de novo **sem** o `INITIAL_NO_AUTH_ACTION_COUNT`:

```sh
moto_server -p 4567
```

O motivo é um defeito da imitação, não da AWS. Com a verificação ligada, o moto espera que toda
requisição traga uma assinatura, e a chamada no centro desta seção traz um token no lugar; o moto
responde a ela com um erro interno, HTTP 500. Sem a contagem, o moto aceita a chamada, e a chave
`test` do `env.sh` volta a mandar neste terminal. Abra um terminal novo, ou rode `source ~/aws/env.sh`
de novo, para que a chave do administrador da seção anterior saia de cena.

## O papel que o job vai assumir

Do lado da AWS, o usuário vira um **papel** (role), e a política de confiança do papel diz quem pode
assumi-lo. Aqui isso não é um principal da AWS, e sim um emissor de tokens: o Google, que assina
tokens de identidade para as contas de serviço com que as cargas de trabalho dele rodam. Salve a
política de confiança como `trust-google.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Federated": "accounts.google.com" },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": { "accounts.google.com:aud": "104857600012345678901" }
      }
    }
  ]
}
```

**A condição é o que torna isso seguro.** O `Principal` sozinho admitiria um token de qualquer conta
de serviço do Google no mundo, já que o Google assina todos com as mesmas chaves. A condição o prende
a uma: o valor é o ID único numérico da conta de serviço com que o job da clínica roda, que o Google
atribui quando a conta é criada. Este foi inventado para o laboratório. A AWS documenta três chaves
de condição que lê de um token do Google, `accounts.google.com:aud`, `accounts.google.com:oaud` e
`accounts.google.com:sub`, e uma política de confiança para um workload deve prender ao menos uma
delas a essa identidade única.

O reinício esvaziou a conta, então crie de novo o bucket e a exportação, depois crie o papel e dê a
ele a mesma permissão estreita que o usuário tinha:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-exports --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-exports
ana@laptop:~/aws$ aws s3api put-object --bucket clinic-exports --key 2026-10-23.csv --query ETag --output text
"d41d8cd98f00b204e9800998ecf8427e"
```

```
ana@laptop:~/aws$ aws iam create-role --role-name reports-sync --assume-role-policy-document file://trust-google.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/reports-sync
ana@laptop:~/aws$ aws iam put-role-policy --role-name reports-sync --policy-name read-exports --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:GetObject","s3:ListBucket"],"Resource":["arn:aws:s3:::clinic-exports","arn:aws:s3:::clinic-exports/*"]}]}'
```

## A troca

No Google Cloud, o job pede ao próprio servidor de metadados um token de identidade e o manda ao
serviço de tokens de segurança da AWS. Essa metade **não foi executada**: não há Google Cloud neste
laboratório. O que dá para executar é a metade da AWS, com `--no-sign-request`, porque esta chamada
leva um token em vez de uma chave e não é assinada:

```
ana@laptop:~/aws$ s=$(aws sts assume-role-with-web-identity --no-sign-request --role-arn arn:aws:iam::123456789012:role/reports-sync --role-session-name nightly-export --web-identity-token not-a-real-token)
ana@laptop:~/aws$ echo "$s" | jq '.Credentials | {AccessKeyId, Expiration}'
{
  "AccessKeyId": "ASIARZPUZDIKKGLSAFXR",
  "Expiration": "2026-10-23T04:47:31.815017+00:00"
}
```

**O moto entregou uma sessão em troca de um token que claramente não é um, e a AWS o recusaria.** A
AWS confere a assinatura do token com as chaves que o Google publica, a validade dele, e depois a
condição da política de confiança; o moto não confere nada disso, e ignora condições por completo. O
que a execução mostra é o formato da resposta, que é o da AWS: uma chave de acesso começando com
`ASIA`, o prefixo de uma chave temporária, e um `Expiration` uma hora depois do início da sessão.
Uma chave `AKIA`, como a do usuário, não tem vencimento nenhum.

Digite a versão de sessão do `with_key`, que leva também o token de sessão, e faça a leitura noturna
como o papel:

```sh
with_session() {
  local c=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$c" | jq -r .Credentials.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$c" | jq -r .Credentials.SecretAccessKey) \
  AWS_SESSION_TOKEN=$(echo "$c" | jq -r .Credentials.SessionToken) "$@"
}
```

```
ana@laptop:~/aws$ with_session "$s" aws sts get-caller-identity --query Arn --output text
arn:aws:sts::123456789012:assumed-role/reports-sync/nightly-export
ana@laptop:~/aws$ with_session "$s" aws s3api list-objects-v2 --bucket clinic-exports --query "Contents[].Key" --output text
2026-10-23.csv
```

Quem chama agora é `assumed-role/reports-sync/nightly-export`. **O nome da sessão é escolhido pelo
job**, e um bom nome identifica a execução, para que um registro do que ela fez possa ser ligado ao
job que fez.

## Aposentando a chave

Com o job passado para o papel, a chave do usuário não tem mais razão de existir, e a seção anterior
já testou as duas alavancas. Numa conta real a ordem é: ver o último uso da chave parar de avançar
depois da primeira noite do job no papel; **desativar** a chave; esperar o bastante para qualquer
coisa que você não conhecia reclamar; e então **apagar** a chave, a política e o usuário. Uma chave
que ainda é usada depois de "a gente mudou o job" quer dizer que outra coisa guarda uma cópia, e o
último uso dela diz por qual serviço e qual região começar a procurar.

## As outras direções

O mesmo padrão funciona em todos os sentidos, e cada provedor documenta a sua metade. **Nada disto foi
executado aqui.**

| o job roda em | ele age em | o que ele usa |
|---|---|---|
| Google Cloud | AWS | um token de identidade do Google, um papel que confia em `accounts.google.com`, como acima |
| Azure | AWS | um token do Microsoft Entra ID para a identidade gerenciada do workload, e um provedor OIDC do IAM para o emissor do tenant |
| AWS | Google Cloud | a **Workload Identity Federation** do Google Cloud, com um pool cujo provedor é a conta AWS |
| AWS ou Google Cloud | Azure | a **federação de identidade de workload** do Microsoft Entra, uma credencial federada num registro de aplicativo ou numa identidade gerenciada |

Em toda linha a propriedade é a mesma: **nenhum segredo é copiado de um provedor para o outro**, a
credencial vence sozinha, e a regra de confiança de cada lado nomeia exatamente uma identidade do
outro.
