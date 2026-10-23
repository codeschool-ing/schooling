---
title: Duas trancas no mesmo objeto
version: 1
---

**Com uma chave gerenciada pelo cliente, ler um objeto exige duas permissões: `s3:GetObject` no
bucket e `kms:Decrypt` na chave.** Elas são escritas em lugares diferentes, normalmente por pessoas
diferentes, e uma requisição a que falte qualquer uma é recusada. É isso que uma chave compra para
quem defende: uma concessão ampla demais no bucket deixa de expor os prontuários sozinha.

A clínica tem exatamente essa concessão ampla demais. A bia lê relatórios, e alguém lhe deu a
`AmazonS3ReadOnlyAccess` da AWS, que permite ler **todo** bucket da conta, o `clinic-records`
incluído. Reescrever a política dela é a correção certa, e a aula 6 trata disso. Esta seção mostra a
segunda tranca segurando enquanto a primeira está errada.

## Verificação ligada

Isto precisa que o moto julgue requisições, então inicie-o como a aula 6 fez. No primeiro terminal:

```sh
INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567
```

No segundo, as mesmas três requisições criam o `admin`, e a quarta prova que a verificação está
ligada:

```
ana@laptop:~/aws$ aws iam create-user --user-name admin --query User.Arn --output text
arn:aws:iam::123456789012:user/admin
ana@laptop:~/aws$ aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ key=$(aws iam create-access-key --user-name admin)
ana@laptop:~/aws$ aws iam list-users

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the ListUsers operation: The security token included in the request is invalid.
ana@laptop:~/aws$ export AWS_ACCESS_KEY_ID=$(echo "$key" | jq -r .AccessKey.AccessKeyId) AWS_SECRET_ACCESS_KEY=$(echo "$key" | jq -r .AccessKey.SecretAccessKey)
ana@laptop:~/aws$ aws sts get-caller-identity --query Arn --output text
arn:aws:iam::123456789012:user/admin
```

E o `with_key` da aula 6, que roda um comando com a chave de outro usuário:

```sh
with_key() {
  local k=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$k" | jq -r .AccessKey.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$k" | jq -r .AccessKey.SecretAccessKey) "$@"
}
```

## O bucket cifra com a chave da clínica por padrão

Uma configuração de **criptografia padrão** no bucket faz o S3 cifrar todo objeto novo com a chave que
ela nomeia, peça o que pedir quem envia. O `BucketKeyEnabled` é a parte que mantém a conta baixa, e a
próxima seção diz por quê. O prontuário enviado é o `record.txt`, da primeira seção desta aula.

```
ana@laptop:~/aws$ k=$(aws kms create-key --description "clinic records" --query KeyMetadata.KeyId --output text)
ana@laptop:~/aws$ aws kms create-alias --alias-name alias/clinic-records --target-key-id "$k"
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-records --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-records
ana@laptop:~/aws$ aws s3api put-bucket-encryption --bucket clinic-records --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms","KMSMasterKeyID":"alias/clinic-records"},"BucketKeyEnabled":true}]}'
ana@laptop:~/aws$ aws s3api put-object --bucket clinic-records --key maria-souza.txt --body record.txt --query "[ServerSideEncryption,SSEKMSKeyId]" --output text
aws:kms	alias/clinic-records
```

O prontuário entrou como `aws:kms`, sob `alias/clinic-records`, sem que o envio mencionasse nenhum
dos dois. **Configurar o padrão no bucket é o que faz da criptografia uma propriedade do lugar, e não
um hábito de cada pessoa que grava nele.**

## A bia, com uma tranca aberta

A bia ganha o seu usuário, uma chave e a política ampla demais do S3:

```
ana@laptop:~/aws$ aws iam create-user --user-name bia --query User.Arn --output text
arn:aws:iam::123456789012:user/bia
ana@laptop:~/aws$ aws iam attach-user-policy --user-name bia --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
ana@laptop:~/aws$ bia=$(aws iam create-access-key --user-name bia)
```

Ela consegue usar a chave? Cifre uma cópia do prontuário com ela, como admin, e peça ao KMS que a
decifre com a chave da bia:

```
ana@laptop:~/aws$ aws kms encrypt --key-id alias/clinic-records --plaintext fileb://record.txt --query CiphertextBlob --output text | base64 -d > record.enc
ana@laptop:~/aws$ with_key "$bia" aws kms decrypt --ciphertext-blob fileb://record.enc --query Plaintext --output text

aws: [ERROR]: An error occurred (403) when calling the Decrypt operation: <?xml version="1.0" encoding="utf-8"?>
<ErrorResponse><Errors><Error><Code>AccessDenied</Code><Message>User: arn:aws:iam::123456789012:user/bia is not authorized to perform: kms:Decrypt</Message><Type>Sender</Type></Error></Errors></ErrorResponse>
```

**Recusado, e pelo motivo certo**: nada dá `kms:Decrypt` à bia. O moto julgou isto exatamente como a
AWS julgaria. Agora o mesmo prontuário pelo S3:

```
ana@laptop:~/aws$ with_key "$bia" aws s3 cp s3://clinic-records/maria-souza.txt -
patient: Maria Souza
allergy: penicillin
```

**Aqui o moto e a AWS se separam.** O moto serviu o prontuário, porque quando o S3 lê um objeto
cifrado com uma chave do KMS o moto não verifica a permissão de quem lê sobre a chave. A AWS
verifica: o S3 pede ao KMS que decifre em nome da bia, o KMS recusa, e a bia recebe `AccessDenied`.
**Essa recusa vem da documentação do S3 e do KMS e não foi executada aqui.** O pedido de decifração
logo acima é a parte dela que o moto julga, e ele disse não.

A AWS vai um passo além para requisições anônimas. Um objeto cifrado com uma chave do KMS só pode ser
lido por uma requisição assinada com a Signature Version 4 da AWS, então a política pública de bucket
da primeira seção não o teria exposto: uma requisição anônima não tem identidade para o KMS
autorizar. O moto a serve mesmo assim, então isso também vem da documentação.

## O que levar disto

A clínica ainda precisa corrigir a política da bia; uma segunda tranca não é motivo para deixar a
primeira quebrada. Mas compare as duas falhas: **com a chave do próprio S3, uma política errada expôs
os prontuários; com a chave da clínica, foram precisas duas**, escritas em dois lugares, e a segunda
é uma política de chave em que pouquíssimas pessoas mexem. Defesa em profundidade, do curso
`security-fundamentals`, é essa frase.
