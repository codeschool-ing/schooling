---
title: An instance, and the ways into it
version: 1
---

**A Cloud SQL instance is one database server: a machine of a size you choose, a disk of a size you
choose, an engine on it, and one or more addresses.** It lives in a region, in a zone of that region,
and it is reached over a network you name. This is the command that would create Quitanda's, written
out in full. **It was not run**: there is no Cloud SQL on this laptop to answer it, and nothing below
is its output.

```sh
gcloud sql instances create quitanda-orders \
  --database-version=POSTGRES_16 --edition=enterprise \
  --cpu=2 --memory=8GiB \
  --region=southamerica-east1 --availability-type=zonal \
  --storage-type=SSD --storage-size=100 --storage-auto-increase \
  --no-assign-ip --network=projects/planner-dev/global/networks/default \
  --backup-start-time=06:00 --enable-point-in-time-recovery \
  --database-flags=log_min_duration_statement=500 \
  --deletion-protection
```

Every flag is a decision somebody makes on a real project:

| flag | what it decides |
|---|---|
| `--database-version=POSTGRES_16` | the engine and its major version; Cloud SQL picks the minor one |
| `--edition=enterprise` | the edition of the previous section, named rather than defaulted |
| `--cpu=2 --memory=8GiB` | the machine, on Enterprise: 2 vCPU and 8 GiB |
| `--availability-type=zonal` | one machine in one zone; `regional` is lesson 7's standby |
| `--storage-type=SSD --storage-size=100` | a 100 GiB SSD disk |
| `--storage-auto-increase` | the disk grows by itself before it fills, and never shrinks |
| `--no-assign-ip --network=…` | no public address; reachable only from that VPC network |
| `--backup-start-time=06:00` | the daily backup starts at 06:00 **UTC**, 03:00 in São Paulo |
| `--enable-point-in-time-recovery` | keep the transaction log too, which lesson 7 restores from |
| `--database-flags=…` | the engine's settings, the next section's subject |
| `--deletion-protection` | `gcloud sql instances delete` is refused until it is turned off |

**The backup time is in UTC**, and the command line's reference says so in its own words, "in the
UTC timezone". A team that writes `03:00` meaning the quiet hour in São Paulo gets a backup at
midnight, local time, while the day's last orders are still arriving.

**The disk grows and never shrinks.** `--storage-auto-increase` is on by default, and the reference
adds a warning beside it: a spike in usage can leave the instance with permanently larger, permanently
billed storage. Lowering the size means moving the data to a new instance. `--storage-auto-increase-limit`
puts a ceiling on it, which is worth setting the day the instance is made.

**No password went into the command.** `--root-password` exists, and it puts the password in the
shell's history, in the process list while the command runs, and in whatever script the command is
copied into. On PostgreSQL the instance is created with a user called `postgres` and no password you
typed, and the password is set afterwards with the command line asking for it:

```sh
gcloud sql users set-password postgres --instance=quitanda-orders --prompt-for-password
```

`--prompt-for-password` reads it with the echo turned off. Better still for the application is no
password at all: Cloud SQL can authenticate a service account through IAM, which `gcp-foundations`
lesson 8 sets up, with the flag `cloudsql.iam_authentication` turned on.

## Three ways in

**An instance created with `--no-assign-ip` has a private address and nothing else**, and that is the
arrangement Google recommends for anything in production. The address lives in a range of your VPC
network that you lend to Google's service network, once per network, which Google's documentation
calls **private services access**: a range reserved with `gcloud compute addresses create` and a
peering made with `gcloud services vpc-peerings connect`, both from the networking of
`gcp-foundations` lessons 15 and 18. A virtual machine in that network then
reaches the instance on its private address and port 5432, and nothing on the internet can, because
no route reaches it.

**The Cloud SQL Auth Proxy is the second way, and it is the one most applications use.** It is a small
program that runs beside the application, listens on `127.0.0.1:5432`, and forwards each connection
to the instance over TLS, authorising it with the IAM identity of whoever runs it. The application
connects to `localhost` and knows nothing of certificates; the instance is named by its **connection
name**, `planner-dev:southamerica-east1:quitanda-orders`, project, region and instance:

```sh
./cloud-sql-proxy --private-ip planner-dev:southamerica-east1:quitanda-orders
```

That was not run either, for the same reason as the first command. On a laptop of a developer with
the right role, the same line without `--private-ip` reaches an instance that has a public address,
and that is the third way: a **public IP**, which is refused to everything except the networks listed
in the instance's authorised networks, or reached only through the proxy. A public address with
`0.0.0.0/0` in the authorised networks is the database equivalent of lesson 4's leaking bucket, and it
happens for the same reason, somebody making a connection work on a Friday.

**What a connection costs is the networking of lesson 5.** Traffic from a machine in the same zone is
free; from another zone of the region it is 0.01 a GiB, like traffic between machines; from another
region it is the inter-region price. An application in `southamerica-east1-a` reading a database in
`southamerica-east1-b` pays for every result set it pulls across.
