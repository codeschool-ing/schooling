---
title: Every use, written down
version: 1
---

OpenBao wrote every request of the last section to the audit file declared in its configuration.
The last line is support's refused attempt to read the key, and it is worth reading whole:

```
ana@lab:~/gov$ sudo tail -n 1 /var/log/bao/audit.log | python3 -m json.tool
{
    "time": "2026-10-07T03:31:32.469348851Z",
    "type": "response",
    "auth": {
        "client_token": "hmac-sha256:e686ccd2a03f9324bbca9c2f4e0b568e9297bdde29e4f80336de4890e00941ba",
        "accessor": "hmac-sha256:28e7353fa80788e9b4780f56296a6183e860c12f58a8ac0604f38794409a2d89",
        "display_name": "token",
        "policies": [
            "default",
            "support"
        ],
        "token_policies": [
            "default",
            "support"
        ],
        "policy_results": {
            "allowed": false
        },
        "token_type": "service",
        "token_ttl": 3600,
        "token_issue_time": "2026-10-07T03:31:31Z"
    },
    "request": {
        "id": "54d19358-f2c4-a195-ae26-f365696091c7",
        "client_id": "YKvI9vKtRWISW5quAhZfWfERA7LcP30yuME/HSu3/W8=",
        "operation": "read",
        "mount_point": "transit/",
        "mount_type": "transit",
        "mount_running_version": "v2.5.5+builtin.bao",
        "mount_class": "secret",
        "client_token": "hmac-sha256:e686ccd2a03f9324bbca9c2f4e0b568e9297bdde29e4f80336de4890e00941ba",
        "client_token_accessor": "hmac-sha256:28e7353fa80788e9b4780f56296a6183e860c12f58a8ac0604f38794409a2d89",
        "namespace": {
            "id": "root"
        },
        "path": "transit/keys/ipe-cpf",
        "remote_address": "127.0.0.1",
        "remote_port": 35222
    },
    "response": {
        "mount_point": "transit/",
        "mount_type": "transit",
        "mount_running_plugin_version": "v2.5.5+builtin.bao",
        "mount_class": "secret",
        "data": {
            "error": "hmac-sha256:5d7ef83fb6db661c7e616c7d331786868549249309a0a85352d82a1d5115e433"
        }
    },
    "error": "1 error occurred:\n\t* permission denied\n\n"
}
```

What is recorded, and what is deliberately not:

- **who** — the token's policies, `default` and `support`, its type and when it was issued. The
  token itself and its accessor are there as **`hmac-sha256:` values**, not in clear;
- **what** — the operation, `read`, on the path `transit/keys/ipe-cpf`, from `127.0.0.1`;
- **the outcome** — `policy_results` says `allowed: false`, and the error is in the last line;
- **not the data.** Every field that could carry a secret is replaced by an HMAC: a keyed hash
  with a key only this OpenBao holds.

The HMACs are the clever part. The log never contains a token, a plaintext CPF or a ciphertext,
so it can be shipped to a log platform and read by the security team without becoming a store of
secrets itself. And yet it can still answer "was this token used?": an investigator holding a
suspect token asks OpenBao to hash it with the same key (its `sys/audit-hash` endpoint does that) and searches
the log for the result. **The log can confirm a value it cannot reveal.**

## What a team does with it

A refused read of a key's configuration by support's token is not an incident — it is Ana testing
a policy. The same line at three in the morning, from an address that is not support's, is the
first line of one. The questions are lesson 1's, one level up:

- **decryptions outside the hours the job runs**, or by a token that never decrypted before;
- **a jump in volume** — support decrypts a few CPFs an hour; ten thousand in a minute is an
  export nobody approved;
- **refusals**, which are either a misconfiguration somebody should fix or a probe somebody should
  notice.

**OpenBao refuses to answer a request when it cannot write it to any enabled audit device.** If the
disk holding the log fills up, encryption and decryption stop. That is a choice in favour of the
record over availability, and it is the right one for a key service: a decryption nobody can
account for is worse than a delay.
