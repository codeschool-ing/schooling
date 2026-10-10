#!/usr/bin/env bash
# The laptop every transcript in gitops was recorded on: one kind cluster, a
# registry and a Git server beside it, and the command-line tools the lessons
# install one at a time.
#
#   sudo bash lab.sh tools     # once: the CLIs into /opt/gitops/bin, and every
#                              # image a lesson runs into the image cache
#   sudo bash lab.sh up        # a fresh lab: the registry, Gitea and a cluster
#                              # called "gitops", as lesson 1 and 2 build them
#   sudo bash lab.sh mirror    # copy the cached images into the registry
#   sudo bash lab.sh down      # delete the cluster and the two containers
#
# EVERYTHING HERE IS WHAT A LESSON TELLS THE STUDENT TO BUILD, in the same
# order, with the same versions; the lessons show every file of it whole. What
# differs is where the software comes from, because the machine this was
# recorded on reaches some places and not others:
#
#   - the CLIs (kind, kubectl, kubeconform, argocd, flux, kubeseal, sops, age,
#     cosign, kustomize, vault) are the released binaries the lessons download, from
#     the same URLs, checked against the same published checksums. Helm's
#     binaries live on get.helm.sh, which this machine cannot reach, so helm is
#     built from its released source with the Go toolchain at the tag below.
#   - THE NODES PULL NOTHING FROM THE INTERNET. Every third-party image a lesson
#     runs is pulled once onto the laptop from Docker Hub and pushed into the
#     lab's own registry (the container lesson 1 starts as `registry`), and each
#     node's containerd is told to use that registry as a mirror for docker.io,
#     ghcr.io and public.ecr.aws. Flux publishes the same images on Docker Hub as
#     on ghcr.io, and public.ecr.aws/docker/library is a copy of Docker Hub's
#     official images, so the bytes a node runs are the bytes the name says.
#   - ARGO CD AND DEX ARE THE EXCEPTION. Their images live on quay.io and
#     ghcr.io and this machine can reach neither. The lab builds two images of
#     its own, named localhost:5001/lab/argocd and localhost:5001/lab/dex so
#     that nothing claims they came from upstream: argocd from the released
#     argocd-linux-amd64 binary (the same multi-call program the upstream image
#     carries, with git, gpg, ssh, helm and kustomize beside it) and dex from
#     its tagged source. Lesson 3's kustomization names them in an `images:`
#     block with a comment telling the student to delete it.
#   - the External Secrets Operator's image lives on ghcr.io too, and is built
#     the same way from its tagged source, as localhost:5001/lab/external-secrets.
#
# Two kind settings are for this machine and say so in the file lesson 1
# shows: it has cgroup v1, which the kubelet refuses since 1.35 unless told
# `failCgroupV1: false`, and it forbids lowering a process's OOM score
# (`restrict_oom_score_adj`).
#
# Recorded on Ubuntu 24.04 with Docker 29.8.2, TZ=America/Sao_Paulo.

set -euo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8

OPT=/opt/gitops
LAB=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export PATH=$OPT/bin:$PATH

KIND=v0.33.0
KUBECTL=v1.37.1
NODE=kindest/node:v1.37.0@sha256:a1ed56cfb0e7b93589bdf97c8cd566405a265939e3620fc4f5de89adff580ae5
ARGOCD=v3.5.4
DEX=v2.45.1
FLUX=2.9.6
KUBESEAL=0.40.0
SOPS=v3.13.3
AGE=v1.3.2
COSIGN=v3.1.3
KUSTOMIZE=v5.8.3
HELM=v4.3.0
VAULT=2.1.2
ESO=v1.3.2
GITEA=gitea/gitea:28.1.0-rootless
REGISTRY=registry:3.1.2

# Images a node runs, as the manifests name them. Each is pulled from Docker
# Hub (FROM) and pushed into the registry under its own name (TO, without the
# registry), which is what the node's mirror asks for.
MIRRORED="
fluxcd/source-controller:v1.9.6
fluxcd/kustomize-controller:v1.9.6
fluxcd/helm-controller:v1.6.5
fluxcd/notification-controller:v1.9.4
fluxcd/image-reflector-controller:v1.2.5
fluxcd/image-automation-controller:v1.2.5
"

die() { echo "lab.sh: $*" >&2; exit 1; }

