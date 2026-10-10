---
title: Checagens que uma máquina faz antes de uma pessoa olhar
version: 1
---

**A atenção de quem revisa é o recurso mais escasso do fluxo, então uma máquina deve gastá-la
antes.** Um manifesto com um erro de digitação no nome de um campo, um texto onde o Kubernetes quer
um número, ou uma indentação que levou uma chave para o objeto errado podem ser achados sem pessoa
nenhuma e sem o cluster. Esta seção acrescenta essa checagem, faz ela informar o Gitea, e faz a regra
de proteção esperar por ela.

## Um validador

O `kubeconform` confere manifestos contra os JSON schemas de uma versão do Kubernetes, offline
exceto para baixar esses schemas na primeira vez. É um arquivo só, instalado como o `kind` na aula 1:

```
ana@laptop:~/setup$ ARCH=$(dpkg --print-architecture)
ana@laptop:~/setup$ curl -fsSLO https://github.com/yannh/kubeconform/releases/download/v0.8.0/kubeconform-linux-$ARCH.tar.gz
ana@laptop:~/setup$ curl -fsSL https://github.com/yannh/kubeconform/releases/download/v0.8.0/CHECKSUMS | grep " kubeconform-linux-$ARCH.tar.gz$" | sha256sum --check
kubeconform-linux-amd64.tar.gz: OK
ana@laptop:~/setup$ tar -xzf kubeconform-linux-$ARCH.tar.gz kubeconform && sudo install -m 0755 kubeconform /usr/local/bin/ && rm kubeconform kubeconform-linux-$ARCH.tar.gz
ana@laptop:~/setup$ kubeconform -v
v0.8.0
```

## Um CI de um script

Um sistema de CI de verdade roda a cada push e devolve o resultado. Aqui um script faz o mesmo
trabalho quando você o roda, o que basta para ver cada parte do arranjo. Ele informa como um usuário
próprio, `ci`, para que as checagens nunca se confundam com a palavra de uma pessoa. Crie o usuário e
o token dele como criou os do Bruno:

```
ana@laptop:~/fleet$ docker exec gitea gitea admin user create --username ci --password 'change-me-also' --email ci@example.org --must-change-password=false
New user 'ci' has been successfully created!
ana@laptop:~/fleet$ docker exec gitea gitea admin user generate-access-token --username ci --token-name checks --scopes write:repository --raw > ~/ci.token
ana@laptop:~/fleet$ chmod 600 ~/ci.token
ana@laptop:~/fleet$ curl -s -o /dev/null -w "%{http_code}\n" -X PUT -H "$AS_ANA" -H "$JSON" -d '{"permission": "write"}' $API/collaborators/ci
204
```

E salve isto como `~/setup/validate.sh`:

```sh
#!/bin/sh
# The course's CI: check one commit of fleet and report the result to Gitea.
# Usage: sh validate.sh COMMIT
sha=$1 api=http://localhost:3000/api/v1/repos/ana/fleet
work=$(mktemp -d)
git clone --quiet http://localhost:3000/ana/fleet.git "$work"
git -C "$work" checkout --quiet "$sha"
if kubeconform -strict -summary -kubernetes-version 1.37.0 "$work/staging"; then
  state=success text="kubeconform passed"
else
  state=failure text="kubeconform found invalid manifests"
fi
curl -s -o /dev/null -H "Authorization: token $(cat ~/ci.token)" \
  -H 'Content-Type: application/json' \
  -d "{\"state\": \"$state\", \"context\": \"validate\", \"description\": \"$text\"}" \
  "$api/statuses/$sha"
echo "validate: $state"
rm -rf "$work"
```

Ele clona o repositório, faz checkout do commit exato que recebeu, valida o `staging/` com `-strict`,
que também recusa campos que o schema não conhece, e publica um **status de commit** chamado
`validate` nesse commit. A regra pode então exigir esse status:

```
ana@laptop:~/fleet$ curl -s -X PATCH -H "$AS_ANA" -H "$JSON" -d '{"enable_status_check": true, "status_check_contexts": ["validate"]}' $API/branch_protections/main | jq '{rule_name, required_approvals, enable_status_check, status_check_contexts}'
{
  "rule_name": "main",
  "required_approvals": 1,
  "enable_status_check": true,
  "status_check_contexts": [
    "validate"
  ]
}
```

## Uma mudança que falha

A Ana pede três réplicas, e escreve o número por extenso:

```
ana@laptop:~/fleet$ git switch --quiet -c three-replicas
ana@laptop:~/fleet$ git diff | grep '^[-+] '
-  replicas: 2
+  replicas: three
ana@laptop:~/fleet$ git commit --quiet -am "staging: three replicas"
ana@laptop:~/fleet$ git push --quiet -u origin three-replicas
remote: 
remote: Create a new pull request for 'three-replicas':        
remote:   http://localhost:3000/ana/fleet/pulls/new/three-replicas        
remote: 
ana@laptop:~/fleet$ curl -s -H "$AS_ANA" -H "$JSON" -d '{"head": "three-replicas", "base": "main", "title": "staging: three replicas", "body": "Load testing starts on Monday."}' $API/pulls | jq .number
2
ana@laptop:~/fleet$ sh ~/setup/validate.sh $(git rev-parse HEAD)
/tmp/tmp.EcfvHQ4Lh5/staging/bulletin.yaml - Deployment bulletin is invalid: problem validating schema. Check JSON formatting: jsonschema validation failed with 'https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.37.0-standalone-strict/deployment-apps-v1.json#' - at '/spec/replicas': got string, want null or integer
Summary: 3 resources found in 1 file - Valid: 2, Invalid: 1, Errors: 0, Skipped: 0
validate: failure
ana@laptop:~/fleet$ curl -s -w " %{http_code}\n" -H "$AS_ANA" -H "$JSON" -d '{"Do": "merge"}' $API/pulls/2/merge
{"message":"Not all required status checks successful","url":"http://localhost:3000/api/swagger"} 405
```

A regra de proteção agora segura o merge por dois motivos, e a mensagem diz o primeiro que
encontrou. **O Bruno nunca precisou ler esta versão**: a máquina disse o que estava errado, com o
campo e o tipo, antes que alguém gastasse atenção com ela. A Ana corrige no mesmo branch:

```
ana@laptop:~/fleet$ git commit --quiet -am "staging: replicas is a number"
ana@laptop:~/fleet$ git push --quiet
remote: 
remote: Visit the existing pull request:        
remote:   http://localhost:3000/ana/fleet/pulls/2        
remote: 
ana@laptop:~/fleet$ sh ~/setup/validate.sh $(git rev-parse HEAD)
Summary: 3 resources found in 1 file - Valid: 3, Invalid: 0, Errors: 0, Skipped: 0
validate: success
ana@laptop:~/fleet$ curl -s -H "$AS_BRUNO" -H "$JSON" -d '{"event": "APPROVED", "body": "Three it is."}' $API/pulls/2/reviews | jq -r .state
APPROVED
ana@laptop:~/fleet$ curl -s -w "%{http_code}\n" -H "$AS_ANA" -H "$JSON" -d '{"Do": "merge"}' $API/pulls/2/merge
200
ana@laptop:~/fleet$ git switch --quiet main && git pull --quiet
ana@laptop:~/fleet$ kubectl -n staging get deployment bulletin
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
bulletin   3/3     3            3           47s
```

O status ficou verde no commit novo, o Bruno aprovou o que de fato vai entrar, e o merge passou.
Dentro de uma passada o laço aplica, e o staging roda três réplicas.
