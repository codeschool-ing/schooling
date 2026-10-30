---
title: The static key, and why it is the problem
version: 1
---

The shop's `photos` service runs in the GKE cluster of lessons 13 and 14 and reads pictures from a
Cloud Storage bucket, `shop-photos`. To call the Storage API it needs a Google identity. **The
quick way to give it one is a service account key: a JSON file holding a private key, mounted into
the pod from a Kubernetes Secret.** It works the first time, and it is the arrangement this lesson
exists to remove.

## What a key file is

A service account key is created with one documented command, which needs an account and was not
run here:

```sh
gcloud iam service-accounts keys create photos-key.json \
  --iam-account=photos-reader@planner-dev.iam.gserviceaccount.com
```

What it writes has this shape. Make a folder `static-key` in `~/gcp`, go into it, and create the
file with these values, which are **not a key**: they have a key's fields and nothing that would
ever authenticate.

```sh
cat > photos-key.json <<'EOF'
{
  "type": "service_account",
  "project_id": "planner-dev",
  "private_key_id": "0000000000000000000000000000000000000000",
  "private_key": "-----BEGIN PRIVATE KEY-----\nNOT A REAL KEY, ONLY ITS SHAPE\n-----END PRIVATE KEY-----\n",
  "client_email": "photos-reader@planner-dev.iam.gserviceaccount.com",
  "client_id": "000000000000000000000",
  "token_uri": "https://oauth2.googleapis.com/token"
}
EOF
```

**A real one has a working private key where this one has a sentence, and that is all it needs.**
Whoever holds the file can act as `photos-reader` from any computer in the world, until somebody
deletes the key. A user-managed key has no expiry of its own unless an organisation policy sets one.

## Into a Secret

The usual next step puts the file into a Kubernetes Secret, so the pod can mount it. A Secret's
`data` holds values in base64, which is what `kubectl create secret` would write. In the lab, with
no cluster, `printf` writes the same thing:

```
ana@laptop:~/gcp/static-key$ printf "apiVersion: v1\nkind: Secret\nmetadata:\n  name: photos-key\ndata:\n  key.json: %s\n" "$(base64 -w0 photos-key.json)" > secret.yaml
ana@laptop:~/gcp/static-key$ cut -c1-72 secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: photos-key
data:
  key.json: ewogICJ0eXBlIjogInNlcnZpY2VfYWNjb3VudCIsCiAgInByb2plY3RfaWQi
```

That line looks like protection, and **base64 is an encoding, not encryption.** Anybody who can read
the Secret, with `kubectl get secret -o yaml`, a backup of the cluster's state, or a copy of the
manifest that went into git, reverses it without a password:

```
ana@laptop:~/gcp/static-key$ grep key.json secret.yaml | awk '{print $2}' | base64 -d | grep -E 'client_email|private_key"'
  "private_key": "-----BEGIN PRIVATE KEY-----\nNOT A REAL KEY, ONLY ITS SHAPE\n-----END PRIVATE KEY-----\n",
  "client_email": "photos-reader@planner-dev.iam.gserviceaccount.com",
```

## Why this is the problem

Everything that can go wrong with a key goes wrong quietly:

- **It leaks without a sign.** A key copied out of a Secret, a laptop or a CI log works from
  anywhere, and the audit log shows `photos-reader` doing what `photos-reader` always does.
- **It does not end.** Nothing expires it, so a key made for a test three years ago still opens the
  bucket today.
- **Rotating it is a project.** A new key has to be created, put into every Secret that carries the
  old one, rolled out, and only then the old one deleted; teams put that off.

Google's own recommendation is to avoid user-managed keys wherever a better mechanism exists, and
organisations commonly forbid creating them with the policy `iam.disableServiceAccountKeyCreation`.
For a pod in GKE the better mechanism is **Workload Identity Federation for GKE**: the pod gets
short-lived tokens for a Google identity without any file existing at all. The next three sections
build it, and the last of them removes even the Google service account.

Delete the file and the Secret before moving on; they were only ever an example of what not to keep.
