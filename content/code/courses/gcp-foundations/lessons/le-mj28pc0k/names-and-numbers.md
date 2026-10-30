---
title: A project's three names, and the name of everything inside it
version: 1
---

**A project has three identifiers, and they are for three different readers.** Mixing them up is
the commonest small mistake in Google Cloud, because two of them look like each other and the
console shows all three on one line.

| | example | chosen by | can change |
|---|---|---|---|
| **project id** | `planner-dev` | you, at creation | never |
| **project number** | `415104041262` | Google, at creation | never |
| **project name** | `Planner development` | you | at any time |

The **id** is what you type: in `gcloud --project`, in Terraform, in the address of every resource.
It is unique across all of Google Cloud, so `planner-dev` can belong to one customer only, and once
a project is deleted its id is never handed out again. `planner-dev`, the id this course's lab uses,
may well belong to somebody's real project; the lab can never reach it, because Google refuses the
placeholder token before it looks any project up. The **number** is what Google uses inside: it
appears in the names of the service accounts Google creates for a project, in some error messages and
in billing data. The number above was made up for this course. The **name** is a
label for people, shown in the console's project picker; nothing joins to it, so rename it freely.

## The project is part of every name

Every resource's name begins with the project it lives in. A topic is not called `orders`; it is
called `projects/planner-dev/topics/orders`. Ask the emulator, which keeps that rule exactly, for two
topics with the same short name in two projects:

```
ana@laptop:~/gcp$ gcloud pubsub topics create orders --project planner-dev
Created topic [projects/planner-dev/topics/orders].
ana@laptop:~/gcp$ gcloud pubsub topics create orders --project planner-prod
Created topic [projects/planner-prod/topics/orders].
ana@laptop:~/gcp$ gcloud pubsub topics list --project planner-prod --format="value(name)"
projects/planner-prod/topics/orders
ana@laptop:~/gcp$ gcloud pubsub topics list --format="value(name)"
projects/planner-dev/topics/orders
```

**Two topics, both called `orders`, and neither knows about the other**, because the project in front
of the name makes them two different names. The emulator accepted `planner-prod` without asking whether
such a project exists, which Google would not do; what it does keep is the naming, and the naming is
the point. `--project` on one command overrides the `core/project` property for that command only,
and the second list without it shows `planner-dev` again.

## The full resource name

Inside one API the short form is enough. **Across APIs**, in an IAM condition, in the asset inventory
of lesson 25, in an audit log, Google uses the **full resource name**, which adds the service in front:

| short name, inside Pub/Sub | full resource name, everywhere |
|---|---|
| `projects/planner-dev/topics/orders` | `//pubsub.googleapis.com/projects/planner-dev/topics/orders` |
| `projects/planner-dev` | `//cloudresourcemanager.googleapis.com/projects/planner-dev` |
| `folders/345678901234` | `//cloudresourcemanager.googleapis.com/folders/345678901234` |

The service that owns the project itself is the **Resource Manager**, `cloudresourcemanager.googleapis.com`.
It is the API that creates projects and folders and moves them about, and no emulator answers it. Ask
the real one for `planner-dev` with no credential, and the refusal names the method it would have run:

```
ana@laptop:~/gcp$ curl -sS https://cloudresourcemanager.googleapis.com/v3/projects/planner-dev
{
  "error": {
    "code": 401,
    "message": "Request is missing required authentication credential. Expected OAuth 2 access token, login cookie or other valid authentication credential. See https://developers.google.com/identity/sign-in/web/devconsole-project.",
    "status": "UNAUTHENTICATED",
    "details": [
      {
        "@type": "type.googleapis.com/google.rpc.ErrorInfo",
        "reason": "CREDENTIALS_MISSING",
        "domain": "googleapis.com",
        "metadata": {
          "method": "google.cloud.resourcemanager.v3.Projects.GetProject",
          "service": "cloudresourcemanager.googleapis.com"
        }
      }
    ]
  }
}
```

`google.cloud.resourcemanager.v3.Projects.GetProject` is the method, in the form the API is defined in.
That a project called `planner-dev` exists, and whose it is, is something only an authenticated
caller with a role on it may learn; an anonymous one learns only that it must sign in. Lesson 24 comes
back to the shape of that answer.