fetch() { # URL FILE: download into $OPT/dl once
  local url=$1 out=$OPT/dl/$2
  [ -s "$out" ] || curl -fsSL -o "$out" "$url"
}

check() { # FILE SUMSFILE: the file's line in a published checksum list
  (cd "$OPT/dl" && grep -E "  \*?$1\$" "$2" | sed 's/\*//' | sha256sum --check --quiet) \
    || die "$1 does not match $2"
}

tools() {
  mkdir -p "$OPT/bin" "$OPT/dl" "$OPT/src"
  local gh=https://github.com
  # crane copies images between registries, for the cache below
  fetch $gh/google/go-containerregistry/releases/download/v0.22.1/go-containerregistry_Linux_x86_64.tar.gz go-containerregistry_Linux_x86_64.tar.gz
  fetch $gh/google/go-containerregistry/releases/download/v0.22.1/checksums.txt crane_checksums.txt
  check go-containerregistry_Linux_x86_64.tar.gz crane_checksums.txt
  tar -xzf "$OPT/dl/go-containerregistry_Linux_x86_64.tar.gz" -C "$OPT/bin" crane

  fetch $gh/kubernetes-sigs/kind/releases/download/$KIND/kind-linux-amd64 kind-linux-amd64
  fetch $gh/kubernetes-sigs/kind/releases/download/$KIND/kind-linux-amd64.sha256sum kind.sha256sum
  check kind-linux-amd64 kind.sha256sum
  install -m 0755 "$OPT/dl/kind-linux-amd64" "$OPT/bin/kind"

  fetch https://dl.k8s.io/release/$KUBECTL/bin/linux/amd64/kubectl kubectl
  echo "$(curl -fsSL https://dl.k8s.io/release/$KUBECTL/bin/linux/amd64/kubectl.sha256)  kubectl" > "$OPT/dl/kubectl.sha256"
  check kubectl kubectl.sha256
  install -m 0755 "$OPT/dl/kubectl" "$OPT/bin/kubectl"

  fetch $gh/argoproj/argo-cd/releases/download/$ARGOCD/argocd-linux-amd64 argocd-linux-amd64
  fetch $gh/argoproj/argo-cd/releases/download/$ARGOCD/cli_checksums.txt argocd_checksums.txt
  local f; for f in hack/gpg-wrapper.sh hack/git-verify-wrapper.sh entrypoint.sh; do
    fetch https://raw.githubusercontent.com/argoproj/argo-cd/$ARGOCD/$f argocd-$(basename $f); done
  check argocd-linux-amd64 argocd_checksums.txt
  install -m 0755 "$OPT/dl/argocd-linux-amd64" "$OPT/bin/argocd"

  fetch $gh/fluxcd/flux2/releases/download/v$FLUX/flux_${FLUX}_linux_amd64.tar.gz flux_${FLUX}_linux_amd64.tar.gz
  fetch $gh/fluxcd/flux2/releases/download/v$FLUX/flux_${FLUX}_checksums.txt flux_checksums.txt
  check flux_${FLUX}_linux_amd64.tar.gz flux_checksums.txt
  tar -xzf "$OPT/dl/flux_${FLUX}_linux_amd64.tar.gz" -C "$OPT/bin" flux

  fetch $gh/bitnami-labs/sealed-secrets/releases/download/v$KUBESEAL/kubeseal-$KUBESEAL-linux-amd64.tar.gz kubeseal-$KUBESEAL-linux-amd64.tar.gz
  fetch $gh/bitnami-labs/sealed-secrets/releases/download/v$KUBESEAL/sealed-secrets_${KUBESEAL}_checksums.txt kubeseal_checksums.txt
  check kubeseal-$KUBESEAL-linux-amd64.tar.gz kubeseal_checksums.txt
  tar -xzf "$OPT/dl/kubeseal-$KUBESEAL-linux-amd64.tar.gz" -C "$OPT/bin" kubeseal

  fetch $gh/getsops/sops/releases/download/$SOPS/sops-$SOPS.linux.amd64 sops-$SOPS.linux.amd64
  fetch $gh/getsops/sops/releases/download/$SOPS/sops-$SOPS.checksums.txt sops_checksums.txt
  check sops-$SOPS.linux.amd64 sops_checksums.txt
  install -m 0755 "$OPT/dl/sops-$SOPS.linux.amd64" "$OPT/bin/sops"

  # age publishes no checksum file; its releases are built reproducibly and
  # the tag's source is what the lesson points at.
  fetch $gh/FiloSottile/age/releases/download/$AGE/age-$AGE-linux-amd64.tar.gz age-$AGE-linux-amd64.tar.gz
  tar -xzf "$OPT/dl/age-$AGE-linux-amd64.tar.gz" -C "$OPT/bin" --strip-components=1 age/age age/age-keygen

  fetch $gh/sigstore/cosign/releases/download/$COSIGN/cosign-linux-amd64 cosign-linux-amd64
  fetch $gh/sigstore/cosign/releases/download/$COSIGN/cosign_checksums.txt cosign_checksums.txt
  check cosign-linux-amd64 cosign_checksums.txt
  install -m 0755 "$OPT/dl/cosign-linux-amd64" "$OPT/bin/cosign"

  fetch "$gh/kubernetes-sigs/kustomize/releases/download/kustomize%2F$KUSTOMIZE/kustomize_${KUSTOMIZE}_linux_amd64.tar.gz" kustomize_${KUSTOMIZE}_linux_amd64.tar.gz
  fetch "$gh/kubernetes-sigs/kustomize/releases/download/kustomize%2F$KUSTOMIZE/checksums.txt" kustomize_checksums.txt
  check kustomize_${KUSTOMIZE}_linux_amd64.tar.gz kustomize_checksums.txt
  tar -xzf "$OPT/dl/kustomize_${KUSTOMIZE}_linux_amd64.tar.gz" -C "$OPT/bin" kustomize

  fetch $gh/yannh/kubeconform/releases/download/v0.8.0/kubeconform-linux-amd64.tar.gz kubeconform-linux-amd64.tar.gz
  fetch $gh/yannh/kubeconform/releases/download/v0.8.0/CHECKSUMS kubeconform_CHECKSUMS
  check kubeconform-linux-amd64.tar.gz kubeconform_CHECKSUMS
  tar -xzf "$OPT/dl/kubeconform-linux-amd64.tar.gz" -C "$OPT/bin" kubeconform

  fetch https://releases.hashicorp.com/vault/$VAULT/vault_${VAULT}_linux_amd64.zip vault_${VAULT}_linux_amd64.zip
  fetch https://releases.hashicorp.com/vault/$VAULT/vault_${VAULT}_SHA256SUMS vault_SHA256SUMS
  check vault_${VAULT}_linux_amd64.zip vault_SHA256SUMS
  unzip -o -q "$OPT/dl/vault_${VAULT}_linux_amd64.zip" vault -d "$OPT/bin"

  [ -x "$OPT/bin/helm" ] && "$OPT/bin/helm" version --short | grep -q "$HELM" \
    || GOBIN=$OPT/bin go install -ldflags "-X helm.sh/helm/v4/internal/version.version=$HELM" helm.sh/helm/v4/cmd/helm@$HELM

  images
}

