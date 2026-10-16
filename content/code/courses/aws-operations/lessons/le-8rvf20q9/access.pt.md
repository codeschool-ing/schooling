---
title: Quem pode ler, e o que o moto confere
version: 1
---

Um segredo só é tão privado quanto as políticas que chegam até ele. A API da loja deve ler o segredo do
seu banco e nada mais: nem a chave do provedor de pagamento, nem os parâmetros de staging, e não gravar
nada. Esta é a lição sobre uma recusa, então o laboratório precisa de um moto que recuse.

## Um moto que confere

Por padrão o moto deixa todo mundo fazer tudo. Pare-o no terminal dele com Ctrl+C e inicie de novo com
**`INITIAL_NO_AUTH_ACTION_COUNT`**: o número de requisições que ele deixa passar sem checar antes de
começar a avaliar políticas. Nove é o número de que a preparação desta seção precisa, e toda requisição
conta, inclusive uma digitada errado:

```sh
INITIAL_NO_AUTH_ACTION_COUNT=9 ~/aws/venv/bin/moto_server -p 4567
```

O moto novo começa vazio. Duas políticas, uma para a aplicação, nomeando o segredo dela com o curinga dos
seis caracteres, e outra que nomeia todo segredo:

`app-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:sa-east-1:123456789012:secret:shop/prod/db-*"
    }
  ]
}
```

`wide-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "*"
    }
  ]
}
```

Depois, a preparação, sete requisições: dois segredos, um parâmetro, e dois usuários com uma política
cada:

```sh
cd ~/aws/secrets
aws secretsmanager create-secret --name shop/prod/db --secret-string '{"username":"shop","password":"first-pass"}' --query Name
aws secretsmanager create-secret --name shop/prod/payments --secret-string '{"provider":"lab"}' --query Name
aws ssm put-parameter --name /shop/prod/db/host --type String --value db.internal --query Version
aws iam create-user --user-name shop-app --query User.Arn
aws iam put-user-policy --user-name shop-app --policy-name read-db-secret --policy-document file://app-policy.json
aws iam create-user --user-name shop-wide --query User.Arn
aws iam put-user-policy --user-name shop-wide --policy-name read-any-secret --policy-document file://wide-policy.json
```

A oitava e a nona criam uma chave de acesso para cada usuário. **Elas são lidas para variáveis e nunca
impressas**: uma chave de acesso não pertence ao histórico de nenhum terminal, nem o de um laboratório.

```
ana@laptop:~/aws/secrets$ read -r KEY SECRET < <(aws iam create-access-key --user-name shop-app --query "AccessKey.[AccessKeyId,SecretAccessKey]" --output text)
ana@laptop:~/aws/secrets$ read -r WKEY WSECRET < <(aws iam create-access-key --user-name shop-wide --query "AccessKey.[AccessKeyId,SecretAccessKey]" --output text)
```

## O usuário da aplicação

```
ana@laptop:~/aws/secrets$ AWS_ACCESS_KEY_ID=$KEY AWS_SECRET_ACCESS_KEY=$SECRET aws sts get-caller-identity --query Arn
"arn:aws:iam::123456789012:user/shop-app"
ana@laptop:~/aws/secrets$ AWS_ACCESS_KEY_ID=$KEY AWS_SECRET_ACCESS_KEY=$SECRET aws ssm get-parameter --name /shop/prod/db/host 2>&1 | grep -o "User: [^<]*"
User: arn:aws:iam::123456789012:user/shop-app is not authorized to perform: ssm:GetParameter
ana@laptop:~/aws/secrets$ AWS_ACCESS_KEY_ID=$KEY AWS_SECRET_ACCESS_KEY=$SECRET aws secretsmanager get-secret-value --secret-id shop/prod/db 2>&1 | grep -o "User: [^<]*"
User: arn:aws:iam::123456789012:user/shop-app is not authorized to perform: secretsmanager:GetSecretValue
```

A identidade é `shop-app`. Ler um parâmetro é recusado, corretamente: a política dele não concede nenhuma
ação `ssm`. **Ler o próprio segredo também é recusado, e na AWS não seria.** Este é o limite que a lição 1
apontou: **o moto confere a ação e não o recurso**. Ele trata toda requisição como dirigida a `*`, então
uma instrução que permite o ARN de um segredo nunca casa, e a política estreita, a certa, não permite nada
aqui.

## O usuário com a política ampla

```
ana@laptop:~/aws/secrets$ AWS_ACCESS_KEY_ID=$WKEY AWS_SECRET_ACCESS_KEY=$WSECRET aws secretsmanager get-secret-value --secret-id shop/prod/db --query Name
"shop/prod/db"
ana@laptop:~/aws/secrets$ AWS_ACCESS_KEY_ID=$WKEY AWS_SECRET_ACCESS_KEY=$WSECRET aws secretsmanager get-secret-value --secret-id shop/prod/payments --query Name
"shop/prod/payments"
ana@laptop:~/aws/secrets$ AWS_ACCESS_KEY_ID=$WKEY AWS_SECRET_ACCESS_KEY=$WSECRET aws secretsmanager put-secret-value --secret-id shop/prod/db --secret-string x 2>&1 | grep -o "User: [^<]*"
User: arn:aws:iam::123456789012:user/shop-wide is not authorized to perform: secretsmanager:PutSecretValue
```

Com `"Resource": "*"`, o moto permite ler os dois segredos, e a AWS também permitiria: **é isso que a
política ampla diz**, e a chave do provedor de pagamento agora pode ser lida por qualquer coisa que tenha
a chave deste usuário. A gravação é recusada, no moto e na AWS, porque nenhuma instrução permite
`PutSecretValue`.

Então o laboratório mostra metade da regra, e a documentação da AWS a outra:

| requisição | moto | AWS |
|---|---|---|
| `shop-app` lê `shop/prod/db` | recusada | **permitida** |
| `shop-app` lê `shop/prod/payments` | recusada | recusada |
| `shop-app` lê um parâmetro | recusada | recusada |
| `shop-wide` lê qualquer dos dois segredos | permitida | permitida |
| `shop-wide` grava um segredo | recusada | recusada |

Na AWS, `app-policy.json` é a política a entregar. Um segredo também pode ter uma **política de recurso**,
nomeando as roles que podem lê-lo, o que deixa a decisão junto do segredo; o moto guarda políticas de
recurso e não avalia nenhuma.

## Depois

A chave de teste não é um usuário neste moto, e a contagem acabou:

```
ana@laptop:~/aws/secrets$ aws secretsmanager list-secrets 2>&1 | grep -o "<Message>[^<]*"
<Message>The security token included in the request is invalid.
```

Essas são as palavras que a lição 1 disse indicarem que uma requisição chegou à AWS. Aqui elas vêm do
moto, que agora confere chaves e nunca ouviu falar de `test`. Pare este moto com Ctrl+C e inicie de novo
sem a variável antes da próxima lição.
