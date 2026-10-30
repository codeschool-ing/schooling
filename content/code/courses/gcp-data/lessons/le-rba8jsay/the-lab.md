---
title: Your lab, step by step
version: 1
---

**This course is practised against emulators, on your own computer, with the real Google Cloud
command line and no Google Cloud account.** An emulator is a program that answers on a port of your
laptop the way a Google service answers on the internet, keeps what it is told in memory, and
forgets it when it stops. The four Google Cloud courses of this catalogue use the same environment,
and `gcp-foundations` builds it in its first lesson too. If you built it there and kept it, check it
with the last block of this section and move on. The platform runs nothing for you: no machine, no
shell in the browser, no account.

## Three ways to have the machine

**Ubuntu 24.04 is where every transcript was recorded**, and three ways to have it work:

- **Installed, which is the one recommended.** Ubuntu as your system, or under WSL on Windows:
  `wsl --install -d Ubuntu-24.04` in an administrator PowerShell, then open "Ubuntu 24.04" from the
  Start menu. Everything below runs in that terminal.
- **A virtual machine**, which is the path on a Mac: Ubuntu Server 24.04 in UTM, VirtualBox or
  Multipass, with 2 processors, 6 GB of memory and 20 GB of disk. The emulators of lessons 9 to 11
  are Java and C++ programs, and two of them at once want more memory than the AWS courses asked for.
- **An online shell rented by the hour.** Nothing here needs more than a terminal with the network
  for the installation and none after it, but no lesson depends on any company's free allowance.

**On your own disk the whole lab comes to about 1.6 GB**, measured at the end of this section, and
nothing in it runs unless you start it. Most of that is the Google Cloud command line with its
emulators.

## The packages from Ubuntu

```sh
sudo apt-get update
sudo apt-get install -y python3 python3-venv curl openjdk-21-jre-headless
```

**Java is for the emulators, not for you.** The Pub/Sub and Firestore emulators are Java programs,
and they start with whatever `java` is on the path.

## The Google Cloud command line

Version 591.0.0, into `~/gcp`, so it needs no `sudo`, with the five emulators this course uses:

```sh
mkdir -p ~/gcp/bin
cd ~/gcp
curl -sS -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-591.0.0-linux-x86_64.tar.gz
tar -xzf google-cloud-cli-591.0.0-linux-x86_64.tar.gz
rm google-cloud-cli-591.0.0-linux-x86_64.tar.gz
export PATH="$HOME/gcp/google-cloud-sdk/bin:$PATH"
gcloud config set component_manager/fixed_sdk_version 591.0.0
gcloud components install beta pubsub-emulator cloud-firestore-emulator bigtable cbt cloud-spanner-emulator --quiet
```

The download is 90 MB, and with the components the directory comes to about 1.2 GB. **The
`fixed_sdk_version` line is what keeps it at 591.0.0**: without it, installing a component offers to
update the whole command line first, and the version in your terminal would stop being the one in
these transcripts.

On an Arm processor, which includes a virtual machine on a Mac with Apple silicon, the file is
`google-cloud-cli-591.0.0-linux-arm.tar.gz`. **The Spanner emulator is published for x86-64 Linux
only**, so on Arm lesson 9 is read rather than practised, or run on an x86-64 machine.

## fake-gcs-server, for Cloud Storage

Google publishes no emulator for Cloud Storage. **fake-gcs-server is an open-source one**, written
by Francisco Souza, and it is one file:

```sh
cd ~/gcp
curl -sSL -O https://github.com/fsouza/fake-gcs-server/releases/download/v1.54.0/fake-gcs-server_1.54.0_Linux_amd64.tar.gz
tar -xzf fake-gcs-server_1.54.0_Linux_amd64.tar.gz -C bin fake-gcs-server
rm fake-gcs-server_1.54.0_Linux_amd64.tar.gz
```

On Arm the archive ends in `_Linux_arm64.tar.gz`. If you already have Go 1.25 or later, `GOBIN=~/gcp/bin
go install github.com/fsouza/fake-gcs-server@v1.54.0` builds the same version from its source, and
that is how the copy these transcripts were recorded with was made.

## The Python libraries, in a virtual environment

