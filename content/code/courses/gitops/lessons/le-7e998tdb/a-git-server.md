---
title: A Git server of your own
version: 1
---

**Lesson 1 kept the desired state in a bare repository on the same disk.** That was enough for
one person and one loop, and it has nothing a team needs: no accounts, no permissions, no pull
requests, no record of who approved what. This section replaces it with Gitea, a Git server that is
one program and runs in a container beside the cluster. Everything this lesson does with it, GitHub
and GitLab do with the same ideas and different buttons.

## Starting it

```sh
docker run -d --restart=always --name gitea --network kind -p 127.0.0.1:3000:3000 \
  -e GITEA__security__INSTALL_LOCK=true gitea/gitea:28.1.0-rootless
```

`--network kind` puts it on the same Docker network as the cluster's node, so **it has two
addresses**: `http://localhost:3000` from your terminal and your browser, and `http://gitea:3000`
from inside the cluster, where the container's name resolves. Lesson 3's Argo CD uses the second.
`INSTALL_LOCK=true` skips the setup page and keeps the defaults, which store everything in a SQLite
file inside the container.

## An account and a token

Gitea's own command line creates the first account, an administrator, and a token for it. The
token goes into a file that only you can read, and never onto the screen:

```
ana@laptop:~$ docker exec gitea gitea admin user create --admin --username ana --password 'change-me-now' --email ana@example.org --must-change-password=false
New user 'ana' has been successfully created!
ana@laptop:~$ docker exec gitea gitea admin user generate-access-token --username ana --token-name terminal --scopes write:repository,write:user --raw > ~/ana.token
ana@laptop:~$ chmod 600 ~/ana.token
ana@laptop:~$ wc -c ~/ana.token
41 /home/ana/ana.token
```

A token is what a program uses instead of your password, and **it carries only the scopes it was
given**: this one may write repositories and your user settings, and nothing else. On a real
server each person makes their own in the web interface, under Settings, Applications; here you
are the administrator and the command line is quicker. The web interface is at
`http://localhost:3000` if you want to look, as `ana` with the password above.

## The repository

The rest of this lesson talks to Gitea's API with `curl`, so three shell variables save typing. Put
them in your terminal, or in `~/.bashrc` to have them in every new one:

```sh
API=http://localhost:3000/api/v1/repos/ana/fleet
AS_ANA="Authorization: token $(cat ~/ana.token)"
JSON='Content-Type: application/json'
```

Creating a repository is a `POST` to the user's list of repositories, and `jq` picks three fields out
of the long answer (`sudo apt-get install jq` if you do not have it):

```
ana@laptop:~$ curl -s -H "$AS_ANA" -H "$JSON" -d '{"name": "fleet", "private": true}' http://localhost:3000/api/v1/user/repos | jq '{full_name, private, clone_url}'
{
  "full_name": "ana/fleet",
  "private": true,
  "clone_url": "http://localhost:3000/ana/fleet.git"
}
```

**Private**, because a configuration repository describes production, and that is nobody's
business outside the team. Git needs the token too, to push. The `store` helper keeps it in
`~/.git-credentials`, which you make readable only by you:

```sh
git config --global credential.helper store
printf 'http://ana:%s@localhost:3000\n' "$(cat ~/ana.token)" > ~/.git-credentials
chmod 600 ~/.git-credentials
```

And `~/fleet` changes its remote from the bare repository to the server, and sends it everything:

```
ana@laptop:~/fleet$ git remote set-url origin http://localhost:3000/ana/fleet.git
ana@laptop:~/fleet$ git push --quiet -u origin main
ana@laptop:~/fleet$ git ls-remote origin
f990998d0c04ea06c327242565667cd2529b864e	HEAD
f990998d0c04ea06c327242565667cd2529b864e	refs/heads/main
ana@laptop:~/fleet$ git log --oneline -1
f990998 Revert "staging: no service"
```

`git ls-remote` asks the server what it has, and `main` points at the same commit as on your
machine: the history of lesson 1, four commits, now on a server. `~/fleet.git` can go with
`rm -rf ~/fleet.git`.

## From inside the cluster

The second address is worth checking once, from a pod that asks Gitea for its version and exits:

```
ana@laptop:~/fleet$ kubectl run probe --restart=Never --image=busybox:1.37 -- wget -qO- http://gitea:3000/api/v1/version
pod/probe created
ana@laptop:~/fleet$ kubectl logs probe; echo
{"version":"28.1.0"}
ana@laptop:~/fleet$ kubectl delete pod probe
pod "probe" deleted from default namespace
```

A pod reached Gitea by its container name and got its version back. When an agent inside the
cluster reads this repository, that is the address it uses.
