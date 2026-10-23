# The image, into the registry. It is the last stage, so nothing reaches the
# registry that a stage before it refused. A run on main also moves the tag
# main, which is what the cluster's manifest names.
set -euo pipefail
tag=localhost:5000/linkbox:${CI_COMMIT:-dev}
docker tag "linkbox:${CI_COMMIT:-dev}" "$tag"
docker push -q "$tag"
if [ "${CI_BRANCH:-}" = main ]; then
  docker tag "$tag" localhost:5000/linkbox:main
  docker push -q localhost:5000/linkbox:main
fi
