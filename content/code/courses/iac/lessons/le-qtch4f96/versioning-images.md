---
title: Versioning what you build
version: 1
---

An image is something other people start, so it needs the same thing lesson 10 asked of a module:
**a name that always means the same contents**. With the version typed into the template, every
build means an edit in two places, and the day somebody forgets one of them, `1.0.1` names two
different images.

Ana takes the version out of the template and adds the git commit beside it. Both become
variables, the version also goes into the image as a label, and a second post-processor writes
down what was built:

```
ana@laptop:~/shop/image$ git diff
diff --git a/web.pkr.hcl b/web.pkr.hcl
index 87b3f2a..554e9e1 100644
--- a/web.pkr.hcl
+++ b/web.pkr.hcl
@@ -7,6 +7,16 @@ packer {
   }
 }
 
+variable "version" {
+  type        = string
+  description = "The image's version: a new one for every build that ships."
+}
+
+variable "commit" {
+  type        = string
+  description = "The git commit the image was built from."
+}
+
 source "docker" "web" {
   image  = "ubuntu:24.04"
   pull   = false
@@ -14,6 +24,8 @@ source "docker" "web" {
   changes = [
     "CMD [\"nginx\", \"-g\", \"daemon off;\"]",
     "EXPOSE 80",
+    "LABEL org.opencontainers.image.version=${var.version}",
+    "LABEL org.opencontainers.image.revision=${var.commit}",
   ]
 }
 
@@ -25,12 +37,21 @@ build {
       "apt-get update -qq",
       "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx > /dev/null",
       "sed -i '/::/d' /etc/nginx/sites-available/default",
-      "echo 'shop web 1.0.1' > /var/www/html/index.html",
+      "echo 'shop web ${var.version}' > /var/www/html/index.html",
     ]
   }
 
   post-processor "docker-tag" {
     repository = "shop-web"
-    tags       = ["1.0.1"]
+    tags       = [var.version]
+  }
+
+  post-processor "manifest" {
+    output     = "manifest.json"
+    strip_path = true
+    custom_data = {
+      version = var.version
+      commit  = var.commit
+    }
   }
 }
```

Three changes, each answering a different question later.

**The variables have no default**, so a build that is not told its version refuses to start:

```
ana@laptop:~/shop/image$ packer build .
Error: Unset variable "version"

A used variable must be set or have a default value; see
https://packer.io/docs/templates/hcl_templates/syntax for details.

Error: Unset variable "commit"

A used variable must be set or have a default value; see
https://packer.io/docs/templates/hcl_templates/syntax for details.
```

That refusal is the point. There is no build without a number, and no number Packer made up.

**The labels go inside the image.** `org.opencontainers.image.version` and `.revision` are names
from the Open Container Initiative's list of standard labels, so other tools know where to look.
Whoever finds the image on a machine months later can ask it where it came from, without access to
any build log.

**The manifest post-processor** writes `manifest.json` in the template's directory, with the id of
every image the build produced and anything added in `custom_data`. It is what the next step of a
pipeline reads to learn what was built: which image id, built from which commit, called what.

The build takes both values from outside, the commit from git itself:

```
ana@laptop:~/shop/image$ packer build -var version=1.1.0 -var commit=$(git rev-parse --short HEAD) . 2>&1 | grep -E "Image ID|Repository|manifest|finished after"
==> docker.web: Image ID: sha256:b1052078e89d77debf8ea50e4ff70e4cad58f8b9d5c4d761feb50498aa4b3085
==> docker.web (docker-tag): Repository: shop-web:1.1.0
==> docker.web: Running post-processor:  (type manifest)
Build 'docker.web' finished after 11 seconds 984 milliseconds.
```

```
ana@laptop:~/shop/image$ jq . manifest.json
{
  "builds": [
    {
      "name": "web",
      "builder_type": "docker",
      "build_time": 1790955737,
      "files": null,
      "artifact_id": "sha256:b1052078e89d77debf8ea50e4ff70e4cad58f8b9d5c4d761feb50498aa4b3085",
      "packer_run_uuid": "b1db7ff2-73a6-ad12-edb4-5d10ad6e4384",
      "custom_data": {
        "commit": "00583ac",
        "version": "1.1.0"
      }
    }
  ],
  "last_run_uuid": "b1db7ff2-73a6-ad12-edb4-5d10ad6e4384"
}
```

```
ana@laptop:~/shop/image$ docker image inspect shop-web:1.1.0 --format '{{json .Config.Labels}}'
{"org.opencontainers.image.revision":"00583ac","org.opencontainers.image.version":"1.1.0"}
ana@laptop:~/shop/image$ docker run --rm shop-web:1.1.0 cat /var/www/html/index.html
shop web 1.1.0
ana@laptop:~/shop/image$ git log --oneline -1
00583ac version and commit come from outside
```

The commit in the label and in the manifest is the one `git log` prints, so the image can be traced
back to the exact template that built it. The image list now has three versions, each an image of
its own:

```
ana@laptop:~/shop/image$ docker images shop-web
IMAGE            ID             DISK USAGE   CONTENT SIZE   EXTRA
shop-web:1.0.0   1dca2ddf1bf5        219MB         70.3MB        
shop-web:1.0.1   7b52839d5bd1        219MB         70.3MB        
shop-web:1.1.0   b1052078e89d        219MB         70.3MB        
```

## Why not `latest`

Docker gives an image the tag `latest` when nobody names one, and plenty of deployments say
`latest` because it is always there. **A tag is a pointer, and a pointer can be moved.** `latest`
is moved by every build, so two machines started from `shop-web:latest` a week apart can be running
different images while every file that describes them is unchanged. And a rollback to `latest` is
no rollback at all, because it names whatever was built most recently, which is the thing being
rolled back.

The base image shows the same thing from the outside. Ubuntu 24.04 was released in April 2024, and
this is when the image behind the tag `ubuntu:24.04` on this laptop was created:

```
ana@laptop:~/shop/image$ docker image inspect ubuntu:24.04 --format '{{.Created}}'
2026-09-11T11:44:06.579973371Z
```

Canonical rebuilds that image with each round of updates and moves the tag to the new one. That is
the right thing for them to do, and it means `ubuntu:24.04` is a different base on different days.

The rule that follows is short. **In production, name images by a version that is never reused**,
and treat a tag like `latest` or `24.04` as a convenience for a human at a terminal. Registries can
enforce it: Amazon ECR, for one, can be set to refuse pushing a tag that already exists. The base
image needs a stronger name than a version, and the last section of this lesson gives it one.
