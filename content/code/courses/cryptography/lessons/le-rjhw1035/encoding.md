---
title: Encoding is a format, not a lock
version: 1
---

**Encoding turns bytes into another representation by a public rule, so that they can travel
somewhere that only accepts text. Anybody can reverse it, because the rule is the whole of it.**
Base64, hexadecimal, URL encoding and PEM are encodings. None of them has a key, and none of them
hides anything from anybody.

## Base64 in three commands

The `Authorization` header of HTTP Basic authentication carries the user name and password joined by
a colon and encoded in Base64. Ana's credentials, encoded:

```
ana@lab:~/lab$ printf 'ana.lima:Vereda@2026' | base64
YW5hLmxpbWE6VmVyZWRhQDIwMjY=
```

And decoded, by anybody who sees the header, with no key:

```
ana@lab:~/lab$ echo 'YW5hLmxpbWE6VmVyZWRhQDIwMjY=' | base64 -d; echo
ana.lima:Vereda@2026
```

That is why Basic authentication is only acceptable inside TLS: the header is the password. Base64 is
there because HTTP headers carry text, and a password may contain bytes that would break the header.
It was never meant to protect anything.

## What the three look like side by side

The same six letters, in hexadecimal, in Base64, and encrypted with AES under the lab's key and then
Base64-encoded for display:

```
ana@lab:~/lab$ printf 'Vereda' | xxd -p; printf 'Vereda' | base64; printf 'Vereda' | openssl enc -aes-256-cbc -K $(cat keys/aes-256.hex) -iv $(cat keys/iv-a.hex) | base64
566572656461
VmVyZWRh
KUUmel4MOXcihqnxJ8ogPg==
```

Hexadecimal spends two characters per byte, Base64 four characters per three bytes. The third line
**also** looks like Base64, because it is: ciphertext is bytes, and bytes that must travel as text get
encoded too. What separates it from the second line is not how it looks but what reverses it. The
second needs `base64 -d`. The third needs `base64 -d` **and the key**.

## The commonest case: a Kubernetes Secret

Kubernetes stores Secret values in Base64, and many people read the word *Secret* and the unreadable
value and assume encryption. Vereda's portal has one, and these commands write it into the lab
exactly as it is deployed:

```sh
cd ~/lab
cat > data/portal-secret.yaml <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: portal-db
type: Opaque
data:
  username: cG9ydGFs
  password: Vi1kYi1zM2NyZXQtMjAyNg==
EOF
```

And whoever can read the manifest, or run `kubectl get secret -o yaml` with read access to it, has the
password:

```
ana@lab:~/lab$ grep password: data/portal-secret.yaml | awk '{print $2}' | base64 -d; echo
V-db-s3cret-2026
```

Kubernetes uses Base64 so that a Secret can hold binary data, such as a keystore, in a YAML file. The
protection of a Secret comes from elsewhere: who is allowed to read it (RBAC), whether the cluster
encrypts its datastore at rest (with a key provider), and whether the manifest is ever committed to a
repository. A Secret manifest in Git, Base64 and all, is a password in Git.
