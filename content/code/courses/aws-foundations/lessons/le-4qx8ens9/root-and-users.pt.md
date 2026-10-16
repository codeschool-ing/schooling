---
title: O usuário root, e os usuários do IAM ao lado dele
version: 1
---

**Um principal é quem assina uma requisição que a AWS depois julga.** Toda chamada à AWS leva uma
assinatura, a assinatura nomeia uma identidade, e o IAM decide o que essa identidade pode fazer. A
imagem errada mais comum é que um usuário do IAM é uma pessoa. **Um usuário é um nome com
credenciais de longo prazo**, e as duas coisas não coincidem: uma pessoa pode trabalhar na AWS por
anos sem usuário do IAM nenhum, entrando por login único como a lição 11 mostra, e um programa no
notebook de alguém pode assinar toda requisição com a chave de um usuário.

Esta lição cria os quatro tipos de principal (os *principais*, no vocabulário da AWS) que existem,
na ordem em que uma conta os encontra: o usuário root, os usuários do IAM, as sessões de role e as
identidades federadas. Os grupos entram no meio, e são a única coisa na lista de identidades do IAM
que **não** é um principal.

## Antes de tudo: uma AWS vazia

Reinicie o moto no primeiro terminal (Ctrl+C, depois `moto_server -p 4567`) para que esta lição
comece de uma AWS vazia, e leia o `env.sh` no segundo, como a lição 1 mostrou. **A verificação de
permissões do moto fica desligada nesta lição**, que é o padrão dele: toda chamada abaixo dá certo,
seja quem for que a faça. A lição 7 liga a verificação. Até lá, um comando que funciona aqui prova
que o comando está certo, não que alguém tinha permissão para rodá-lo.

## O usuário root

Abrir uma conta AWS cria uma identidade, a partir do e-mail e da senha digitados no formulário. Essa
identidade é o **usuário root**, e o ARN dele não tem nome, só a conta:
`arn:aws:iam::123456789012:root`. Ele tem todas as permissões da conta, e **nenhuma política do
IAM da conta consegue tirar uma delas**. Só uma service control policy, definida de fora pela
organização, limita o usuário root de uma conta membro, e a lição 4 mostra como.

Uma lista curta de tarefas exige o root e nada mais, segundo a documentação da AWS: mudar o nome da
conta, o e-mail ou a senha do root, mudar ou cancelar o plano de suporte, e fechar a conta. **Todo o
resto é feito por algum outro principal**, então a senha do root fica guardada num lugar seguro,
protegida com MFA, e só sai de lá para essas tarefas. A seção da lição 1 sobre uma conta real dá a
ordem para fazer isso. Uma organização pode ir além e remover de vez a senha do root das contas
membro, o que a documentação do IAM chama de acesso root centralizado.

O moto não tem usuário root para entrar: o `get-caller-identity` da lição 1 respondeu com um
usuário chamado `moto`. O que ele guarda é o resumo da conta, e duas das linhas dele são a primeira
coisa que uma auditoria de uma conta real lê:

```
ana@laptop:~/aws$ aws iam get-account-summary --query "SummaryMap.{AccountMFAEnabled:AccountMFAEnabled,AccountAccessKeysPresent:AccountAccessKeysPresent,Users:Users,GroupsPerUserQuota:GroupsPerUserQuota}"
{
    "AccountMFAEnabled": 0,
    "AccountAccessKeysPresent": 0,
    "Users": 0,
    "GroupsPerUserQuota": 10
}
```

**As duas linhas `Account…` descrevem o usuário root, não a conta.** `AccountMFAEnabled` vale 1
quando o root tem segundo fator, e `AccountAccessKeysPresent` vale 1 quando o root tem chave de
acesso. Uma conta real quer 1 e 0. O moto imprime 0 nas duas porque não há root por trás dele,
que é o único caso em que 0 de MFA não é um achado.

## Usuários do IAM

A loja tem três pessoas além da ana: a bia, desenvolvedora, o caio, analista, e a dani, do
financeiro. Cada uma ganha um usuário do IAM aqui, porque esse é o principal de que esta lição
trata. A lição 11 leva as pessoas para o IAM Identity Center, que é o lugar de uma pessoa numa
organização real.

```
ana@laptop:~/aws$ aws iam create-user --user-name bia
{
    "User": {
        "Path": "/",
        "UserName": "bia",
        "UserId": "js9pb6447kryw6le9a1i",
        "Arn": "arn:aws:iam::123456789012:user/bia",
        "CreateDate": "2026-10-16T16:06:21.871983+00:00"
    }
}
```

O ARN é o endereço do usuário em toda política: o serviço `iam`, nenhuma região porque o IAM é
global, a conta, depois `user/` e o nome. `UserId` é o **id único** do usuário, e é uma coisa
diferente do nome, à qual a próxima seção volta. **Os ids do moto não têm o formato dos da AWS.**
Os ids de usuário da AWS têm 21 caracteres e começam com `AIDA`; os do moto são 20 letras minúsculas
e dígitos aleatórios, como acima. Os outros dois usuários:

```
ana@laptop:~/aws$ aws iam create-user --user-name caio --query "User.[UserName,UserId,Arn]" --output text
caio	uamtq0s7tvnse8tqk0us	arn:aws:iam::123456789012:user/caio
ana@laptop:~/aws$ aws iam create-user --user-name dani --query "User.[UserName,UserId,Arn]" --output text
dani	c9jkpficj8fz3num8nga	arn:aws:iam::123456789012:user/dani
```

Um usuário pode ter dois tipos de credencial de longo prazo, e longo prazo quer dizer
exatamente isso: elas duram até alguém apagá-las.

- **Uma senha**, para o console, criada por `create-login-profile`. A AWS a chama de perfil de
  login.
- **Uma chave de acesso**, para a linha de comando e os SDKs: um id e um segredo que assinam
  requisições.

```
ana@laptop:~/aws$ aws iam create-login-profile --user-name bia --password 'Lab-only-pass-2026' --password-reset-required
{
    "LoginProfile": {
        "UserName": "bia",
        "CreateDate": "2026-10-16T16:06:21.871983+00:00",
        "PasswordResetRequired": false
    }
}
ana@laptop:~/aws$ aws iam create-access-key --user-name bia --query "AccessKey.[AccessKeyId,Status]" --output text
AKIARZPUZDIKEBQA4QAN	Active
```

**Um id de chave de acesso começa com `AKIA`**, no moto e na AWS: quatro letras que querem dizer
"chave de longo prazo de um usuário do IAM". O `--query` imprimiu o id e o status e deixou o
segredo fora da tela, um hábito que vale a pena ter mesmo com as chaves do moto, que não abrem nada
fora dele. O moto também registrou `PasswordResetRequired` como falso, embora o comando pedisse
verdadeiro; a AWS guarda a opção e obriga a bia a escolher uma senha nova no primeiro login.

A senha e a chave têm a mesma fraqueza: **funcionam de qualquer lugar, para qualquer um que as
tenha, até alguém perceber.** É por isso que a lição 12 chama a chave de acesso de último recurso, e
é por isso que as roles da próxima seção existem.
