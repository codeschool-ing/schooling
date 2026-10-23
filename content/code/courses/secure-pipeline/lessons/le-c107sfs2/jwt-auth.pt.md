---
title: O Vault confia na CI, e uma role decide quais execuções
version: 1
---

O Vault confere tokens de identidade com o **método de autenticação JWT**. Ele tem duas camadas, e a
diferença entre elas é onde mora a segurança de toda esta aula. **A configuração do método diz em
qual assinatura acreditar. Uma role diz quais dos tokens aceitos recebem qual policy.** Um token
assinado pela chave certa não ganha nada sozinho; ele precisa casar com uma role.

### Confiando na chave do servidor de CI

Habilite o método e entregue a ele a chave pública e o nome de emissor com que o `mint.py` assina:

```
ana@vm:~/linkbox$ vault auth enable jwt
Success! Enabled jwt auth method at: jwt/
ana@vm:~/linkbox$ vault write auth/jwt/config jwt_validation_pubkeys="$(cat ~/ci/oidc/ci-oidc.pub)" bound_issuer=https://ci.linkbox.example
Success! Data written to: auth/jwt/config
```

`jwt_validation_pubkeys` é o jeito mais simples de dizer ao Vault em quais assinaturas acreditar:
colar a chave pública. `bound_issuer` faz o Vault recusar um token cujo claim `iss` seja qualquer
outro, o que importa no dia em que a mesma chave, ou uma chave da mesma lista, assinar para outra
coisa.

### Uma role que confere pouco demais

A primeira role é a fácil de escrever e errada. Ela confere que o token é para o Vault e nada sobre a
execução, e anexa a policy de assinatura:

```
ana@vm:~/linkbox$ vault write auth/jwt/role/linkbox-any role_type=jwt bound_audiences=vault user_claim=sub token_policies=linkbox-sign token_ttl=5m
Success! Data written to: auth/jwt/role/linkbox-any
ana@vm:~/linkbox$ feature=$(python3 ~/ci/oidc/mint.py refs/heads/try-something)
ana@vm:~/linkbox$ curl -s --data "{\"role\": \"linkbox-any\", \"jwt\": \"$feature\"}" $VAULT_ADDR/v1/auth/jwt/login | jq -c ".auth | {policies, lease_duration}"
{"policies":["default","linkbox-sign"],"lease_duration":300}
ana@vm:~/linkbox$ vault delete auth/jwt/role/linkbox-any
Success! Data deleted (if it existed) at: auth/jwt/role/linkbox-any
```

**Uma execução de uma branch chamada `try-something` fez login e recebeu a policy que lê a senha de
assinatura.** Nada no token é falso: o servidor de CI o assinou, ele é para o Vault, está dentro da
validade. O problema é exatamente esse. A role confiou em todo token que o servidor de CI vier a
assinar, e o servidor de CI assina um para toda branch que alguém envia, então essa role entrega a
senha a toda branch, igualzinho ao arquivo que ela deveria substituir. O mesmo erro num serviço
hospedado é pior, porque lá o emissor assina para todo repositório de todo cliente; a última seção da
aula volta a isso.

O defeito está na role, então a correção é uma role que confira a execução. Apague esta antes de
seguir, como a captura faz: uma role que ninguém usa continua sendo uma porta de entrada.

### Uma role amarrada a main

Salve a role como `~/ci/vault/linkbox-main.json`:

```json
{
  "role_type": "jwt",
  "bound_audiences": ["vault"],
  "bound_claims": {
    "repository": "ana/linkbox",
    "ref": "refs/heads/main"
  },
  "user_claim": "sub",
  "token_policies": ["linkbox-sign"],
  "token_ttl": "5m",
  "token_max_ttl": "5m"
}
```

`bound_claims` é a linha que faltava na primeira role: **todo claim listado precisa ser igual ao
valor dado**, ou o login é recusado. `user_claim` nomeia o claim que o Vault registra como quem fez
login, então o log de auditoria dele diz `repo:ana/linkbox:ref:refs/heads/main` em vez de um número
de token. E `token_ttl` com `token_max_ttl` dão ao token do Vault os mesmos cinco minutos do token de
identidade, sem renovação além deles. Carregue-a e faça login com o token de `main` emitido na seção
anterior e com o de `try-something`:

```
ana@vm:~/linkbox$ vault write auth/jwt/role/linkbox-main - <~/ci/vault/linkbox-main.json
Success! Data written to: auth/jwt/role/linkbox-main
ana@vm:~/linkbox$ curl -s --data "{\"role\": \"linkbox-main\", \"jwt\": \"$main\"}" $VAULT_ADDR/v1/auth/jwt/login | jq -c ".auth | {policies, lease_duration}"
{"policies":["default","linkbox-sign"],"lease_duration":300}
ana@vm:~/linkbox$ curl -s --data "{\"role\": \"linkbox-main\", \"jwt\": \"$feature\"}" $VAULT_ADDR/v1/auth/jwt/login | jq -c
{"errors":["error validating claims: claim \"ref\" does not match any associated bound claim values"]}
```

