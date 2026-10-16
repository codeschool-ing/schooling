---
title: Revisando uma mudança na produção
version: 1
---

**Quem revisa código de aplicação pergunta "isto está certo?". Quem revisa estado desejado faz uma
segunda pergunta: "o que isto vai fazer com o cluster?"** O diff responde a primeira. A segunda
precisa do cluster.

## Dois diffs

Antes de aprovar, o Bruno lê a mudança como o Git a vê, e depois como o cluster a veria:

```
ana@laptop:~/fleet$ git fetch --quiet
ana@laptop:~/fleet$ git diff --stat main origin/banner-v2
 staging/bulletin.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@laptop:~/fleet$ git diff main origin/banner-v2 | grep '^[-+] '
-          value: Staging has the new banner.
+          value: Staging is ready for review.
ana@laptop:~/fleet$ git switch --quiet --detach origin/banner-v2
ana@laptop:~/fleet$ kubectl diff -f staging/ | grep '^[-+] '
-  generation: 1
+  generation: 2
-          value: Staging has the new banner.
+          value: Staging is ready for review.
ana@laptop:~/fleet$ git switch --quiet main
```

O primeiro diff é o commit: uma linha. O segundo é o `kubectl diff`, que manda os manifestos ao
servidor da API como um ensaio e imprime o que mudaria **no objeto vivo**: a mesma linha, mais o
`generation` subindo, que é o Kubernetes dizendo que vai começar um rollout. Numa mudança de uma
linha os dois concordam. Eles deixam de concordar quando o objeto vivo se desviou, ou quando um campo
que o commit não tocou tem um valor padrão que o cluster preenche. **O `kubectl diff` precisa de
acesso de leitura ao cluster**, o que é ok para o Bruno na mesa dele e não é algo para entregar a um
sistema de CI; a próxima seção verifica o que dá para verificar sem isso.

## Aprovando e fazendo o merge

```
ana@laptop:~/fleet$ curl -s -H "$AS_BRUNO" -H "$JSON" -d '{"event": "APPROVED", "body": "Checked against the live object: one value, one rollout."}' $API/pulls/1/reviews | jq '{state, user: .user.login, body}'
{
  "state": "APPROVED",
  "user": "bruno",
  "body": "Checked against the live object: one value, one rollout."
}
ana@laptop:~/fleet$ curl -s -w "%{http_code}\n" -H "$AS_ANA" -H "$JSON" -d '{"Do": "merge"}' $API/pulls/1/merge
200
ana@laptop:~/fleet$ git pull --quiet
ana@laptop:~/fleet$ git log --oneline -3
e1e3fc8 Merge pull request 'staging: ready for review' (#1) from banner-v2 into main
19332a9 staging: ready for review
7cb8caf Revert "staging: no service"
```

A revisão fica registrada no pull request com o nome do Bruno e o comentário dele, e o merge passa. A
`main` no servidor agora termina num commit de merge que cita o pull request.

## E o cluster acompanha

O laço da aula 1 lê só o repositório, então aponte-o para o servidor. O clone antigo dele veio do
`~/fleet.git`; apague-o e rode o laço de novo no segundo terminal:

```sh
rm -rf ~/.reconcile
sh ~/setup/reconcile.sh http://localhost:3000/ana/fleet.git staging
```

Ele clona com as credenciais que o Git já tem para `localhost:3000`, que são as suas; o agente da
aula 3 recebe um token só de leitura próprio. Segundos depois, no segundo terminal:

```
ana@laptop:~$ sh ~/setup/reconcile.sh http://localhost:3000/ana/fleet.git staging
02:01:35 at e1e3fc8
deployment.apps/bulletin configured
```

e no primeiro:

```
ana@laptop:~/fleet$ curl -s localhost:8080
bulletin 1.0
message: Staging is ready for review.
token: none
```

Ninguém rodou `kubectl apply`. A mudança foi do editor da Ana para um branch, um pull request, a
aprovação do Bruno, um merge, e da `main` para o cluster, e cada passo deixou um registro com um nome.