```sh
python3 -m venv ~/gcp/venv
~/gcp/venv/bin/pip install -q google-cloud-storage==3.16.0 google-cloud-pubsub==2.42.0 \
  google-cloud-firestore==2.33.0 google-cloud-bigtable==2.50.0 google-cloud-spanner==3.70.0
~/gcp/venv/bin/pip install -q duckdb==1.5.6 pyarrow==25.0.1
```

**The first line is Google's client libraries**, the ones a program uses to talk to each service,
and each of them looks for an emulator in an environment variable before it looks for Google. **The
second line is this course's own**: BigQuery has no emulator at all, so the lessons from 13 on read
the same Parquet files with **DuckDB**, a database engine that lives inside a Python program, and
write them with **PyArrow**. Lesson 13 says exactly what that stands in for and what it cannot.

## Two terminals

**An emulator runs in a terminal of its own**, and stays in the foreground there, printing a line
per request. Open a terminal and start the one for Cloud Storage:

```sh
cd ~/gcp && export PATH="$HOME/gcp/bin:$PATH"
fake-gcs-server -scheme http -port 4443 -backend memory -location southamerica-east1
```

Leave it running. `Ctrl+C` stops it, and **stopping it forgets everything**, because `-backend
memory` keeps the buckets in memory and nowhere else. `-scheme http` saves you a certificate the
command line would not trust, and `-location` is the region it reports for every bucket, for a
reason the next section but one shows. Lessons 9, 10, 11 and 19 start their own emulators the same
way, each in its terminal, and say which.

## Every time you open a terminal

In a second terminal, the one you type into for the rest of the course:

```sh
cd ~/gcp
export PATH="$HOME/gcp/google-cloud-sdk/bin:$HOME/gcp/bin:$PATH" && source venv/bin/activate
export CLOUDSDK_CORE_PROJECT=planner-dev CLOUDSDK_AUTH_DISABLE_CREDENTIALS=true
export CLOUDSDK_API_ENDPOINT_OVERRIDES_STORAGE=http://localhost:4443/storage/v1/ STORAGE_EMULATOR_HOST=http://localhost:4443
export CLOUDSDK_API_ENDPOINT_OVERRIDES_PUBSUB=http://localhost:8085/ PUBSUB_EMULATOR_HOST=localhost:8085
export CLOUDSDK_API_ENDPOINT_OVERRIDES_SPANNER=http://localhost:9020/ SPANNER_EMULATOR_HOST=localhost:9010
export FIRESTORE_EMULATOR_HOST=localhost:8080 BIGTABLE_EMULATOR_HOST=localhost:8086
```

The first line is where the course's files go. The second puts `gcloud` on the path and switches to
the virtual environment. **The third is half the trick**: `CLOUDSDK_CORE_PROJECT` names the project
every command acts in, `planner-dev`, which the emulators accept as written, and
`CLOUDSDK_AUTH_DISABLE_CREDENTIALS` tells `gcloud` to send no credentials at all, so there is nothing
of yours that could reach Google. **The other three lines are the other half**: each
`CLOUDSDK_API_ENDPOINT_OVERRIDES_…` sends one service's requests from `gcloud` to a port of this
laptop, and each `…_EMULATOR_HOST` does the same for the Python library of that service. Every
`CLOUDSDK_` variable is a `gcloud` setting that lives only in this terminal, which is the point: close
the terminal and nothing is left configured.

## Check that it answers

```
ana@laptop:~/gcp$ gcloud version
Google Cloud SDK 591.0.0
beta 2026.10.26
bigtable 
bq 2.1.41
bundled-python3-unix 3.14.9
cbt 1.25.7
cloud-firestore-emulator 1.22.0
cloud-spanner-emulator 1.5.59
core 2026.10.26
gcloud-crc32c 1.0.0
gsutil 5.38
pubsub-emulator 0.8.37
ana@laptop:~/gcp$ gcloud auth list

No credentialed accounts.

To login, run:
  $ gcloud auth login `ACCOUNT`

ana@laptop:~/gcp$ gcloud storage buckets list
Listed 0 items.
ana@laptop:~/gcp$ du -sh ~/gcp
1.6G	/home/ana/gcp
```

**`No credentialed accounts` is the first proof you are not talking to Google**, and `Listed 0
items.` is the second: an empty Cloud Storage. Against the real service the same command with no
credentials would be refused, not answered. If you see an account
you recognise, or an error, the next section is the one to read.
