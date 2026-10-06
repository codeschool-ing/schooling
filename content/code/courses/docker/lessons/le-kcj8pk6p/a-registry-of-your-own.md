---
title: A registry of your own
version: 1
---

**A registry is a program like any other, and the reference one is an image: `registry:3`, the
CNCF Distribution project.** Running it takes a minute, and doing so is the quickest way to see
everything a registry does, because Docker Hub and every cloud registry speak the same API.

## Starting it, with a password

A registry anyone can push to is a registry somebody will fill with their own images, so Ana gives
hers a user from the start. The registry checks passwords against an `htpasswd` file, and the tool
that writes one is inside the `httpd` image:

```
ana@vm:~$ mkdir auth && docker run --rm --entrypoint htpasswd httpd:2 -Bbn ana lab-only > auth/htpasswd
ana@vm:~$ cut -c1-20 auth/htpasswd
ana:$2y$05$XsINzn15f
```

The password is stored as a bcrypt hash, the `$2y$` prefix, never as itself. Then the registry, with
its storage in a named volume and the password file mounted read-only:

```
ana@vm:~$ docker run -d --name registry -p 127.0.0.1:5000:5000 -v registry-data:/var/lib/registry -v "$PWD/auth":/auth:ro -e REGISTRY_AUTH=htpasswd -e REGISTRY_AUTH_HTPASSWD_REALM=lab -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd registry:3
159da126c53391067054553254509daad82e5ce143073def39ea190c7bd7ff26
```

## Naming an image for it

**An image goes to the registry its name says.** To push `shelf:1.0.0` to Ana's registry, it needs a
name that starts with the registry's address. `docker tag` adds a second name to the same image, and
both names share one id:

```
ana@vm:~$ docker tag shelf:1.0.0 localhost:5000/shelf:1.0.0
ana@vm:~$ docker image ls --format "{{.Repository}}:{{.Tag}}\t{{.ID}}" | grep shelf
shelf:1.0.0	f13bb63f689b
localhost:5000/shelf:1.0.0	f13bb63f689b
```

## Pushing

First without logging in:

```
ana@vm:~$ docker push localhost:5000/shelf:1.0.0
The push refers to repository [localhost:5000/shelf]
287d7fef7bb7: Waiting
a5789fc40e82: Waiting
44136fa355b3: Waiting
990a9c434e5e: Waiting
push access denied, repository does not exist or may require authorization: authorization failed: no basic auth credentials
```

`no basic auth credentials`: the registry refused before a single layer was sent. Ana logs in,
passing the password on standard input so that it never appears in the shell's history or in the
process list:

```
ana@vm:~$ echo lab-only | docker login localhost:5000 -u ana --password-stdin

WARNING! Your credentials are stored unencrypted in '/home/ana/.docker/config.json'.
Configure a credential helper to remove this warning. See
https://docs.docker.com/go/credential-store/

Login Succeeded
ana@vm:~$ jq . ~/.docker/config.json
{
  "auths": {
    "localhost:5000": {
      "auth": "YW5hOmxhYi1vbmx5"
    }
  }
}
ana@vm:~$ jq -r ".auths[\"localhost:5000\"].auth" ~/.docker/config.json | base64 -d; echo
ana:lab-only
```

**Read the warning.** `docker login` stored the credentials in `~/.docker/config.json`, and the
`auth` field is not encrypted, only encoded: `base64 -d` gives back `ana:lab-only` in one command.
Anybody who can read that file has the account. On a laptop, configure a **credential helper**,
which keeps the secret in the operating system's keychain instead; Docker Desktop sets one up by
default. On a CI runner, log in at the start of the job with a short-lived token and log out at the
end, which lesson 26 does.

