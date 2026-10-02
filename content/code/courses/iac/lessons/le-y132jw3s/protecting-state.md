---
title: Encrypting the state before it leaves the laptop
version: 1
---

The last three sections keep secrets out of the state where a provider allows it. Something always
gets in anyway: a resource with no write-only argument, a data source that reads a secret, a key a
provider generates and returns. For that remainder, the state's own protection is the last line,
and lesson 7's "protecting" section built most of it: a bucket nobody outside the team can read,
blocked public access, versioning, and `encrypt = true`.

That last setting is worth a precise look, because it sounds like more than it is. `encrypt = true`
asks S3 to encrypt the object **on S3's disks**. Anybody the bucket lets read the object gets it
decrypted, in plain text, because decrypting it for authorised readers is what S3 does. A KMS key
of your own (`kms_key_id` in the backend) adds a second permission a reader needs, which helps. A reader with both still gets plain text, and so does every copy that leaves the bucket, such as a
`terraform state pull` on somebody's laptop.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A grid of two rows and three columns. The columns are three places a state passes through: the memory of the program running the plan, what somebody the bucket lets read receives, and S3's own disks. With S3's encryption alone, the state is plain text in the first two and encrypted only on the disks. With OpenTofu's state encryption, it is plain text only in the program's memory and encrypted in the other two.\"><text x=\"310.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">in the program's memory</text><text x=\"460.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">to a reader of the bucket</text><text x=\"610.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">on S3's disks</text><text x=\"20.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">S3 encryption</text><text x=\"20.0\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">encrypt = true</text><rect x=\"245\" y=\"60\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">plain text</text><rect x=\"395\" y=\"60\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">plain text</text><rect x=\"545\" y=\"60\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">encrypted</text><text x=\"20.0\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">OpenTofu encryption</text><text x=\"20.0\" y=\"192.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">encryption { }</text><rect x=\"245\" y=\"150\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">plain text</text><rect x=\"395\" y=\"150\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">encrypted</text><rect x=\"545\" y=\"150\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">encrypted</text><text x=\"460.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the second row moves the line one column to the left</text></svg>", "caption": "Where a state is plain text. S3's encryption protects the disks; OpenTofu's protects everything after the program."}
```

**Terraform has no way to encrypt the state before it writes it.** OpenTofu, the fork lesson 1
introduced, does: the state is encrypted inside the program, and the backend, local or S3, only
ever stores ciphertext. This is the feature lesson 1 promised, and the lab has `tofu` to show it.

## Turning it on

A small configuration with one generated password, run with `tofu`. The provider is named by its
full address because the lab's offline mirror files providers under Terraform's registry, while
OpenTofu defaults to its own; lesson 17 says more about the two registries.

```hcl
terraform {
  required_providers {
    random = {
      source  = "registry.terraform.io/hashicorp/random"
      version = "~> 3.7"
    }
  }
}

