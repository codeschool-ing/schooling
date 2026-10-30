---
title: Impersonation: borrowing an account for an hour
version: 1
---

**Impersonation is a person, or another service account, asking Google for a token that belongs to a
service account, and using it for a while.** The person keeps their own identity and their own second
factor; the service account keeps its roles; and the link between them is a grant of
`roles/iam.serviceAccountTokenCreator` on the account, which can be read, audited and removed. Every
request made with the borrowed token is logged as the service account **and** names who borrowed it.

That answers a question every team meets: how does a person run the deployment as the deployer,
without a credential that lives on their laptop? The deployer's roles stay on the deployer, and the
people who may borrow them are a list on one account.

## The lab asks, and Google refuses

`gcloud` has a flag for one command, `--impersonate-service-account`, and a property for every command
after it, `auth/impersonate_service_account`. The flag is enough to see what happens:

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

**The request never reached the emulator.** Before any Pub/Sub call, `gcloud` asked
`iamcredentials.googleapis.com`, in Google's datacentres, for a token in the deployer's name, with the
placeholder as its own credential. The refusal names the method,
`google.iam.credentials.v1.IAMCredentials.GenerateAccessToken`, and the role the caller would need. That
method is the whole of impersonation, and `curl` can call it directly:

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

The body says what is asked for: a token for the **scope** `cloud-platform`, every API the account's roles
allow, with a **lifetime** of `3600s`. An hour is the most Google gives by default; an organisation can
allow up to twelve with the policy `iam.allowServiceAccountCredentialLifetimeExtension`. A token that
expires on its own is the property that makes impersonation safe: a token copied by mistake into a log
stops working before most people would find it.

## Terraform, as the deployer

The provider can impersonate too, which is how a team runs `terraform apply` with the deployer's roles
while each person signs in as themselves. Two pieces, one on each side: the account and who may borrow
it, and a provider block that borrows it. Make a directory with lesson 2's provider file:

```sh
mkdir -p ~/gcp/deployer && cd ~/gcp/deployer
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Save this as `deployer.tf`:

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

The account's `email` is the one thing in the plan worth noticing: `deployer@planner-dev.iam.gserviceaccount.com`
is known before anything is created, because it is built from the id and the project. The grant sits on the
account, not on the project, which is the previous section's rule. A real team's provider would then carry
`impersonate_service_account = "deployer@planner-dev.iam.gserviceaccount.com"` in its `provider` block, and
every plan and apply would start with the same `generateAccessToken` the lab saw refused.
