---
title: Encrypting a small value, and the context that binds it
version: 1
---

A customer managed key and an alias for it, in `~/aws/kms` (`mkdir -p ~/aws/kms && cd ~/aws/kms`):

```
ana@laptop:~/aws/kms$ KEY=$(aws kms create-key --description "shop orders" --query KeyMetadata.KeyId --output text); echo $KEY
e646e99c-ee02-4891-b5c7-9ac684b09fad
ana@laptop:~/aws/kms$ aws kms create-alias --alias-name alias/shop-orders --target-key-id $KEY
ana@laptop:~/aws/kms$ aws kms describe-key --key-id alias/shop-orders --query 'KeyMetadata.[KeyManager,KeySpec,KeyUsage,KeyState]' --output text
CUSTOMER	SYMMETRIC_DEFAULT	None	Enabled
ana@laptop:~/aws/kms$ aws kms get-key-policy --key-id $KEY --policy-name default --query Policy --output text | jq .Statement
[
  {
    "Sid": "Enable IAM User Permissions",
    "Effect": "Allow",
    "Principal": {
      "AWS": "arn:aws:iam::123456789012:root"
    },
    "Action": "kms:*",
    "Resource": "*"
  }
]
```

The alias is the name the code uses. It can be pointed at a new key later without any program changing,
which is the reason never to write a key's id into code. The key is `SYMMETRIC_DEFAULT`, a 256-bit AES
key, made by KMS and managed by the customer; AWS would say `ENCRYPT_DECRYPT` where moto leaves the
usage empty. Its policy is the default one, the
single statement of the previous section: the account's root principal, `kms:*`, which is how IAM
policies get their say.

## Encrypt and decrypt

KMS encrypts up to 4 KB directly. A short note will do:

```
ana@laptop:~/aws/kms$ printf 'card ending 4242' > note.txt
ana@laptop:~/aws/kms$ aws kms encrypt --key-id alias/shop-orders --plaintext fileb://note.txt --encryption-context order=1001 --query CiphertextBlob --output text | base64 -d > note.enc
ana@laptop:~/aws/kms$ wc -c note.txt note.enc
16 note.txt
80 note.enc
96 total
```

Sixteen bytes of text became 80 of ciphertext here, more on AWS, and the size is nothing to depend on.
What matters is that the ciphertext carries more than the text: it names the key it was made with. **Decrypting does not need the key's id**:

```
ana@laptop:~/aws/kms$ aws kms decrypt --ciphertext-blob fileb://note.enc --encryption-context order=1001 --query KeyId --output text
arn:aws:kms:sa-east-1:123456789012:key/e646e99c-ee02-4891-b5c7-9ac684b09fad
ana@laptop:~/aws/kms$ aws kms decrypt --ciphertext-blob fileb://note.enc --encryption-context order=1001 --query Plaintext --output text | base64 -d; echo
card ending 4242
```

KMS read the key from the ciphertext and answered with its ARN and the text. That is why a program
decrypting data needs permission on the key but not configuration about it.

## The encryption context

The encrypt command added `--encryption-context order=1001`: a set of names and values that is **not
secret, not stored inside the ciphertext, and required to decrypt**. Without it, or with a different
one, KMS refuses:

```
ana@laptop:~/aws/kms$ aws kms decrypt --ciphertext-blob fileb://note.enc --query KeyId --output text

aws: [ERROR]: An error occurred (InvalidCiphertextException) when calling the Decrypt operation:
ana@laptop:~/aws/kms$ aws kms decrypt --ciphertext-blob fileb://note.enc --encryption-context order=1002 --query KeyId --output text

aws: [ERROR]: An error occurred (InvalidCiphertextException) when calling the Decrypt operation:
```

**This is real AWS behaviour, and moto has it right.** The context binds a ciphertext to what it is
about. A ciphertext copied from order 1001's row into order 1002's would decrypt perfectly without a
context; with one, it fails, and the mistake or the tampering is found. The context also appears in
CloudTrail beside every decrypt, so the audit log says which order was read, not only which key was
used.

## The limit

```
ana@laptop:~/aws/kms$ head -c 5000 /dev/zero > five-kb.bin
ana@laptop:~/aws/kms$ aws kms encrypt --key-id alias/shop-orders --plaintext fileb://five-kb.bin 2>&1 | tail -1
aws: [ERROR]: An error occurred (ValidationException) when calling the Encrypt operation: 1 validation error detected: Value at 'plaintext' failed to satisfy constraint: Member must have length less than or equal to 4096
```

4,096 bytes is the most `Encrypt` takes, on AWS as in moto. Anything larger, a file, a backup, a column
of a million rows, is not sent to KMS at all. It is encrypted locally with a key KMS hands out, and that
is the next section.