# Third-party images a node runs, copied once from Docker Hub (through Google's
# mirror of it, mirror.gcr.io) into a cache registry on 127.0.0.1:5002 that
# outlives every cluster, and from there into a fresh `registry` by `up`.
THIRD_PARTY="busybox:1.37 postgres:17-alpine hashicorp/vault:$VAULT hashicorp/vault-k8s:1.7.6
bitnami/sealed-secrets-controller:$KUBESEAL $MIRRORED"
CACHE=127.0.0.1:5002

images() {
  local i
  for i in $NODE $GITEA $REGISTRY buildpack-deps:trixie-scm buildpack-deps:trixie-curl; do
    docker image inspect "$i" >/dev/null 2>&1 || docker pull -q "$i" >/dev/null || die "cannot pull $i"
  done
  docker inspect cache >/dev/null 2>&1 || docker run -d --restart=always --name cache \
    -p $CACHE:5000 -v "$OPT/cache:/var/lib/registry" $REGISTRY >/dev/null
  sleep 1
  for i in $THIRD_PARTY; do
    crane manifest "$CACHE/$i" >/dev/null 2>&1 || crane copy --platform linux/amd64 "mirror.gcr.io/$i" "$CACHE/$i"
  done
  # public.ecr.aws/docker/library/redis is Docker Hub's official redis
  crane manifest "$CACHE/docker/library/redis:8.2.3-alpine" >/dev/null 2>&1 \
    || crane copy --platform linux/amd64 mirror.gcr.io/library/redis:8.2.3-alpine "$CACHE/docker/library/redis:8.2.3-alpine"
  # Argo CD, from its released binary, laid out as the upstream image lays it out
  crane manifest "$CACHE/lab/argocd:$ARGOCD" >/dev/null 2>&1 || {
    rm -rf "$OPT/src/argocd" && mkdir -p "$OPT/src/argocd"
    cp "$OPT/dl/argocd-linux-amd64" "$OPT/src/argocd/argocd"
    cp "$OPT/bin/helm" "$OPT/bin/kustomize" "$OPT/src/argocd/"
    for f in gpg-wrapper.sh git-verify-wrapper.sh entrypoint.sh; do cp "$OPT/dl/argocd-$f" "$OPT/src/argocd/$f"; done
    cp "$LAB/lab/argocd.Dockerfile" "$OPT/src/argocd/Dockerfile"
    docker build -q -t $CACHE/lab/argocd:$ARGOCD "$OPT/src/argocd" >/dev/null
    docker push -q --platform linux/amd64 $CACHE/lab/argocd:$ARGOCD >/dev/null
  }
  crane manifest "$CACHE/lab/dex:$DEX" >/dev/null 2>&1 || {
    rm -rf "$OPT/src/dex" && mkdir -p "$OPT/src/dex"
    # dex's go.mod says github.com/dexidp/dex while its tags are v2.x, so
    # `go install …@tag` refuses it; the tag is cloned and built instead.
    git clone -q --depth 1 --branch $DEX https://github.com/dexidp/dex "$OPT/src/dex/src"
    (cd "$OPT/src/dex/src" && CGO_ENABLED=0 go build -o "$OPT/src/dex/dex" ./cmd/dex)
    cp "$LAB/lab/dex.Dockerfile" "$OPT/src/dex/Dockerfile"
    docker build -q -t $CACHE/lab/dex:$DEX "$OPT/src/dex" >/dev/null
    docker push -q --platform linux/amd64 $CACHE/lab/dex:$DEX >/dev/null
  }
}

