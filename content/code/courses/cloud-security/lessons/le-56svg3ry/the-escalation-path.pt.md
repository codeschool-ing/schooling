---
title: O caminho de escalada que ninguém revogou
version: 1
---

**A dani saiu em março, e o usuário do IAM dela não. Ele ainda tem uma chave de acesso, e uma
política inline que o deixa anexar políticas a usuários. Essa permissão sozinha basta para a chave
dela se tornar administradora, e nesta seção você vê isso acontecer no seu próprio laboratório.**
Depois você tem a descoberta que o resto da aula fecha.

Nada aqui é técnica para entrar na conta de ninguém. A chave desta história já pertence à conta, a
política foi escrita pelos próprios administradores dela, e a requisição usa a permissão exatamente
como foi concedida. **É isso que faz disso um defeito de configuração, e não uma invasão**: a AWS não
fez nada de errado, e nenhuma linha de log pareceria estranha.

## Ligando a verificação

Até aqui o moto aceitou qualquer chave. Para ver uma negação, e uma escalada, ele precisa julgar
requisições. Isso é uma opção lida quando ele inicia: **`INITIAL_NO_AUTH_ACTION_COUNT=3` deixa as
três primeiras requisições passarem sem verificação e julga todas as seguintes.** As três
requisições livres são gastas criando um administrador, já que um juiz precisa de alguém que seja o
administrador da conta e ainda não há ninguém. Toda requisição conta, inclusive uma que falha, então
digite as três abaixo com cuidado.

No primeiro terminal, pare o moto com Ctrl+C e inicie de novo assim:

```sh
INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567
```

No segundo terminal, as três requisições: um usuário chamado `admin`, a política
`AdministratorAccess` da AWS para ele, e uma chave de acesso guardada numa variável do shell em vez
de impressa. A quarta requisição prova que a verificação está ligada, e o `export` passa este
terminal para a chave do admin:

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

A quarta requisição foi recusada porque o terminal ainda levava a chave `test`, que o IAM do moto
nunca emitiu. Do `export` em diante, este terminal é o admin.

Mais uma ferramenta antes da história. `with_key` roda um único comando com a chave de outro
usuário, sem mudar a do terminal; digite-a no segundo terminal:

```sh
with_key() {
  local k=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$k" | jq -r .AccessKey.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$k" | jq -r .AccessKey.SecretAccessKey) "$@"
}
```

## A conta como a dani a deixou

O caio desenvolve o sistema de agendamento e tem a `PowerUserAccess` da AWS, que permite tudo menos
IAM e Organizations. A bia lê relatórios com a `ReadOnlyAccess`. O usuário da dani ganhou uma
política inline em fevereiro, para que ela mesma desse a política de relatórios a cada analista
novo, e uma chave para o script de onde ela fazia isso:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["iam:AttachUserPolicy", "iam:ListAttachedUserPolicies"],
      "Resource": "*"
    }
  ]
}
```

Salve-a como `manage-users.json` e monte a conta:

```
ana@laptop:~/aws$ aws iam create-user --user-name caio --query User.Arn --output text
arn:aws:iam::123456789012:user/caio
ana@laptop:~/aws$ aws iam attach-user-policy --user-name caio --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
ana@laptop:~/aws$ aws iam create-user --user-name bia --query User.Arn --output text
arn:aws:iam::123456789012:user/bia
ana@laptop:~/aws$ aws iam attach-user-policy --user-name bia --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess
ana@laptop:~/aws$ aws iam create-user --user-name dani --query User.Arn --output text
arn:aws:iam::123456789012:user/dani
ana@laptop:~/aws$ aws iam put-user-policy --user-name dani --policy-name manage-users --policy-document file://manage-users.json
ana@laptop:~/aws$ dani=$(aws iam create-access-key --user-name dani)
```

## O que a chave consegue fazer

A chave se comporta exatamente como a política dela diz. Ela não lista os usuários da conta, porque
nada permite `iam:ListUsers`:

```
ana@laptop:~/aws$ with_key "$dani" aws iam list-users --query "Users[].UserName" --output text

