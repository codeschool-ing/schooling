---
title: When the setup fails
version: 1
---

A course is most often abandoned here, on an error about a tool the student has not finished
installing. These are the failures met while this lesson was recorded, in the order the setup meets
them, and what each one means. **Six of them were produced on purpose and are quoted as the machine
printed them; the other two are described, and each says why.**

**The virtual environment was not created.** Ubuntu ships Python without the part that makes virtual
environments. `python3 -m venv` then stops with a message that begins *The virtual environment was not
created successfully because ensurepip is not available* and names the package to install. The cure is
`sudo apt-get install -y python3-venv`, from the first block of the setup. The failed attempt leaves a
half-made `~/gcp/venv` behind, so remove it with `rm -rf ~/gcp/venv` and run that block again. **This
one was not produced here**, because the machine the lessons were recorded on has the package and the
failure needs it absent. The `cloud` course, lesson 1, quotes the whole message.

**`apt-get` says it could not get a lock.** Ubuntu installs its own updates in the first minutes after
a machine starts, and only one program may install packages at a time. Wait a few minutes and run the
command again. Deleting the lock file is the advice you will find online, and it is how a package
database gets damaged. **Not produced here either**: it depends on what the machine happens to be doing.

**`gcloud` is not found.** The tools are installed and this terminal does not know where:

```
ana@laptop:~$ gcloud version
bash: line 1: gcloud: command not found
```

Every new terminal starts without the CLI's directory on its path. `source ~/gcp/env.sh` puts it back,
and the same line fixes a missing `terraform`. On an Ubuntu desktop the message may add a suggestion to
install `google-cloud-cli` from a package. Ignore it: the version the course needs is already installed
in `~/.local`.

**`gcloud` runs, and asks you to sign in.** This one is worth reading twice, because it looks like a
problem with your Google account and is not:

```
ana@laptop:~/gcp$ ~/.local/google-cloud-sdk/bin/gcloud pubsub topics list
ERROR: (gcloud.pubsub.topics.list) You do not currently have an active account selected.
Please run:

  $ gcloud auth login

to obtain new credentials.

If you have already logged in with a different account, run:

  $ gcloud config set account ACCOUNT

to select an already authenticated account to use.
```

The command was found by its full path, but `env.sh` was never read, so `CLOUDSDK_CONFIG` was not set
and `gcloud` looked for its settings in `~/.config/gcloud`, where there are none: no project, no
placeholder token, no address for the emulator. **Do not run `gcloud auth login` to make it go away.**
That signs a real Google account into a directory the lab was built to keep away from. `source
~/gcp/env.sh` is the cure.

**The emulator is not running.** The CLI has nobody to talk to on port 8085, and says so at length:

```
ana@laptop:~/gcp$ gcloud pubsub topics list
ERROR: gcloud crashed (ConnectionError): HTTPConnectionPool(host='localhost', port=8085): Max retries exceeded with url: /v1/projects/planner-dev/topics?alt=json (Caused by NewConnectionError("HTTPConnection(host='localhost', port=8085): Failed to establish a new connection: [Errno 111] Connection refused"))

If you would like to report this issue, please run the following command:
  gcloud feedback

To check gcloud for common problems, please run the following command:
  gcloud info --run-diagnostics
```

`gcloud crashed` sounds worse than it is. The useful part is at the end of the first line, `Connection
refused` on `localhost` port `8085`: nothing is listening there. Start the emulator in the first
terminal, as the previous section shows. The suggestion to run `gcloud feedback` is meant for a real
crash; this is not one, so there is nothing to report.

**There is no Java.** The emulator is a Java program, and the CLI checks before starting it:

```
ana@laptop:~/gcp$ gcloud beta emulators pubsub start --host-port=localhost:8085
ERROR: (gcloud.beta.emulators.pubsub.start) To use the Google Cloud Pub/Sub emulator, a Java 7+ JRE must be installed and on your system PATH
```

The message asks for Java 7 or later, which is older than anything Ubuntu 24.04 still ships. Install
`openjdk-21-jre-headless` from the first block of the setup and start the emulator again.

**The port is already taken.** A second emulator started while the first is still running finds port
8085 in use. It prints a Java stack trace some forty lines long, and two of its lines are the ones to
read:

```
ana@laptop:~/gcp$ timeout 20 gcloud beta emulators pubsub start --host-port=localhost:8085 2>&1 | grep -m2 -E "Exception|already in use"
[pubsub] Exception in thread "main" java.net.BindException: Address already in use
[pubsub] 	Suppressed: java.lang.RuntimeException: Rethrowing promise failure cause
```

`Address already in use` means another program holds the port, and usually it is the emulator you
started earlier in another terminal and forgot. Look for it there and stop it with **Ctrl+C**. If you
cannot find it, `ss -ltnp | grep 8085` names the process holding the port.

**A request went to Google instead of to the emulator.** This is the failure the lab is built to make
harmless. Remove the property that points Pub/Sub at port 8085, ask again, and put the property back:

```
ana@laptop:~/gcp$ gcloud config unset api_endpoint_overrides/pubsub
Unset property [api_endpoint_overrides/pubsub].
ana@laptop:~/gcp$ gcloud pubsub topics list
ERROR: (gcloud.pubsub.topics.list) UNAUTHENTICATED: Request had invalid authentication credentials. Expected OAuth 2 access token, login cookie or other valid authentication credential. See https://developers.google.com/identity/sign-in/web/devconsole-project. This command is authenticated with an access token from /home/ana/gcp/placeholder-token specified by the [auth/access_token_file] property.
- '@type': type.googleapis.com/google.rpc.ErrorInfo
  metadata:
    method: google.pubsub.v1.Publisher.ListTopics
    service: pubsub.googleapis.com
  reason: CREDENTIALS_MISSING
ana@laptop:~/gcp$ gcloud config set api_endpoint_overrides/pubsub http://localhost:8085/
WARNING: The value set for [api_endpoint_overrides/pubsub] was found to be associated with a universe domain outside of the current config universe [googleapis.com]. Please create a new gcloud configuration for each universe domain you make requests to using `gcloud config configurations create` with the `--universe-domain` flag or switch to a configuration associated with [http://localhost:8085/].
Updated property [api_endpoint_overrides/pubsub].
```

With no override, `gcloud` sent the request to `pubsub.googleapis.com`, in Google's datacentres, and
Google refused the word `placeholder` as a credential. **That refusal is the safety net working**: a
command that escapes the lab fails rather than doing something in somebody's project. If you ever see
it when you meant to talk to the emulator, the override is missing; `gcloud config list` shows whether
it is there.
