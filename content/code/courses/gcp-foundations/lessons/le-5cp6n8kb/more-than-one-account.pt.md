---
title: Mais de uma conta
version: 1
---

**Credenciais e configurações ficam separadas.** O `gcloud auth login` guarda uma credencial de uma conta; a
propriedade `core/account` de uma configuração diz qual das credenciais guardadas aquela configuração usa. Uma
pessoa com uma conta de trabalho e uma pessoal, ou um engenheiro que também tem uma conta de emergência, lição
10, mantém um repositório de credenciais e escolhe por configuração. Este laboratório não guardou credencial
nenhuma, o que o `gcloud auth list` diz com clareza:

```
ana@laptop:~/gcp$ gcloud auth list

No credentialed accounts.

To login, run:
  $ gcloud auth login `ACCOUNT`
```

A configuração `default` não precisa de uma: a propriedade `auth/access_token_file` dela entrega ao gcloud o token
de mentira diretamente. A configuração `prod` da seção anterior não tem essa propriedade nem conta, então um
comando rodado com ela para antes de qualquer pedido ser feito:

```
ana@laptop:~/gcp$ gcloud pubsub topics list --configuration=prod
ERROR: (gcloud.pubsub.topics.list) You do not currently have an active account selected.
Please run:

  $ gcloud auth login

to obtain new credentials.

If you have already logged in with a different account, run:

  $ gcloud config set account ACCOUNT

to select an already authenticated account to use.
```

## Produção por uma conta de serviço

O planner não deixa a conta de ninguém agir em produção. As contas dos engenheiros têm um papel lá,
`roles/iam.serviceAccountTokenCreator` em `deployer@planner-prod`, e todo comando de produção roda como essa conta
de serviço, a impersonação da lição 8. Uma configuração pode levar isso como propriedade, para ninguém ter de se
lembrar da opção:

```
ana@laptop:~/gcp$ gcloud config set auth/impersonate_service_account deployer@planner-prod.iam.gserviceaccount.com --configuration=prod
Updated property [auth/impersonate_service_account].
```

Dê ao `prod` o token de mentira do laboratório, para ele ter com o que impersonar, e tente de novo. Este pedido
chega ao Google:

```
ana@laptop:~/gcp$ gcloud config set auth/access_token_file /home/ana/gcp/placeholder-token --configuration=prod
Updated property [auth/access_token_file].
ana@laptop:~/gcp$ gcloud pubsub topics list --configuration=prod
WARNING: This command is using service account impersonation. All API calls will be executed as [deployer@planner-prod.iam.gserviceaccount.com].
ERROR: (gcloud.pubsub.topics.list) UNAUTHENTICATED: Failed to impersonate [deployer@planner-prod.iam.gserviceaccount.com]. Make sure the account that's trying to impersonate it has access to the service account itself and the "roles/iam.serviceAccountTokenCreator" role. Request had invalid authentication credentials. Expected OAuth 2 access token, login cookie or other valid authentication credential. See https://developers.google.com/identity/sign-in/web/devconsole-project. This command is authenticated with an access token from /home/ana/gcp/placeholder-token specified by the [auth/access_token_file] property. Impersonation is used to impersonate deployer@planner-prod.iam.gserviceaccount.com. 
- '@type': type.googleapis.com/google.rpc.ErrorInfo
  metadata:
    method: google.iam.credentials.v1.IAMCredentials.GenerateAccessToken
    service: iamcredentials.googleapis.com
  reason: CREDENTIALS_MISSING
```

**O aviso na primeira linha é a propriedade funcionando**: toda chamada será feita como `deployer@`. A recusa
vem do `iamcredentials.googleapis.com`, o serviço que emite o token de vida curta da conta de serviço, o
`GenerateAccessToken` da lição 8, que recusou o token de mentira antes de qualquer pedido ao Pub/Sub ser feito.
Com uma conta real que tenha o papel, a mesma configuração receberia um token para `deployer@` e o usaria, e o
log de auditoria nomearia as duas: a conta de serviço que agiu e a pessoa que pediu.

Uma credencial que o gcloud guarda não é usada por nada disto: as **credenciais padrão de aplicação** que o
`gcloud auth application-default login` guarda são para programas, não para o gcloud, e a lição 24 é sobre elas.
