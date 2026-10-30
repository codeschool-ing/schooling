---
title: The account key opens everything
version: 1
---

**A storage account has two keys, and either one can do anything to anything in the account.**
Read every blob, delete every container, change the settings of the blob service, and sign access
for somebody else. People picture the key as a password for one user. It is closer to the master key
of a building: nothing records whose hand held it, and the only way to take it back from everybody
who has a copy is to change the lock, which locks out every honest holder at the same moment.

Every request in lessons 1 to 5 was signed with it. `UseDevelopmentStorage=true` is shorthand that
the libraries expand to Azurite's account name and its key, and the key is published by Microsoft
because it protects nothing but a laptop. This lesson writes it out, with the addresses it will use,
so that every piece of a request is visible. First the file it reads:

```sh
mkdir -p export
printf 'order_id,customer_id,total_cents\n29-1,c-17,4590\n29-2,c-03,12800\n' > export/orders-2026-10-29.csv
```

Then four variables, typed in the terminal you use for this lesson:

```sh
export KEY='Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw=='
export ACCOUNT=http://127.0.0.1:10000/devstoreaccount1
export CONTAINER=$ACCOUNT/orders-raw
export BLOB=$CONTAINER/exports/2026/10/orders-2026-10-29.csv
```

## Signed with the key

```
ana@laptop:~/azure$ az storage container create -n orders-raw -o none && az storage blob upload -c orders-raw -n exports/2026/10/orders-2026-10-29.csv -f export/orders-2026-10-29.csv --no-progress -o none
ana@laptop:~/azure$ env -u AZURE_STORAGE_CONNECTION_STRING az storage container list --account-name devstoreaccount1 --account-key "$KEY" --blob-endpoint "$ACCOUNT" --query "[].name" -o tsv
orders-raw
ana@laptop:~/azure$ env -u AZURE_STORAGE_CONNECTION_STRING az storage container list --account-name devstoreaccount1 --account-key "${KEY/E/F}" --blob-endpoint "$ACCOUNT" --query "[].name" -o tsv 2>&1
ERROR: 
The request may be blocked by network rules of storage account. Please check network rule set using 'az storage account show -n accountname --query networkRuleSet'.
If you want to change the default action to apply when no rule matches, please use 'az storage account update'.
                    
ana@laptop:~/azure$ az storage account keys list -n stquitandadataprd 2>&1 | tail -1
ERROR: Please run 'az login' to setup account.
```

**The second command left the connection string out and gave the account name and the key
instead**, which is what the connection string had been doing all along: the command line signs each
request with an HMAC of its contents, computed with the key, and Azurite recomputes it and compares.
The third changed one character of the key, and Azurite refused the request because the signature did
not match. The command line's message does not say so: its error line is empty, and it suggests checking the
account's network rules, which have nothing to do with it here. **The cause is the signature.** The key itself never travels; only the signature does.

The last command asks for the keys of an account on Azure. It is a control-plane request, so it
stops at the login as every such command has in this course. On Azure, **whoever can list the keys
has the keys**: the permission to do so comes with roles such as Contributor on the account, and that
is how a key ends up in a script, a configuration file or a pipeline variable, which is where leaked
keys are found.

## Two keys, for rotation

An account has `key1` and `key2` so that one can be changed while the other keeps working.
Microsoft's documented procedure is to move every client to the second key, regenerate the first,
move the clients back, and regenerate the second. A regenerated key invalidates every signature made
with the old one, including every shared access signature of the next section that it signed: that
is the one thing rotation does instantly, and it is why rotation is the emergency answer to a leaked
key and the blunt answer to a leaked signature.

**A key that never leaves the account cannot leak.** Azure has two ways to get there, and both are
in the last section of this lesson: signing in with Microsoft Entra ID instead of a key, and
switching shared key access off for the account altogether.
