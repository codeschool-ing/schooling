---
title: As credenciais de quem o provider usa
version: 1
---

**O bloco do provider não nomeia chave nenhuma, e não deve.** O provider google procura credenciais numa
ordem fixa e pega a primeira que acha. Num laptop é o login de uma pessoa, numa esteira é a própria conta
de serviço da máquina, e em nenhum dos dois lugares um arquivo de chave é escrito na configuração.

Peça um plano antes de lhe dar qualquer coisa:

```
ana@laptop:~/gcp/tf/shop$ terraform plan -input=false -no-color 2>&1 | tail -8


Error: Attempted to load application default credentials since neither `credentials` nor `access_token` was set in the provider block.  No credentials loaded. To use your gcloud credentials, run 'gcloud auth application-default login'.  Original error: google: could not find default credentials. See https://cloud.google.com/docs/authentication/external/set-up-adc for more information

  with provider["registry.terraform.io/hashicorp/google"],
  on main.tf line 9, in provider "google":
   9: provider "google" {
```

O provider procurou em todos os lugares que conhece, não achou nada, e parou antes de calcular qualquer
coisa. A mensagem nomeia o terceiro lugar, as Application Default Credentials, porque é lá que ele
esperava que uma pessoa num laptop tivesse feito login.

## A ordem, a primeira vence

1. **Um token de acesso** em `GOOGLE_OAUTH_ACCESS_TOKEN`, ou `access_token` no bloco. É usado como está,
   sem renovação, e expira em uma hora quando vem do Google. Este curso o usa para dar ao provider algo que
   não é credencial nenhuma.
2. **Um arquivo de credenciais** nomeado por `GOOGLE_APPLICATION_CREDENTIALS` ou `credentials` no bloco:
   uma chave de conta de serviço, ou uma configuração de Workload Identity Federation.
3. **Application Default Credentials**, o arquivo que `gcloud auth application-default login` escreve em
   `~/.config/gcloud/application_default_credentials.json`. Essa é a resposta do laptop: o login da própria
   pessoa, de curta duração, renovado pelo `gcloud`.
4. **O servidor de metadados**, quando o Terraform roda no Google Cloud: um passo do Cloud Build, uma
   máquina do Compute Engine, um job do Cloud Run. A conta de serviço da máquina responde, sem nada
   guardado em lugar nenhum. Essa é a resposta da esteira.

**Um arquivo de chave de conta de serviço é o último recurso e nunca o padrão.** É um segredo de longa
duração que funciona de qualquer lugar até alguém apagá-lo, e a lição 8 de `gcp-foundations` é a lição
sobre o porquê. O segundo item existe sobretudo para a Workload Identity Federation, em que o arquivo não
guarda segredo, só onde trocar um token de outra plataforma, que é a lição 9 daquele curso.

## O token que este curso usa

Não há conta do Google aqui, então este curso dá ao provider um token que não é um:

```sh
export GOOGLE_OAUTH_ACCESS_TOKEN=fake
```

```
ana@laptop:~/gcp/tf/shop$ terraform plan -input=false -no-color | grep -A3 -E "^  #|terraform_labels" | grep -v "^--"
  # google_storage_bucket.assets will be created
  + resource "google_storage_bucket" "assets" {
      + deletion_policy             = "DELETE"
      + effective_labels            = {
      + terraform_labels            = {
          + "goog-terraform-provisioned" = "true"
          + "managed-by"                 = "terraform"
          + "team"                       = "shop"
```

O plano é calculado no seu computador: o Terraform compara a configuração com o estado, não acha nada no
estado e propõe criar o bucket. `terraform_labels` é a junção dos rótulos do próprio recurso com os
`default_labels` do provider, que é o que será escrito no bucket: os dois do bloco do provider, e um
terceiro que o provider acrescenta sozinho, `goog-terraform-provisioned`, que diz que um recurso veio do
Terraform sem ninguém precisar lembrar de dizer. `effective_labels` acrescenta os que o próprio Google
anexar. Com o token, o provider pergunta uma vez ao Google de quem é o token, ouve que é inválido, e segue
sem dizer nada; nada mais sai do seu computador, e o bucket vai para o `fake-gcs-server`.

## Agindo como outra conta

Uma pessoa num laptop não deve ter as permissões para mudar a produção diretamente. O provider pode, em vez
disso, **personificar** (impersonate) uma conta de serviço: as credenciais da própria pessoa só são usadas
para pedir um token de curta duração da conta de serviço, e todo o resto é feito como essa conta:

```hcl
provider "google" {
  project                     = "planner-prod"
  region                      = "southamerica-east1"
  impersonate_service_account = "terraform@planner-prod.iam.gserviceaccount.com"
}
```

Para isso, a pessoa precisa de `roles/iam.serviceAccountTokenCreator` naquela conta, e de nada no
projeto. Tirar esse papel tira o acesso dela à produção, e o log de auditoria da lição 9 registra os dois
nomes: a conta que agiu e a pessoa por trás dela. Esse bloco não foi executado aqui: não existe
`planner-prod` para onde personificar.
