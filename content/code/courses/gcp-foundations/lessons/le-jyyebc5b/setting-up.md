---
title: Installing the lab
version: 1
---

Everything below runs in a terminal on Ubuntu 24.04, as your own user, and only the first block asks
for `sudo`. **Everything else lands in two places: `~/gcp`, where you work for the rest of the
course, and `~/.local`, where the Google Cloud CLI and Terraform go.** Deleting those two removes the
lab completely.

## The packages from Ubuntu

Python, `curl`, `jq` and `unzip` come from Ubuntu's own archive, and so does Java, which the Pub/Sub
emulator is written in:

```sh
sudo apt-get update
sudo apt-get install -y python3 python3-venv curl jq unzip openjdk-21-jre-headless
```

**`python3-venv` and the Java runtime are the two people leave out**, because neither comes with
Ubuntu. The section on failures says what each absence looks like.

## The Google Cloud CLI

Google publishes its command line as an archive that unpacks into a single directory and runs from
there, with its own copy of Python inside. These commands download one fixed version, the one every
transcript in this course was recorded with, into your home directory, so they need no `sudo`:

```sh
mkdir -p ~/gcp ~/.local/bin
cd ~/gcp
curl -sS -o gcloud.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-589.0.0-linux-x86_64.tar.gz
tar -xzf gcloud.tar.gz -C ~/.local
rm gcloud.tar.gz
```

The archive is about 90 MB. On a computer with an Arm processor, which includes a virtual machine
on a Mac with Apple silicon, the file name ends in `linux-arm.tar.gz` instead. A newer version works
for everything this course does; the version lines and the wording of a few messages will differ
from the lessons, and nothing else will.

Google's own instructions also offer the CLI as an Ubuntu package from `packages.cloud.google.com`.
That route installs it for every user and needs `sudo` for each update. The archive keeps the whole
lab in your home directory, and that is the reason this course takes it.

## Two more parts of the CLI

The CLI is built from **components**, and the archive brings only the core ones. The Pub/Sub emulator
is a component, and so are the `beta` commands that start it:

```sh
~/.local/google-cloud-sdk/bin/gcloud components install pubsub-emulator beta --quiet
```

Components are installed **at the version of the CLI you have**, so 589.0.0 brings the emulator
that shipped with 589.0.0, and a student who installs the same archive next year gets the same
emulator.

## Terraform

Lessons 2 to 21 write the estate as Terraform files and ask Terraform what it would do with them.
HashiCorp publishes it as a zip with one program inside:

```sh
cd ~/gcp
curl -sS -o terraform.zip https://releases.hashicorp.com/terraform/1.16.4/terraform_1.16.4_linux_amd64.zip
unzip -qo terraform.zip terraform -d ~/.local/bin
rm terraform.zip
```

On Arm the file is `terraform_1.16.4_linux_arm64.zip`. If you did the `iac` course and kept its lab,
this is the same version, and `terraform version` will say so.

## Python's libraries, in a virtual environment

Two Python libraries are used later: Google's client library for Pub/Sub in lesson 24, and DuckDB, a
small database that reads the billing data of lesson 14. A virtual environment is a directory holding
its own copy of Python's package installer, so what you install there touches nothing else on the
machine:

```sh
python3 -m venv ~/gcp/venv
~/gcp/venv/bin/pip install -q 'google-cloud-pubsub==2.42.0' 'duckdb==1.5.6'
```

## One file that sets up every terminal

A few environment variables tell the tools where things are. One short file sets all of them, and
every lesson starts by reading it:

```sh
cat > ~/gcp/env.sh <<'EOF'
# The Google Cloud courses' lab. Read it into every terminal: source ~/gcp/env.sh
export PATH="$HOME/.local/bin:$HOME/.local/google-cloud-sdk/bin:$PATH"
. "$HOME/gcp/venv/bin/activate"
export CLOUDSDK_CONFIG="$HOME/gcp/gcloud"
export PUBSUB_EMULATOR_HOST=localhost:8085
export TF_PLUGIN_CACHE_DIR="$HOME/gcp/terraform-plugins"
export CHECKPOINT_DISABLE=1
mkdir -p "$TF_PLUGIN_CACHE_DIR"
cd "$HOME/gcp"
EOF
```

Line by line, after the comment:

