---
title: Building the image, and running it
version: 1
---

Three commands, in the same order as Terraform's. `packer init` installs the plugins the
`packer` block asks for, `packer fmt` checks the layout, and `packer validate` checks the template
without building anything:

```
ana@laptop:~/shop/image$ packer init .
ana@laptop:~/shop/image$ packer fmt -check .
ana@laptop:~/shop/image$ packer validate .
The configuration is valid.
```

`packer init` printed nothing because the Docker plugin was already installed on this laptop; on a
fresh machine it downloads it and says so. `fmt -check` is silent when the file is already
formatted. Then the build:

```
ana@laptop:~/shop/image$ packer build .
docker.web: output will be in this color.

==> docker.web: Creating a temporary directory for sharing data...
==> docker.web: Starting docker container...
==> docker.web: Run command: docker run -v /tmp/tmp2323089762:/packer-files -d -i -t --entrypoint=/bin/sh -- ubuntu:24.04
==> docker.web: Container ID: 4d07b26f46f96b7f27b91fd55dae33d244021c2e9c73e3b9742b5562463ab978
==> docker.web: Provisioning with shell script: /tmp/packer-shell915544868
==> docker.web: debconf: delaying package configuration, since apt-utils is not installed
==> docker.web: Committing the container
==> docker.web: Image ID: sha256:62e9c4686c66329965b7e533d2162c07b0e77cca1a3e37ffd7b09aa314cdbc58
==> docker.web: Killing the container: 4d07b26f46f96b7f27b91fd55dae33d244021c2e9c73e3b9742b5562463ab978
==> docker.web: Running post-processor:  (type docker-tag)
==> docker.web (docker-tag): Tagging image: sha256:62e9c4686c66329965b7e533d2162c07b0e77cca1a3e37ffd7b09aa314cdbc58
==> docker.web (docker-tag): Repository: shop-web:1.0.0
Build 'docker.web' finished after 17 seconds 998 milliseconds.

==> Wait completed after 17 seconds 998 milliseconds

==> Builds finished. The artifacts of successful builds are:
--> docker.web: Imported Docker image: sha256:62e9c4686c66329965b7e533d2162c07b0e77cca1a3e37ffd7b09aa314cdbc58
--> docker.web: Imported Docker image: shop-web:1.0.0 with tags shop-web:1.0.0
```

Read it as **the four steps of the previous section**. Packer starts a container from `ubuntu:24.04`
(the `Run command` line is the `docker run` it used), runs the provisioner's script in it, commits
the container as an image, kills the container, and hands the image to the post-processor, which
tags it. The `debconf` line is apt complaining inside the container, not an error. And the image
exists:

```
ana@laptop:~/shop/image$ docker images shop-web
IMAGE            ID             DISK USAGE   CONTENT SIZE   EXTRA
shop-web:1.0.0   62e9c4686c66        219MB         70.3MB        
```

## A successful build is not a working image

**Packer reported success because every step exited with status zero.** That is all it checks. So Ana
starts the image the way a machine would:

```
ana@laptop:~/shop/image$ docker run --rm shop-web:1.0.0
nginx: [emerg] socket() [::]:80 failed (97: Address family not supported by protocol)
```

nginx stopped at once. Its default site listens on IPv6 as well as IPv4, and the machine this
lesson was recorded on gives its containers no IPv6 at all:

```
ana@laptop:~/shop/image$ docker run --rm shop-web:1.0.0 grep -n "listen" /etc/nginx/sites-available/default
22:	listen 80 default_server;
23:	listen [::]:80 default_server;
27:	# listen 443 ssl default_server;
28:	# listen [::]:443 ssl default_server;
80:#	listen 80;
81:#	listen [::]:80;
ana@laptop:~/shop/image$ docker run --rm shop-web:1.0.0 ls /proc/net/if_inet6
ls: cannot access '/proc/net/if_inet6': No such file or directory
```

The second `listen` line of the default site, `[::]:80`, is the one nginx cannot open, and the
missing `/proc/net/if_inet6` is the kernel saying there is no IPv6 here. On your laptop the image
may well start. That is the point: the build ran on one machine and the image runs on others, and
**a provisioner's exit code says nothing about whether the result works where it is going**. Only
starting it does, which is why an image pipeline runs the image and asks it something before
publishing it, the same way lesson 13 runs a module before trusting it.

**The fix belongs in the template, not in a running container.** Ana deletes the IPv6 lines in the
provisioner, and gives the result a new version, because `1.0.0` already names an image and that
image does not change:

```
ana@laptop:~/shop/image$ git diff
diff --git a/web.pkr.hcl b/web.pkr.hcl
index 90e9556..87b3f2a 100644
--- a/web.pkr.hcl
+++ b/web.pkr.hcl
@@ -24,12 +24,13 @@ build {
     inline = [
       "apt-get update -qq",
       "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx > /dev/null",
-      "echo 'shop web 1.0.0' > /var/www/html/index.html",
+      "sed -i '/::/d' /etc/nginx/sites-available/default",
+      "echo 'shop web 1.0.1' > /var/www/html/index.html",
     ]
   }
 
   post-processor "docker-tag" {
     repository = "shop-web"
-    tags       = ["1.0.0"]
+    tags       = ["1.0.1"]
   }
 }
```

```
ana@laptop:~/shop/image$ packer build . 2>&1 | grep -E "Image ID|Repository|finished"
==> docker.web: Image ID: sha256:2aaf4859b5ed8c589de37aa9784d5c3255b5787efd06da56dd39cfd15923dc02
==> docker.web (docker-tag): Repository: shop-web:1.0.1
Build 'docker.web' finished after 12 seconds 930 milliseconds.
==> Builds finished. The artifacts of successful builds are:
```

## Running it

Now the container stays up, and answers:

```
ana@laptop:~/shop/image$ docker run -d --name shop-web-check -p 127.0.0.1:18080:80 shop-web:1.0.1
dbb954be4eb30f1e8adeedda449c922f76b6725aacbabce213e1709a6bfaa80d
ana@laptop:~/shop/image$ curl -s localhost:18080
shop web 1.0.1
ana@laptop:~/shop/image$ docker rm -f shop-web-check
shop-web-check
```

`-d` runs it in the background, `-p 127.0.0.1:18080:80` connects port 18080 on the laptop to port
80 in the container, and `curl` asks for the page the provisioner wrote. The page says `1.0.1`
because the template says so. In a real shop the check before publishing is this request, made by
a script, failing the pipeline when the answer is wrong.

**A version names one image, for good.** `1.0.0` is still on the laptop, still broken, under its
own name (the image list in the next section shows it), and it stays that way: a version that was published and found faulty is followed by a
newer version, never rebuilt under the old number. Writing the number into the template by hand,
twice per build, is how a number gets reused, and the next section takes it out.
