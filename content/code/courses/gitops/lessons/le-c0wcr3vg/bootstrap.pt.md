---
title: Um bootstrap que passa por revisão
version: 1
---

**O `flux bootstrap` é o caminho de entrada habitual**: um comando que instala o Flux, faz commit dos
manifestos do próprio Flux no repositório e aponta o Flux para eles, para que dali em diante o Flux se
atualize e se conserte a partir do Git. Ele faz isso com um push na `main`. No `fleet`, ninguém faz
push na `main`, bootstrap inclusive, e isso é a regra funcionando. Então esta seção faz à mão as três
coisas que o `flux bootstrap` faz, e o commit passa por um pull request como todo o resto.

## Os manifestos, no repositório

Os componentes do Flux são um arquivo que o `flux install --export` escreve. Mais dois arquivos dizem
o que o Flux deve ler. No `~/fleet`, num branch novo:

```sh
mkdir -p clusters/lab/flux-system
flux install --export > clusters/lab/flux-system/gotk-components.yaml
```

Salve isto como `clusters/lab/flux-system/gotk-sync.yaml`:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: flux-system
  namespace: flux-system
spec:
  interval: 1m
  url: http://gitea:3000/ana/fleet.git
  ref:
    branch: main
  secretRef:
    name: fleet-auth
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: flux-system
  namespace: flux-system
spec:
  interval: 10m
  path: ./clusters/lab
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
```

e isto como `clusters/lab/flux-system/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- gotk-components.yaml
- gotk-sync.yaml
```

O `GitRepository` busca o `fleet` a cada minuto, com as credenciais de um Secret chamado
`fleet-auth` que esta seção cria e que nunca vai para o Git. A `Kustomization` chamada `flux-system`
aplica tudo o que está em `clusters/lab` a cada dez minutos, **o que inclui os manifestos do próprio
Flux**: daqui em diante, atualizar o Flux é um pull request que muda o `gotk-components.yaml`.

`clusters/lab/` é a pasta deste cluster. Qualquer outra coisa que este cluster deva rodar ganha um
arquivo ali, e o primeiro é o staging. Salve isto como `clusters/lab/staging.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: staging
  namespace: flux-system
spec:
  interval: 10m
  path: ./staging
  prune: true
  wait: true
  timeout: 2m
  sourceRef:
    kind: GitRepository
    name: flux-system
```

O `wait: true` faz o Flux esperar o que aplicou ficar pronto, até o `timeout`, antes de dizer que a
Kustomization está pronta: o status de sincronização e a saúde da aula 3, juntos numa resposta só.

```
ana@laptop:~/fleet$ git switch --quiet -c flux
ana@laptop:~/fleet$ mkdir -p clusters/lab/flux-system
ana@laptop:~/fleet$ flux install --export > clusters/lab/flux-system/gotk-components.yaml
ana@laptop:~/fleet$ git rm -r --quiet argocd
ana@laptop:~/fleet$ git add clusters
ana@laptop:~/fleet$ git status --short
D  argocd/bulletin-staging.yaml
D  argocd/project-bulletin.yaml
A  clusters/lab/flux-system/gotk-components.yaml
A  clusters/lab/flux-system/gotk-sync.yaml
A  clusters/lab/flux-system/kustomization.yaml
A  clusters/lab/staging.yaml
ana@laptop:~/fleet$ wc -l clusters/lab/flux-system/gotk-components.yaml
6092 clusters/lab/flux-system/gotk-components.yaml
ana@laptop:~/fleet$ git commit --quiet -m "flux: bootstrap the lab cluster; argocd retired"
```

O `git rm -r argocd` está no mesmo pull request, como a seção anterior disse. O diff é grande porque
o `gotk-components.yaml` é: todo tipo de recurso e todo controlador do Flux, 6092 linhas, escritas
por um programa e fixadas numa versão.

## Os três passos, à mão

Depois do merge, o cluster recebe os componentes do Flux, as credenciais e o ponteiro para o Git,
nessa ordem:

```
ana@laptop:~/fleet$ kubectl apply --server-side -f clusters/lab/flux-system/gotk-components.yaml | tail -n 2
service/webhook-receiver serverside-applied
deployment.apps/notification-controller serverside-applied
ana@laptop:~/fleet$ kubectl -n flux-system wait --for=condition=Available deployment --all --timeout=180s
deployment.apps/helm-controller condition met
deployment.apps/kustomize-controller condition met
deployment.apps/notification-controller condition met
deployment.apps/source-controller condition met
ana@laptop:~/fleet$ flux create secret git fleet-auth --url=http://gitea:3000/ana/fleet.git --username=flux --password="$(cat ~/flux.token)"
► git secret 'fleet-auth' created in 'flux-system' namespace
ana@laptop:~/fleet$ kubectl apply -f clusters/lab/flux-system/gotk-sync.yaml
gitrepository.source.toolkit.fluxcd.io/flux-system created
kustomization.kustomize.toolkit.fluxcd.io/flux-system created
ana@laptop:~/fleet$ flux get sources git
NAME       	REVISION          	SUSPENDED	READY	MESSAGE                                           
flux-system	main@sha1:e22a01dd	False    	True 	stored artifact for revision 'main@sha1:e22a01dd'	
ana@laptop:~/fleet$ flux get kustomizations
NAME       	REVISION          	SUSPENDED	READY	MESSAGE                              
flux-system	main@sha1:e22a01dd	False    	True 	Applied revision: main@sha1:e22a01dd	
staging    	main@sha1:e22a01dd	False    	True 	Applied revision: main@sha1:e22a01dd	
```

Do terceiro comando em diante, o cluster é do Flux. Ele buscou a `main`, aplicou o `clusters/lab`,
que criou a Kustomization `staging`, que aplicou o `staging/`. Os objetos que a aula 3 deixou foram
adotados sem ser recriados, e as duas Kustomizations informam o commit que aplicaram.
