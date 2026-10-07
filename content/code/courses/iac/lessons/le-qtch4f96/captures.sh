#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of iac, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh tools      # once: the software the lab runs
#   sudo bash ../../lab.sh hosts up   # starts the Docker daemon, among other things
#   sudo bash captures.sh
#
# IT RUNS IN TWO HALVES, and the first is not inside the lab.
#
#   - The Docker half (Packer, docker run) runs first, OUTSIDE lab.sh's sandbox,
#     as the user who started this script, in a scratch directory under /tmp
#     whose `shop/image` is printed as ~/shop/image. The lab's user has no access
#     to Docker's socket on the machine this was recorded on, and opening the
#     socket to it was not something a lesson should do. On your own laptop
#     you are in the `docker` group and the commands are the same. The prompt
#     is printed by this script, as capture.sh prints it.
#   - The AWS half (rolling-out) runs inside the lab as usual, against moto.
#     It does not need the laptop's network, so LAB_HOSTS is cleared before
#     capture.sh is sourced: moto then gets a network namespace of its own and
#     cannot meet another lab's moto on the laptop's port 4566.
#
# Ids that Docker and AWS invent (image ids, container ids, ami-…, i-…) and
# git's commit hashes are different on every run, and so are the timings.
#
# What is STAGED rather than typed, and not shown in the lesson:
#   - every edit to web.pkr.hcl and terraform.tfvars is made by sed, and the
#     lesson shows it as the `git diff` ana runs afterwards;
#   - PACKER_TMP_DIR=/tmp, so the directory Packer shares with its container
#     is one the Docker daemon can see;
#   - the two AMIs in rolling-out, made with create-image from a throwaway
#     instance, as an image pipeline on AWS would have published them. moto
#     copies a record; there is nothing inside either. The lesson prints these
#     commands for the student to run, and says where each quiet commit and
#     git init below happens.
#
# Images and containers it makes are all called shop-web…, and it removes them
# at the end. It never touches anything else Docker is running.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail

if [ -z "${IN_LAB:-}" ]; then
  # ------------------------------------------------------------ the Docker half
  (
  S=$(mktemp -d /tmp/iac-le-qtch4f96-XXXXXX)
  export HOME=$S TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat CHECKPOINT_DISABLE=1
  export PATH=/opt/iac/bin:$PATH PACKER_PLUGIN_PATH=/opt/iac/packer-plugins PACKER_TMP_DIR=/tmp
  export GIT_CONFIG_GLOBAL=$S/.gitconfig
  decolour() { sed -u 's/\x1b\[[0-9;]*m//g'; }
  prompt() { printf 'ana@laptop:%s$ %s\n' "${PWD/#$S/\~}" "$1"; }
  run() { prompt "$1"; eval "$1" 2>&1 </dev/null | decolour; return 0; }
  quiet() { eval "$1" >/dev/null 2>&1 </dev/null || true; }
  put() { mkdir -p "$(dirname "$1")" && cat > "$1"
    printf '##### file:%s\n' "${PWD/#$S/\~}/$1"; cat "$1"; printf '##### end-file\n'; }
  block() { printf '##### %s\n' "$1"; }
  clean() {
    docker ps -aq --filter name=^shop-web- | xargs -r docker rm -f >/dev/null 2>&1
    docker images --format '{{.Repository}}:{{.Tag}}' shop-web | xargs -r docker rmi >/dev/null 2>&1
  }
  clean
  quiet 'git config --global user.name Ana'
  quiet 'git config --global user.email ana@example.com'
  quiet 'git config --global init.defaultBranch main'
  commit() { quiet "git add -A && git commit -qm '$1'"; }
  mkdir -p "$S/shop/image" && cd "$S/shop/image"
  quiet 'git init -q . && printf "manifest.json\n" > .gitignore'

  block a-template
  put web.pkr.hcl <<'CODE'
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
CODE
  commit 'the web image'

  block init
  run 'packer init .'
  run 'packer fmt -check .'
  run 'packer validate .'
  block build-1
  run 'packer build .'
  block images-1
  run 'docker images shop-web'
  block run-1
  run 'docker run --rm shop-web:1.0.0'
  run 'docker run --rm shop-web:1.0.0 grep -n "listen" /etc/nginx/sites-available/default'
  run 'docker run --rm shop-web:1.0.0 ls /proc/net/if_inet6'

  # STAGED: the fix, shown as the diff
  sed -i "s|^      \"echo 'shop|      \"sed -i '/::/d' /etc/nginx/sites-available/default\",\n      \"echo 'shop|; s/1\\.0\\.0/1.0.1/g" web.pkr.hcl
  block fix
  run 'git diff'
  commit 'nginx listens on IPv4 only'
  block build-2
  run 'packer build . 2>&1 | grep -E "Image ID|Repository|finished"'
  block serve
  run 'docker run -d --name shop-web-check -p 127.0.0.1:18080:80 shop-web:1.0.1'
  sleep 1
  run 'curl -s localhost:18080'
  run 'docker rm -f shop-web-check'

  block fry
  run "time docker run --rm ubuntu:24.04 sh -c 'apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx > /dev/null && nginx -v'"
  block bake
  run 'time docker run --rm shop-web:1.0.1 nginx -v'

  # ------------------------------------------------ versioning-images
  # STAGED: the version and the commit become variables
  python3 - web.pkr.hcl <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
s = s.replace('source "docker" "web" {', '''variable "version" {
  type        = string
  description = "The image's version: a new one for every build that ships."
}

variable "commit" {
  type        = string
  description = "The git commit the image was built from."
}

source "docker" "web" {''')
s = s.replace('    "EXPOSE 80",\n', '''    "EXPOSE 80",
    "LABEL org.opencontainers.image.version=${var.version}",
    "LABEL org.opencontainers.image.revision=${var.commit}",
''')
s = s.replace("'shop web 1.0.1'", "'shop web ${var.version}'")
s = s.replace('tags       = ["1.0.1"]\n  }', '''tags       = [var.version]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
    custom_data = {
      version = var.version
      commit  = var.commit
    }
  }''')
open(p, "w").write(s)
PY
  block versioning-diff
  run 'git diff'
  commit 'version and commit come from outside'
  block unset
  run 'packer build .'
  block build-3
  run 'packer build -var version=1.1.0 -var commit=$(git rev-parse --short HEAD) . 2>&1 | grep -E "Image ID|Repository|manifest|finished after"'
  block manifest
  run 'jq . manifest.json'
  block labels
  run "docker image inspect shop-web:1.1.0 --format '{{json .Config.Labels}}'"
  run 'docker run --rm shop-web:1.1.0 cat /var/www/html/index.html'
  run 'git log --oneline -1'
  block images-3
  run 'docker images shop-web'
  block moving-tag
  run "docker image inspect ubuntu:24.04 --format '{{.Created}}'"

  # ------------------------------------------------ reproducible
  block digest
  run "docker image inspect ubuntu:24.04 --format '{{index .RepoDigests 0}}'"
  DIGEST=$(docker image inspect ubuntu:24.04 --format '{{index .RepoDigests 0}}')
  block policy
  run "docker run --rm $DIGEST sh -c 'apt-get update -qq && apt-cache policy nginx'"
  NGINX=$(docker run --rm "$DIGEST" sh -c 'apt-get update -qq && apt-cache policy nginx' 2>/dev/null | awk '/Candidate:/ {print $2}')
  # STAGED: the two pins
  sed -i "s|image  = \"ubuntu:24.04\"|image  = \"$DIGEST\"|; s|-qq nginx >|-qq nginx=$NGINX >|" web.pkr.hcl
  block pin-diff
  run 'git diff'
  commit 'pin the base image and nginx'
  block build-4
  run 'packer build -var version=1.2.0 -var commit=$(git rev-parse --short HEAD) . 2>&1 | grep -E "Run command|Image ID|finished"'
  run 'docker run --rm shop-web:1.2.0 dpkg-query -W nginx'

  block live
  run 'docker run -d --name shop-web-live -p 127.0.0.1:18080:80 shop-web:1.2.0'
  sleep 1
  run "docker exec shop-web-live sh -c \"echo 'fixed by hand' > /var/www/html/index.html\""
  run 'curl -s localhost:18080'
  run 'docker diff shop-web-live | grep www'
  block replace
  run 'docker rm -f shop-web-live'
  run 'docker run -d --name shop-web-live -p 127.0.0.1:18080:80 shop-web:1.2.0'
  sleep 1
  run 'curl -s localhost:18080'
  run 'docker diff shop-web-live | grep www'

  clean
  cd / && rm -rf "$S"
  )
