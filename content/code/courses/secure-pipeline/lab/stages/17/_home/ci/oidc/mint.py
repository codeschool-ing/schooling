"""The CI server's identity tokens. For the branch a run is building, a JSON
Web Token that says which repository and which branch it is, signed with
the CI server's own private key. Anybody holding the public half can check
that this server said it and that nobody changed a word since.

    python3 ~/ci/oidc/mint.py REF [AUDIENCE]

prints the token, which is good for five minutes. The audience is the one
service it is meant for; Vault, unless you say otherwise.
"""
import base64
import json
import os
import subprocess
import sys
import time
import uuid
from pathlib import Path

KEY = Path(os.environ.get("CI_OIDC_KEY", Path.home() / "ci/oidc/ci-oidc.key"))
ISSUER = "https://ci.linkbox.example"
REPOSITORY = "ana/linkbox"
LIFETIME = 300


def b64(data):
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def claims(ref, audience):
    now = int(time.time())
    return {
        "iss": ISSUER,
        "sub": f"repo:{REPOSITORY}:ref:{ref}",
        "aud": audience,
        "repository": REPOSITORY,
        "ref": ref,
        "iat": now,
        "nbf": now,
        "exp": now + LIFETIME,
        "jti": str(uuid.uuid4()),
    }


def mint(ref, audience="vault"):
    header = b64(json.dumps({"alg": "RS256", "typ": "JWT"}).encode())
    payload = b64(json.dumps(claims(ref, audience)).encode())
    signed = header + "." + payload
    signature = subprocess.run(["openssl", "dgst", "-sha256", "-sign", str(KEY)],
                               input=signed.encode(), capture_output=True, check=True).stdout
    return signed + "." + b64(signature)


if __name__ == "__main__":
    print(mint(*sys.argv[1:3]))
