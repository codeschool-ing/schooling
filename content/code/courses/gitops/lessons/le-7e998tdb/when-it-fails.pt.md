---
title: Quando o fluxo falha
version: 1
---

Cada uma destas foi produzida de propósito contra o Gitea desta aula, e cada uma para uma mudança por
um motivo que vale ler.

## Um token errado

```
ana@laptop:~/fleet$ curl -s -w " %{http_code}\n" -H "Authorization: token 0123456789abcdef" $API
{"message":"invalid username, password or token","url":"http://localhost:3000/api/swagger"} 401
```

`401` e `invalid username, password or token`. O token do cabeçalho não bateu com nenhum token do
servidor: uma cópia que perdeu um caractere, um arquivo lido do caminho errado, ou um token que foi
apagado. O `wc -c ~/ana.token` deve dizer 41, quarenta caracteres e uma quebra de linha; crie um
token novo se não disser.

## Uma aprovação que venceu

O Bruno aprova, e a Ana envia mais um commit para o branch antes do merge:

```
ana@laptop:~/fleet$ git switch --quiet -c banner-v3
ana@laptop:~/fleet$ git commit --quiet -am "staging: in use by QA"
ana@laptop:~/fleet$ git push --quiet -u origin banner-v3
remote: 
remote: Create a new pull request for 'banner-v3':        
remote:   http://localhost:3000/ana/fleet/pulls/new/banner-v3        
remote: 
ana@laptop:~/fleet$ curl -s -H "$AS_ANA" -H "$JSON" -d '{"head": "banner-v3", "base": "main", "title": "staging: in use by QA"}' $API/pulls | jq .number
5
ana@laptop:~/fleet$ sh ~/setup/validate.sh $(git rev-parse HEAD)
Summary: 3 resources found in 1 file - Valid: 3, Invalid: 0, Errors: 0, Skipped: 0
validate: success
ana@laptop:~/fleet$ curl -s -H "$AS_BRUNO" -H "$JSON" -d '{"event": "APPROVED", "body": "OK."}' $API/pulls/5/reviews | jq -r .state
APPROVED
ana@laptop:~/fleet$ git commit --quiet -am "staging: until Friday"
ana@laptop:~/fleet$ git push --quiet
remote: 
remote: Visit the existing pull request:        
remote:   http://localhost:3000/ana/fleet/pulls/5        
remote: 
ana@laptop:~/fleet$ sh ~/setup/validate.sh $(git rev-parse HEAD)
Summary: 3 resources found in 1 file - Valid: 3, Invalid: 0, Errors: 0, Skipped: 0
validate: success
ana@laptop:~/fleet$ curl -s -w " %{http_code}\n" -H "$AS_ANA" -H "$JSON" -d '{"Do": "merge"}' $API/pulls/5/merge
{"message":"Does not have enough approvals","url":"http://localhost:3000/api/swagger"} 405
```

A regra descarta uma aprovação quando chegam commits novos, então a aprovação deixa de contar e o
merge é recusado. É a regra funcionando: **o Bruno aprovou uma versão que não é mais a que vai
entrar.** Ele revisa o commit novo e aprova de novo.

## O Git pede um usuário

```
ana@laptop:~/fleet$ git ls-remote http://127.0.0.1:3000/ana/fleet.git
fatal: could not read Username for 'http://127.0.0.1:3000': terminal prompts disabled
```

O Git não achou credencial guardada para esse endereço. Num terminal ele para e pede um usuário;
esta transcrição foi gravada com os prompts do Git desligados, então ele diz por que não conseguiu
perguntar. Ou o `~/.git-credentials` não foi escrito, ou foi escrito para outro endereço:
`http://127.0.0.1:3000` e `http://localhost:3000` são dois servidores diferentes para o Git. O remoto
e a linha da credencial precisam citar o mesmo host.

## `jq: command not found`

Todo comando que manda a saída para o `jq` não imprime nada útil sem ele. O
`sudo apt-get install jq` o instala; os comandos também funcionam sem a parte `| jq …`, ao preço de
ler uma página de JSON.
