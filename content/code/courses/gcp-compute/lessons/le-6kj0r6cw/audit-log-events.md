---
title: Events from the audit log
version: 1
---

Some services announce their changes directly, as Cloud Storage does. Most do not. **For those,
Eventarc listens to Cloud Audit Logs: every administrative call to a Google API is written there,
and a trigger can match any of them by service and method.** It is the widest net Eventarc has,
and the slowest.

## What an audit entry carries

An audit log entry records who called which method of which service, on what resource, and whether
it worked. A trigger on them names three things:

| criterion | an example |
|---|---|
| `type` | `google.cloud.audit.log.v1.written` |
| `serviceName` | `compute.googleapis.com` |
| `methodName` | `v1.compute.instances.insert` |

So "run something whenever anybody creates a virtual machine in this project" is one trigger, with
nothing to install on the machines and nothing to poll. Google's documentation lists the services
and methods that write audit entries; the method names are the API's own, which is why they read
like `v1.compute.instances.insert` rather than like English.

## Written down

In Terraform the trigger looks like section 02's, with different criteria. **This block was not
planned in the lab**, because the plan would print what section 02's printed:

```hcl
resource "google_eventarc_trigger" "new_machines" {
  name     = "machine-created"
  location = "southamerica-east1"

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.audit.log.v1.written"
  }
  matching_criteria {
    attribute = "serviceName"
    value     = "compute.googleapis.com"
  }
  matching_criteria {
    attribute = "methodName"
    value     = "v1.compute.instances.insert"
  }

  destination {
    cloud_run_service {
      service = "inventory"
      region  = "southamerica-east1"
    }
  }

  service_account = "eventarc@planner-dev.iam.gserviceaccount.com"
}
```

## Three things that surprise people

**Data access logs are off by default.** Administrative actions, such as creating a machine, are
always logged; reading data, such as fetching an object, is logged only for the services where you
turn data access logs on, and you pay for the volume. A trigger on a method that is not logged
never fires, and nothing tells you so.

**It is not immediate.** An audit entry is written after the call completes, and Google documents
delivery as taking up to a few minutes, against seconds for a direct event. Fine for keeping an
inventory, wrong for anything a person is waiting on.

**The location is `global` for global services.** Audit logs of a service that has no region are
written globally, and a trigger in `southamerica-east1` would see nothing; the trigger's location
has to match where the entries are written.

None of this could be run here: there is no project, so nothing writes audit entries. The shape of
the event that arrives is a CloudEvent like every other, with the audit entry as its data, and the
function receiving it is written exactly as in lesson 17.
