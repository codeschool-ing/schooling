---
title: The REST underneath
version: 1
---

**Every tool in this course is a client of the same APIs.** gcloud, Terraform's provider, the client
libraries and the console all turn what you asked for into HTTP requests to `*.googleapis.com`, or to gRPC,
its binary sibling, on the same services. Each API is a set of resources with names like paths,
`projects/planner-dev/topics/orders`, and a few verbs on them. Seeing the requests is the fastest way to
understand any of the tools, and gcloud will show them.

## gcloud, with the requests showing

`--log-http` makes gcloud print every request it sends and every response it receives. The full log is long,
mostly headers, so the `sed` keeps the address, the method, the bodies and the status:

```
ana@laptop:~/gcp$ gcloud pubsub topics create orders --log-http 2>&1 | sed -n '/^uri:/p;/^method:/p;/^== body start/,/^== body end/p;/^status:/p;/^-- body start/,/^-- body end/p'
uri: http://localhost:8085/v1/projects/planner-dev/topics/orders?alt=json
method: PUT
== body start ==
{"name": "projects/planner-dev/topics/orders"}
== body end ==
status: 200
-- body start --
{
  "name": "projects/planner-dev/topics/orders"
}

-- body end --
```

**Creating a topic is a `PUT` of its name to its own address.** The address is the resource's name under
`/v1/`, the body is the resource, and the reply is the resource as the server now holds it. It went to
`localhost:8085` because lesson 1 set `api_endpoint_overrides/pubsub`; without that property, the same request
would go to `https://pubsub.googleapis.com/v1/projects/planner-dev/topics/orders`.

## The same API, by hand

With the shape known, `curl` can do what gcloud did. Make a subscription the same way, a `PUT` of a resource
whose body names its topic:

```
ana@laptop:~/gcp$ curl -s -X PUT http://localhost:8085/v1/projects/planner-dev/subscriptions/orders-sub -H 'Content-Type: application/json' -d '{"topic": "projects/planner-dev/topics/orders"}'
{
  "name": "projects/planner-dev/subscriptions/orders-sub",
  "topic": "projects/planner-dev/topics/orders",
  "pushConfig": {
  },
  "ackDeadlineSeconds": 10,
  "messageRetentionDuration": "604800s"
}
```

The reply has fields nobody sent, `ackDeadlineSeconds` and `messageRetentionDuration`, which are the
subscription's defaults: the API fills in what was not said, exactly as Terraform's plans showed with *known
after apply*.

Against Google, the one difference is a header, `Authorization: Bearer` and an access token. With the lab's
placeholder:

```
ana@laptop:~/gcp$ curl -s https://pubsub.googleapis.com/v1/projects/planner-dev/topics -H "Authorization: Bearer $(cat ~/gcp/placeholder-token)"
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
          "method": "google.pubsub.v1.Publisher.ListTopics",
          "service": "pubsub.googleapis.com"
        }
      }
    ]
  }
}
```

**That is the refusal every tool in this course has quoted**, without a tool in the way: a JSON error with a
code, a status, and an `ErrorInfo` naming the service and the method, `google.pubsub.v1.Publisher.ListTopics`,
which is the gRPC name of what the REST address called. gcloud's errors, Terraform's errors and the libraries'
errors are this body, reworded.
