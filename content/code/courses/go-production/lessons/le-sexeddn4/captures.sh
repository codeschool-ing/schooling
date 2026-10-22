#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of go-production, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it. Every program it runs is placed from
# a lesson's own .md by `lab.sh place`, so nothing here is a second copy.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1, gcc and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the four files of hits, placed from lesson 1 (le-03nqvqms) into ~/ship,
#     with `go mod init example.com/hits` and access.log written by genlog
#     -n 20000, exactly as lesson 1 shows them.
#   - probe/main.go, Containerfile, .containerignore and probe/Containerfile,
#     placed from this lesson's sections, and `go mod init example.com/probe`
#     in ~/ship/probe, which the lesson names.
#   - Podman 4.9.3 from Ubuntu's archive, installed by lesson 17, and the two
#     base images, pulled once before this script runs (podman pull
#     docker.io/library/golang:1.27.1 and
#     gcr.io/distroless/static-debian12:nonroot). Docker Hub limits anonymous
#     pulls, and a build that finds its base already present pulls nothing.
#   - before the first build, the untagged images left by earlier runs of this
#     script are removed, so that the first `podman build` is a first build and
#     not a run of the layer cache. Only images whose history carries this
#     lesson's build steps are touched.
#   - cosign, installed with `go install` as the lesson shows; the first install
#     takes about three minutes and prints its downloads, a later one prints
#     nothing.
#   - COSIGN_PASSWORD. The lesson types `read -rs COSIGN_PASSWORD` and
#     `export COSIGN_PASSWORD` once; here each captured command runs in a shell
#     of its own, so the script hands the variable to every cosign line, and
#     feeds the `read` its line on standard input.
# Everything random is visible as random: image and container ids of builds
# without --timestamp, cosign's keys and signatures. Nothing here is a timing.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, podman 4.9.3,
# cosign v3.1.3, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
LAB_SH=${LAB_SH:-$HERE/../../lab.sh}
LESSON=$(basename "$HERE")
lab() { bash "$LAB_SH" "$@"; }
on() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "$*" 2>&1 || true; }
quiet() { lab exec "$1" "$2" >/dev/null 2>&1 || true; }
place() { lab place "$LESSON" "$1" "$2" "$3"; }
block() { printf '##### %s\n' "$1"; }
PASS='a passphrase only Ana knows'
cos() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "export COSIGN_PASSWORD='$PASS'; $*" 2>&1 || true; }
FMT='table {{.Repository}} {{.Tag}} {{.Size}}'

block setup
lab fresh ship
lab fresh ship-copy
lab place le-03nqvqms arguments tools/genlog/main.go ship
lab place le-03nqvqms subcommands internal/tally/tally.go ship
lab place le-03nqvqms subcommands main.go ship
lab place le-03nqvqms output-and-exit-codes main_test.go ship
quiet ship 'go mod init example.com/hits'
quiet ship 'go run ./tools/genlog -n 20000 > access.log'
quiet ship 'podman image exists docker.io/library/golang:1.27.1 || podman pull docker.io/library/golang:1.27.1'
quiet ship 'podman image exists gcr.io/distroless/static-debian12:nonroot || podman pull gcr.io/distroless/static-debian12:nonroot'
quiet ship 'for t in $(podman images --format "{{.Repository}}:{{.Tag}}" --filter reference=localhost/hits --filter reference=localhost/probe); do podman rmi -f $t; done'
quiet ship 'for n in 1 2 3 4 5; do for i in $(podman images -a --filter dangling=true --format "{{.ID}}"); do podman image inspect --format "{{range .History}}{{.CreatedBy}} {{end}}" $i | grep -q -e "WORKDIR /src" -e " in /hits" -e " in /probe" && podman rmi -f $i; done; done'

block static
on ship 'go build -o hits . && file hits | cut -d, -f1,4'
on ship 'ldd hits'
on ship 'go list -deps . | grep -x runtime/cgo; echo $?'
place a-static-binary probe/main.go ship
quiet ship/probe 'go mod init example.com/probe'
on ship/probe 'go build -o probe . && file probe | cut -d, -f1,4'
on ship/probe 'ldd probe | cut -d" " -f1'
on ship/probe 'go list -deps . | grep -x runtime/cgo'
on ship/probe './probe'
on ship/probe 'CGO_ENABLED=0 go build -o probe . && file probe | cut -d, -f1,4'
on ship/probe 'ldd probe; ./probe'
on ship 'CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o hits . && stat -c "%s bytes  %n" hits'
on ship 'file hits | cut -d, -f1,4; ./hits top -n 1 access.log'

block image
place the-image Containerfile ship
place the-image .containerignore ship
on ship "podman images --format '$FMT' --filter reference=docker.io/library/golang --filter reference=gcr.io/distroless/static-debian12"
on ship 'podman build --cap-drop=all --network=none -t hits:1 .'
on ship "podman images --format '$FMT' --filter reference=localhost/hits"
on ship 'podman run --rm --network=none -i hits:1 top -n 3 < access.log'
on ship 'podman run --rm --network=none -v "$PWD/access.log:/data/access.log:ro" hits:1 count /data/access.log'
on ship 'podman image inspect --format "{{.Config.User}} {{.Config.Entrypoint}}" hits:1'
on ship 'install -m 600 access.log private.log && podman run --rm --network=none -v "$PWD/private.log:/data/access.log:ro" hits:1 count /data/access.log; echo $?'
on ship 'podman run --rm --network=none -i hits:1 top -n 1 < private.log'
quiet ship 'rm private.log'
on ship 'podman history --format "{{.Size}}\t{{.CreatedBy}}" hits:1'
on ship 'podman build --cap-drop=all --network=none -t hits:1 .'

