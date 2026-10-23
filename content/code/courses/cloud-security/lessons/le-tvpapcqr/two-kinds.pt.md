---
title: Dois tipos de credencial, e o que não expira
version: 1
---

**A AWS assina requisições com dois tipos de credencial. A chave de acesso de um usuário funciona até
alguém apagá-la. A sessão de um papel funciona por um tempo definido e depois para sozinha. Quase tudo
nesta aula decorre dessa diferença.** O primeiro tipo é o que vaza, é copiado para arquivos e
sobrevive à pessoa que o criou, então a chave mais segura é a que nunca precisou existir.

A imagem errada é a de que chave e senha são a mesma coisa com nomes diferentes. Uma senha pertence a
uma pessoa que a digita, atrás de uma página de entrada que pode pedir um segundo fator. Uma chave de
acesso é um par de textos que assina requisições de API diretamente: sem página de entrada, sem
segundo fator, e sem nada do lado da AWS que saiba se o programa que a tem é aquele a quem ela foi
dada.

## Os dois tipos, no laboratório

Inicie o moto no primeiro terminal com a verificação ligada, e gaste as três requisições livres no
`admin` exatamente como a aula 6 fez; a transcrição abaixo as repete. Depois digite duas funções no
segundo terminal. `with_key` roda um comando com a chave de um usuário, como na aula 6, e
`with_session` faz o mesmo com uma sessão de papel, que leva um terceiro valor, o token de sessão:

```sh
with_key() {
  local k=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$k" | jq -r .AccessKey.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$k" | jq -r .AccessKey.SecretAccessKey) "$@"
}
with_session() {
  local c=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$c" | jq -r .Credentials.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$c" | jq -r .Credentials.SecretAccessKey) \
  AWS_SESSION_TOKEN=$(echo "$c" | jq -r .Credentials.SessionToken) "$@"
}
```

```
ana@laptop:~/aws$ aws iam create-user --user-name admin --query User.Arn --output text
arn:aws:iam::123456789012:user/admin
ana@laptop:~/aws$ aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ key=$(aws iam create-access-key --user-name admin)
ana@laptop:~/aws$ aws iam list-users

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the ListUsers operation: The security token included in the request is invalid.
ana@laptop:~/aws$ export AWS_ACCESS_KEY_ID=$(echo "$key" | jq -r .AccessKey.AccessKeyId) AWS_SECRET_ACCESS_KEY=$(echo "$key" | jq -r .AccessKey.SecretAccessKey)
```

O caio ganha um usuário e uma chave, do jeito que o sistema de agendamento foi montado no começo:

```
ana@laptop:~/aws$ aws iam create-user --user-name caio --query User.Arn --output text
arn:aws:iam::123456789012:user/caio
ana@laptop:~/aws$ aws iam attach-user-policy --user-name caio --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
ana@laptop:~/aws$ caio=$(aws iam create-access-key --user-name caio)
ana@laptop:~/aws$ echo "$caio" | jq ".AccessKey | {AccessKeyId, Status, CreateDate}"
{
  "AccessKeyId": "AKIARZPUZDIKKKVVGHFV",
  "Status": "Active",
  "CreateDate": "2026-10-23T04:07:08.317255+00:00"
}
```

**Nenhuma expiração em lugar nenhum dessa resposta.** A chave fica `Active` da data de criação até
alguém agir. O id dela começa com `AKIA`, que é como a AWS marca uma chave de usuário de longa
duração.

Agora o outro tipo. Um papel chamado `booking-app` faz as vezes da máquina em que a aplicação roda; na
AWS a política de confiança nomearia o serviço, como o EC2 ou o Lambda, e aqui ela nomeia o `admin`,
para que você o assuma deste terminal. Salve a política de confiança como `trust-admin.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS": "arn:aws:iam::123456789012:user/admin"},
      "Action": "sts:AssumeRole"
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam create-role --role-name booking-app --assume-role-policy-document file://trust-admin.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/booking-app
ana@laptop:~/aws$ session=$(aws sts assume-role --role-arn arn:aws:iam::123456789012:role/booking-app --role-session-name booking --duration-seconds 900)
ana@laptop:~/aws$ echo "$session" | jq ".Credentials | {AccessKeyId, Expiration, SessionToken: (.SessionToken[:24] + \"...\")}"
{
  "AccessKeyId": "ASIARZPUZDIKNBP5G5RW",
  "Expiration": "2026-10-23T04:22:09.783539+00:00",
  "SessionToken": "FQoGZXIvYXdzEBYaD17teWIs..."
}
ana@laptop:~/aws$ with_session "$session" aws sts get-caller-identity --query Arn --output text
arn:aws:sts::123456789012:assumed-role/booking-app/booking
```

Três diferenças, todas visíveis:

| | chave de acesso de usuário | sessão de papel |
|---|---|---|
| o id começa com | `AKIA` | `ASIA` |
| partes | um id e um segredo | um id, um segredo e um token de sessão |
| termina | quando alguém a apaga | em `Expiration`, aqui quinze minutos depois de emitida |

O filtro do `jq` cortou o token de sessão para caber na tela. **Ninguém precisa se lembrar de revogar
uma sessão**: em `Expiration` a AWS deixa de aceitá-la. A captura não esperou quinze minutos para ver
isso acontecer, então é o comportamento documentado da AWS, não uma execução.

## Qual tipo usar, e onde

| quem assina | o que deveria ter |
|---|---|
| uma pessoa | uma sessão, vinda da entrada pelo provedor de identidade (aula 6) |
| um programa numa máquina ou função da AWS | a sessão do papel que a plataforma lhe dá, buscada e renovada pelo SDK |
| um programa fora da AWS, como um pipeline | uma sessão obtida por federação, que a aula 4 montou |
| um programa sem caminho para nenhum desses | uma chave de acesso, guardada como as próximas três seções dizem |

A última linha é o único lugar em que uma chave de acesso cabe, e ela é menor do que parece: a
maioria dos programas que têm uma chave a têm porque ninguém montou a linha de cima.
