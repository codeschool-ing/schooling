---
title: Cifrando um valor pequeno, e o contexto que o amarra
version: 1
---

Uma chave gerenciada pelo cliente e um alias para ela, em `~/aws/kms` (`mkdir -p ~/aws/kms && cd ~/aws/kms`):

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

O alias é o nome que o código usa. Ele pode ser apontado para uma chave nova depois sem nenhum programa
mudar, e é por isso que o id de uma chave nunca vai para o código. A chave é `SYMMETRIC_DEFAULT`, uma chave
AES de 256 bits, criada pelo KMS e gerenciada pelo cliente; a AWS diria `ENCRYPT_DECRYPT` onde o moto deixa
o uso vazio. A política dela é a padrão, a instrução única da seção anterior: o principal root da conta,
`kms:*`, que é como as políticas IAM ganham voz.

## Cifrar e decifrar

O KMS cifra até 4 KB diretamente. Uma nota curta serve:

```
ana@laptop:~/aws/kms$ printf 'card ending 4242' > note.txt
ana@laptop:~/aws/kms$ aws kms encrypt --key-id alias/shop-orders --plaintext fileb://note.txt --encryption-context order=1001 --query CiphertextBlob --output text | base64 -d > note.enc
ana@laptop:~/aws/kms$ wc -c note.txt note.enc
16 note.txt
80 note.enc
96 total
```

Dezesseis bytes de texto viraram 80 de texto cifrado aqui, mais na AWS, e o tamanho não é algo de que
depender. O que importa é que o texto cifrado carrega mais que o texto: ele nomeia a chave com que foi
feito. **Decifrar não precisa do id da chave**:

```
ana@laptop:~/aws/kms$ aws kms decrypt --ciphertext-blob fileb://note.enc --encryption-context order=1001 --query KeyId --output text
arn:aws:kms:sa-east-1:123456789012:key/e646e99c-ee02-4891-b5c7-9ac684b09fad
ana@laptop:~/aws/kms$ aws kms decrypt --ciphertext-blob fileb://note.enc --encryption-context order=1001 --query Plaintext --output text | base64 -d; echo
card ending 4242
```

O KMS leu a chave do texto cifrado e respondeu com o ARN dela e o texto. É por isso que um programa que
decifra dados precisa de permissão na chave, mas não de configuração sobre ela.

## O contexto de criptografia

O comando de cifrar acrescentou `--encryption-context order=1001`: um conjunto de nomes e valores que
**não é secreto, não fica guardado no texto cifrado, e é obrigatório para decifrar**. Sem ele, ou com
outro, o KMS recusa:

```
ana@laptop:~/aws/kms$ aws kms decrypt --ciphertext-blob fileb://note.enc --query KeyId --output text

aws: [ERROR]: An error occurred (InvalidCiphertextException) when calling the Decrypt operation:
ana@laptop:~/aws/kms$ aws kms decrypt --ciphertext-blob fileb://note.enc --encryption-context order=1002 --query KeyId --output text

aws: [ERROR]: An error occurred (InvalidCiphertextException) when calling the Decrypt operation:
```

**Esse é o comportamento real da AWS, e o moto o acerta.** O contexto amarra um texto cifrado àquilo de
que ele trata. Um texto cifrado copiado da linha do pedido 1001 para a do pedido 1002 decifraria
perfeitamente sem contexto; com um, falha, e o erro ou a adulteração é encontrado. O contexto também
aparece no CloudTrail ao lado de cada decrypt, então o log de auditoria diz qual pedido foi lido, e não só
qual chave foi usada.

## O limite

```
ana@laptop:~/aws/kms$ head -c 5000 /dev/zero > five-kb.bin
ana@laptop:~/aws/kms$ aws kms encrypt --key-id alias/shop-orders --plaintext fileb://five-kb.bin 2>&1 | tail -1
aws: [ERROR]: An error occurred (ValidationException) when calling the Encrypt operation: 1 validation error detected: Value at 'plaintext' failed to satisfy constraint: Member must have length less than or equal to 4096
```

4.096 bytes é o máximo que o `Encrypt` aceita, na AWS como no moto. Qualquer coisa maior, um arquivo, um
backup, uma coluna de um milhão de linhas, nem vai ao KMS. É cifrada localmente com uma chave que o KMS
entrega, e essa é a próxima seção.
