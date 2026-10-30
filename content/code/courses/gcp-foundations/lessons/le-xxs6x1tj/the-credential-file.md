---
title: The credential file, and an exchange Google refuses
version: 1
---

A workload does not run the exchange by hand. **It is given a credential configuration file**, a short
JSON document that tells Google's client libraries and `gcloud` where to find the outside token and what
to trade it for. The file holds **no secret**: it says where the token is, not what it is. That is the
difference between it and a key, and it is why it can sit in a repository.

`gcloud` writes one without asking Google anything, so the lab can make the real thing. The project number
and the pool are the made-up ones of the previous section:

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

Every field is one of the steps of the first section:

| field | what it says |
|---|---|
| `type: external_account` | this is federation, not a key, which would say `service_account` |
| `audience` | the pool and provider the token is presented to, as a full resource name |
| `subject_token_type` | the outside token is a JWT |
| `token_url` | step 2: Google's Security Token Service |
| `credential_source.file` | where the outside token will be when the workload runs |
| `service_account_impersonation_url` | step 3: trade the federated token for the deployer's |

In a GitHub workflow, Google's own action for authentication writes this file and puts the job's token
where `credential_source` says; the client libraries of lesson 24 find the file through the variable
`GOOGLE_APPLICATION_CREDENTIALS`, and the workflow never holds a key.

## The exchange, sent to Google

Step 2 is one HTTP request, and `curl` can send it to the real STS. The token in it is the text
`not-a-real-token`, which is all the lab has:

```
ana@laptop:~/gcp/federation$ curl -sS -X POST https://sts.googleapis.com/v1/token -H 'Content-Type: application/json' -d '{"grantType": "urn:ietf:params:oauth:grant-type:token-exchange", "audience": "//iam.googleapis.com/projects/415104041262/locations/global/workloadIdentityPools/ci-pool/providers/github", "scope": "https://www.googleapis.com/auth/cloud-platform", "requestedTokenType": "urn:ietf:params:oauth:token-type:access_token", "subjectTokenType": "urn:ietf:params:oauth:token-type:jwt", "subjectToken": "not-a-real-token"}'
{"error":"invalid_target","error_description":"The target service indicated by the \"audience\" parameters is invalid. This might either be because the pool or provider is disabled or deleted or because it doesn't exist."}
```

**Google refused the audience before it read the token**: there is no pool `ci-pool` in a project numbered
`415104041262` that it can find, because that number was made up for this course. Note that the request
carried no Google credential at all, and STS answered anyway. **STS is called without a Google
credential**, because its whole job is to issue the first one; what it checks instead is
the outside token, against the pool's provider. With a real pool, the same request with a junk token would
be refused for the token; with a real token from a repository outside `example`, for the condition.

That is as far as the lab can take federation, and it is a long way: the configuration is real, the file is
real, the request is the one a workload sends, and the refusal is Google's.