| line | what it does |
|---|---|
| `PATH` | puts `~/.local/bin`, where `terraform` is, and the CLI's own `bin`, where `gcloud` is, on the path |
| `activate` | switches to the virtual environment, so `python3` sees the two libraries |
| `CLOUDSDK_CONFIG` | **gives `gcloud` a directory of settings that belongs to the lab and to nothing else** |
| `PUBSUB_EMULATOR_HOST` | tells Google's client libraries to send Pub/Sub requests to the emulator on this computer |
| `TF_PLUGIN_CACHE_DIR` | keeps one copy of Terraform's Google provider, about 130 MB, for every directory that asks for it |
| `CHECKPOINT_DISABLE` | stops Terraform asking HashiCorp whether a newer version exists |

`CLOUDSDK_CONFIG` is the line that matters most. Without it, `gcloud` keeps its settings and its
credentials in `~/.config/gcloud`. **If you have ever signed in to a real Google account with
`gcloud`, that is where the account is**, and a lab that shared the directory would send its
commands to your real projects. With the line, the lab sees a directory of its own that has never
held a credential.

## The lab's settings

`gcloud` reads its settings, which it calls **properties**, from that directory. Five of them make the
lab what it is:

```sh
source ~/gcp/env.sh
echo placeholder > ~/gcp/placeholder-token
gcloud config set core/project planner-dev
gcloud config set core/disable_usage_reporting true
gcloud config set auth/access_token_file ~/gcp/placeholder-token
gcloud config set api_endpoint_overrides/pubsub http://localhost:8085/
gcloud config set compute/region southamerica-east1
```

| property | what it does |
|---|---|
| `core/project` | `planner-dev`, the project every command acts on unless it names another |
| `core/disable_usage_reporting` | keeps the CLI from sending Google statistics about its own use |
| `auth/access_token_file` | **the credential: the word `placeholder` in a file.** `gcloud` sends it as it stands, the emulator ignores it, and Google refuses it |
| `api_endpoint_overrides/pubsub` | **sends every Pub/Sub request to the emulator, on port 8085 of this computer, instead of to Google** |
| `compute/region` | `southamerica-east1`, São Paulo, the region every lesson works in |

Two of those commands answer with a warning, and both are expected. The override warns that
`http://localhost:8085/` belongs to no *universe domain* it knows: a universe is a separate copy of
Google Cloud, such as one run for a government, and `googleapis.com` is the public one. An address on
your own computer is in none of them, which is exactly what the lab wants.

The order matters once. `gcloud` checks a region against Google before it stores one, and it refuses
to ask anything at all until it has a credential, so `compute/region` comes after the token. With
only a placeholder to send, the check cannot be made, and `gcloud` says so and stores the value
anyway. Setting it a second time shows the warning:

```
ana@laptop:~/gcp$ gcloud config set compute/region southamerica-east1
WARNING: Property validation for compute/region was skipped.
Updated property [compute/region].
```

**Never put a real credential in that file**, or anywhere this course asks you to write. `placeholder`
is not a secret, and a request that escapes to Google by mistake fails rather than doing something.
A real token is a secret, and a file in your home directory gets copied into backups, shared folders
and screenshots without anybody deciding to.

## Every time you open a terminal

One line, in each of the two terminals:

```sh
source ~/gcp/env.sh
```

Your prompt gains `(venv)` at the front; the transcripts in the lessons leave it out.

In the **first terminal**, start the emulator. It keeps that terminal busy for as long as it runs,
which is the point: what it says appears there as it happens.

```sh
gcloud beta emulators pubsub start --host-port=localhost:8085
```

In the **second terminal**, check that each tool answers, and then send the emulator its first
request:

```
ana@laptop:~/gcp$ gcloud version
Google Cloud SDK 589.0.0
beta 2026.10.09
bq 2.1.40
bundled-python3-unix 3.14.8
core 2026.10.09
gcloud-crc32c 1.0.0
gsutil 5.37
pubsub-emulator 0.8.37
Updates are available for some Google Cloud CLI components.  To install them,
please run:
  $ gcloud components update
ana@laptop:~/gcp$ gcloud config list
[api_endpoint_overrides]
pubsub = http://localhost:8085/
[auth]
access_token_file = /home/ana/gcp/placeholder-token
[compute]
region = southamerica-east1
[core]
disable_usage_reporting = true
project = planner-dev

Your active configuration is: [default]
ana@laptop:~/gcp$ gcloud pubsub topics create orders
Created topic [projects/planner-dev/topics/orders].
ana@laptop:~/gcp$ gcloud pubsub topics list
---
name: projects/planner-dev/topics/orders
ana@laptop:~/gcp$ terraform version
Terraform v1.16.4
on linux_amd64
ana@laptop:~/gcp$ python3 -c 'from importlib.metadata import version as v; print(v("duckdb"), v("google-cloud-pubsub"))'
1.5.6 2.42.0
ana@laptop:~/gcp$ cd ~ && du -sh .local/google-cloud-sdk .local/bin/terraform gcp/venv
893M	.local/google-cloud-sdk
115M	.local/bin/terraform
135M	gcp/venv
ana@laptop:~/gcp$ ps -C java -o rss=,comm=
178328 java
```

