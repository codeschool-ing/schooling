#!/usr/bin/env bash
# The laptop every transcript in this course was recorded on, and the cloud it
# talks to.
#
# THERE IS NO CLOUD ACCOUNT IN THIS COURSE, and nothing here is billed. The AWS
# that Terraform, the AWS CLI and CloudFormation talk to is moto, the emulator
# the cloud course already used for S3: a Python program that answers the AWS
# APIs on a port of the laptop, keeps what it was told in memory, and forgets
# everything when it stops. It runs no machine and carries no traffic. An
# instance it "launches" is a record with an id and a state, which is exactly
# what Terraform reads back, and nothing more.
#
# WHAT IS REAL. Terraform, OpenTofu, Terragrunt, Packer, Ansible, Checkov, tfsec,
# Trivy, Puppet (Ubuntu's package), Salt and the AWS CDK are the released programs
# at the versions pinned below, and every
# provider is the one HashiCorp publishes. The machines Ansible configures are
# Docker containers running sshd, and the image Packer builds is a real Docker
# image.
#
# WHAT IS STAGED, and why. The machine this was recorded on could reach
# releases.hashicorp.com, PyPI, npm and the Go module proxy, and not the
# Terraform Registry or GitHub's release downloads. So:
#   - the providers are downloaded from releases.hashicorp.com, checked against
#     HashiCorp's published SHA256SUMS, unpacked, and served to Terraform from a
#     local directory (a "filesystem mirror"). terraform init prints the same lines
#     either way; what it writes into the lock file differs, and lesson 2 says
#     how.
#   - tofu, terragrunt, tfsec, trivy and the Docker plugin for Packer are built
#     from their released source with the Go toolchain, at the tags below,
#     because their binaries are published on GitHub.
#   - every run gets its own network namespace, so moto is always on
#     localhost:4566 and always empty when a capture starts. A small dnsmasq
#     answers *.localhost with 127.0.0.1, because the AWS SDK addresses a bucket
#     as <bucket>.localhost:4566; on your own computer, `s3_use_path_style =
#     true` in the provider block does the same job.
#
#   sudo bash lab.sh tools       # once: install everything into /opt/iac
#   sudo bash lab.sh run CMD...  # CMD inside a fresh lab, as ana, in /home/ana
#   sudo bash lab.sh hosts up    # the containers Ansible configures (lessons 18-19)
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -euo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8

OPT=/opt/iac
TERRAFORM=1.16.4
PACKER=1.16.1
PROVIDERS="aws:6.67.0 local:2.9.1 random:3.9.1 random:3.8.1 null:3.3.2 tls:4.4.1"
MOTO=5.2.3
AWSCLI=1.46.1
ANSIBLE=2.21.4
CHECKOV=3.3.22
SALT=3008.3
CDK=2.1144.0
CDK_LIB=2.272.0
TOFU=v1.13.1
TERRAGRUNT=v1.1.6
TFSEC=v1.28.14
TRIVY=v0.75.0
PACKER_DOCKER=v1.1.4
RUNS=/var/tmp/iac-runs

hashicorp() { # NAME VERSION FILE-PREFIX: a release zip, checked against its SHA256SUMS
  local name=$1 version=$2 dest=$3 file=${1}_${2}_linux_amd64.zip
  local base=https://releases.hashicorp.com/$name/$version
  mkdir -p "$dest"
  [ -f "$dest/$file" ] && return 0
  curl -sSfo "$dest/$file" "$base/$file"
  curl -sSf "$base/${name}_${version}_SHA256SUMS" | grep " $file\$" | (cd "$dest" && sha256sum -c --quiet)
}

gobuild() { # MODULE@VERSION PACKAGE NAME [LDFLAGS]: built inside its own
  # module, since several of these carry replace directives that go install
  # refuses. LDFLAGS stamps the version the way each project's release does.
  local mv=$1 pkg=$2 name=$3 ld=${4:-} dir
  [ -x "$OPT/bin/$name" ] && return 0
  dir=$(GOTOOLCHAIN=auto go mod download -json "$mv" | jq -r .Dir)
  rm -rf "$OPT/src/$name" && mkdir -p "$OPT/src" && cp -r "$dir" "$OPT/src/$name" && chmod -R u+w "$OPT/src/$name"
  (cd "$OPT/src/$name" && GOTOOLCHAIN=auto GOFLAGS=-mod=mod go build -trimpath -ldflags "$ld" -o "$OPT/bin/$name" "$pkg")
}

