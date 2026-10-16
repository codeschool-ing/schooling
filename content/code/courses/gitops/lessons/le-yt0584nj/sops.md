---
title: SOPS and age
version: 1
---

**SOPS encrypts the values of a YAML file and leaves its keys readable.** A pull request that
changes a token then shows that `token` changed, in which file, and nothing about the value. Who can
decrypt is decided by the keys the file is encrypted to: a cloud key management service, a PGP key,
or an **age** key, the simplest of them, which is a small modern tool built for exactly this.

Both are single binaries from their release pages; `sops` has a checksum file and `age` is a
tarball:

```
ana@laptop:~/setup$ curl -fsSLO https://github.com/getsops/sops/releases/download/v3.13.3/sops-v3.13.3.linux.$ARCH
ana@laptop:~/setup$ curl -fsSL https://github.com/getsops/sops/releases/download/v3.13.3/sops-v3.13.3.checksums.txt | grep " sops-v3.13.3.linux.$ARCH$" | sha256sum --check
sops-v3.13.3.linux.amd64: OK
ana@laptop:~/setup$ sudo install -m 0755 sops-v3.13.3.linux.$ARCH /usr/local/bin/sops && rm sops-v3.13.3.linux.$ARCH
ana@laptop:~/setup$ curl -fsSLO https://github.com/FiloSottile/age/releases/download/v1.3.2/age-v1.3.2-linux-$ARCH.tar.gz
ana@laptop:~/setup$ tar -xzf age-v1.3.2-linux-$ARCH.tar.gz && sudo install -m 0755 age/age age/age-keygen /usr/local/bin/ && rm -r age age-v1.3.2-linux-$ARCH.tar.gz
ana@laptop:~/setup$ sops --disable-version-check --version; age --version
sops 3.13.3
v1.3.2
```

An age key is one line of private key, kept in the file SOPS looks in by default, and a public key
derived from it that starts with `age1`:

```
ana@laptop:~$ mkdir -p ~/.config/sops/age && age-keygen -o ~/.config/sops/age/keys.txt
Public key: age16890kj8h7350f8d3nah8fk9s67ert0uqasr3ydumddk00fqv93jsxqsenx
ana@laptop:~$ stat -c '%A %n' ~/.config/sops/age/keys.txt
-rw------- /home/ana/.config/sops/age/keys.txt
ana@laptop:~$ AGE=$(age-keygen -y ~/.config/sops/age/keys.txt); echo $AGE
age16890kj8h7350f8d3nah8fk9s67ert0uqasr3ydumddk00fqv93jsxqsenx
```

The private key file is readable by you only, as `age-keygen` made it. `$AGE` keeps the public key
for the next file.

SOPS reads its rules from `.sops.yaml` at the top of the repository: which files, which parts of
them and which keys. This one encrypts the `data` and `stringData` of any file under a `production`
directory whose name ends in `.sops.yaml`, to one age key. Your own public key goes in place of
`AGE_PUBLIC_KEY`. Save this as `.sops.yaml`:

```yaml
creation_rules:
- path_regex: apps/.*/production/.*\.sops\.yaml$
  encrypted_regex: ^(data|stringData)$
  age: AGE_PUBLIC_KEY
```

```
ana@laptop:~/fleet$ git switch --quiet -c production-token
ana@laptop:~/fleet$ cat .sops.yaml
creation_rules:
- path_regex: apps/.*/production/.*\.sops\.yaml$
  encrypted_regex: ^(data|stringData)$
  age: age16890kj8h7350f8d3nah8fk9s67ert0uqasr3ydumddk00fqv93jsxqsenx
ana@laptop:~/fleet$ TOKEN=$(openssl rand -hex 16)
ana@laptop:~/fleet$ kubectl -n production create secret generic bulletin-token --from-literal=token=$TOKEN --dry-run=client -o yaml > apps/bulletin/production/token.sops.yaml
ana@laptop:~/fleet$ sops --encrypt --in-place apps/bulletin/production/token.sops.yaml
ana@laptop:~/fleet$ cat apps/bulletin/production/token.sops.yaml
apiVersion: v1
data:
    token: ENC[AES256_GCM,data:q+RtdAW+bDo1BHHmFz/Ur1wzy9n2jULlz1YHM9R1sp2EepISC5KDfStrkys=,iv:yq2Adsl4qnyLSsFBLXN631rzBFPX63n8QFJi0OBSh94=,tag:jdkgtgoGzgQ5Zzyml4VCfg==,type:str]
kind: Secret
metadata:
    name: bulletin-token
    namespace: production
sops:
    age:
        - enc: |
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBtbDBHOG5qdjcwT1p3Q1ZH
            TzEzUS8zT3dtUFFHZzE1YUxObUdlWVE0WndBCnlxNDJwdVdZOGxDV1liVysyalli
            VHcxTU4yV2ZjcnFVM0FZdXYzNFpkV0UKLS0tIFZQUmZYblFHUEdGTlljQWNGeVpv
            UmQvRzlTcTBWUDByQzRXTWt1RCtSb00Kcy77a2V3QY1Xx1t9EWt4w1A5C11Pvn5U
            442sbXgBGS6lHFYCpxhjyF4S0fMnsWkNA/UqFzcRHt5Fj1XhxlAWUQ==
            -----END AGE ENCRYPTED FILE-----
          recipient: age16890kj8h7350f8d3nah8fk9s67ert0uqasr3ydumddk00fqv93jsxqsenx
    encrypted_regex: ^(data|stringData)$
    lastmodified: "2026-10-16T00:47:16Z"
    mac: ENC[AES256_GCM,data:0OtBmdHS11AhKDruf+WItP53xkBVbgw9N7xPujAye2GNlXBubwEk8/YxeElZ7d1PaGqJVqEe1b225FIHZIR7gc6vxVnEEFPTewEU0TrUjZPFd8o0rhV37t/DSl6oA5Xbg/dgZgmfzmgSBdWofh6NQ1ixlany+uaRlyki6jhNNZY=,iv:ESOB0OAcaowZkey1/f/YhUPMlTu6cCVymho4LE3GD1M=,tag:x6rAVVJsvxQMsaiXSuhJ9w==,type:str]
    version: 3.13.3
```

