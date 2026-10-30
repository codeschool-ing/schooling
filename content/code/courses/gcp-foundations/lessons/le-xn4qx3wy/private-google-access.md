---
title: Private Google Access
version: 1
---

**Private Google Access lets a machine with no external address reach Google's APIs.** Cloud Storage,
Pub/Sub, BigQuery and the rest are served on public addresses, and a machine with only an internal one
cannot reach a public address by itself. With Private Google Access switched on for its subnet, it can: the
packets leave by the default internet gateway route and never leave Google's network, and nothing on the
internet is reachable that way. It is **a setting per subnet**, `private_ip_google_access` in Terraform, and
it changes nothing for machines that have an external address.

## Two ranges of Google's

Google publishes two sets of addresses for reaching its APIs privately, each behind a name that resolves to
them. Ask the laptop's own resolver:

```
ana@laptop:~/gcp$ getent hosts private.googleapis.com restricted.googleapis.com | sort
199.36.153.10   private.googleapis.com
199.36.153.11   private.googleapis.com
199.36.153.4    restricted.googleapis.com
199.36.153.5    restricted.googleapis.com
199.36.153.6    restricted.googleapis.com
199.36.153.7    restricted.googleapis.com
199.36.153.8    private.googleapis.com
199.36.153.9    private.googleapis.com
```

**Real answers**, from public DNS: four addresses each, the `/30` ranges `199.36.153.8/30` and
`199.36.153.4/30`.

| name | range | what it reaches |
|---|---|---|
| `private.googleapis.com` | `199.36.153.8/30` | most Google APIs |
| `restricted.googleapis.com` | `199.36.153.4/30` | only the APIs that VPC Service Controls can protect, so that a perimeter around a project's data cannot be stepped around |

Neither is used by default. A machine asking for `storage.googleapis.com` gets the ordinary public addresses,
which Private Google Access also reaches, and that is enough for most networks. A company that wants every
API call to go to one of the two ranges creates a **private DNS zone** for `googleapis.com` that answers with
them, lesson 19, and a route for the range, the previous section's `private-googleapis`. That is the
planner's production: no default route, a route for `199.36.153.8/30` only, and DNS sending
`*.googleapis.com` there.

## Switching it on

The São Paulo subnet of lesson 15, with Private Google Access on. In `~/gcp/pga`, with lesson 2's provider
file:

```sh
mkdir -p ~/gcp/pga && cd ~/gcp/pga
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Save as `subnet.tf`:

```hcl
resource "google_compute_subnetwork" "sao_paulo" {
  project                  = "planner-dev"
  name                     = "planner-sao-paulo"
  network                  = "planner"
  region                   = "southamerica-east1"
  ip_cidr_range            = "10.10.0.0/20"
  private_ip_google_access = true
}
```

```
ana@laptop:~/gcp/pga$ terraform plan -input=false -no-color | grep -E "^Plan|private_ip_google_access"
      + private_ip_google_access         = true
Plan: 1 to add, 0 to change, 0 to destroy.
```

One line of the file. What it does not do is as important: **it opens no firewall rule and needs none
inbound**, since the machine starts the connection and lesson 16's implied rule allows egress; and **it gives
no permission**. A machine that reaches Cloud Storage still needs its service account to hold a role on the
bucket, lesson 8, and reaching the API without one is a refusal from IAM rather than from the network.
