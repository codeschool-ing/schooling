---
title: A Packer template
version: 2
---

**Packer builds machine images from a template**, and it is the same idea for every kind of image:
start a temporary machine from a base image, run steps inside it, save the result as a new image,
throw the temporary machine away. What changes from one target to the next is only what "machine"
and "image" mean. On AWS the temporary machine is an EC2 instance and the result is an AMI; for
Docker it is a container, and the result is a container image.

The lab has no AWS that runs machines (moto keeps records, not computers), so this lesson builds
Docker images, which are real and run on the laptop. The template is HCL, the language of every
Terraform file in this course, in a file whose name ends `.pkr.hcl`. Ana keeps it in its own
repository, `~/shop/image`, which ignores one file a build will write there, as the section on
versioning shows:

```sh
mkdir -p ~/shop/image && cd ~/shop/image
git init -q . && printf "manifest.json\n" > .gitignore
```

The template is `web.pkr.hcl`:

```hcl
packer {
  required_plugins {
    docker = {
      source  = "github.com/hashicorp/docker"
      version = "~> 1.1"
    }
  }
}

source "docker" "web" {
  image  = "ubuntu:24.04"
  pull   = false
  commit = true
  changes = [
    "CMD [\"nginx\", \"-g\", \"daemon off;\"]",
    "EXPOSE 80",
  ]
}

build {
  sources = ["source.docker.web"]

  provisioner "shell" {
    inline = [
      "apt-get update -qq",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx > /dev/null",
      "echo 'shop web 1.0.0' > /var/www/html/index.html",
    ]
  }

  post-processor "docker-tag" {
    repository = "shop-web"
    tags       = ["1.0.0"]
  }
}
```

It has three top-level blocks, and each has a single job.

**`packer`** says which plugins the template needs. Packer itself knows no clouds and no
containers, the way Terraform knows no AWS without its provider. Each builder is a plugin, here
`github.com/hashicorp/docker`, with a version constraint written exactly like a provider's.

**`source "docker" "web"`** says where the temporary machine comes from. The first label is the
builder, the second a name of Ana's choosing. `image` is the base to start from. `commit = true`
asks for the container to be saved as an image at the end, which is what makes this a build and
not just a run. `changes` are settings written into the new image: the command it runs when
started, and the port it listens on.

`pull = false` is there because of the recording. By default Packer asks Docker Hub for the newest
`ubuntu:24.04` before every build, and while this lesson was being recorded Docker Hub answered
those requests with `429 Too Many Requests`. With `pull = false` the build uses the copy already on
the laptop. Leaving it out is the ordinary setting; four sections on, this lesson explains
why the base image should be pinned either way. With the line in, your Docker needs that copy
before the first build, so fetch it once:

```sh
docker pull ubuntu:24.04
```

Yours is whichever image the tag points at on the day you pull it, which the section on versioning
comes back to.

**`build`** says what happens. `sources` names the source blocks to start from, and a build can
list several to produce the same image for several targets at once. Inside it:

- a **provisioner** is a step run inside the temporary machine. `shell` runs commands; `file`
  copies files in; an `ansible` provisioner, from another plugin, runs a playbook such as lesson
  18's against the machine being built. They run in order, and any step that fails stops the build.
- a **post-processor** acts on the image after it is saved. `docker-tag` gives it the name
  `shop-web:1.0.0`.

Ana commits the template as it stands, `git add -A && git commit -qm 'the web image'`, so that the
diffs in the next sections show only what changed after it.

The same template for AWS would differ in its `source` block and little else. This one is
**illustrative, not run here**: the `amazon-ebs` plugin is not installed for this lesson, and moto
starts no machine to provision.

```hcl
source "amazon-ebs" "web" {
  region        = "sa-east-1"
  instance_type = "t3.micro"
  ssh_username  = "ubuntu"
  ami_name      = "shop-web-1.0.0"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"]
    most_recent = true
  }
}
```

`source_ami_filter` is the same search lesson 5 did with `data "aws_ami"`, and `099720109477` is
the account Canonical publishes Ubuntu's images from. The provisioners and the post-processors
would be the ones above, minus the tag; the AMI gets its name from `ami_name`.