tools() {
  apt-get update -q >/dev/null
  apt-get install -y -q dnsmasq-base iproute2 jq tree unzip openssh-client git puppet >/dev/null
  id ana >/dev/null 2>&1 || useradd -m -u 1500 -s /bin/bash ana
  mkdir -p "$OPT/bin"
  hashicorp terraform "$TERRAFORM" "$OPT/dl"
  unzip -oq "$OPT/dl/terraform_${TERRAFORM}_linux_amd64.zip" terraform -d "$OPT/bin"
  hashicorp packer "$PACKER" "$OPT/dl"
  unzip -oq "$OPT/dl/packer_${PACKER}_linux_amd64.zip" packer -d "$OPT/bin"
  local p
  for p in $PROVIDERS; do
    hashicorp "terraform-provider-${p%%:*}" "${p#*:}" "$OPT/mirror/registry.terraform.io/hashicorp/${p%%:*}"
  done
  # The same providers, unpacked: from an unpacked mirror Terraform links the
  # provider into .terraform instead of copying it, so a run does not write
  # 800 MB per working directory and no two runs ever write the same file.
  local z d
  for z in "$OPT"/mirror/registry.terraform.io/hashicorp/*/*.zip; do
    p=${z%/*}; p=${p##*/}; v=${z##*_${p}_}; v=${z#*terraform-provider-${p}_}; v=${v%%_*}
    d=$OPT/unpacked/registry.terraform.io/hashicorp/$p/$v/linux_amd64
    [ -d "$d" ] || { mkdir -p "$d" && unzip -oq "$z" -d "$d"; }
  done
  chmod -R a+rX "$OPT/unpacked"
  cat > "$OPT/terraformrc" <<EOF
provider_installation {
  filesystem_mirror {
    path = "$OPT/unpacked"
  }
}
EOF
  [ -x "$OPT/venv/bin/moto_server" ] || { python3 -m venv "$OPT/venv"; "$OPT/venv/bin/pip" install -q "moto[server]==$MOTO" "awscli==$AWSCLI"; }
  [ -x "$OPT/venv-ansible/bin/ansible" ] || { python3.12 -m venv "$OPT/venv-ansible"; "$OPT/venv-ansible/bin/pip" install -q "ansible-core==$ANSIBLE"; }
  [ -x "$OPT/venv-checkov/bin/checkov" ] || { python3 -m venv "$OPT/venv-checkov"; "$OPT/venv-checkov/bin/pip" install -q "checkov==$CHECKOV"; }
  [ -x "$OPT/venv-salt/bin/salt-call" ] || { python3 -m venv "$OPT/venv-salt"; "$OPT/venv-salt/bin/pip" install -q "salt==$SALT"; }
  [ -x "$OPT/cdk/node_modules/.bin/cdk" ] || { mkdir -p "$OPT/cdk" && (cd "$OPT/cdk" && npm init -y >/dev/null \
    && npm install --silent "aws-cdk@$CDK" "aws-cdk-lib@$CDK_LIB" "constructs@10"); }
  gobuild "github.com/opentofu/opentofu@$TOFU" ./cmd/tofu tofu \
    "-X github.com/opentofu/opentofu/version.dev=no"
  gobuild "github.com/gruntwork-io/terragrunt@$TERRAGRUNT" . terragrunt \
    "-X github.com/gruntwork-io/terragrunt/internal/version.Version=$TERRAGRUNT"
  gobuild "github.com/aquasecurity/tfsec@$TFSEC" ./cmd/tfsec tfsec \
    "-X github.com/aquasecurity/tfsec/version.Version=$TFSEC"
  gobuild "github.com/aquasecurity/trivy@$TRIVY" ./cmd/trivy trivy \
    "-X github.com/aquasecurity/trivy/pkg/version/app.ver=${TRIVY#v}"
  gobuild "github.com/hashicorp/packer-plugin-docker@$PACKER_DOCKER" . packer-plugin-docker
  PACKER_PLUGIN_PATH=$OPT/packer-plugins "$OPT/bin/packer" plugins install \
    --path "$OPT/bin/packer-plugin-docker" github.com/hashicorp/docker >/dev/null
}

# run CMD...: inside its own network and mount namespaces, with an empty moto
# on localhost:4566, a home directory that is new for this run, and the
# environment ana's shell has. Root sets the lab up; CMD runs as ana.
#
# LAB_HOSTS=1 keeps the laptop's own network instead, which is what lessons 18
# to 20 need: the containers of `hosts up` are on a bridge of the laptop's, and
# Packer talks to its Docker daemon. moto then listens on the laptop itself.
run() {
  local id; id=$(date +%s%N)
  mkdir -p "$RUNS/$id"
  chown ana: "$RUNS/$id"
  if [ -n "${LAB_HOSTS:-}" ]; then
    exec unshare --mount --propagation private -- bash "$0" inside "$RUNS/$id" "$@"
  fi
  exec unshare --net --mount --propagation private -- bash "$0" inside "$RUNS/$id" "$@"
}