```
ana@vm:~$ docker push localhost:5000/shelf:1.0.0
The push refers to repository [localhost:5000/shelf]
3214acf345c0: Pushed
52630fc75a18: Pushed
dd64bf2dd177: Pushed
dcaa5a89b0cc: Pushed
7c12895b777b: Pushed
44136fa355b3: Pushed
bf7a4185f015: Pushed
2780920e5dbf: Pushed
98143612ed16: Waiting
287d7fef7bb7: Pushed
b839dfae01f6: Pushed
990a9c434e5e: Pushed
a5789fc40e82: Pushed
39dc083afc39: Pushed
96ed2737ae31: Pushed
98143612ed16: Pushed
1.0.0: digest: sha256:f13bb63f689b9a6af18ddd859e492acf9e4c332d041a90d5970f55c0c0823f11 size: 856
```

## What the registry now holds

The registry's HTTP API answers ordinary requests. The list of repositories, the tags of `shelf`, and
the headers of the manifest that `1.0.0` points to:

```
ana@vm:~$ curl -s -u ana:lab-only localhost:5000/v2/_catalog
{"repositories":["shelf"]}
ana@vm:~$ curl -s -u ana:lab-only localhost:5000/v2/shelf/tags/list
{"name":"shelf","tags":["1.0.0"]}
ana@vm:~$ curl -s -u ana:lab-only -o /dev/null -D - -H "Accept: application/vnd.oci.image.index.v1+json" localhost:5000/v2/shelf/manifests/1.0.0 | grep -i -E "content-type|docker-content-digest"
Content-Type: application/vnd.oci.image.index.v1+json
Docker-Content-Digest: sha256:f13bb63f689b9a6af18ddd859e492acf9e4c332d041a90d5970f55c0c0823f11
```

**`Docker-Content-Digest` is the digest the push printed**, `sha256:f13b…`, and also the local image
id: the same bytes, named the same way, on both sides. Ana deletes her local copies and pulls the
image back by that digest, not by its tag:

```
ana@vm:~$ docker image rm shelf:1.0.0 localhost:5000/shelf:1.0.0
Untagged: shelf:1.0.0
Untagged: localhost:5000/shelf:1.0.0
Deleted: sha256:f13bb63f689b9a6af18ddd859e492acf9e4c332d041a90d5970f55c0c0823f11
ana@vm:~$ docker pull localhost:5000/shelf@sha256:f13bb63f689b9a6af18ddd859e492acf9e4c332d041a90d5970f55c0c0823f11
localhost:5000/shelf@sha256:f13bb63f689b9a6af18ddd859e492acf9e4c332d041a90d5970f55c0c0823f11: Pulling from shelf
98143612ed16: Pulling fs layer
44136fa355b3: Download complete
98143612ed16: Already exists
287d7fef7bb7: Download complete
98143612ed16: Pull complete
Digest: sha256:f13bb63f689b9a6af18ddd859e492acf9e4c332d041a90d5970f55c0c0823f11
Status: Downloaded newer image for localhost:5000/shelf@sha256:f13bb63f689b9a6af18ddd859e492acf9e4c332d041a90d5970f55c0c0823f11
localhost:5000/shelf@sha256:f13bb63f689b9a6af18ddd859e492acf9e4c332d041a90d5970f55c0c0823f11
ana@vm:~$ docker run -d --name from-registry localhost:5000/shelf@sha256:f13bb63f689b9a6af18ddd859e492acf9e4c332d041a90d5970f55c0c0823f11
9d6907334998d9800338f1f354ede4e52f56667eb77202b4a6fa8f57fd51311e
ana@vm:~$ docker logs from-registry
2026/10/06 17:36:22 catalogue: built in, 3 books
2026/10/06 17:36:22 shelf 1.0.0 listening on :8080
```

The pull names the digest it asked for and gets the same one back, and the container started from
it reports `shelf 1.0.0`. **A deployment that names images this way runs exactly what was tested**,
whatever happens to the tag afterwards.

## Logging out

```
ana@vm:~$ docker logout localhost:5000
Removing login credentials for localhost:5000
ana@vm:~$ jq . ~/.docker/config.json
{
  "auths": {}
}
```

The entry is gone from `config.json`. On a shared machine, that is the last command of the session.
