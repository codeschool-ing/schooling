---
title: Your Google Cloud, on your own computer
version: 1
---

This course is practised on your own computer, against **the emulators Google publishes** for a
few of its services and an open-source imitation of Cloud Storage, with the real `gcloud` command
line pointed at them. There is no Google Cloud account anywhere in it, nothing is billed, and the
platform runs nothing for you: every command in these lessons is one you type in your own terminal.
**Lesson 1 of `gcp-foundations` is where the terminal itself comes from**: the three ways to have one
on Ubuntu 24.04 (installed, which it recommends; a virtual machine; a shell rented online), what each
costs your computer, and what to do when the setup fails. Its lab is not this one. This course also
needs Docker, an imitation of Cloud Storage and its own pinned `gcloud`, so build what follows even
if you took that course: it goes into the same `~/gcp` and `~/.local`, and the one thing it replaces
is the `gcloud` in `~/.local`, with version 591.0.0.

## Building it

Docker runs the emulators, and three more packages come from Ubuntu's archive. `python3-venv` is
the one people leave out, because Ubuntu ships Python without it:

```sh
sudo apt-get update
sudo apt-get install -y docker.io python3-venv curl unzip jq
sudo usermod -aG docker "$USER"
```

The last line lets you run `docker` without `sudo`. It takes effect at your next login, so log out
and in again before going on.

Then the `gcloud` command line, version 591.0.0, into `~/.local`, a Python virtual environment of
its own in `~/gcp/venv`, and the two images that stand in for the cloud. Nothing here needs `sudo`:

```sh
mkdir -p ~/gcp ~/.local/bin && cd ~/gcp
curl -sS -o gcloud.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-591.0.0-linux-x86_64.tar.gz
tar -xzf gcloud.tar.gz -C ~/.local && rm gcloud.tar.gz
ln -sf ~/.local/google-cloud-sdk/bin/gcloud ~/.local/bin/gcloud
python3 -m venv ~/gcp/venv
docker pull -q fsouza/fake-gcs-server:1.52.2
docker pull -q gcr.io/google.com/cloudsdktool/google-cloud-cli:591.0.0-emulators
```

On a computer with an Arm processor the file is `google-cloud-cli-591.0.0-linux-arm.tar.gz`.

## Starting it, every time

**Both emulators keep everything in memory and forget it when they stop**, so nothing from
yesterday is still there today, and no lesson assumes it is. Start them with two commands; each
prints the id of the container it started:

```sh
docker run -d --rm --name gcs -p 4443:4443 fsouza/fake-gcs-server:1.52.2 -scheme http -backend memory -public-host localhost:4443
docker run -d --rm --name pubsub -p 8085:8085 gcr.io/google.com/cloudsdktool/google-cloud-cli:591.0.0-emulators gcloud beta emulators pubsub start --project=planner-dev --host-port=0.0.0.0:8085
```

`gcs` answers the Cloud Storage API on port 4443, and `pubsub` is Google's own Pub/Sub emulator on
port 8085. Then, in the terminal you work in, eight lines point everything at them:

```sh
cd ~/gcp && source venv/bin/activate
export PATH="$HOME/.local/bin:$PATH"
export CLOUDSDK_CORE_PROJECT=planner-dev
export CLOUDSDK_AUTH_DISABLE_CREDENTIALS=true
export CLOUDSDK_API_ENDPOINT_OVERRIDES_STORAGE=http://localhost:4443/storage/v1/
export CLOUDSDK_API_ENDPOINT_OVERRIDES_PUBSUB=http://localhost:8085/
export STORAGE_EMULATOR_HOST=http://localhost:4443
export PUBSUB_EMULATOR_HOST=localhost:8085
```

The project is `planner-dev`, the name the four Google Cloud courses share; the shop this course
operates lives in it. `CLOUDSDK_AUTH_DISABLE_CREDENTIALS` tells `gcloud` not to look for a login,
because there is none to find. The two `OVERRIDES` lines send its Cloud Storage and Pub/Sub
requests to your computer instead of to Google, and the two `EMULATOR_HOST` lines do the same for
Google's client libraries in Python. The variables live in that terminal only, so a new terminal
needs the eight lines again.

