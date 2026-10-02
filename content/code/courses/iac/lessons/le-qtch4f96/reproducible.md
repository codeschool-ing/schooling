---
title: Reproducible, and immutable in practice
version: 1
---

A version number says *which* image runs. It does not say that building the same template again
would give the same image, and as the template stands, it would not. Two of its inputs are names
that move: `ubuntu:24.04`, which the section on versioning showed being rebuilt under the same tag, and
`nginx`, which means whatever version the archive offers on the day of the build. **A build is
reproducible when every input is named by something that cannot move.** Ana pins both.

The base image gets its **digest**, the hash of its contents, which Docker records when it pulls an
image:

```
ana@laptop:~/shop/image$ docker image inspect ubuntu:24.04 --format '{{index .RepoDigests 0}}'
ubuntu@sha256:008173c23f95b170204355c12626cb5a965d779a7e1283b09e9cffbb1bf33ca3
```

A digest is not a pointer. If the contents changed, the hash would be a different one, so
`ubuntu@sha256:…` names one image for as long as it exists anywhere. The package gets an exact
version, read from the archive, starting from that same base:

```
ana@laptop:~/shop/image$ docker run --rm ubuntu@sha256:008173c23f95b170204355c12626cb5a965d779a7e1283b09e9cffbb1bf33ca3 sh -c 'apt-get update -qq && apt-cache policy nginx'
nginx:
  Installed: (none)
  Candidate: 1.24.0-2ubuntu7.18
  Version table:
     1.24.0-2ubuntu7.18 500
        500 http://archive.ubuntu.com/ubuntu noble-updates/main amd64 Packages
        500 http://security.ubuntu.com/ubuntu noble-security/main amd64 Packages
     1.24.0-2ubuntu7 500
        500 http://archive.ubuntu.com/ubuntu noble/main amd64 Packages
```

```
ana@laptop:~/shop/image$ git diff
diff --git a/web.pkr.hcl b/web.pkr.hcl
index 554e9e1..5ea1fd9 100644
--- a/web.pkr.hcl
+++ b/web.pkr.hcl
@@ -18,7 +18,7 @@ variable "commit" {
 }
 
 source "docker" "web" {
-  image  = "ubuntu:24.04"
+  image  = "ubuntu@sha256:008173c23f95b170204355c12626cb5a965d779a7e1283b09e9cffbb1bf33ca3"
   pull   = false
   commit = true
   changes = [
@@ -35,7 +35,7 @@ build {
   provisioner "shell" {
     inline = [
       "apt-get update -qq",
-      "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx > /dev/null",
+      "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx=1.24.0-2ubuntu7.18 > /dev/null",
       "sed -i '/::/d' /etc/nginx/sites-available/default",
       "echo 'shop web ${var.version}' > /var/www/html/index.html",
     ]
```

```
ana@laptop:~/shop/image$ packer build -var version=1.2.0 -var commit=$(git rev-parse --short HEAD) . 2>&1 | grep -E "Run command|Image ID|finished"
==> docker.web: Run command: docker run -v /tmp/tmp412904059:/packer-files -d -i -t --entrypoint=/bin/sh -- ubuntu@sha256:008173c23f95b170204355c12626cb5a965d779a7e1283b09e9cffbb1bf33ca3
==> docker.web: Image ID: sha256:4aa04aae31eefc80964c792c998433512330cdd26599c9c421c147d75a763816
Build 'docker.web' finished after 13 seconds 353 milliseconds.
==> Builds finished. The artifacts of successful builds are:
ana@laptop:~/shop/image$ docker run --rm shop-web:1.2.0 dpkg-query -W nginx
nginx	1.24.0-2ubuntu7.18
```

The `Run command` line shows the container started from the digest, not the tag, and the image has
the version the template asked for and no other. If the archive stops offering that version, the
next build fails at `apt-get install`, loudly, on the day of the build, rather than quietly
producing something different. The version table above lists two versions of nginx, the one the
release shipped and the newest update; an older update is not in it.

Reproducible here means the same software at the same versions from the same template. It does not
mean a byte-identical file: two builds still differ in timestamps inside the image, so their ids
differ too. What matters is that nothing *installed* differs, and that any difference is a diff
somebody committed.

## Pinning is not freezing

The objection to all this is the right one: a pinned image never receives a security fix. **Pins
make updates deliberate, not rare.** The arrangement that works is a scheduled rebuild, say once a
week, from the pipeline lesson 15 describes: it checks for a newer base digest and newer package
versions, writes them into the template as a commit, builds the next version, runs it, and
publishes it. The updates arrive on a schedule, each one a reviewed diff and a new version number,
and each rollout is the one-line change of the previous section. A fix that cannot wait is the same
path, run that day.

## Immutable, with evidence

Lesson 1 claimed that under immutable infrastructure drift has nowhere to live. Here is what that
means on a running container. Somebody fixes the page by hand, inside it:

```
ana@laptop:~/shop/image$ docker run -d --name shop-web-live -p 127.0.0.1:18080:80 shop-web:1.2.0
74568e70502cfe6c0900ffdccf1961f411db91473a90fbaf6d02e97d476765a4
ana@laptop:~/shop/image$ docker exec shop-web-live sh -c "echo 'fixed by hand' > /var/www/html/index.html"
ana@laptop:~/shop/image$ curl -s localhost:18080
fixed by hand
ana@laptop:~/shop/image$ docker diff shop-web-live | grep www
C /var/www
C /var/www/html
C /var/www/html/index.html
```

The hand edit works, and Docker can even list it: `docker diff` compares the running container with
the image it came from, and `C` marks what changed. That is drift, and on a mutable server it would
stay until somebody noticed. Here the next replacement removes it:

```
ana@laptop:~/shop/image$ docker rm -f shop-web-live
shop-web-live
ana@laptop:~/shop/image$ docker run -d --name shop-web-live -p 127.0.0.1:18080:80 shop-web:1.2.0
8e3d4c7f7d8d03d440c960e6e96f367ddefb79dd57e7d1095abd368e21c54693
ana@laptop:~/shop/image$ curl -s localhost:18080
shop web 1.2.0
ana@laptop:~/shop/image$ docker diff shop-web-live | grep www
```

The new container is the image again, and `docker diff` finds nothing in the web directory. **Under
this model a fix made by hand is lost by design**, so the only fixes that last are the ones made in
the template and shipped as a new version. That is the whole trade lesson 1 described, now in
commands: a build step and a version for every change, in exchange for machines that are exactly
what their image says, every time one is started.

What stays mutable is what lesson 1 said should: the data. The database, the bucket with the shop's
images and the logs live outside the image, and a replaced web server loses none of them because it
never held any.