`gcloud version` lists the components, and `pubsub-emulator` and `beta` are among them. **Leave
the update it offers alone**: `gcloud components update` would move the whole CLI to the newest
version, and the transcripts in these lessons to a version they were not recorded with.
`gcloud config list` prints the five properties, and says which **configuration** they belong to:
`default`, the one every CLI starts with. Lesson 22 makes more. `topics create` and `topics list`
are the first requests to reach the emulator, which accepted `planner-dev` as a project without
asking whether it exists. Nothing on this computer knows; that is the first difference between the
lab and Google, and the next section lists the rest.

In the first terminal, the emulator printed a few lines when it started:

```
ana@laptop:~/gcp$ gcloud beta emulators pubsub start --host-port=localhost:8085
Executing: /home/ana/.local/google-cloud-sdk/platform/pubsub-emulator/bin/cloud-pubsub-emulator --host=localhost --port=8085
[pubsub] This is the Google Pub/Sub fake.
[pubsub] Implementation may be incomplete or differ from the real system.
[pubsub] Oct 30, 2026 2:55:35 PM com.google.cloud.pubsub.testing.v1.Main main
[pubsub] INFO: IAM integration is disabled. IAM policy methods and ACL checks are not supported
[pubsub] SLF4J(W): No SLF4J providers were found.
[pubsub] SLF4J(W): Defaulting to no-operation (NOP) logger implementation
[pubsub] SLF4J(W): See https://www.slf4j.org/codes.html#noProviders for further details.
[pubsub] Oct 30, 2026 2:55:36 PM com.google.cloud.pubsub.testing.v1.Main main
[pubsub] INFO: Server started, listening on 8085
[pubsub] Oct 30, 2026 2:55:36 PM io.gapi.emulators.netty.HttpVersionRoutingHandler channelRead
[pubsub] INFO: Detected non-HTTP/2 connection.
[pubsub] Oct 30, 2026 2:55:39 PM io.gapi.emulators.netty.HttpVersionRoutingHandler channelRead
[pubsub] INFO: Detected non-HTTP/2 connection.
[pubsub] Oct 30, 2026 2:55:39 PM io.gapi.emulators.grpc.HttpAdapter$StubMethodHandler handle
[pubsub] INFO: Forwarding key: Host
[pubsub] Oct 30, 2026 2:55:39 PM io.gapi.emulators.grpc.HttpAdapter$StubMethodHandler handle
[pubsub] INFO: Forwarding key: user-agent
[pubsub] Oct 30, 2026 2:55:39 PM io.gapi.emulators.grpc.HttpAdapter$StubMethodHandler handle
[pubsub] INFO: Forwarding key: accept-encoding
[pubsub] Oct 30, 2026 2:55:39 PM io.gapi.emulators.grpc.HttpAdapter$StubMethodHandler handle
[pubsub] INFO: Forwarding key: accept
[pubsub] Oct 30, 2026 2:55:39 PM io.gapi.emulators.grpc.HttpAdapter$StubMethodHandler handle
[pubsub] INFO: Not forwarding key: Connection
[pubsub] Oct 30, 2026 2:55:39 PM io.gapi.emulators.grpc.HttpAdapter$StubMethodHandler handle
[pubsub] INFO: Not forwarding key: Content-Length
[pubsub] Oct 30, 2026 2:55:39 PM io.gapi.emulators.grpc.HttpAdapter$StubMethodHandler handle
[pubsub] INFO: Forwarding key: content-type
[pubsub] Oct 30, 2026 2:55:39 PM io.gapi.emulators.grpc.HttpAdapter$StubMethodHandler handle
[pubsub] INFO: Forwarding key: authorization
```

**`IAM integration is disabled` is the emulator saying what it is not.** It accepts every request
from anybody, and lessons 5 to 9, which are about who may do what, are taught from Google's
documentation for exactly that reason. The lines after `Server started` are the first request
arriving, `topics create`, one header at a time. The last of them, `Forwarding key: authorization`,
is the placeholder token reaching the emulator, which does nothing with it. Every request adds a
dozen lines like these, and the transcript stops after the first.

The last lines of the second terminal are the cost of the lab: the disk the installations take, and
the memory the emulator holds while it runs, in kilobytes. Stop the emulator with **Ctrl+C** in its
terminal when you finish a session; the next lesson starts it again, empty.
