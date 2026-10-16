---
title: Ligando a verificação do moto
version: 1
---

Até agora o moto disse sim a tudo. **A partir desta seção, o moto julga toda requisição**: um
usuário sem permissão é recusado, como a lição 1 prometeu. As lições 8 e 9 começam do mesmo jeito,
então vale a pena fazer isto com calma uma vez.

## O que ele verifica, e o que não

Com a verificação ligada, o moto recusa uma requisição como a AWS recusaria quando o motivo é um
destes:

- **nenhuma política de quem chama permite a ação**, seja a política inline, gerenciada pelo
  cliente ou gerenciada pela AWS, e tenha ela chegado a quem chama diretamente, por um grupo ou por
  uma role;
- **uma política de quem chama a nega explicitamente**, mesmo que outra a permita;
- **a política de confiança de uma role não nomeia quem chama** e tenta assumi-la;
- **a chave é uma que o IAM do moto nunca emitiu**, como `test`.

Ele não verifica limites de permissões (permission boundaries), service control policies, a
política do próprio bucket, políticas de sessão nem condições dentro de uma instrução. A lição 8
mede cada um desses e ensina o que a AWS faz no lugar.

## A contagem

A chave é uma variável de ambiente lida quando o moto inicia: **`INITIAL_NO_AUTH_ACTION_COUNT=3`
deixa passar as três primeiras requisições sem verificação, e julga toda requisição depois delas.**
As três requisições livres existem porque um juiz precisa de alguém para ser o administrador, e
ainda não há ninguém: elas são gastas criando um. Depois da terceira, toda requisição tem de ser
assinada com uma chave que o próprio IAM do moto emitiu, e as políticas dessa chave decidem.

**Toda requisição conta, inclusive uma que falha.** Um erro de digitação que volta como erro já
gastou uma das três. Requisições ao endereço de controle do próprio moto, `/moto-api/`, não contam,
e a linha de comando nunca envia nenhuma. No primeiro terminal, pare o moto com Ctrl+C e inicie-o
assim:

```sh
INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567
```

No segundo, as três requisições: um usuário chamado `admin`, a política `AdministratorAccess` da
AWS para ele, e uma chave de acesso. A chave fica numa variável do shell, `key`, em vez de ser
impressa ou salva:

```
ana@laptop:~/aws$ aws iam create-user --user-name admin --query User.Arn --output text
arn:aws:iam::123456789012:user/admin
ana@laptop:~/aws$ aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ key=$(aws iam create-access-key --user-name admin)
ana@laptop:~/aws$ aws iam list-users

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the ListUsers operation: The security token included in the request is invalid.
ana@laptop:~/aws$ export AWS_ACCESS_KEY_ID=$(echo "$key" | jq -r .AccessKey.AccessKeyId) AWS_SECRET_ACCESS_KEY=$(echo "$key" | jq -r .AccessKey.SecretAccessKey)
ana@laptop:~/aws$ aws sts get-caller-identity
{
    "UserId": "4mf2zzta72ljh4imk5i5",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/admin"
}
ana@laptop:~/aws$ aws iam list-users --query "Users[].UserName"
[
    "admin"
]
```

O quarto comando foi recusado, e o motivo está nas palavras dele: **a requisição foi assinada com
`test`, e o IAM do moto nunca emitiu uma chave chamada `test`**. É a contagem se esgotando, e isso
prova que a verificação está ligada antes de qualquer outra tentativa.

A linha do `export` passa este terminal para a chave do admin. O `jq -r` tira um campo do JSON que
o `create-access-key` devolveu, e o `export` põe o id e o segredo onde a linha de comando procura
primeiro. **Essas são chaves do moto, inventadas por ele e sem valor em qualquer outro lugar**; não
estão na tela de ninguém nem em arquivo nenhum, e somem quando o moto para. O `get-caller-identity`
confirma: daqui em diante o terminal trabalha como `admin`.

Um terminal novo lê o `env.sh` e começa de novo com `test`, que o moto agora recusa, e a variável
`key` só existe neste shell. **Trabalhe neste único terminal durante a lição inteira.**

## Quando a contagem sai errada

Se uma das três requisições falha, a contagem anda do mesmo jeito. Assim fica um erro de digitação
no nome da política, num moto iniciado com a mesma contagem:

```
ana@laptop:~/aws$ aws iam create-user --user-name admin
{
    "User": {
        "Path": "/",
        "UserName": "admin",
        "UserId": "4mf2zzta72ljh4imk5i5",
        "Arn": "arn:aws:iam::123456789012:user/admin",
        "CreateDate": "2026-10-16T16:23:16.286274+00:00"
    }
}
ana@laptop:~/aws$ aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAcess

aws: [ERROR]: An error occurred (NoSuchEntity) when calling the AttachUserPolicy operation: Policy arn:aws:iam::aws:policy/AdministratorAcess does not exist or is not attachable.
ana@laptop:~/aws$ aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ aws iam create-access-key --user-name admin --query AccessKey.AccessKeyId

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the CreateAccessKey operation: The security token included in the request is invalid.
```

O `AdministratorAcess` mal escrito gastou a segunda requisição, o comando corrigido gastou a
terceira, e **a chave de acesso chegou em quarto e foi recusada**. Não há volta por dentro: pare o
moto, inicie-o de novo com a contagem, e digite as três requisições outra vez.

## Um comando como outra pessoa

As próximas seções dão uma política à bia e depois agem como ela, um comando por vez, enquanto o
terminal continua `admin`. Uma pequena função do shell faz isso: ela recebe o JSON que o
`create-access-key` imprimiu, e roda o resto da linha com essa chave no ambiente daquele comando
apenas. Digite-a no segundo terminal:

```sh
with_key() {
  local k=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$k" | jq -r .AccessKey.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$k" | jq -r .AccessKey.SecretAccessKey) "$@"
}
```

`with_key "$bia" aws s3 ls` então roda `aws s3 ls` assinado com a chave da bia, e o comando seguinte
é assinado com a do admin de novo. As lições 8 e 9 usam a mesma função.