inside() {
  local home=$1; shift
  [ -n "${LAB_HOSTS:-}" ] || ip link set lo up
  mount --bind "$home" /home/ana
  printf 'nameserver 127.0.0.1\n' > "$home/.resolv.conf"
  mount --bind "$home/.resolv.conf" /etc/resolv.conf
  dnsmasq --no-resolv --no-hosts --listen-address=127.0.0.1 --bind-interfaces \
    --address=/localhost/127.0.0.1 --pid-file="$home/.dnsmasq.pid" --user=root
  "$OPT/venv/bin/moto_server" -H 127.0.0.1 -p 4566 >"$home/.moto.log" 2>&1 </dev/null &
  local moto=$!
  local i; for i in $(seq 50); do curl -s -o /dev/null localhost:4566 && break; sleep 0.2; done
  cat > "$home/.lab-env" <<EOF
export PATH=$OPT/bin:$OPT/venv/bin:$OPT/venv-ansible/bin:$OPT/venv-checkov/bin:$OPT/venv-salt/bin:$OPT/cdk/node_modules/.bin:$(dirname "$(command -v node)"):/usr/local/bin:/usr/bin:/bin
export NODE_PATH=$OPT/cdk/node_modules CDK_DISABLE_CLI_TELEMETRY=true
export HOME=/home/ana USER=ana TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat
export TF_CLI_CONFIG_FILE=$OPT/terraformrc CHECKPOINT_DISABLE=1 TF_IN_AUTOMATION=
export AWS_ENDPOINT_URL=http://localhost:4566 AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=sa-east-1
export PACKER_PLUGIN_PATH=$OPT/packer-plugins
EOF
  if [ -f "$OPT/ssh/id_ed25519" ]; then
    mkdir -p "$home/.ssh" && cp "$OPT/ssh/id_ed25519" "$OPT/ssh/id_ed25519.pub" "$home/.ssh/"
    chmod 700 "$home/.ssh" && chmod 600 "$home/.ssh/id_ed25519"
  fi
  chown -R ana: "$home"
  local status=0
  runuser -u ana -- env -i bash -c '. /home/ana/.lab-env; cd /home/ana; "$@"' lab "$@" || status=$?
  kill "$(cat "$home/.dnsmasq.pid")" 2>/dev/null || true
  kill "$moto" 2>/dev/null || true
  # what a run made is only ever read through its transcript
  umount /home/ana 2>/dev/null; rm -rf "$home"
  return $status
}

# The machines Ansible, Puppet and Salt configure: Ubuntu containers with sshd,
# on a bridge of their own, reachable from the laptop by name.
HOSTS="web1:172.30.0.11 web2:172.30.0.12 db1:172.30.0.21"
hosts() {
  case $1 in
    up)
      if ! docker info >/dev/null 2>&1; then
        setsid dockerd >/var/log/iac-dockerd.log 2>&1 </dev/null &
        local i; for i in $(seq 60); do docker info >/dev/null 2>&1 && break; sleep 0.5; done
      fi
      docker network inspect iac >/dev/null 2>&1 || docker network create --subnet 172.30.0.0/24 iac >/dev/null
      if ! docker image inspect iac-host >/dev/null 2>&1; then
        docker build -q -t iac-host - >/dev/null <<'EOF'
FROM ubuntu:24.04
RUN apt-get update -q && apt-get install -yq openssh-server python3 sudo && rm -rf /var/lib/apt/lists/* \
 && useradd -m -s /bin/bash deploy && echo 'deploy ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/deploy \
 && mkdir -p /run/sshd /home/deploy/.ssh && chown deploy: /home/deploy/.ssh
CMD ["/usr/sbin/sshd", "-D", "-e"]
EOF
      fi
      # ana's key lives with the lab rather than in /home/ana, because every run
      # gets a /home/ana of its own; `inside` copies it into each one
      mkdir -p "$OPT/ssh"
      [ -f "$OPT/ssh/id_ed25519" ] || ssh-keygen -q -t ed25519 -N "" -C ana@laptop -f "$OPT/ssh/id_ed25519"
      local h name addr
      for h in $HOSTS; do
        name=${h%%:*} addr=${h#*:}
        docker rm -f "$name" >/dev/null 2>&1 || true
        docker run -d --name "$name" --hostname "$name" --network iac --ip "$addr" iac-host >/dev/null
        docker cp "$OPT/ssh/id_ed25519.pub" "$name:/home/deploy/.ssh/authorized_keys"
        docker exec "$name" chown deploy: /home/deploy/.ssh/authorized_keys
        grep -q " $name\$" /etc/hosts || printf '%s %s\n' "$addr" "$name" >> /etc/hosts
      done
      ;;
    down)
      local h; for h in $HOSTS; do docker rm -f "${h%%:*}" >/dev/null 2>&1 || true; done ;;
  esac
}

case ${1:-} in
  tools) tools ;;
  run) shift; run "$@" ;;
  inside) shift; inside "$@" ;;
  hosts) shift; hosts "$@" ;;
  *) echo "usage: lab.sh tools | run CMD... | hosts up|down" >&2; exit 2 ;;
esac