Then check it answers:

```
ana@laptop:~/gcp$ gcloud version
Google Cloud SDK 591.0.0
bq 2.1.41
bundled-python3-unix 3.14.9
core 2026.10.26
gcloud-crc32c 1.0.0
gsutil 5.38
ana@laptop:~/gcp$ gcloud storage buckets create gs://planner-dev-check --location=southamerica-east1
Creating gs://planner-dev-check/...
ana@laptop:~/gcp$ gcloud storage buckets list --format="value(name)"
planner-dev-check
ana@laptop:~/gcp$ gcloud pubsub topics create check
Created topic [projects/planner-dev/topics/check].
ana@laptop:~/gcp$ du -sh ~/.local/google-cloud-sdk ~/gcp/venv
535M	/home/ana/.local/google-cloud-sdk
16M	/home/ana/gcp/venv
ana@laptop:~/gcp$ docker image ls --format '{{.Repository}}:{{.Tag}} {{.Size}}' | grep -E 'fake-gcs|emulators'
gcr.io/google.com/cloudsdktool/google-cloud-cli:591.0.0-emulators 1.73GB
fsouza/fake-gcs-server:1.52.2 78MB
```

The bucket was created in `gcs` and the topic in `pubsub`, and neither left your computer. The last
two commands are the disk the environment takes: about half a gigabyte for `gcloud`, and 1.8 GB for
the two images, most of it the emulators' image, which carries a whole `gcloud` and a Java runtime
of its own. `docker image rm` with the two names, and deleting `~/gcp` and
`~/.local/google-cloud-sdk`, removes all of it.

## When it does not answer

Three failures cover nearly every case.

**The variables are missing.** A new terminal where the eight lines were not typed has a `gcloud`
that wants a login, and says so before it sends anything anywhere:

```
ana@laptop:~/gcp$ gcloud storage buckets list
ERROR: (gcloud.storage.buckets.list) You do not currently have an active account selected.
Please run:

  $ gcloud auth login

to obtain new credentials.

If you have already logged in with a different account, run:

  $ gcloud config set account ACCOUNT

to select an already authenticated account to use.
```

**Do not run `gcloud auth login`.** It is the right advice for somebody with an account and the
wrong one here: type the eight lines and ask again.

**An emulator is not running**, because the computer restarted or the container was stopped.
`gcloud` cannot connect, and reports it as a crash, with the port in the middle of the message:

```
ana@laptop:~/gcp$ gcloud storage buckets list
ERROR: gcloud crashed (ConnectionError): HTTPConnectionPool(host='localhost', port=4443): Max retries exceeded with url: /storage/v1/b?alt=json&maxResults=1000&project=planner-dev&projection=full (Caused by NewConnectionError("HTTPConnection(host='localhost', port=4443): Failed to establish a new connection: [Errno 111] Connection refused"))

If you would like to report this issue, please run the following command:
  gcloud feedback

To check gcloud for common problems, please run the following command:
  gcloud info --run-diagnostics
```

`Connection refused` on 4443 is `gcs`, on 8085 is `pubsub`. `docker ps` lists what is running;
start what is missing with its `docker run` line.

**The port is taken**, by a container you started earlier or by another program. Docker creates
the container and then cannot give it the port:

```
ana@laptop:~/gcp$ docker run -d --rm --name gcs2 -p 4443:4443 fsouza/fake-gcs-server:1.52.2 -scheme http -backend memory -public-host localhost:4443
627bfbe920cd756429b675f61451b8fdf52b78525213609b05ea9146e7bbf474
docker: Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint gcs2 (74cf65e283314206890feca19bc21fcd6473e1d264a1bcd5f5243b446cfd94fb): Bind for 0.0.0.0:4443 failed: port is already allocated

Run 'docker run --help' for more information
```

The emulator already on that port is usually the one you want. `docker ps` names it, and
`ss -ltnp | grep 4443` finds a program that is not a container.
