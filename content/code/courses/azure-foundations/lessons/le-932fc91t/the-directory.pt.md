---
title: O tenant é um diretório, e qualquer um pode perguntar onde ele fica
version: 1
---

**O Microsoft Entra ID não é uma parte do Azure que você liga. Ele é o diretório que todo tenant do
Azure já é**, e ele existia antes de qualquer assinatura: o mesmo diretório guarda as identidades do
Microsoft 365, do Teams e de toda aplicação em que uma empresa entra com as contas de trabalho. Até
2023 ele se chamava Azure Active Directory, e metade do que você vai ler na internet ainda diz isso.
O nome mudou; o produto, os endpoints e os códigos de erro, não.

Um tenant guarda quatro tipos de objeto, e esta lição e as duas seguintes os tratam em ordem:

| objeto | o que é | lição |
|---|---|---|
| usuário | uma pessoa, ou uma conta com que uma pessoa faz login | 6 |
| grupo | um conjunto de usuários, dispositivos ou outros principals, que recebe acesso de uma vez por todos eles | 6 |
| aplicação e service principal | o registro de um programa, e a identidade dele dentro de um tenant | 7 |
| identidade gerenciada | uma identidade que o Azure cria e mantém para um recurso | 8 |

Usuários, grupos, service principals e identidades gerenciadas são todos **principals**: algo que
pode fazer login, ou receber um papel. A lição 9 dá papéis a eles.

## Perguntando ao Entra ID onde um tenant fica

O Entra ID responde em `login.microsoftonline.com`, o endereço que a lição 1 leu do `az cloud show`.
Parte do que ele responde é pública de propósito: antes de um programa pedir a alguém que faça login,
ele precisa saber para onde mandar a pessoa, e a resposta é um **documento de descoberta** que
qualquer um pode buscar. Este é o de `organizations`, o nome que representa "qualquer tenant de
trabalho ou de escola":

```sh
mkdir -p ~/azure/entra && cd ~/azure/entra
```

```
ana@laptop:~/azure/entra$ curl -sS https://login.microsoftonline.com/organizations/v2.0/.well-known/openid-configuration | jq '{issuer, authorization_endpoint, token_endpoint, jwks_uri}'
{
  "issuer": "https://login.microsoftonline.com/{tenantid}/v2.0",
  "authorization_endpoint": "https://login.microsoftonline.com/organizations/oauth2/v2.0/authorize",
  "token_endpoint": "https://login.microsoftonline.com/organizations/oauth2/v2.0/token",
  "jwks_uri": "https://login.microsoftonline.com/organizations/discovery/v2.0/keys"
}
```

**Esta é uma resposta real do Microsoft Entra ID**, a primeira do curso. É o documento de descoberta
do padrão OpenID Connect, e todo provedor de identidade que fala o padrão publica um no mesmo
caminho. Quatro endereços nele importam:

- `authorization_endpoint` é para onde uma **pessoa** é mandada para fazer login, num navegador;
- `token_endpoint` é onde um **programa** pede um token, que é a lição 7;
- `jwks_uri` guarda as chaves públicas que assinam todo token, para que qualquer um que receba um
  possa conferir que ele veio do Entra ID;
- `issuer` é o que um token vai dizer sobre quem o emitiu, com `{tenantid}` preenchido pelo tenant que
  emitiu.

Pergunte por um tenant que não existe e o Entra ID diz isso, com as próprias palavras:

```
ana@laptop:~/azure/entra$ curl -sS https://login.microsoftonline.com/aaaabbbb-0000-cccc-1111-dddd2222eeee/v2.0/.well-known/openid-configuration | jq '{error, error_codes, error_description: (.error_description | split(" Trace ID")[0])}'
{
  "error": "invalid_tenant",
  "error_codes": [
    90002
  ],
  "error_description": "AADSTS90002: Tenant 'aaaabbbb-0000-cccc-1111-dddd2222eeee' not found. Check to make sure you have the correct tenant ID and are signing into the correct cloud. Check with your subscription administrator, this may happen if there are no active subscriptions for the tenant."
}
```

**`AADSTS90002` é o código de um tenant de que o Entra ID nunca ouviu falar**, e `AADSTS` abre todo
erro do Entra ID, um prefixo que sobrou do nome antigo. O id é o tenant inventado que este curso usa
para a loja, no padrão que a própria documentação da Microsoft usa, e a resposta prova que ele está
livre. O filtro do `jq` cortou a descrição no *Trace ID*, um valor que o Entra ID inventa para cada
pedido para que o suporte dele o encontre, e que uma transcrição não consegue repetir.

**Nomes `.onmicrosoft.com` são de quem chegar primeiro.** Todo tenant ganha um ao ser criado, e o
tenant da loja neste curso é escrito `shop.onmicrosoft.com` porque o formato é o certo. Esse nome
exato já é de outra pessoa: o Entra ID responde por ele. Então este curso dá à loja **um domínio
próprio, `shop.example`**, que uma empresa de verdade verificaria no tenant acrescentando um registro
de DNS, e o pessoal dela faz login como `bia@shop.example`. O `.example` é reservado para
documentação e nunca pode pertencer a ninguém.

## Um usuário é um objeto, e o nome dele não é o id

```
ana@laptop:~/azure/entra$ az ad user list --display-name Bia
ERROR: Please run 'az login' to setup account.
```

Listar usuários é uma pergunta para o **Microsoft Graph**, a API em `graph.microsoft.com` pela qual
tudo no diretório é lido e escrito, e ela precisa de login como todo o resto. **Não executado.** Com
login, cada usuário volta com dois nomes que as pessoas confundem:

- o **user principal name**, `bia@shop.example`, que ela digita para entrar. Parece um endereço de
  e-mail e não precisa ser um; ele pode mudar, e muda, quando alguém se casa ou uma empresa troca de
  domínio;
- o **object id**, um GUID que o Entra ID deu a ela quando foi criada, e que nunca muda.

**Toda permissão, toda linha de log e toda participação em grupo apontam para o object id.** Um script
que guarda quem fez o quê pelo user principal name perde o histórico no dia em que o nome muda, que é
exatamente a falha que juntar por um id estável evita. Leia o object id de tudo o que você guardar.

Os usuários são de dois tipos. Um **membro** pertence ao tenant: o pessoal da própria loja. Um
**convidado** é uma pessoa de outra organização convidada a entrar, que faz login com a conta da
própria organização ou com uma pessoal e aparece no diretório da loja com `#EXT#` no user principal
name. A contadora da loja, de um escritório de fora, é uma convidada: ela recebe acesso aos
relatórios de cobrança e a loja nunca guarda a senha dela.
