# Policy as code: this project's own rules, in policy/, over the files that
# say how linkbox is built and how it runs. The rules' own tests run first,
# so a rule that has stopped refusing what it was written to refuse breaks
# the build before it is trusted to pass anything.
set -euo pipefail
conftest verify --no-color
conftest test --no-color --namespace docker Dockerfile
conftest test --no-color --namespace kubernetes k8s/