`main` recebe a policy por 300 segundos. `try-something` é recusado, e **o erro nomeia o claim que
falhou**, que é o que você quer de uma recusa que um dia vai ler num log de CI: não "negado", mas qual
condição não se cumpriu.

### Cada checagem, recusando uma vez

Mais dois tokens mostram as checagens que vêm antes das da role. Um é emitido para outra audiência,
como seria um token destinado ao registry. O outro é assinado por uma chave que o Vault nunca viu:

```
ana@vm:~/linkbox$ elsewhere=$(python3 ~/ci/oidc/mint.py refs/heads/main registry)
ana@vm:~/linkbox$ curl -s --data "{\"role\": \"linkbox-main\", \"jwt\": \"$elsewhere\"}" $VAULT_ADDR/v1/auth/jwt/login | jq -c
{"errors":["error validating token: invalid audience (aud) claim: audience claim does not match any expected audience"]}
ana@vm:~/linkbox$ openssl genpkey -quiet -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out /tmp/stranger.key
ana@vm:~/linkbox$ stranger=$(CI_OIDC_KEY=/tmp/stranger.key python3 ~/ci/oidc/mint.py refs/heads/main)
ana@vm:~/linkbox$ curl -s --data "{\"role\": \"linkbox-main\", \"jwt\": \"$stranger\"}" $VAULT_ADDR/v1/auth/jwt/login | jq -c
{"errors":["error validating token: error verifying token signature: no known key successfully validated the token signature"]}
ana@vm:~/linkbox$ rm /tmp/stranger.key
```

