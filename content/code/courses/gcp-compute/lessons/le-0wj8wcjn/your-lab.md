---
title: Your lab, in brief
version: 1
---

**This course is practised on your own computer, with the real Google Cloud command line and no
Google Cloud account.** Nothing in it is billed and nothing reaches Google. The four Google Cloud
courses of this school share one environment, and `gcp-foundations` builds it in its lesson 1,
with each path explained and a section on what goes wrong. If you did that course and kept the
lab, skip to the check near the end of this section. If not, the steps are below in brief, and
they build the same thing.

## What stands in for Google Cloud, and what nothing can

**Google publishes no imitation of its control plane.** Nothing you can install answers "create a
virtual machine", "deploy a Cloud Run service" or "make a GKE cluster" the way Google does, and
this course does not pretend otherwise. What it has instead is four tools that are honest about
what they are:

- **gcloud**, Google's own command line. Everything it does on your computer works: its
  configuration, its help, the credentials it writes for Docker. Everything it would send to
  Google stops before it leaves, because there is no account to send it from, and you will see
  that refusal below.
- **Terraform with Google's provider.** `terraform plan` works out, on your computer, every
  attribute a resource would have and what it would create. It is the closest thing to Compute
  Engine's answer that can be had without Compute Engine, and most lessons on virtual machines,
  groups and clusters are practised with it.
- **Docker**, because Cloud Run, its jobs and App Engine's flexible environment run containers,
  and a container that keeps Google's contract runs on your laptop exactly as it would there.
- **Emulators** for the event lessons: Google's own Pub/Sub emulator, the Functions Framework that
  Cloud Run functions are built on, and fake-gcs-server, an open-source imitation of Cloud
  Storage.

**What none of them gives you is a measurement.** A cold start timed on your laptop is your
laptop's; a price is never computed by any of them. Every price in this course comes from Google's
published price pages instead, collected in a short program the next section shows you whole.

Where a lesson teaches something no tool here can run (a rolling update across real zones, a
preemption, the load balancer GKE builds), it says so plainly, shows Google's documented commands
and marks them as not run. No output is ever written for them.

## Three ways to have the lab

**Recommended: install it on Ubuntu 24.04**, on your own computer or in a virtual machine you
already have. It needs about 3 GB of disk, nearly two thirds of it the emulators' image, and
nothing running in the background except Docker. A **virtual machine** (VirtualBox, or Multipass
on Windows and macOS) costs about 6 GB of disk and 4 GB of memory while it runs, and gives you a
clean Ubuntu to break. An **online environment** such as GitHub Codespaces needs no installation
and already has Docker, at the price of a monthly allowance of hours and storage that you should
check before relying on it. `gcp-foundations` lesson 1 walks through all three; the commands
below are the same in each.

## The commands

The packages come from Ubuntu's own archive, and this is the only step that needs `sudo`. The
last line lets you use Docker without `sudo`; it takes effect after you log out and in again:

```sh
sudo apt-get update
sudo apt-get install -y python3 python3-venv curl unzip jq docker.io
sudo usermod -aG docker "$USER"
```

The Google Cloud command line, version 591.0.0, and Terraform 1.17.1, both unpacked into your
home directory. On an Arm processor, which includes a virtual machine on a Mac with Apple silicon,
the file names end in `arm` and `arm64` instead of `x86_64` and `amd64`:

```sh
mkdir -p ~/gcp ~/.local/bin
cd ~/gcp
curl -sSO https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-591.0.0-linux-x86_64.tar.gz
tar -xzf google-cloud-cli-591.0.0-linux-x86_64.tar.gz -C ~/.local
rm google-cloud-cli-591.0.0-linux-x86_64.tar.gz
curl -sSO https://releases.hashicorp.com/terraform/1.17.1/terraform_1.17.1_linux_amd64.zip
unzip -q -o terraform_1.17.1_linux_amd64.zip terraform -d ~/.local/bin
rm terraform_1.17.1_linux_amd64.zip
```

The Python side, in a virtual environment of its own, so it touches nothing else on the machine:
the Functions Framework, Google's Pub/Sub client library and gunicorn, a web server lessons 8 and
19 use:

```sh
python3 -m venv ~/gcp/venv
~/gcp/venv/bin/pip install -q functions-framework==3.10.2 google-cloud-pubsub==2.43.0 gunicorn==26.2.0
```

