---
title: More than one account
version: 1
---

**Credentials and configurations are kept apart.** `gcloud auth login` stores a credential for an account;
the `core/account` property of a configuration says which of the stored credentials that configuration
uses. One person with a work account and a personal one, or one engineer who also holds a break-glass
account, lesson 10, keeps one credential store and chooses per configuration. This lab has stored no
credential at all, which `gcloud auth list` says plainly:

```
ana@laptop:~/gcp$ gcloud auth list

No credentialed accounts.

To login, run:
  $ gcloud auth login `ACCOUNT`
```

The `default` configuration does not need one: its `auth/access_token_file` property hands gcloud the
placeholder token directly. The `prod` configuration of the previous section has no such property and no
account, so a command run with it stops before any request is made:

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

## Production through a service account

The planner does not let anybody's own account act in production. Its engineers' accounts hold one role
there, `roles/iam.serviceAccountTokenCreator` on `deployer@planner-prod`, and every production command runs
as that service account, lesson 8's impersonation. A configuration can carry that as a property, so nobody
has to remember the flag:

```
ana@laptop:~/gcp$ gcloud config set auth/impersonate_service_account deployer@planner-prod.iam.gserviceaccount.com --configuration=prod
Updated property [auth/impersonate_service_account].
```

Give `prod` the lab's placeholder token, so that it has something to impersonate with, and try again. This
request reaches Google:

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

**The warning on the first line is the property working**: every call will be made as `deployer@`. The refusal
comes from `iamcredentials.googleapis.com`, the service that issues the service account's short-lived token,
lesson 8's `GenerateAccessToken`, which refused the placeholder before any Pub/Sub request was made. With a
real account that holds the role, the same configuration would get a token for `deployer@` and use it, and
the audit log would name both: the service account that acted and the person who asked.

One credential gcloud keeps is not used by any of this: the **application default credentials** that
`gcloud auth application-default login` stores are for programs, not for gcloud, and lesson 24 is about them.
