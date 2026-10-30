---
title: Searching the estate
version: 1
---

**A search names a scope, a query and, optionally, the asset types**, and returns what matches anywhere under
the scope. The API is public in the sense that matters here: its **discovery document**, the machine-readable
description every Google API publishes, needs no credential at all, and it is where gcloud, the client
libraries and Terraform's provider learn what an API offers. Ask it which methods the Cloud Asset API has:

```
ana@laptop:~/gcp$ curl -s 'https://cloudasset.googleapis.com/$discovery/rest?version=v1' | jq -r '.resources.v1.methods | keys[]'
analyzeIamPolicy
analyzeIamPolicyLongrunning
analyzeMove
analyzeOrgPolicies
analyzeOrgPolicyGovernedAssets
analyzeOrgPolicyGovernedContainers
batchGetAssetsHistory
exportAssets
queryAssets
searchAllIamPolicies
searchAllResources
```

**A real answer from Google**, with no token sent: the list of methods, which are gcloud's commands of the
previous section under their API names. And the one the planner uses most:

```
ana@laptop:~/gcp$ curl -s 'https://cloudasset.googleapis.com/$discovery/rest?version=v1' | jq '.resources.v1.methods.searchAllResources | {httpMethod, flatPath, parameters: (.parameters | keys)}'
{
  "httpMethod": "GET",
  "flatPath": "v1/{v1Id}/{v1Id1}:searchAllResources",
  "parameters": [
    "assetTypes",
    "orderBy",
    "pageSize",
    "pageToken",
    "query",
    "readMask",
    "scope"
  ]
}
```

A `GET` on a scope, `organizations/123456789012` or `folders/…` or `projects/…`, with `query` and `assetTypes`
the parameters that do the work. The others page through results and choose which fields come back.

## The query language

A query is a set of field conditions, the same idea as lesson 22's gcloud filters, over the fields every
resource has:

| query | finds |
|---|---|
| `labels.team:planner` | resources whose `team` label is `planner` |
| `NOT labels.team:*` | resources with **no** `team` label at all |
| `location:southamerica-east1` | resources in São Paulo |
| `state:ACTIVE` | resources whose state is active |
| `createTime<1735689600` | resources created before 1 January 2025, the time written in seconds |
| `name:scratch` | resources whose name contains the word |

Conditions are joined with `AND` and `OR`, and **asset types narrow the search** before the query does:
`--asset-types=pubsub.googleapis.com/Topic` looks only at topics.

The planner's weekly question, every topic in the organisation with no owner:

```
ana@laptop:~/gcp$ gcloud asset search-all-resources --scope=organizations/123456789012 --query="NOT labels.team:*" --asset-types=pubsub.googleapis.com/Topic
ERROR: (gcloud.asset.search-all-resources) UNAUTHENTICATED: Request had invalid authentication credentials. Expected OAuth 2 access token, login cookie or other valid authentication credential. See https://developers.google.com/identity/sign-in/web/devconsole-project. This command is authenticated with an access token from /home/ana/gcp/placeholder-token specified by the [auth/access_token_file] property.
- '@type': type.googleapis.com/google.rpc.ErrorInfo
  metadata:
    method: google.cloud.asset.v1.AssetService.SearchAllResources
    service: cloudasset.googleapis.com
  reason: CREDENTIALS_MISSING
```

Refused by `cloudasset.googleapis.com`, in the words of the method the discovery document named,
`SearchAllResources`. With `roles/cloudasset.viewer` on the organisation, the reply would be one line per
unlabelled topic in every project, with its project, its location and its creation time: the list lesson 14's
`forgotten.sql` would want next to it.
