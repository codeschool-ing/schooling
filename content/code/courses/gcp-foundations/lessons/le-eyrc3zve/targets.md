---
title: Targets: tags or service accounts
version: 1
---

**A rule names its machines in one of three ways**: all the machines in the network, the machines carrying a
**network tag**, or the machines running as a **service account**. The same three, minus *all*, name the
sources of an ingress rule when the traffic comes from inside the network. Which one a company uses is a
security decision, not a matter of taste.

| | a network tag | a service account |
|---|---|---|
| what it is | a word on the machine, such as `web` | the identity the machine runs as, lesson 8 |
| who can put it on a machine | **anyone who can edit the machine** | someone holding `roles/iam.serviceAccountUser` on that account |
| what it already means | nothing else | everything the account may do in IAM |

The difference is in the second line. **A tag is a word anyone who can edit the machine can add**, and adding
`db` to a machine opens every rule that targets `db` to it. Attaching a service account needs a role on the
account itself, the same act-as permission lesson 8 warned about, so a rule targeting `db@` cannot be widened
by somebody who only edits instances. The planner uses service accounts for every rule that lets something
in, and tags only for rules that take something away, where a misplaced tag can only make a machine harder
to reach.

## Writing one

In `~/gcp/firewall`, with lesson 2's provider file:

```sh
mkdir -p ~/gcp/firewall && cd ~/gcp/firewall
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Save this as `firewall.tf`. It lets the web machines reach the database on 5432, and it has two mistakes:

```hcl
resource "google_compute_firewall" "web_to_db" {
  project  = "planner-dev"
  name     = "allow-web-to-db"
  network  = "planner"
  priority = 70000

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_tags             = ["web"]
  target_service_accounts = ["db@planner-dev.iam.gserviceaccount.com"]
}
```

```
ana@laptop:~/gcp/firewall$ terraform plan -input=false -no-color 2>&1 | grep -E "^Error|conflicts"
Error: expected priority to be in the range (0 - 65535), got 70000
Error: Conflicting configuration arguments
"source_tags": conflicts with target_service_accounts
Error: Conflicting configuration arguments
"target_service_accounts": conflicts with source_tags
```

**The provider refuses both before asking Google.** A priority stops at 65535. And a rule may name its
machines by tags or by service accounts, never both: a source by tag with a target by account mixes the two
ways of naming, which Google's API refuses and the provider knows it does. Name the source by its account
too. Replace `firewall.tf` with this:

```hcl
resource "google_compute_firewall" "web_to_db" {
  project = "planner-dev"
  name    = "allow-web-to-db"
  network = "planner"

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_service_accounts = ["web@planner-dev.iam.gserviceaccount.com"]
  target_service_accounts = ["db@planner-dev.iam.gserviceaccount.com"]
}
```

```
ana@laptop:~/gcp/firewall$ terraform plan -input=false -no-color | grep -E "^Plan|priority|direction"
      + direction               = (known after apply)
      + priority                = 1000
Plan: 1 to add, 0 to change, 0 to destroy.
```

Priority 1000, the default, since the file no longer says one. The direction is *known after apply*: the file
does not say one either, and Google fills in `INGRESS` when it creates the rule. Planned, not created; the
`planner` network is the one lesson 15 planned and nobody made.

**A rule names a source by account, not by address.** The database is not told that 10.10.0.5 may connect;
it is told that whatever runs as `web@` may, wherever it is in the network and whatever address it has
today. Machines come and go with new addresses, and a rule written in addresses goes wrong the first time
one of them is replaced.
