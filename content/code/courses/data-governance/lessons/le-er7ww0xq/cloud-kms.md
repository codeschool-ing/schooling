---
title: The same jobs in a cloud
version: 1
---

Most companies do not run their own key service for their cloud data; they use the provider's.
The concepts of this lesson carry over one to one, and only the commands change:

| this lesson | AWS KMS | Google Cloud KMS | Azure Key Vault |
|---|---|---|---|
| a transit key | a KMS key | a key in a key ring | a key in a vault |
| a policy on a path | a key policy and IAM | IAM roles on the key | access policies or Azure RBAC |
| `transit/encrypt` | `Encrypt` | `encrypt` | `encrypt` |
| `transit/datakey` | `GenerateDataKey` | none: encrypt a key you generate | none: wrap a key you generate |
| rotate, versions | automatic yearly rotation | rotation schedule, key versions | rotation policy, key versions |
| the audit file | CloudTrail | Cloud Audit Logs | Azure Monitor logs |

The two commands below are the AWS and Google equivalents of section 9's data key and of section
6's encryption. **They were not run**: no account on either cloud is reachable from where this
course was recorded. They are taken from each provider's documentation and are here to be
recognised, not copied.

```sh
aws kms generate-data-key --key-id alias/ipe-backup --key-spec AES_256
gcloud kms encrypt --key ipe-cpf --keyring ipe --location southamerica-east1 \
  --plaintext-file cpf.txt --ciphertext-file cpf.enc
```

## Who holds the key, again

A cloud KMS raises one question OpenBao in your own VM does not: **the provider runs the hardware
the keys live in.** Three arrangements answer it differently:

- **Keys generated and held by the provider** — the default, and enough for most data: the
  provider's staff cannot use a key without going through the same policies and audit as you.
- **Bring your own key (BYOK)** — you generate the key material and import it, so you hold a copy
  outside the provider, and can prove where the key came from.
- **Hold your own key (HYOK)**, or an external key manager — the key stays in a service you
  control and the cloud asks it for every use; you can cut the provider off by refusing.

The more control, the more of the availability problem from section 3 becomes yours. **An
external key that is unreachable is a cloud database that cannot be read**, by you as much as by
anybody else. The choice belongs with whoever can say which risk the company would rather carry,
and it is written down where the next person can find it.
