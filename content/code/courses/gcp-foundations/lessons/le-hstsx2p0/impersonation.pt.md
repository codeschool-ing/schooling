---
title: Personificação: pegar uma conta emprestada por uma hora
version: 1
---

**Personificação é uma pessoa, ou outra conta de serviço, pedindo ao Google um token que pertence a uma
conta de serviço, e usando-o por um tempo.** A pessoa mantém a própria identidade e o próprio segundo
fator; a conta de serviço mantém os seus papéis; e a ligação entre as duas é uma concessão de
`roles/iam.serviceAccountTokenCreator` na conta, que pode ser lida, auditada e removida. Todo pedido
feito com o token emprestado fica registrado como a conta de serviço **e** nomeia quem a pegou.

Isso responde a uma pergunta que toda equipe encontra: como uma pessoa roda o deploy como o deployer, sem
uma credencial morando no notebook dela? Os papéis do deployer ficam no deployer, e as pessoas que podem
pegá-los emprestados são uma lista numa conta.

## O laboratório pede, e o Google recusa

O `gcloud` tem uma flag para um comando, `--impersonate-service-account`, e uma propriedade para todo
comando depois dela, `auth/impersonate_service_account`. A flag basta para ver o que acontece:

```
ana@laptop:~/gcp$ gcloud pubsub topics list --impersonate-service-account=deployer@planner-dev.iam.gserviceaccount.com
WARNING: This command is using service account impersonation. All API calls will be executed as [deployer@planner-dev.iam.gserviceaccount.com].
ERROR: (gcloud.pubsub.topics.list) UNAUTHENTICATED: Failed to impersonate [deployer@planner-dev.iam.gserviceaccount.com]. Make sure the account that's trying to impersonate it has access to the service account itself and the "roles/iam.serviceAccountTokenCreator" role. Request had invalid authentication credentials. Expected OAuth 2 access token, login cookie or other valid authentication credential. See https://developers.google.com/identity/sign-in/web/devconsole-project. This command is authenticated with an access token from /home/ana/gcp/placeholder-token specified by the [auth/access_token_file] property. Impersonation is used to impersonate deployer@planner-dev.iam.gserviceaccount.com. 
- '@type': type.googleapis.com/google.rpc.ErrorInfo
  metadata:
    method: google.iam.credentials.v1.IAMCredentials.GenerateAccessToken
    service: iamcredentials.googleapis.com
  reason: CREDENTIALS_MISSING
```

**O pedido nunca chegou ao emulador.** Antes de qualquer chamada ao Pub/Sub, o `gcloud` pediu ao
`iamcredentials.googleapis.com`, nos datacenters do Google, um token em nome do deployer, com o
placeholder como credencial própria. A recusa nomeia o método,
`google.iam.credentials.v1.IAMCredentials.GenerateAccessToken`, e o papel de que quem pede precisaria.
Esse método é a personificação inteira, e o `curl` consegue chamá-lo direto:

```
ana@laptop:~/gcp$ curl -sS -X POST -H 'Authorization: Bearer placeholder' -H 'Content-Type: application/json' -d '{"scope": ["https://www.googleapis.com/auth/cloud-platform"], "lifetime": "3600s"}' https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/deployer@planner-dev.iam.gserviceaccount.com:generateAccessToken
{
  "error": {
    "code": 401,
    "message": "Request had invalid authentication credentials. Expected OAuth 2 access token, login cookie or other valid authentication credential. See https://developers.google.com/identity/sign-in/web/devconsole-project.",
    "status": "UNAUTHENTICATED",
    "details": [
      {
        "@type": "type.googleapis.com/google.rpc.ErrorInfo",
        "reason": "CREDENTIALS_MISSING",
        "metadata": {
          "method": "google.iam.credentials.v1.IAMCredentials.GenerateAccessToken",
          "service": "iamcredentials.googleapis.com"
        }
      }
    ]
  }
}
```

O corpo diz o que é pedido: um token para o **escopo** `cloud-platform`, toda API que os papéis da conta
permitem, com **validade** de `3600s`. Uma hora é o máximo que o Google dá por padrão; uma organização pode
permitir até doze com a política `iam.allowServiceAccountCredentialLifetimeExtension`. Um token que expira
sozinho é a propriedade que torna a personificação segura: um token copiado por engano num log para de
funcionar antes que a maioria das pessoas o encontre.

## Terraform, como o deployer

O provider também personifica, que é como uma equipe roda `terraform apply` com os papéis do deployer
enquanto cada pessoa entra como ela mesma. Duas peças, uma de cada lado: a conta e quem pode pegá-la
emprestada, e um bloco de provider que a pega. Crie um diretório com o arquivo do provider da lição 2:

```sh
mkdir -p ~/gcp/deployer && cd ~/gcp/deployer
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Salve isto como `deployer.tf`:

```hcl
resource "google_service_account" "deployer" {
  account_id   = "deployer"
  display_name = "Runs terraform apply for planner"
}

# Who may borrow it: the on-call group, on this one account.
resource "google_service_account_iam_member" "oncall_borrows_deployer" {
  service_account_id = google_service_account.deployer.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "group:planner-oncall@example.com"
}
```

```
ana@laptop:~/gcp/deployer$ terraform plan -input=false -no-color | grep -E '^  # |      \+ (account_id|email|member|role) |^Plan:'
  # google_service_account.deployer will be created
      + account_id      = "deployer"
      + email           = "deployer@planner-dev.iam.gserviceaccount.com"
      + member          = "serviceAccount:deployer@planner-dev.iam.gserviceaccount.com"
  # google_service_account_iam_member.oncall_borrows_deployer will be created
      + member             = "group:planner-oncall@example.com"
      + role               = "roles/iam.serviceAccountTokenCreator"
Plan: 2 to add, 0 to change, 0 to destroy.
```

O `email` da conta é a única coisa do plano que vale notar:
`deployer@planner-dev.iam.gserviceaccount.com` é conhecido antes de qualquer coisa ser criada, porque é
feito do id e do projeto. A concessão fica na conta, não no projeto, a regra da seção anterior. O provider
de uma equipe real levaria então `impersonate_service_account = "deployer@planner-dev.iam.gserviceaccount.com"`
no bloco `provider`, e todo plan e apply começaria com o mesmo `generateAccessToken` que o laboratório viu
recusado.