fi

# ------------------------------------------------------------ the AWS half
unset LAB_HOSTS
. "$(dirname "$0")/../../capture.sh"

quiet 'git config --global user.name Ana'
quiet 'git config --global user.email ana@example.com'
quiet 'git config --global init.defaultBranch main'
commit() { quiet "git add -A && git commit -qm '$1'"; }

# STAGED: the image pipeline publishes two builds as AMIs
BASE=$(aws ec2 run-instances --image-id ami-1e749f67 --instance-type t3.micro --query 'Instances[0].InstanceId' --output text)
quiet "aws ec2 create-image --instance-id $BASE --name shop-web-1.0.1"
sleep 2
quiet "aws ec2 create-image --instance-id $BASE --name shop-web-1.1.0"
quiet "aws ec2 terminate-instances --instance-ids $BASE"

mkdir -p shop/app && cd shop/app
block amis
run 'aws ec2 describe-images --owners self --query "sort_by(Images,&Name)[].[Name,ImageId]" --output text'
put main.tf <<'CODE'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "sa-east-1"
}

variable "web_version" {
  description = "The version of the shop-web image the web server runs."
  type        = string
}

data "aws_ami" "web" {
  owners = ["self"]

  filter {
    name   = "name"
    values = ["shop-web-${var.web_version}"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.web.id
  instance_type = "t3.micro"
  tags          = { Name = "web", Version = var.web_version }

  lifecycle {
    create_before_destroy = true
  }
}
CODE
put terraform.tfvars <<'CODE'
web_version = "1.0.1"
CODE
quiet 'terraform init'
quiet 'git init -q . && printf ".terraform/\n*.tfstate*\n" > .gitignore'
commit 'web runs shop-web 1.0.1'
block apply-1
run 'terraform apply -auto-approve | tail -n 3'

sed -i 's/1\.0\.1/1.1.0/' terraform.tfvars
block bump
run 'git diff'
block plan
run 'terraform plan -no-color'
block apply-2
run 'terraform apply -auto-approve | grep -E "Destr|Creat|Apply"'
commit 'web runs shop-web 1.1.0'
block rollback
run 'git revert --no-edit HEAD | head -n 1'
run 'terraform plan -no-color | grep -E "must be|ami|Version|Plan:"'