Cada um é recusado num passo diferente, e a figura põe os quatro em ordem. A checagem de audiência é
o que impede um token emitido para um serviço de ser reaproveitado contra outro: um registry que
recebesse um token poderia, sem ela, usá-lo para entrar no Vault. A checagem de assinatura é a base
das outras, porque tudo depois dela lê claims que só a assinatura torna confiáveis.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 192\" role=\"img\" data-fig=\"sp-l17-checks\" aria-label=\"As checagens que o Vault faz num token de identidade antes de devolver um token do Vault, em ordem: a assinatura contra a chave pública em que confia, depois o emissor, depois a audiência, depois os claims que a role amarra, repository e ref. Cada checagem tem o token desta aula que ela recusou: um assinado pela chave de um estranho, um emitido para o registry e um para a branch try-something. Um token que passa pelas quatro recebe um token do Vault com a policy linkbox-sign por cinco minutos, que lê um caminho.\"><defs><marker id=\"sp-l17-checks-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l17-checks-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"8\" y=\"40\" width=\"112\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"64.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um login</text><text x=\"64.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">role + JWT</text><path d=\"M120 68 L130 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l17-checks-ah-phosphor)\"></path><rect x=\"132\" y=\"40\" width=\"100\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"182.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">assinatura</text><text x=\"182.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">chave confiável?</text><path d=\"M182 96 L182 136\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l17-checks-ah-amber)\"></path><rect x=\"132\" y=\"138\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"182.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">chave estranha</text><path d=\"M232 68 L242 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l17-checks-ah-phosphor)\"></path><rect x=\"244\" y=\"40\" width=\"100\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"294.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">emissor</text><text x=\"294.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">bound_issuer</text><path d=\"M344 68 L354 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l17-checks-ah-phosphor)\"></path><rect x=\"356\" y=\"40\" width=\"100\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"406.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">audiência</text><text x=\"406.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">bound_audiences</text><path d=\"M406 96 L406 136\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l17-checks-ah-amber)\"></path><rect x=\"356\" y=\"138\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"406.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">feito p/ o registry</text><path d=\"M456 68 L466 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l17-checks-ah-phosphor)\"></path><rect x=\"468\" y=\"40\" width=\"100\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"518.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">claims</text><text x=\"518.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">bound_claims</text><path d=\"M518 96 L518 136\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l17-checks-ah-amber)\"></path><rect x=\"468\" y=\"138\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"518.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">try-something</text><text x=\"64\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">recusado aqui</text><path d=\"M568 68 L586 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l17-checks-ah-phosphor)\"></path><rect x=\"588\" y=\"40\" width=\"126\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"651.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">token do Vault</text><text x=\"651.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8\" fill=\"var(--paper-dim)\">linkbox-sign, 5 minutos</text></svg>", "caption": "Quatro checagens, cada uma com o token desta aula que ela barrou. Só a última sabe alguma coisa das branches do linkbox.", "same": ["role + JWT", "claims"]}
```

Uma coisa que as capturas não recusam merece atenção. O token de `main` fez login uma vez na captura
anterior e é usado de novo abaixo, e o Vault aceita as duas vezes. **Um token de identidade é um
token ao portador durante os cinco minutos dele**: quem o tiver usa, quantas vezes quiser, até o
`exp`. A vida curta é o que limita um token roubado, e é por isso que um log nunca deve imprimir o
token, mesmo ele não contendo segredo nenhum.

### O lado do pipeline

Falta o punhado de linhas que um estágio do pipeline roda: trocar o token de identidade por um token
do Vault, ler um campo e devolver o token do Vault. Salve como `ci/vault-read.sh`:

```sh
# One field of one secret, read from Vault with the identity this run was
# given. The CI server mints that identity for the branch it is building and
# hands it over in CI_ID_TOKEN; Vault decides from its claims whether this
# run may have the secret at all. Nothing in this file is a credential, and
# the Vault token it gets is revoked when the script ends.
#
#   ci/vault-read.sh ROLE SECRET FIELD
set -euo pipefail
vault=${VAULT_ADDR:-http://127.0.0.1:8200}
fail() { jq -r '.errors[]?' <<<"$1" >&2; exit 1; }
login=$(curl -s --data "$(jq -n --arg role "$1" --arg jwt "$CI_ID_TOKEN" '{$role, $jwt}')" \
  "$vault/v1/auth/jwt/login")
token=$(jq -er .auth.client_token <<<"$login") || fail "$login"
trap 'curl -s -X POST -H "X-Vault-Token: $token" "$vault/v1/auth/token/revoke-self"' EXIT
secret=$(curl -s -H "X-Vault-Token: $token" "$vault/v1/secret/data/$2")
jq -er --arg field "$3" '.data.data[$field]' <<<"$secret" || fail "$secret"
```

O `jq -n` monta o pedido de login, então um token com algum caractere estranho não quebra o JSON. O
`jq -e` sai com erro quando o campo não existe, o que faz o script **falhar fechado**: um login ou uma
leitura recusados param o estágio com a mensagem do próprio Vault, em vez de entregar ao próximo
comando uma senha vazia. O `trap` revoga o token do Vault assim que o script termina, com sucesso ou
não, então os cinco minutos são um teto e não a vida normal.

Rode-o como o servidor de CI rodaria para uma execução de `main` e para uma de `try-something`:

```
ana@vm:~/linkbox$ CI_ID_TOKEN=$main bash ci/vault-read.sh linkbox-main linkbox/signing password | cmp - ~/ci/keys/password && echo same
same
ana@vm:~/linkbox$ CI_ID_TOKEN=$feature bash ci/vault-read.sh linkbox-main linkbox/signing password; echo "exit $?"
error validating claims: claim "ref" does not match any associated bound claim values
exit 1
ana@vm:~/linkbox$ git add ci/vault-read.sh
ana@vm:~/linkbox$ git commit -q -m "the pipeline reads its secrets from Vault with an identity of its own"
9:44AM INF 0 commits scanned.
9:44AM INF scanned ~939 bytes (939 bytes) in 209ms
9:44AM INF no leaks found
```

A execução de `main` lê um valor igual ao arquivo no disco do servidor de CI, e a comparação diz isso
sem imprimi-lo. A de `try-something` para com status de saída 1 e o motivo. Faça o commit do script; o
hook de pre-commit da aula 6 procura segredos na mudança na entrada e não acha nenhum, porque não há
nenhum nela.

### O que um servidor de CI de verdade mudaria, e por que este não muda

Num servidor de CI preparado para isso, o hook emitiria um token para cada execução e o passaria
adiante. As linhas abaixo não foram executadas neste curso. No hook da aula 1, a linha que inicia o
pipeline ganharia uma variável:

```sh
  if CI_ID_TOKEN=$(python3 ~/ci/oidc/mint.py "$ref") \
      CI_COMMIT=${new:0:7} CI_BRANCH=${ref#refs/heads/} CI_LOGS=$run/logs \
      "$run/src/ci/pipeline.sh"; then
```

e o `ci/sign.sh` buscaria a senha no Vault em vez de no arquivo:

```sh
COSIGN_PASSWORD=$(bash ci/vault-read.sh linkbox-main linkbox/signing password)
```

depois do que o arquivo em `~/ci/keys` poderia ser apagado, e uma branch que mudasse o `sign.sh` para
imprimir a senha descobriria que não há nada para imprimir. **O pipeline deste curso continua lendo o
arquivo**, e o hook fica como a aula 1 o escreveu. O motivo é o servidor em modo dev: ele vive o tempo
do contêiner e esquece tudo quando para, então um pipeline que dependesse dele quebraria na primeira
vez que a máquina reiniciasse. As aulas 18 a 20 continuam enviando ao servidor de CI, e precisam que
ele funcione sem Vault nenhum rodando. Num Vault de produção, as duas linhas acima são a mudança
inteira.
