#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of aws-operations. Output not
# committed; every transcript was copied from a run of this script.
#
#   bash captures.sh       (after lab.sh student; price.py is lesson 1's)
#
# STAGED: moto has no registry protocol, so `docker push` cannot reach it. The
# lab hands ECR the last request a push makes, the manifest, through
# `aws ecr put-image`, from manifests written here: two "builds" that differ in
# one layer. The layers they name were never uploaded anywhere. moto derives
# an image's digest from its layer digests, where a registry hashes the
# manifest's bytes; the lesson says so.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/aws" || exit 1
rm -rf ecr && mkdir ecr && cd ecr || exit 1
moto_up
student_env
from_lesson "$HERE/../le-a4hvmgna/prices.md" price.py > price.py

put build-a.json <<'EOF2'
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "config": {
    "mediaType": "application/vnd.oci.image.config.v1+json",
    "size": 1470,
    "digest": "sha256:9c7a54a9a43cca047013b82af109fe963fde787f63f9e016fdc3384500c2823d"
  },
  "layers": [
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
      "size": 29724688,
      "digest": "sha256:c6a83fedfae6ed8a4f5f7cbb6a7b6f1c1ec3d86fea8cb9e5ba2e01e6a87b2a6e"
    },
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
      "size": 412933,
      "digest": "sha256:3f1b0d6c4e2a8b9f7d5c3e1a0b9c8d7e6f5a4b3c2d1e0f9a8b7c6d5e4f3a2b1c"
    }
  ]
}
EOF2
quiet 'sed "s/3f1b0d6c4e2a8b9f/7a2e9c1d5b3f8e6a/; s/412933/415007/" build-a.json > build-b.json'

block mutable
run 'aws ecr create-repository --repository-name shop/web --query repository.imageTagMutability'
run 'aws ecr put-image --repository-name shop/web --image-tag latest --image-manifest file://build-a.json --query image.imageId.imageDigest --output text'
run 'diff build-a.json build-b.json'
run 'aws ecr put-image --repository-name shop/web --image-tag latest --image-manifest file://build-b.json --query image.imageId.imageDigest --output text'
run "aws ecr describe-images --repository-name shop/web --query 'imageDetails[].[imageDigest,imageTags[0]]' --output text"

block immutable
run 'aws ecr create-repository --repository-name shop/api --image-tag-mutability IMMUTABLE --query repository.imageTagMutability'
run 'aws ecr put-image --repository-name shop/api --image-tag 1.4.0 --image-manifest file://build-a.json --query image.imageId.imageDigest --output text'
run 'aws ecr put-image --repository-name shop/api --image-tag 1.4.0 --image-manifest file://build-b.json'
run 'aws ecr put-image --repository-name shop/api --image-tag 1.4.1 --image-manifest file://build-b.json --query image.imageId.imageDigest --output text'
run 'aws ecr put-image --repository-name shop/api --image-tag 3f9c2a1b7e40 --image-manifest file://build-b.json --query image.imageId.imageTag --output text'
run "aws ecr describe-images --repository-name shop/api --query 'imageDetails[].imageTags' --output text"

block exclusion
run "aws ecr create-repository --repository-name shop/worker --image-tag-mutability IMMUTABLE_WITH_EXCLUSION --image-tag-mutability-exclusion-filters filterType=WILDCARD,filter='dev-*' --query 'repository.[imageTagMutability,imageTagMutabilityExclusionFilters[0].filter]' --output text"

block scan
run 'aws ecr put-image-scanning-configuration --repository-name shop/api --image-scanning-configuration scanOnPush=true --query imageScanningConfiguration'
run 'aws ecr start-image-scan --repository-name shop/api --image-id imageTag=1.4.1 --query imageScanStatus'
run "aws ecr describe-image-scan-findings --repository-name shop/api --image-id imageTag=1.4.1 --query 'imageScanFindings.findings[].[name,severity,attributes[?key==\`package_name\`].value|[0]]' --output text"

from_lesson "$HERE/scanning.md" scan-gate.sh > scan-gate.sh
block gate
run 'bash scan-gate.sh shop/api 1.4.1; echo "exit status $?"'

put lifecycle.json <<'EOF2'
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "untagged images go after 7 days",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 7
      },
      "action": { "type": "expire" }
    },
    {
      "rulePriority": 2,
      "description": "keep the 30 newest dev builds",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["dev-"],
        "countType": "imageCountMoreThan",
        "countNumber": 30
      },
      "action": { "type": "expire" }
    }
  ]
}
EOF2
block lifecycle
run 'aws ecr put-lifecycle-policy --repository-name shop/web --lifecycle-policy-text file://lifecycle.json --query repositoryName'
run 'aws ecr start-lifecycle-policy-preview --repository-name shop/web 2>&1 | grep -m1 ERROR'
block price
run 'python3 price.py AmazonECR data storage'
run 'python3 price.py AmazonInspectorV2 SAE1-container-image'