Google's Terraform provider, 8.9.0, downloaded once into a folder of your own, and a Terraform
setting that makes every later `terraform init` take it from there. After this, nothing Terraform
does in the course needs the internet:

```sh
mkdir -p ~/gcp/mirror && cd ~/gcp/mirror
cat > versions.tf <<'EOF'
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.9.0"
    }
  }
}
EOF
terraform providers mirror ~/.terraform.d/mirror
cd ~/gcp && rm -r ~/gcp/mirror
mkdir -p ~/.terraform.d/plugin-cache
cat > ~/.terraformrc <<EOF
plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
provider_installation {
  filesystem_mirror {
    path = "$HOME/.terraform.d/mirror"
  }
}
EOF
```

The four images the later lessons run. The first is Google's, with every emulator in it; the
other three come from Docker Hub:

```sh
docker pull gcr.io/google.com/cloudsdktool/google-cloud-cli:591.0.0-emulators
docker pull fsouza/fake-gcs-server:1.56.1
docker pull registry:3.1.2
docker pull python:3.12.13-slim
```

**Every time you open a terminal to work**, these lines go first. They put the tools on your
path, name the course's project, region and zone, and hand Terraform a word to use as its access
token:

```sh
cd ~/gcp
source venv/bin/activate
export PATH="$HOME/.local/google-cloud-sdk/bin:$HOME/.local/bin:$PATH"
export CLOUDSDK_CORE_PROJECT=planner-dev
export CLOUDSDK_COMPUTE_REGION=southamerica-east1 CLOUDSDK_COMPUTE_ZONE=southamerica-east1-a
export GOOGLE_OAUTH_ACCESS_TOKEN=no-account
export CHECKPOINT_DISABLE=1
```

**`planner-dev` is the course's project**, the one `gcp-foundations` names and every emulator
accepts as written. `southamerica-east1` is São Paulo. `no-account` is not a token and Google
would refuse it, which is the point: Terraform needs something before it will plan, and this
something can never reach a real account. `CHECKPOINT_DISABLE` stops Terraform from asking
HashiCorp whether a newer version exists. Your prompt gains `(venv)` at the front; the transcripts
leave it out.

## Checking it answers

In your working terminal:

```
ana@laptop:~/gcp$ gcloud version
Google Cloud SDK 591.0.0
bq 2.1.41
bundled-python3-unix 3.14.9
core 2026.10.26
gcloud-crc32c 1.0.0
gsutil 5.38
ana@laptop:~/gcp$ terraform version
Terraform v1.17.1
on linux_amd64

ana@laptop:~/gcp$ docker run --rm python:3.12.13-slim python3 --version
Python 3.12.13
ana@laptop:~/gcp$ gcloud config list
[compute]
region = southamerica-east1
zone = southamerica-east1-a
[core]
disable_usage_reporting = True
project = planner-dev

Your active configuration is: [default]
```

**The configuration came from your environment variables, not from a file**: `gcloud config
list` shows what is in force, wherever it was set. And the one thing it does not show is an
account, which is what the next command runs into:

```
ana@laptop:~/gcp$ gcloud compute machine-types list --zones=southamerica-east1-a
ERROR: (gcloud.compute.machine-types.list) You do not currently have an active account selected.
Please run:

  $ gcloud auth login

to obtain new credentials.

If you have already logged in with a different account, run:

  $ gcloud config set account ACCOUNT

to select an already authenticated account to use.
```

That refusal happens on your computer, before anything is sent. **Every command in this course
that would talk to Google ends there**, and that is why the lessons show such commands from the
documentation and mark them, rather than running them.

## When it does not answer

Three failures cover nearly everything. **The terminal is new and the lines above were not typed
in it.** The shell then answers that it cannot find `gcloud` or `terraform` at all; on Ubuntu's
desktop it may add a suggestion to install a package, which you should ignore, because the tools
are installed and only the path is missing. Type the seven lines again.

**Terraform has no token**, because the `GOOGLE_OAUTH_ACCESS_TOKEN` line was skipped. You meet
that one in section 04 of this lesson, the first time you run a plan, and it says so there.

And **Docker refuses you**, because the group change has not taken effect in this login:

```
ana@laptop:~/gcp$ docker ps
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

Log out and in again, or restart the virtual machine. `id` lists `docker` among your groups once
it has worked.
