---
title: Um push que chega ao cluster em segundos
version: 1
---

**O polling é o motivo de um merge levar um ou três minutos para chegar**, no Flux como no Argo CD.
A cura é a mesma nos dois: o servidor Git chama o agente quando algo é enviado. No Flux essa chamada é
recebida pelo notification controller, por meio de um `Receiver`, que manda o source controller buscar
na hora.

## A ponta que recebe

Um webhook que qualquer um pudesse chamar deixaria qualquer um fazer o Flux buscar, então a chamada é
assinada. O segredo compartilhado é um texto aleatório que vive em dois lugares, o cluster e o Gitea,
e nunca no `fleet`:

```sh
openssl rand -hex 20 > ~/webhook.token && chmod 600 ~/webhook.token
kubectl -n flux-system create secret generic webhook-token --from-literal=token="$(cat ~/webhook.token)"
```

O Receiver e um caminho de fora do cluster para ele vão para o `fleet`. O Gitea roda ao lado do
cluster, não dentro, então não alcança um Service ClusterIP; um Service NodePort na porta de
recebimento do notification controller dá a ele um endereço no nó. Salve isto como
`clusters/lab/webhook.yaml`:

```yaml
apiVersion: notification.toolkit.fluxcd.io/v1
kind: Receiver
metadata:
  name: gitea
  namespace: flux-system
spec:
  type: github
  events: ["ping", "push"]
  secretRef:
    name: webhook-token
  resources:
  - kind: GitRepository
    name: flux-system
---
apiVersion: v1
kind: Service
metadata:
  name: webhook-receiver-node
  namespace: flux-system
spec:
  type: NodePort
  selector:
    app: notification-controller
  ports:
  - port: 80
    targetPort: 9292
    nodePort: 30082
```

O `type: github` não é engano. O Gitea assina os webhooks dele do jeito do GitHub, com um HMAC do
corpo no cabeçalho `X-Hub-Signature-256`, então o receptor de GitHub do Flux os confere. O pull request
passa como sempre, e depois que o Flux o aplica, o Receiver tem um caminho:

```
ana@laptop:~/fleet$ openssl rand -hex 20 > ~/webhook.token && chmod 600 ~/webhook.token
ana@laptop:~/fleet$ kubectl -n flux-system create secret generic webhook-token --from-literal=token="$(cat ~/webhook.token)"
secret/webhook-token created
ana@laptop:~/fleet$ git switch --quiet -c webhook
ana@laptop:~/fleet$ git add clusters/lab/webhook.yaml
ana@laptop:~/fleet$ git commit --quiet -m "flux: a receiver for the Gitea webhook"
ana@laptop:~/fleet$ kubectl -n flux-system get receiver gitea
NAME    AGE   READY   STATUS
gitea   6s    True    Receiver initialized for path: /hook/cd7d996da164a97747cde971c3693d52be4dd248170bf2ed445bf3cbe9b4b19d
```

O caminho é um hash do nome e do token do Receiver. **Adivinhá-lo não basta para disparar uma
busca**, porque uma requisição sem a assinatura certa é recusada; ele só precisa ser imprevisível o
bastante para ninguém tropeçar nele.

## A ponta que chama

O Gitea se recusa, por padrão, a chamar endereços privados, o que é uma defesa sensata para um
servidor na internet: um webhook é um jeito de fazer o servidor mandar requisições em nome de alguém.
O endereço do nó é privado, então este Gitea fica sabendo que endereços privados são permitidos, no
arquivo de configuração dele, e é reiniciado:

```sh
docker exec gitea sed -i '/^\[security\]$/a ALLOWED_HOST_LIST = private' /etc/gitea/app.ini
docker restart gitea
```

Depois, o próprio webhook, no `fleet`, com o mesmo segredo e o caminho do Receiver:

```
ana@laptop:~/fleet$ docker exec gitea grep -A1 '^\[security\]$' /etc/gitea/app.ini
[security]
ALLOWED_HOST_LIST = private
ana@laptop:~/fleet$ HOOK_PATH=$(kubectl -n flux-system get receiver gitea -o jsonpath='{.status.webhookPath}')
ana@laptop:~/fleet$ curl -s -H "$AS_ANA" -H "$JSON" -d "{\"type\": \"gitea\", \"events\": [\"push\"], \"active\": true, \"config\": {\"url\": \"http://gitops-control-plane:30082$HOOK_PATH\", \"content_type\": \"json\", \"secret\": \"$(cat ~/webhook.token)\"}}" $API/hooks | jq '{id, type, events, active}'
{
  "id": 1,
  "type": "gitea",
  "events": [
    "push"
  ],
  "active": true
}
```

## A diferença que isso faz

Uma mudança no staging, pelo pull request de sempre. Desta vez ninguém digita `flux reconcile`:

```
ana@laptop:~/fleet$ git switch --quiet -c webhook-banner
ana@laptop:~/fleet$ git commit --quiet -am "staging: updated by a webhook"
ana@laptop:~/fleet$ git log -1 --format="%h %s"
218c0ba Merge pull request 'staging: updated by a webhook' (#7) from webhook-banner into main
ana@laptop:~/fleet$ flux get kustomizations staging
NAME   	REVISION          	SUSPENDED	READY	MESSAGE                              
staging	main@sha1:218c0baa	False    	True 	Applied revision: main@sha1:218c0baa	
ana@laptop:~/fleet$ curl -s localhost:8080
bulletin 1.0
message: Staging is updated by a webhook.
token: none
```

Dez segundos depois do merge, sem ninguém digitar `flux reconcile`, o staging roda o commit novo. O
Gitea chamou o Receiver, o source controller buscou e o kustomize controller reagiu ao artefato novo,
contra o minuto do intervalo do `GitRepository` e os dez minutos da Kustomization. Os intervalos
ficam, como a rede de segurança para um webhook que se perdeu.