`token`'s value is now `ENC[...]`, and everything else reads as before: the kind, the name, the
namespace. The `sops` block at the end is SOPS's own: the data key, encrypted to the age key, and a
MAC over the whole file, so that an edit made without SOPS is detected rather than decrypted.

Whoever holds the private key reads the value back, which is how a person on call checks what
production has without going to the cluster:

```
ana@laptop:~/fleet$ sops --decrypt --extract '["data"]["token"]' apps/bulletin/production/token.sops.yaml | base64 -d | sha256sum | cut -c1-12
252c569e030c
```

That is the fingerprint `bulletin` will print for this token, computed from the file alone.

## The check meets an encrypted file

Production's kustomization lists `token.sops.yaml` among its resources, and the branch goes up for
review. The check runs first:

```
ana@laptop:~/fleet$ git add .sops.yaml apps && git commit --quiet -m "production: a token encrypted with SOPS"
ana@laptop:~/fleet$ git push --quiet -u origin production-token 2>/dev/null
ana@laptop:~/fleet$ sh ~/setup/validate.sh $(git rev-parse HEAD)
Summary: 2 resources found in 1 file - Valid: 2, Invalid: 0, Errors: 0, Skipped: 0
Summary: 4 resources found in 1 file - Valid: 2, Invalid: 0, Errors: 0, Skipped: 2
/tmp/tmp.I2wSNQEKy3/out.yaml - Secret bulletin-token is invalid: problem validating schema. Check JSON formatting: jsonschema validation failed with 'https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.37.0-standalone-strict/secret-v1.json#' - at '': additional properties 'sops' not allowed
Summary: 5 resources found in 1 file - Valid: 4, Invalid: 1, Errors: 0, Skipped: 0
Summary: 5 resources found in 1 file - Valid: 4, Invalid: 0, Errors: 0, Skipped: 1
validate: failure
```

Staging and production each built and validated, and production's Secret was refused by the strict
schema: `additional properties 'sops' not allowed`. The check posted `failure`, and the pull request
cannot merge.

`kubeconform -strict` refuses any field a Kubernetes object does not have, and SOPS added one:
`sops`, holding the encrypted data key and a checksum of the file. Flux removes it when it decrypts,
so what reaches the cluster is a plain Secret. The check should validate the same thing, so
`validate.sh` drops the `sops` block before validating. In `~/setup/validate.sh`, the `elif` line
becomes these two:

```sh
  elif ! awk '/^sops:/ { s = 1; next } /^[^ ]/ { s = 0 } !s' "$work/out.yaml" |
       kubeconform -strict -summary -skip HelmRelease,OCIRepository,SealedSecret -kubernetes-version 1.37.0; then
```

`awk` skips from a line `sops:` to the next line that starts at the margin, the next key or the next
`---`, and `kubeconform` reads what is left from its input. Nothing is decrypted: **the check never
holds the key**, which is the point.

## Flux decrypts

The cluster needs the private key to decrypt, and it is the one secret that cannot come from Git: it
is what opens everything else. It goes in by hand, once, as a Secret in `flux-system`, and
`clusters/lab/production.yaml` gains the lines that tell Flux to use it, under `spec`:

```yaml
  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

```
ana@laptop:~/fleet$ kubectl -n flux-system create secret generic sops-age --from-file=age.agekey=$HOME/.config/sops/age/keys.txt
secret/sops-age created
ana@laptop:~/fleet$ git diff | grep '^[-+] '
+  decryption:
+    provider: sops
+    secretRef:
+      name: sops-age
ana@laptop:~/fleet$ git commit --quiet -am "production: Flux decrypts with sops-age"
ana@laptop:~/fleet$ curl -s localhost:8081
bulletin 1.1
message: Welcome to the bulletin.
pod: bulletin-bdddf5d46-7rgfw
token: sha256:252c569e030c
ana@laptop:~/fleet$ kubectl -n production get secret bulletin-token -o jsonpath="{.data.token}" | base64 -d | sha256sum | cut -c1-12
252c569e030c
```

Production's pods had started before the Secret existed, with the volume marked optional and empty;
the kubelet filled in the file on a later sync of the volume, without a restart, and the page shows
the fingerprint `sops --decrypt` computed from the file.

Flux builds the overlay, decrypts every value SOPS encrypted, and applies the result. The plaintext
exists in the cluster's Secret and in the controller's memory, and nowhere in Git.
