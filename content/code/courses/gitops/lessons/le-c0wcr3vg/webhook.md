---
title: A push that reaches the cluster in seconds
version: 1
---

**Polling is the reason a merge takes a minute or three to arrive**, in Flux as in Argo CD. The cure
is the same in both: the Git server calls the agent when something is pushed. In Flux that call is
received by the notification controller, through a `Receiver`, which tells the source controller to
fetch at once.

## The receiving end

A webhook that anybody could call would let anybody make Flux fetch, so the call is signed. The
shared secret is a random string that lives in two places, the cluster and Gitea, and never in
`fleet`:

```sh
openssl rand -hex 20 > ~/webhook.token && chmod 600 ~/webhook.token
kubectl -n flux-system create secret generic webhook-token --from-literal=token="$(cat ~/webhook.token)"
```

The Receiver and a way in from outside the cluster go into `fleet`. Gitea runs beside the cluster,
not in it, so it cannot reach a ClusterIP Service; a NodePort Service on the notification controller's
receiver port gives it an address on the node. Save this as `clusters/lab/webhook.yaml`:

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

`type: github` is not a mistake. Gitea signs its webhooks the way GitHub does, with an HMAC of the
body in the `X-Hub-Signature-256` header, so Flux's GitHub receiver checks them. The pull request
goes through as usual, and once Flux has applied it, the Receiver has a path:

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

The path is a hash of the Receiver's name and token. **Guessing it is not enough to trigger a fetch**,
because a request without the right signature is refused; it only has to be unpredictable enough
that nobody stumbles on it.

## The calling end

Gitea refuses by default to call private addresses, which is a sensible defence for a server on the
internet: a webhook is a way to make the server send requests on somebody's behalf. The node's
address is private, so this Gitea is told that private addresses are allowed, in its configuration
file, and restarted:

```sh
docker exec gitea sed -i '/^\[security\]$/a ALLOWED_HOST_LIST = private' /etc/gitea/app.ini
docker restart gitea
```

Then the webhook itself, on `fleet`, with the same secret and the path from the Receiver:

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

## The difference it makes

A change to staging, through the usual pull request. This time nobody types `flux reconcile`:

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

Ten seconds after the merge, with nobody typing `flux reconcile`, staging runs the new commit.
Gitea called the Receiver, the source controller fetched, and the kustomize controller reacted to
the new artifact, against the minute of the `GitRepository` interval and the ten minutes of the
Kustomization's. The intervals stay, as the safety net for a webhook that was lost.
