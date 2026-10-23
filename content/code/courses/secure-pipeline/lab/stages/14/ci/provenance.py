"""The provenance of this run, as a SLSA v1 predicate: what was built, from
which commit of which repository, by which builder, and when. The image it
describes is the subject of the attestation that carries it."""
import datetime
import json
import os
from pathlib import Path

# The CI server checks the pushed commit out detached, so HEAD holds its hash.
commit = Path(".git/HEAD").read_text().strip()
print(json.dumps({
    "buildDefinition": {
        "buildType": "https://example.org/linkbox/ci/pipeline/v1",
        "externalParameters": {
            "repository": "ci/linkbox.git",
            "ref": "refs/heads/" + os.environ.get("CI_BRANCH", "main"),
        },
        "resolvedDependencies": [
            {"uri": "git+file:ci/linkbox.git", "digest": {"gitCommit": commit}},
        ],
    },
    "runDetails": {
        "builder": {"id": "https://example.org/linkbox/ci/post-receive"},
        "metadata": {
            "invocationId": os.environ.get("CI_LOGS", "local"),
            "finishedOn": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
        },
    },
}, indent=2))
