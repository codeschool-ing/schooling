---
title: A reconciler you can read in one screen
version: 1
---

**Argo CD and Flux are large programs, and at their centre is a loop small enough to write in
shell.** Writing it first is the fastest way to see what the large programs are for, and later
which of their features are that loop done properly. Save this as `~/setup/reconcile.sh`:

```sh
#!/bin/sh
# A reconciler in a dozen lines: fetch what Git says, apply it, wait, again.
# Usage: sh reconcile.sh REPOSITORY DIRECTORY
repo=$1 dir=$2 work=$HOME/.reconcile
[ -d "$work/.git" ] || git clone --quiet "$repo" "$work"
while true; do
  git -C "$work" pull --quiet --ff-only
  echo "$(date +%T) at $(git -C "$work" rev-parse --short HEAD)"
  kubectl apply -f "$work/$dir" | grep -v unchanged
  sleep 15
done
```

It keeps a clone of its own in `~/.reconcile`, separate from `~/fleet` where you edit. **It reads
only what was pushed**, never your working files, which is the same rule a real controller follows:
what is on your disk and not in the repository does not exist. Every fifteen seconds it pulls,
prints the commit it is at, and applies the directory; `grep -v unchanged` hides the objects that
already matched, so the loop prints a line only when it changed something.

## Running it

Open a second terminal for it, because it does not stop until you press `Ctrl+C`:

```sh
sh ~/setup/reconcile.sh ~/fleet.git staging
```

Back in the first terminal, change the message in `staging/bulletin.yaml` to `Staging has the new
banner.` and push it:

```
ana@laptop:~/fleet$ git diff | grep '^[-+] '
-          value: Staging is open for testing.
+          value: Staging has the new banner.
ana@laptop:~/fleet$ git commit --quiet -am "staging: new banner"
ana@laptop:~/fleet$ git push --quiet
ana@laptop:~/fleet$ curl -s localhost:8080
bulletin 1.0
message: Staging has the new banner.
token: none
```

And this is what the second terminal printed meanwhile:

```
ana@laptop:~$ sh ~/setup/reconcile.sh ~/fleet.git staging
01:32:39 at 5dd3a45
01:32:55 at 1949f7b
deployment.apps/bulletin configured
```

The output tells the story. At first the loop is at `5dd3a45` and changes nothing, because the
cluster already matches. On the pass after the push it is at `1949f7b` and reports
`deployment.apps/bulletin configured`: the template changed, so Kubernetes started a rollout. A few
seconds later `curl` gets the new message from a new pod.

**Nobody ran `kubectl` against the cluster to deploy this change.** You pushed a commit, and the
loop, which has the credentials, found it and applied it. That inversion is the second and third of
the four principles in one picture: the desired state is pulled, and the pulling never stops.
