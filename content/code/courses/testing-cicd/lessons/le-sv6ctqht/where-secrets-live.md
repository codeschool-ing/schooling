---
title: Where a secret sits on the machine
version: 2
---

Out of the repository, a secret still has to be somewhere on the machine that runs the program, and
"somewhere" has an audience. Two places matter for `shipquote`: the file the token is read from, and
the process that holds it.

## The file

The production configuration was written with the default permissions of a new file:

```
ana@laptop:~/shipquote$ stat -c "%A %n" ~/envs/production/config.env
-rw-r--r-- /home/ana/envs/production/config.env
ana@laptop:~/shipquote$ chmod 600 ~/envs/production/config.env && stat -c "%A %n" ~/envs/production/config.env
-rw------- /home/ana/envs/production/config.env
```

`-rw-r--r--` means the owner can read and write, and **every other user on the machine can read**.
Any account on that server, a monitoring agent, another team's service, a compromised process, could
read the carrier token. `chmod 600` leaves read and write to the owner alone: `-rw-------`. The rule
is short: **a file holding a secret is readable only by the account that runs the program.** On
container platforms the equivalent is a secret mounted as a file or injected as a variable by the
platform, never baked into the image.

## The process

How a secret reaches the process matters too. Compare a token passed as a command-line argument with
one passed in the environment, as `shipquote` does. The first is a Python process that sleeps for
thirty seconds and does nothing else, started in the background with a token among its arguments:

```sh
python3 -c 'import time; time.sleep(30)' --carrier-token=lab-live-token &
```

Then, within those thirty seconds, what anybody on the machine can list:

```
ana@laptop:~/shipquote$ ps -o args= -C python3 | grep "[c]arrier-token"
python3 -c import time; time.sleep(30) --carrier-token=lab-live-token
ana@laptop:~/shipquote$ ps -o args= -C python3 | grep -c "[S]HIPQUOTE_CARRIER_TOKEN"
0
```

The first process was started with the token as an argument, and `ps` printed it. **On Linux any user
can list every process's arguments**, so a token on a command line is published to the whole machine
for as long as the process runs, and often to shell histories and audit logs as well. The second
command counts processes whose arguments mention `SHIPQUOTE_CARRIER_TOKEN`, and finds none:
`shipquote`'s token lives in its environment, and `/proc/<pid>/environ`, which lesson 8 section 03
read, is readable only by the process's owner and by root.

## The order of preference

From safest to least safe, for a program that needs a secret:

1. fetched at start-up from a secrets manager, with a short-lived credential (section 09);
2. a file readable only by the program's account, or a platform-mounted secret;
3. an environment variable, set by whatever starts the process;
4. a command-line argument: never.

Each step down widens the audience. The lab uses the third, for simplicity, with the file it comes
from made private.
