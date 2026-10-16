#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of aws-compute (ECR), as a script
# that produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                     # once, beside course.json
#   bash lessons/le-92qqj3wv/captures.sh  # the moto and Docker blocks
#   LAB_HOSTS=1 bash lessons/le-92qqj3wv/captures.sh prices
#
# Every run starts from an EMPTY moto and the terminal lines of lesson 1's
# section `your-lab`. Docker is the one the `docker` course installs; the image
# nginx:1.29-alpine is already on the machine, as lesson 8 leaves it.
#
# What is STAGED rather than typed:
#   - moto is started by the lab before the first command, not in a second
#     terminal;
#   - web/Dockerfile is taken out of the section `pushing` and lifecycle.json
#     out of the example in `tags-and-lifecycle`, so the files the student
#     copies are the files that ran;
#   - the image's digests change on every run, because a build writes the time
#     into the layer it adds: the lesson quotes the run it was written from, and
#     its prose names no digest that only one run printed;
#   - `prices` reads prices.py out of lesson 1's `the-price-sheet` and needs the
#     internet (the recording machine reaches it through a proxy, given as
#     HTTPS_PROXY; it does not change what AWS publishes);
#   - the images this script builds are removed at the end, which the student
#     does not need to do.
#
# NOT RUN, because moto answers ECR's API and not the registry protocol that
# `docker login`, `docker push` and `docker pull` speak: the section `pushing`
# shows those commands as AWS documents them, says so, and runs PutImage
# against moto instead, which is the last call a push makes.
#
# Recorded 2026-10-16 on Ubuntu 24.04, no AWS account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
LESSON1=$(cd "$HERE/../le-ps61q5st" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

if [ "${1:-}" = prices ]; then
  export HTTPS_PROXY=$LAB_PROXY
  from_example "$LESSON1/the-price-sheet.md" prices.py > prices.py
  block prices
  run 'python3 prices.py containers | grep -A3 "EKS and ECR"'
  exit 0
fi

REG=123456789012.dkr.ecr.sa-east-1.amazonaws.com

block repo-create
run 'aws ecr create-repository --repository-name shop/web'

block repo-bad-name
run 'aws ecr create-repository --repository-name Shop/Web'

block repo-policy
run "aws ecr set-repository-policy --repository-name shop/web --policy-text '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"ProductionPulls\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::444455556666:root\"},\"Action\":[\"ecr:BatchGetImage\",\"ecr:GetDownloadUrlForLayer\"]}]}' --query policyText --output text"

block build
quiet 'mkdir -p web'
from_lesson "$HERE/pushing.md" web/Dockerfile > web/Dockerfile
run "echo '<h1>shop 1.0.0</h1>' > web/index.html"
run 'docker build -q --provenance=false -t shop/web:1.0.0 web'
run "docker tag shop/web:1.0.0 $REG/shop/web:1.0.0"
run "docker image ls --format '{{.Repository}}:{{.Tag}}  {{.ID}}' | grep shop/web"

block login
run 'aws ecr get-login-password'
run "aws ecr get-authorization-token --query 'authorizationData[0].[proxyEndpoint,expiresAt]'"

block manifest
run "docker image inspect --format '{{.Id}}' shop/web:1.0.0"
run "D=\$(docker image inspect --format '{{.Id}}' shop/web:1.0.0 | cut -d: -f2)"
run 'docker save shop/web:1.0.0 | tar -xO "blobs/sha256/$D" > manifest.json'
run "jq '{mediaType, config: .config.digest, layers: [.layers[].size]}' manifest.json"
run 'sha256sum manifest.json'

block put
run 'aws ecr put-image --repository-name shop/web --image-tag 1.0.0 --image-manifest file://manifest.json --query image.imageId'
run 'aws ecr describe-images --repository-name shop/web'

block retag
run 'aws ecr put-image --repository-name shop/web --image-tag latest --image-manifest file://manifest.json --query image.imageId.imageTag'
run "aws ecr describe-images --repository-name shop/web --query 'imageDetails[].imageTags'"

block second
run "echo '<h1>shop 1.0.1</h1>' > web/index.html"
run 'docker build -q --provenance=false -t shop/web:1.0.1 web'
run "docker save shop/web:1.0.1 | tar -xO \"blobs/sha256/\$(docker image inspect --format '{{.Id}}' shop/web:1.0.1 | cut -d: -f2)\" > manifest-1.0.1.json"
run 'aws ecr put-image --repository-name shop/web --image-tag 1.0.1 --image-manifest file://manifest-1.0.1.json --query image.imageId.imageTag'
run 'aws ecr put-image --repository-name shop/web --image-tag latest --image-manifest file://manifest-1.0.1.json --query image.imageId.imageTag'
run "aws ecr describe-images --repository-name shop/web --query 'imageDetails[].[imageDigest,imageTags]'"

block overwrite
run "echo '<h1>shop 1.0.0, fixed</h1>' > web/index.html"
run 'docker build -q --provenance=false -t shop/web:1.0.0 web'
run "docker save shop/web:1.0.0 | tar -xO \"blobs/sha256/\$(docker image inspect --format '{{.Id}}' shop/web:1.0.0 | cut -d: -f2)\" > manifest-fixed.json"
run 'aws ecr put-image --repository-name shop/web --image-tag 1.0.0 --image-manifest file://manifest-fixed.json --query image.imageId.imageTag'
run "aws ecr describe-images --repository-name shop/web --query 'imageDetails[].[imageDigest,imageTags]'"

block immutable
run 'aws ecr put-image-tag-mutability --repository-name shop/web --image-tag-mutability IMMUTABLE'
run 'aws ecr put-image --repository-name shop/web --image-tag 1.0.1 --image-manifest file://manifest-fixed.json'
run 'aws ecr put-image --repository-name shop/web --image-tag latest --image-manifest file://manifest-fixed.json'

block exclusion
run 'aws ecr put-image-tag-mutability --repository-name shop/web --image-tag-mutability IMMUTABLE_WITH_EXCLUSION --image-tag-mutability-exclusion-filters filterType=WILDCARD,filter=latest'
run 'aws ecr put-image --repository-name shop/web --image-tag latest --image-manifest file://manifest-fixed.json --query image.imageId.imageTag'
run 'aws ecr put-image --repository-name shop/web --image-tag 1.0.1 --image-manifest file://manifest-fixed.json'

block lifecycle
from_example "$HERE/tags-and-lifecycle.md" lifecycle.json > lifecycle.json
run 'aws ecr put-lifecycle-policy --repository-name shop/web --lifecycle-policy-text file://lifecycle.json --query repositoryName'
run "aws ecr get-lifecycle-policy --repository-name shop/web --query lifecyclePolicyText --output text | jq -c '.rules[] | [.rulePriority, .selection.tagStatus, .selection.countType, .selection.countNumber]'"
run 'aws ecr start-lifecycle-policy-preview --repository-name shop/web'

block scan
run 'aws ecr put-image-scanning-configuration --repository-name shop/web --image-scanning-configuration scanOnPush=true --query imageScanningConfiguration'
run 'aws ecr start-image-scan --repository-name shop/web --image-id imageTag=1.0.1 --query imageScanStatus'
run "aws ecr describe-image-scan-findings --repository-name shop/web --image-id imageTag=1.0.1 --query 'imageScanFindings.findings[].[name,severity,attributes[?key==\`package_name\`].value|[0]]' --output text"
run 'aws ecr get-registry-scanning-configuration'

block cleanup
run 'aws ecr delete-repository --repository-name shop/web'
run 'aws ecr delete-repository --repository-name shop/web --force --query repository.repositoryName'
quiet "docker rmi shop/web:1.0.0 shop/web:1.0.1 $REG/shop/web:1.0.0"
