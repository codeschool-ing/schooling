---
title: Shared VPC: one network, several projects
version: 1
---

**Shared VPC lets one project own a network and other projects put their machines in it.** The owner is the
**host project**; the others are **service projects**. The network, its subnets, its routes and its firewall
rules live in the host and are run by the network team. The machines, databases and clusters live in the
service projects and are run by the teams that own them, each billed to its own project. It is how one
company has one network without having one project.

The planner's design from lesson 2 was made for it. `planner-network`, in the `shared` folder, is the host,
and `planner-prod` and `planner-staging` are service projects attached to it:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l18-shared\" aria-label=\"The host project planner-network holds the network planner, with two subnets: planner-prod-sao-paulo and planner-staging-sao-paulo, and the firewall rules. The network team runs it. Below, two service projects, planner-prod and planner-staging, each holding its own machines, which sit in the host's subnets: production machines in the prod subnet, staging machines in the staging subnet. The developers group holds Network User on the staging subnet only. Each service project is billed for its own machines and their traffic.\"><defs><marker id=\"l18-shared-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"16.0\" width=\"680.0\" height=\"120.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"40.0\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">host project planner-network</text><text x=\"680.0\" y=\"34.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">run by the network team</text><rect x=\"60.0\" y=\"52.0\" width=\"280.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"200.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">planner-prod-sao-paulo</text><rect x=\"380.0\" y=\"52.0\" width=\"280.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"520.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">planner-staging-sao-paulo</text><text x=\"360.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">network planner: subnets, routes, firewall rules</text><rect x=\"60.0\" y=\"180.0\" width=\"280.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">service project planner-prod</text><text x=\"200.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">production machines</text><text x=\"200.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">billed here</text><path d=\"M200.0 178.0 L200.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-shared-af-ah-phosphor)\"></path><rect x=\"380.0\" y=\"180.0\" width=\"280.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"520.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">service project planner-staging</text><text x=\"520.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">staging machines</text><text x=\"520.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">billed here</text><path d=\"M520.0 178.0 L520.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-shared-af-ah-phosphor)\"></path><text x=\"530.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">planner-devs: Network User</text><text x=\"360.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">one network, run in one place; machines and bills stay with their teams</text></svg>", "caption": "The host owns the network; service projects own what runs in it."}
```

## Who does what

Shared VPC splits the work of a network across four roles, which is most of its value:

| role | granted on | lets its holder |
|---|---|---|
| `roles/compute.xpnAdmin`, Shared VPC Admin | the organisation or a folder | make a project a host, and attach service projects to it |
| `roles/compute.networkAdmin` | the host project | create and change networks, subnets and routes |
| `roles/compute.securityAdmin` | the host project | create and change firewall rules |
| `roles/compute.networkUser`, Network User | the host project, or **one subnet** of it | create resources in a service project that use that subnet |

The last row is the one that matters day to day. **A team that holds Network User on one subnet can put
machines there and nowhere else**, while the subnet, its range and the firewall in front of it stay the
network team's. Granting it on the whole host project gives every subnet to the team, which is the shortcut
the planner does not take. (`xpn` in the role's name is the feature's old internal name, and it never
changed.)

A service project is attached to **one host at a time**, and a host cannot itself be a service project. Both
must be in the same organisation.

## Writing it

In `~/gcp/shared-vpc`, with lesson 2's provider file:

```sh
mkdir -p ~/gcp/shared-vpc && cd ~/gcp/shared-vpc
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Save this as `shared.tf`. It makes `planner-network` a host, attaches the two service projects, and gives the
developers group the staging subnet and nothing else:

```hcl
resource "google_compute_shared_vpc_host_project" "network" {
  project = "planner-network"
}

resource "google_compute_shared_vpc_service_project" "prod" {
  host_project    = google_compute_shared_vpc_host_project.network.project
  service_project = "planner-prod"
}

resource "google_compute_shared_vpc_service_project" "staging" {
  host_project    = google_compute_shared_vpc_host_project.network.project
  service_project = "planner-staging"
}

resource "google_compute_subnetwork_iam_member" "devs_use_staging" {
  project    = "planner-network"
  region     = "southamerica-east1"
  subnetwork = "planner-staging-sao-paulo"
  role       = "roles/compute.networkUser"
  member     = "group:planner-devs@example.com"
}
```

```
ana@laptop:~/gcp/shared-vpc$ terraform plan -input=false -no-color | grep -E "^Plan|# google|role|member"
  # google_compute_shared_vpc_host_project.network will be created
  # google_compute_shared_vpc_service_project.prod will be created
  # google_compute_shared_vpc_service_project.staging will be created
  # google_compute_subnetwork_iam_member.devs_use_staging will be created
  + resource "google_compute_subnetwork_iam_member" "devs_use_staging" {
      + member     = "group:planner-devs@example.com"
      + role       = "roles/compute.networkUser"
Plan: 4 to add, 0 to change, 0 to destroy.
```

Four resources, planned and not created. Applying them needs the Shared VPC Admin role on the organisation,
which nobody in this lab holds. **Billing follows the machine, not the network**: a machine that
`planner-staging` creates in the shared subnet is billed to `planner-staging`, and so is the traffic it
sends, which is what keeps lesson 14's query by project true after the network moved out of the projects.