mirror() { # copy every cached image into the running registry
  local i
  for i in $(crane catalog $CACHE); do
    for t in $(crane ls "$CACHE/$i"); do
      crane copy "$CACHE/$i:$t" "localhost:5001/$i:$t" 2>/dev/null
      # docker.io/busybox is docker.io/library/busybox to a mirror
      case $i in */*) ;; *) crane copy "$CACHE/$i:$t" "localhost:5001/library/$i:$t" 2>/dev/null ;; esac
    done
  done
}

nodes_mirror() { # each node: localhost:5001 is the registry, and so are the mirrors
  local n h
  for n in $(kind get nodes --name gitops); do
    for h in localhost:5001 docker.io ghcr.io public.ecr.aws; do
      docker exec "$n" mkdir -p "/etc/containerd/certs.d/$h"
      printf '[host."http://registry:5000"]\n' | docker exec -i "$n" tee "/etc/containerd/certs.d/$h/hosts.toml" >/dev/null
    done
  done
}

# The file a lesson shows under the line naming `NAME` and ending in a colon.
shown() {
  awk -v name="\`$2\`" '
    f == 0 && index($0, name) && /:$/ { f = 1; next }
    f == 1 && /^```/ { f = 2; next }
    f == 2 && /^```$/ { exit }
    f == 2 { print }' "$1"
}

up() { # lesson 1's registry and cluster
  down
  docker run -d --restart=always --name registry -p 127.0.0.1:5001:5000 $REGISTRY >/dev/null
  sleep 1; mirror
  mkdir -p /home/ana/setup
  shown "$LAB/lessons/le-9qamvn14/the-cluster.md" '~/setup/cluster.yaml' > /home/ana/setup/cluster.yaml
  ( unset HTTPS_PROXY https_proxy HTTP_PROXY http_proxy NO_PROXY no_proxy
    kind create cluster --name gitops --image "$NODE" --config /home/ana/setup/cluster.yaml --quiet )
  docker network connect kind registry
  nodes_mirror
  kubectl wait --for=condition=Ready node --all --timeout=180s >/dev/null
}

gitea() { # lesson 2's Gitea, started as lesson 2 starts it, and ready
  docker run -d --restart=always --name gitea --network kind -p 127.0.0.1:3000:3000 \
    -e GITEA__security__INSTALL_LOCK=true $GITEA >/dev/null
  until curl -fs localhost:3000/api/v1/version >/dev/null; do sleep 1; done
}

L1=$LAB/lessons/le-9qamvn14
L2=$LAB/lessons/le-7e998tdb
commit_at() { GIT_AUTHOR_DATE=$1 GIT_COMMITTER_DATE=$1 git commit --quiet "${@:2}"; }

# The state at the end of lesson 1, built from the files lesson 1 shows: the
# bulletin image 1.0 in the registry, ~/bulletin, ~/fleet and its bare remote
# with lesson 1's four commits at their dates (so their hashes are lesson 1's),
# and staging applied.
stage1() {
  export GIT_AUTHOR_NAME='Ana Lima' GIT_AUTHOR_EMAIL=ana@example.org
  export GIT_COMMITTER_NAME='Ana Lima' GIT_COMMITTER_EMAIL=ana@example.org
  rm -rf /home/ana/bulletin /home/ana/fleet /home/ana/fleet.git /home/ana/.reconcile
  mkdir -p /home/ana/bulletin /home/ana/fleet/staging
  shown "$L1/the-application.md" '~/bulletin/index.cgi' > /home/ana/bulletin/index.cgi
  shown "$L1/the-application.md" '~/bulletin/Dockerfile' > /home/ana/bulletin/Dockerfile
  shown "$L1/a-reconciler.md" '~/setup/reconcile.sh' > /home/ana/setup/reconcile.sh
  docker build --quiet --build-arg VERSION=1.0 -t localhost:5001/bulletin:1.0 /home/ana/bulletin >/dev/null
  docker push --quiet localhost:5001/bulletin:1.0 >/dev/null
  cd /home/ana/fleet
  shown "$L1/desired-state.md" '~/fleet/staging/bulletin.yaml' > staging/bulletin.yaml
  git init --quiet --bare /home/ana/fleet.git
  git init --quiet && git add staging/bulletin.yaml
  commit_at 2026-10-12T09:00:00-03:00 -m "staging: bulletin 1.0"
  git remote add origin /home/ana/fleet.git
  sed -i 's/value: Staging is open for testing./value: Staging has the new banner./' staging/bulletin.yaml
  commit_at 2026-10-12T09:20:00-03:00 -am "staging: new banner"
  cp staging/bulletin.yaml /tmp/bulletin.yaml
  python3 -c "import sys; p=sys.argv[1]; s=open(p).read(); open(p,'w').write(s[:s.rindex('---\n')])" staging/bulletin.yaml
  commit_at 2026-10-12T09:40:00-03:00 -am "staging: no service"
  GIT_AUTHOR_DATE=2026-10-12T09:45:00-03:00 GIT_COMMITTER_DATE=2026-10-12T09:45:00-03:00 \
    git revert --quiet --no-edit HEAD >/dev/null
  git push --quiet -u origin main
  kubectl apply -f staging/ >/dev/null
  kubectl -n staging rollout status deployment bulletin --timeout=180s >/dev/null
  cd /home/ana
}

# The state at the end of lesson 2, on top of stage1: Gitea with ana, bruno and
# ci and their tokens in ~, git's credential file, fleet on the server and
# protected (one approval, the validate check), kubeconform, validate.sh, and
# the two changes lesson 2 kept: the "ready for review" banner and 3 replicas.
# Each goes through `merge`, the flow lesson 2 shows.
stage2() {
  export GIT_AUTHOR_NAME='Ana Lima' GIT_AUTHOR_EMAIL=ana@example.org
  export GIT_COMMITTER_NAME='Ana Lima' GIT_COMMITTER_EMAIL=ana@example.org
  docker rm -f gitea >/dev/null 2>&1 || true
  gitea
  local u
  docker exec gitea gitea admin user create --admin --username ana --password change-me-now --email ana@example.org --must-change-password=false >/dev/null
  for u in bruno ci; do
    docker exec gitea gitea admin user create --username $u --password change-me-too --email $u@example.org --must-change-password=false >/dev/null
  done
  docker exec gitea gitea admin user generate-access-token --username ana --token-name terminal --scopes write:repository,write:user --raw > /home/ana/ana.token
  docker exec gitea gitea admin user generate-access-token --username bruno --token-name terminal --scopes write:repository --raw > /home/ana/bruno.token
  docker exec gitea gitea admin user generate-access-token --username ci --token-name checks --scopes write:repository --raw > /home/ana/ci.token
  chmod 600 /home/ana/*.token
  git config --global credential.helper store
  printf 'http://ana:%s@localhost:3000\n' "$(cat /home/ana/ana.token)" > /home/ana/.git-credentials
  chmod 600 /home/ana/.git-credentials
  api POST /user/repos '{"name": "fleet", "private": true}' >/dev/null
  cd /home/ana/fleet
  git remote set-url origin http://localhost:3000/ana/fleet.git
  git push --quiet -u origin main
  for u in bruno ci; do api PUT /repos/ana/fleet/collaborators/$u '{"permission": "write"}' >/dev/null; done
  api POST /repos/ana/fleet/branch_protections '{"rule_name": "main", "enable_push": false, "required_approvals": 1, "dismiss_stale_approvals": true, "enable_status_check": true, "status_check_contexts": ["validate"]}' >/dev/null
  shown "$L2/checks.md" '~/setup/validate.sh' > /home/ana/setup/validate.sh
  git switch --quiet -c banner-v2
  sed -i 's/value: Staging has the new banner./value: Staging is ready for review./' staging/bulletin.yaml
  commit_at 2026-10-13T10:00:00-03:00 -am "staging: ready for review"
  merge banner-v2 "staging: ready for review"
  git switch --quiet -c three-replicas
  sed -i 's/  replicas: 2/  replicas: 3/' staging/bulletin.yaml
  commit_at 2026-10-13T11:05:00-03:00 -am "staging: three replicas"
  merge three-replicas "staging: three replicas"
  kubectl apply -f staging/ >/dev/null
  kubectl -n staging rollout status deployment bulletin --timeout=180s >/dev/null
  cd /home/ana
}

api() { # METHOD PATH [JSON]: Gitea's API as ana
  curl -fs -X "$1" -H "Authorization: token $(cat /home/ana/ana.token)" \
    -H 'Content-Type: application/json' ${3:+-d "$3"} "http://localhost:3000/api/v1$2"
}

# merge BRANCH TITLE: lesson 2's flow for the branch checked out in the current
# repository: push it, open the pull request as Ana, run validate.sh on its
# head as the CI, approve as Bruno, merge as Ana, and bring main up to date.
merge() {
  local repo n sha
  repo=$(git remote get-url origin | sed 's#.*localhost:3000/##; s#\.git$##')
  sha=$(git rev-parse HEAD)
  git push --quiet -u origin "$1" 2>/dev/null
  n=$(api POST /repos/$repo/pulls "{\"head\": \"$1\", \"base\": \"main\", \"title\": \"$2\"}" | jq .number)
  if [ "$repo" = ana/fleet ]; then
    (cd /home/ana && sh /home/ana/setup/validate.sh "$sha" >/dev/null)
  else
    curl -fs -H "Authorization: token $(cat /home/ana/ci.token)" -H 'Content-Type: application/json' \
      -d '{"state": "success", "context": "validate"}' "http://localhost:3000/api/v1/repos/$repo/statuses/$sha" >/dev/null
  fi
  curl -fs -H "Authorization: token $(cat /home/ana/bruno.token)" -H 'Content-Type: application/json' \
    -d '{"event": "APPROVED", "body": "Approved."}' "http://localhost:3000/api/v1/repos/$repo/pulls/$n/reviews" >/dev/null
  api POST /repos/$repo/pulls/$n/merge '{"Do": "merge"}' || die "pull request $n of $repo did not merge"
  git switch --quiet main && git pull --quiet
}

down() {
  kind delete cluster --name gitops >/dev/null 2>&1 || true
  docker rm -f registry gitea >/dev/null 2>&1 || true
}

case "${1:-}" in
  merge) shift; merge "$@" ;;
  tools|images|mirror|up|down|nodes_mirror|gitea|stage1|stage2) "$1" ;;
  *) sed -n '2,12p' "$0"; exit 1 ;;
esac