resource "random_password" "db" {
  length = 20
}
```

```
ana@laptop:~/shop/tofu$ tofu apply -auto-approve -no-color | grep -E "^Apply"
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
ana@laptop:~/shop/tofu$ jq -r ".resources[0].instances[0].attributes.result" terraform.tfstate
<<k9VdD%LM0mWVF(m3&?
```

A plain state, password readable, the starting point of every existing configuration. Ana adds the
encryption in a file of its own:

```hcl
variable "state_passphrase" {
  type      = string
  sensitive = true
}

terraform {
  encryption {
    key_provider "pbkdf2" "passphrase" {
      passphrase = var.state_passphrase
    }

    method "aes_gcm" "state" {
      keys = key_provider.pbkdf2.passphrase
    }

    method "unencrypted" "migrate" {}

    state {
      method = method.aes_gcm.state

      fallback {
        method = method.unencrypted.migrate
      }
    }
  }
}
```

Four pieces. The **key provider** `pbkdf2` derives a key from a passphrase, and needs nothing else.
The **method** `aes_gcm` encrypts with that key. The `state` block says the state is written with
that method. And the **fallback** lets this one run read the state that is still plain: without
it, OpenTofu would try to decrypt a file that was never encrypted, and stop.

The passphrase is a variable on purpose. Written into the file, it would be one more secret in git;
here it was exported in the shell beforehand as `TF_VAR_state_passphrase`, which is how a pipeline
would hand it over from its own secret store. Then the apply, and the file it wrote:

```
ana@laptop:~/shop/tofu$ tofu apply -auto-approve -no-color | grep -E "^Apply"
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

```
ana@laptop:~/shop/tofu$ jq "keys" terraform.tfstate
[
  "encrypted_data",
  "encryption_version",
  "lineage",
  "meta",
  "serial"
]
ana@laptop:~/shop/tofu$ jq -r ".encrypted_data" terraform.tfstate | cut -c 1-64
qbFmTxtO+mzpi0/71keIGUxl5WFBLvhCeUr2osANv3cJMCXNu5XTC3TClvm5ZD0B
ana@laptop:~/shop/tofu$ grep -c "\"result\"" terraform.tfstate
0
ana@laptop:~/shop/tofu$ jq -r ".meta[]" terraform.tfstate | base64 -d; echo
{"salt":"MjbK6Nj6UlGm+3KPiShY2cJK8CvC1R9fXxFjBKjxV3I=","iterations":600000,"hash_function":"sha512","key_length":32}
```

The state is now a short envelope: a serial and a lineage, left in the clear, and `encrypted_data`,
which is the state itself. The word `result` appears nowhere in the file. The `meta` entry holds
what is needed to derive the key again from the passphrase (a random salt, the iteration count, the
hash) and not the key. OpenTofu reads it back as before:

```
ana@laptop:~/shop/tofu$ tofu state list
random_password.db
ana@laptop:~/shop/tofu$ tofu plan | tail -n 3

No changes. Your infrastructure matches the configuration.
```

## After the migration

The fallback has done its job, and left in place it would also accept a plain state that somebody
put back in the bucket. Ana removes it and the `unencrypted` method with it, so that the `state`
block is just the method, and plans once more:

```
ana@laptop:~/shop/tofu$ sed -n "/state {/,/^    }/p" encryption.tf
    state {
      method = method.aes_gcm.state
    }
ana@laptop:~/shop/tofu$ tofu plan | tail -n 3

No changes. Your infrastructure matches the configuration.
```

Now the two failures that matter. The wrong passphrase:

```
ana@laptop:~/shop/tofu$ TF_VAR_state_passphrase='a-different-passphrase-entirely' tofu plan
Acquiring state lock. This may take a few moments...
╷
│ Error: Error acquiring the state lock
│ 
│ Error message: failed to write backup file: decryption failed for all
│ provided methods
│ attempted decryption failed for state: decryption failed: cipher: message
│ authentication failed
│ 
│ OpenTofu acquires a state lock to protect the state from being written
│ by multiple users at the same time. Please resolve the issue above and try
│ again. For most commands, you can disable locking with the "-lock=false"
│ flag, but this is not recommended.
╵
```

The message arrives wrapped in a locking error, because the first thing the local backend does is
back the state up, and it cannot read what it should copy. The line that matters is `message
authentication failed`: AES-GCM does not decrypt to garbage, it refuses. And Terraform, asked to
work in the same directory and then to read a copy of the same file:

```
ana@laptop:~/shop/tofu$ terraform init
Initializing the backend...

╷
│ Error: Terraform encountered problems during initialisation, including problems
│ with the configuration, described below.
│ 
│ The Terraform configuration must be valid before initialization so that
│ Terraform can determine which modules and providers need to be installed.
│ 
│ 
╵
╷
│ Error: Unsupported block type
│ 
│   on encryption.tf line 7, in terraform:
│    7:   encryption {
│ 
│ Blocks of type "encryption" are not expected here.
╵
╷
│ Error: Unsupported block type
│ 
│   on encryption.tf line 7, in terraform:
│    7:   encryption {
│ 
│ Blocks of type "encryption" are not expected here.
╵
ana@laptop:~/shop/tofu-copy$ cp ../tofu/terraform.tfstate . && terraform state list
Failed to load state: Unsupported state file format: The state file does not have a "version" attribute, which is required to identify the format version.
```

Terraform does not know the `encryption` block, and reads the encrypted file as a state with no
version. Two consequences follow. **This configuration now belongs to OpenTofu**, and going back to
Terraform means decrypting the state with `tofu` first. And **the passphrase is now the most
important secret this configuration has.** Lose it and the state is gone, every version written
since the migration included, because each one was encrypted with it. A team running this in
earnest uses a key provider backed by a key service, such as `aws_kms`, so that the key is a
permission IAM grants rather than a string somebody has to keep.

Two loose ends. The versions the bucket kept from before the migration are still there and still plain text, so delete them, and rotate any secret they held. And the same `encryption`
block takes a `plan` block beside `state`, which encrypts the saved plan file, copy three from
"where-they-leak".