block scratch
on ship 'podman run --rm --network=none --entrypoint sh hits:1; echo $?'
place smaller-than-small probe/Containerfile ship
on ship/probe 'podman build -q --cap-drop=all -t probe:scratch .'
on ship/probe 'podman build -q --cap-drop=all --build-arg BASE=gcr.io/distroless/static-debian12:nonroot -t probe:distroless .'
on ship/probe 'podman run --rm --network=none probe:scratch'
on ship/probe 'podman run --rm --network=none probe:distroless'
on ship/probe "podman images --format '$FMT' --filter reference=localhost/probe"
on ship 'podman create --name peek hits:1 >/dev/null && podman export peek > peek.tar && podman rm peek >/dev/null'
on ship 'tar -tf peek.tar | wc -l; tar -tf peek.tar | grep -c zoneinfo/'
on ship 'tar -tf peek.tar | grep -E "^(etc/(passwd|group|nsswitch.conf)|etc/ssl/certs/.*|bin/.*|hits)$"'
on ship 'tar -xOf peek.tar etc/passwd'
quiet ship 'rm peek.tar'
on ship/probe 'CGO_ENABLED=0 go build -tags timetzdata -o probe-tz . && stat -c "%s bytes  %n" probe probe-tz'
quiet ship/probe 'rm probe-tz'
on ship/probe 'CGO_ENABLED=1 go build -o probe . && podman build -q --cap-drop=all --build-arg BASE=gcr.io/distroless/static-debian12:nonroot -t probe:dynamic .'
on ship/probe 'podman run --rm --network=none probe:dynamic; echo $?'
quiet ship/probe 'CGO_ENABLED=0 go build -o probe .'

block digest
on ship 'podman image inspect --format "{{.Digest}}" gcr.io/distroless/static-debian12:nonroot'
on ship 'podman manifest inspect gcr.io/distroless/static-debian12@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab | jq -r ".manifests[] | .platform.architecture + \" \" + .digest"'
place smaller-than-small Containerfile ship
on ship 'podman build --cap-drop=all --network=none -t hits:1 . | grep -e STEP -e COMMIT'

block sums
on ship 'for a in amd64 arm64; do CGO_ENABLED=0 GOARCH=$a go build -trimpath -ldflags="-s -w" -o dist/hits-linux-$a .; done'
on ship/dist 'sha256sum hits-* > SHA256SUMS && cat SHA256SUMS'
on ship/dist 'sha256sum -c SHA256SUMS'
on ship/dist 'printf x >> hits-linux-arm64; sha256sum -c SHA256SUMS; echo $?'
on ship 'CGO_ENABLED=0 GOARCH=arm64 go build -trimpath -ldflags="-s -w" -o dist/hits-linux-arm64 . && cd dist && sha256sum -c --quiet SHA256SUMS'
on ship 'rm dist/hits-linux-arm64 && CGO_ENABLED=0 GOARCH=arm64 go build -trimpath -ldflags="-s -w" -o dist/hits-linux-arm64 . && cd dist && sha256sum -c --quiet SHA256SUMS && echo all good'

block repro
on ship 'cp -r go.mod main.go internal ~/ship-copy/'
on ship 'go build -o /tmp/hits-a . && (cd ~/ship-copy && go build -o /tmp/hits-b .) && sha256sum /tmp/hits-a /tmp/hits-b'
on ship 'go build -trimpath -o /tmp/hits-a . && (cd ~/ship-copy && go build -trimpath -o /tmp/hits-b .) && sha256sum /tmp/hits-a /tmp/hits-b'
quiet ship 'rm -f /tmp/hits-a /tmp/hits-b'
on ship 'podman create --name peek hits:1 >/dev/null && podman cp peek:/hits from-image && podman rm peek >/dev/null'
on ship 'sha256sum hits from-image dist/hits-linux-amd64'
on ship 'podman image inspect --format "{{.Created}}" gcr.io/distroless/static-debian12:nonroot'
on ship 'podman build -q --no-cache --cap-drop=all --network=none --timestamp 0 -t hits:r1 .'
on ship 'podman build -q --no-cache --cap-drop=all --network=none --timestamp 0 -t hits:r2 .'
on ship 'podman build -q --no-cache --cap-drop=all --network=none -t hits:r2 .'

block cosign
on ship 'go install github.com/sigstore/cosign/v3/cmd/cosign@v3.1.3'
on ship 'cosign version 2>&1 | grep -e GitVersion -e GoVersion -e Platform'
printf 'ana@vm:~/ship$ read -rs COSIGN_PASSWORD; export COSIGN_PASSWORD\n'
printf '%s\n' "$PASS" | lab exec ship 'read -rs COSIGN_PASSWORD; export COSIGN_PASSWORD' 2>&1 || true
cos ship 'cosign generate-key-pair'
on ship 'stat -c "%a  %n" cosign.key cosign.pub'
on ship 'cosign signing-config create --out no-tlog.json && cat no-tlog.json; echo'
cos ship 'cosign sign-blob --key cosign.key --signing-config no-tlog.json --bundle dist/SHA256SUMS.sigstore.json dist/SHA256SUMS'
on ship 'cosign verify-blob --key cosign.pub --bundle dist/SHA256SUMS.sigstore.json --insecure-ignore-tlog dist/SHA256SUMS'
on ship 'sed "2s/^......../00000000/" dist/SHA256SUMS > forged; cosign verify-blob --key cosign.pub --bundle dist/SHA256SUMS.sigstore.json --insecure-ignore-tlog forged; echo $?'
on ship 'jq -r .messageSignature.messageDigest.digest dist/SHA256SUMS.sigstore.json | base64 -d | od -An -tx1 -v | tr -d " \n"; echo'
on ship 'sha256sum dist/SHA256SUMS'
