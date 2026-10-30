---
title: O arquivo de credencial, e uma troca que o Google recusa
version: 1
---

Um workload não faz a troca à mão. **Ele recebe um arquivo de configuração de credencial**, um documento
JSON curto que diz às bibliotecas cliente do Google e ao `gcloud` onde achar o token de fora e pelo que
trocá-lo. O arquivo **não guarda segredo**: diz onde o token está, não o que ele é. Essa é a diferença
entre ele e uma chave, e é por isso que ele pode ficar num repositório.

O `gcloud` escreve um sem perguntar nada ao Google, então o laboratório consegue fazer a coisa real. O
número do projeto e o pool são os inventados da seção anterior:

```sh
cd ~/gcp/federation
gcloud iam workload-identity-pools create-cred-config \
  projects/415104041262/locations/global/workloadIdentityPools/ci-pool/providers/github \
  --service-account=deployer@planner-dev.iam.gserviceaccount.com \
  --credential-source-file=/tmp/github-token \
  --output-file=credentials.json
```

```
ana@laptop:~/gcp/federation$ cat credentials.json
{
  "universe_domain": "googleapis.com",
  "type": "external_account",
  "audience": "//iam.googleapis.com/projects/415104041262/locations/global/workloadIdentityPools/ci-pool/providers/github",
  "subject_token_type": "urn:ietf:params:oauth:token-type:jwt",
  "token_url": "https://sts.googleapis.com/v1/token",
  "credential_source": {
    "file": "/tmp/github-token"
  },
  "service_account_impersonation_url": "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/deployer@planner-dev.iam.gserviceaccount.com:generateAccessToken"
}
```

Todo campo é um dos passos da primeira seção:

| campo | o que diz |
|---|---|
| `type: external_account` | isto é federação, não uma chave, que diria `service_account` |
| `audience` | o pool e o provider a que o token é apresentado, como nome completo de recurso |
| `subject_token_type` | o token de fora é um JWT |
| `token_url` | o passo 2: o Security Token Service do Google |
| `credential_source.file` | onde o token de fora vai estar quando o workload rodar |
| `service_account_impersonation_url` | o passo 3: trocar o token federado pelo do deployer |

Num workflow do GitHub, a action do próprio Google para autenticação escreve esse arquivo e põe o token do
job onde o `credential_source` diz; as bibliotecas cliente da lição 24 acham o arquivo pela variável
`GOOGLE_APPLICATION_CREDENTIALS`, e o workflow nunca tem uma chave.

## A troca, mandada ao Google

O passo 2 é um pedido HTTP, e o `curl` consegue mandá-lo ao STS real. O token nele é o texto
`not-a-real-token`, que é tudo que o laboratório tem:

```
ana@laptop:~/gcp/federation$ curl -sS -X POST https://sts.googleapis.com/v1/token -H 'Content-Type: application/json' -d '{"grantType": "urn:ietf:params:oauth:grant-type:token-exchange", "audience": "//iam.googleapis.com/projects/415104041262/locations/global/workloadIdentityPools/ci-pool/providers/github", "scope": "https://www.googleapis.com/auth/cloud-platform", "requestedTokenType": "urn:ietf:params:oauth:token-type:access_token", "subjectTokenType": "urn:ietf:params:oauth:token-type:jwt", "subjectToken": "not-a-real-token"}'
{"error":"invalid_target","error_description":"The target service indicated by the \"audience\" parameters is invalid. This might either be because the pool or provider is disabled or deleted or because it doesn't exist."}
```

**O Google recusou a audiência antes de ler o token**: não existe um pool `ci-pool` num projeto de número
`415104041262` que ele consiga achar, porque esse número foi inventado para este curso. Repare que o
pedido não levava credencial do Google nenhuma, e o STS respondeu mesmo assim. **O STS é chamado sem
credencial do Google**, porque o trabalho inteiro dele é emitir a primeira; o que ele confere no lugar é o
token de fora, contra o provider do pool. Com um pool real, o mesmo pedido com um token qualquer seria
recusado pelo token; com um token real de um repositório fora de `example`, pela condição.

É até aí que o laboratório leva a federação, e é longe: a configuração é real, o arquivo é real, o pedido
é o que um workload manda, e a recusa é do Google.
