#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged rather than typed, and this lesson has more of it than most:
#
# - Trivy's vulnerability database is fetched BEFORE the lab starts, by this
#   script, on the host: the OCI artifact mirror.gcr.io/aquasec/trivy-db:2,
#   which is where Trivy itself downloads it from, saved under
#   /opt/docker-lab/trivy-cache and copied into Ana's home. The lab's
#   containers have no network, so Trivy runs with --skip-db-update and
#   --offline-scan. Every count in the lesson is as of the database's
#   UpdatedAt, which the lesson prints.
# - The images below are pulled before the first command, the lesson 18
#   Dockerfile and probe/main.go are written quietly, and a registry:3 is
#   started on 127.0.0.1:5000 without a password (lesson 15 covers that).
# - BuildKit fetches its SBOM generator, docker/buildkit-syft-scanner, on the
#   first build that asks for one; its pull lines are filtered out of the
#   build output, which the lesson shows only in part.
#
# - The fix in the last section updates one Go module. Ana has no Go on her
#   machine and the lab's containers have no network, so the module, and
#   everything shelf needs to vendor it, is downloaded on the host BEFORE the
#   lab starts, with the checksum database's answers that verify it
#   (/opt/docker-lab/gopath/pkg, copied to ~/gopkg). The containerised
#   `go get` runs with GOPROXY=off, which the command shows, and verifies the
#   module against those cached answers; checksum verification stays on.
#
# Nothing here signs an image: the lab cannot reach Sigstore's services, and
# the lesson marks its signing commands as not run.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, Trivy 0.75, TZ=America/Sao_Paulo.
export LAB_IMAGES="golang:1.25 gcr.io/distroless/static-debian12:nonroot alpine:3.22 debian:trixie-slim registry:3 aquasec/trivy:0.75.0"
if [ -z "${IN_LAB:-}" ] && [ ! -s /opt/docker-lab/trivy-cache/db/trivy.db ]; then
  m=$(curl -fsS -H "Accept: application/vnd.oci.image.manifest.v1+json" \
    https://mirror.gcr.io/v2/aquasec/trivy-db/manifests/2) || exit 1
  d=$(printf '%s' "$m" | jq -r '.layers[0].digest')
  sudo mkdir -p /opt/docker-lab/trivy-cache/db
  curl -fsSL "https://mirror.gcr.io/v2/aquasec/trivy-db/blobs/$d" -o /tmp/trivy-db.tgz || exit 1
  [ "sha256:$(sha256sum /tmp/trivy-db.tgz | cut -d' ' -f1)" = "$d" ] || { echo "digest mismatch" >&2; exit 1; }
  sudo tar -xzf /tmp/trivy-db.tgz -C /opt/docker-lab/trivy-cache/db && rm /tmp/trivy-db.tgz
fi
if [ -z "${IN_LAB:-}" ] && [ ! -d /opt/docker-lab/gopath/pkg/mod/golang.org/x/text@v0.39.0 ]; then
  sudo install -d -o "$(id -u)" /opt/docker-lab/gopath
  tmp=$(mktemp -d) && cp -r "$(dirname "$0")/../../lab/shelf/." "$tmp" || exit 1
  (cd "$tmp" && export PATH=$PATH:/usr/local/go/bin GOPATH=/opt/docker-lab/gopath GOFLAGS=-mod=mod \
    && go get golang.org/x/text@v0.39.0 && go mod tidy && go mod vendor) || exit 1
  chmod -R u+w /opt/docker-lab/gopath
  rm -rf "$tmp" /opt/docker-lab/gopath/pkg/mod/golang.org/toolchain* /opt/docker-lab/gopath/pkg/mod/cache/download/golang.org/toolchain
fi
. "$(dirname "$0")/../../capture.sh"
quiet 'cp -r /opt/docker-lab/trivy-cache ~/trivy-cache'
quiet 'cp -r /opt/docker-lab/gopath/pkg ~/gopkg'
quiet 'docker run -d --name registry -p 127.0.0.1:5000:5000 registry:3'
cd shelf
mkdir -p probe
staged probe/main.go <<'GO'
// probe exits 0 when a GET of its one argument answers 200, and 1 otherwise.
// It is the health check for an image that has no shell and no curl.
package main

import (
	"net/http"
	"os"
	"time"
)

func main() {
	c := http.Client{Timeout: 2 * time.Second}
	r, err := c.Get(os.Args[1])
	if err != nil || r.StatusCode != http.StatusOK {
		os.Exit(1)
	}
}
GO
staged Dockerfile <<'DF'
FROM golang:1.25 AS build
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
RUN go build net/http github.com/jackc/pgx/v5/pgxpool
COPY *.go ./
COPY probe/ probe/
ARG VERSION=dev
RUN CGO_ENABLED=0 go build -ldflags "-X main.version=${VERSION}" -o /out/shelf . \
 && CGO_ENABLED=0 go build -o /out/probe ./probe

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/shelf /out/probe /
USER 65532:65532
HEALTHCHECK --interval=5s --timeout=2s --start-period=5s --retries=3 \
  CMD ["/probe", "http://127.0.0.1:8080/health"]
CMD ["/shelf"]
DF
staged .dockerignore <<'IGN'
.git
.env
testdata/
Dockerfile*
.dockerignore
IGN
cd ..

block wrapper
run 'trivy() { docker run --rm -v ~/trivy-cache:/cache -v "$PWD":/work -w /work aquasec/trivy:0.75.0 "$@" --cache-dir /cache --skip-db-update --skip-version-check --offline-scan --scanners vuln --quiet; }'
run 'jq -c "{UpdatedAt}" ~/trivy-cache/db/metadata.json'

block build
run 'cd shelf && docker build -q --build-arg VERSION=1.6.0 -t shelf:1.6.0 . && cd ..'
run 'docker save debian:trixie-slim -o debian.tar; docker save alpine:3.22 -o alpine.tar; docker save shelf:1.6.0 -o shelf.tar'

block counts
put severities.jq <<'JQ'
[.Results[]?.Vulnerabilities[]?.Severity]
| group_by(.) | map("\(.[0])=\(length)") | join(" ")
| if . == "" then "none" else . end
JQ
run 'for i in debian alpine shelf; do printf "%-7s " $i; trivy image --input $i.tar --format json | jq -r -f severities.jq; done'

block shelf-table
run 'trivy image --input shelf.tar'

block one-finding
run 'trivy image --input debian.tar --format json | jq "[.Results[0].Vulnerabilities[] | select(.Severity == \"HIGH\")][0] | {VulnerabilityID, PkgName, InstalledVersion, FixedVersion, Status}"'
run 'trivy image --input debian.tar --format json | jq -r "[.Results[0].Vulnerabilities[].Status] | group_by(.) | map(\"\(.[0])=\(length)\") | join(\" \")"'
run 'trivy image --input debian.tar --ignore-unfixed --format json | jq -r -f severities.jq'

block gate
run 'trivy image --input shelf.tar --exit-code 1 --severity HIGH,CRITICAL > /dev/null; echo "exit $?"'
run 'trivy image --input debian.tar --exit-code 1 --severity HIGH,CRITICAL > /dev/null; echo "exit $?"'

block attest-build
run 'cd shelf && docker build --sbom=true --provenance=mode=min --build-arg VERSION=1.6.0 -t localhost:5000/shelf:1.6.0 --push . 2>&1 | grep -E "attestation|manifest list|pushing manifest" | sort -u; cd ..'

block index
run 'docker buildx imagetools inspect localhost:5000/shelf:1.6.0'

block sbom
run 'docker buildx imagetools inspect localhost:5000/shelf:1.6.0 --format "{{json .SBOM.SPDX}}" | jq -r ".packages[] | select(.versionInfo != null) | \"\(.name) \(.versionInfo)\"" | sort'

block provenance
run 'docker buildx imagetools inspect localhost:5000/shelf:1.6.0 --format "{{json .Provenance.SLSA}}" | jq "{dependencies: [.buildDefinition.resolvedDependencies[] | {uri, sha256: .digest.sha256[0:12]}], revision: .runDetails.metadata.buildkit_metadata.vcs.revision}"'

block update
run 'cd shelf'
run 'docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/src -w /src -v ~/gopkg:/go/pkg -e GOCACHE=/tmp/gocache -e GOPROXY=off -e GOFLAGS=-mod=mod golang:1.25 sh -c "go get golang.org/x/text@v0.39.0 && go mod tidy && go mod vendor"'
run 'git diff --stat -- go.mod go.sum vendor/modules.txt'
run 'grep x/text go.mod'
run 'docker build -q --build-arg VERSION=1.6.1 -t shelf:1.6.1 . && docker save shelf:1.6.1 -o ../shelf-1.6.1.tar'
run 'cd ..'
run 'trivy image --input shelf-1.6.1.tar --format json | jq -r -f severities.jq'