aws: [ERROR]: An error occurred (AccessDenied) when calling the ListUsers operation: User: arn:aws:iam::123456789012:user/dani is not authorized to perform: iam:ListUsers
```

Mas `iam:AttachUserPolicy` com `"Resource": "*"` permite anexar **qualquer** política a **qualquer**
usuário, e o usuário para quem ela foi escrita é um deles:

```
ana@laptop:~/aws$ with_key "$dani" aws iam attach-user-policy --user-name dani --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

**Um prompt em silêncio é a descoberta.** A requisição deu certo, e deste momento em diante a chave
de uma pessoa que saiu há sete meses tem `AdministratorAccess`. A requisição que falhou um minuto
atrás agora funciona:

```
ana@laptop:~/aws$ with_key "$dani" aws iam list-users --query "Users[].UserName" --output text
admin	caio	bia	dani
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" data-fig=\"l06-path\" aria-label=\"O caminho de escalada desta aula, da esquerda para a direita. Um usuário que ninguém removeu quando a dani saiu em março; uma chave de acesso nele que ninguém desativou; uma política inline que permite iam:AttachUserPolicy em todo recurso. Juntos, eles deixam a chave anexar a AdministratorAccess ao próprio usuário, e daí em diante ela pode tudo na conta. Debaixo de cada um dos três primeiros elos, a correção que o corta: remover o usuário, apagar a chave, ou nomear a única política que pode ser anexada. Cortar qualquer um fecha o caminho.\"><defs><marker id=\"l06-path-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l06-path-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"124.0\" height=\"74.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"82.0\" y=\"70.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um usuário que</text><text x=\"82.0\" y=\"83.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ninguém removeu</text><path d=\"M146.0 77.0 L158.0 77.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-path-af-ah-paper-dim)\"></path><path d=\"M82.0 118.0 L82.0 168.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"26.0\" y=\"170.0\" width=\"112.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"82.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">remover o usuário</text><rect x=\"160.0\" y=\"40.0\" width=\"124.0\" height=\"74.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"222.0\" y=\"70.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma chave que</text><text x=\"222.0\" y=\"83.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ninguém desativou</text><path d=\"M286.0 77.0 L298.0 77.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-path-af-ah-paper-dim)\"></path><path d=\"M222.0 118.0 L222.0 168.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"166.0\" y=\"170.0\" width=\"112.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"222.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">apagar a chave</text><rect x=\"300.0\" y=\"40.0\" width=\"124.0\" height=\"74.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"362.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma política inline</text><text x=\"362.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">iam:AttachUserPolicy</text><text x=\"362.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">&quot;Resource&quot;: &quot;*&quot;</text><path d=\"M426.0 77.0 L438.0 77.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-path-af-ah-paper-dim)\"></path><path d=\"M362.0 118.0 L362.0 168.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"306.0\" y=\"170.0\" width=\"112.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"362.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">nomear a única política</text><rect x=\"440.0\" y=\"40.0\" width=\"124.0\" height=\"74.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"502.0\" y=\"63.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">anexar</text><text x=\"502.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">AdministratorAccess</text><text x=\"502.0\" y=\"90.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a si mesma</text><path d=\"M566.0 77.0 L578.0 77.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-path-af-ah-amber)\"></path><rect x=\"580.0\" y=\"40.0\" width=\"120.0\" height=\"74.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"640.0\" y=\"69.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">tudo</text><text x=\"640.0\" y=\"84.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">na conta</text><text x=\"222.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">corte qualquer elo e o caminho se fecha</text></svg>", "caption": "Três coisas comuns em sequência fazem o caminho, e cada uma tem a sua correção. Uma revisão que encontra só uma delas já encontrou o bastante para fechá-lo.", "same": ["AdministratorAccess"]}
```

Três coisas se alinharam, e cada uma é comum sozinha: um usuário que ninguém removeu, uma chave que
ninguém desativou, e uma permissão escrita para um trabalho pequeno com um `*` onde deveria estar uma
lista de analistas. **Tire qualquer uma e o caminho se fecha.** Esse é o formato da maioria das
descobertas de escalada, e o motivo de a próxima seção procurar as três separadamente.

Uma ressalva sobre este laboratório: a AWS também julgaria uma condição na política, como uma que
limitasse quais políticas podem ser anexadas, enquanto o moto ignora condições. A última seção volta a
isso.
