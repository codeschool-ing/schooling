---
title: Instalando o Argo CD
version: 1
---

**O Argo CD é instalado do jeito que ele instala todo o resto: aplicando manifestos.** O projeto
publica um arquivo por versão com todos os objetos de que precisa, e um arquivo do Kustomize de três
linhas aponta para ele. Salve isto como `~/setup/argocd/kustomization.yaml`:

```yaml
namespace: argocd
resources:
- https://raw.githubusercontent.com/argoproj/argo-cd/v3.5.4/manifests/install.yaml
# The machine these transcripts were recorded on cannot reach quay.io or
# ghcr.io; it runs images built from Argo CD's released binary and from Dex's
# tagged source, from its own registry. Delete these five lines on yours.
images:
- name: quay.io/argoproj/argocd
  newName: localhost:5001/lab/argocd
- name: ghcr.io/dexidp/dex
  newName: localhost:5001/lab/dex
```

A versão está fixada, `v3.5.4`, e esse é o hábito que o curso pede em todo lugar: **uma URL que cita
uma versão quer dizer sempre os mesmos bytes**, e atualizar o Argo CD vira uma mudança de uma linha
neste arquivo, revisada como qualquer outra. O Kustomize, que o `kubectl` já traz embutido, baixa o
arquivo e põe o namespace em todos os objetos dele. A aula 6 é sobre o próprio Kustomize.

```
ana@laptop:~/setup$ kubectl create namespace argocd
namespace/argocd created
ana@laptop:~/setup$ kubectl apply --server-side -k argocd/ | tail -n 3
networkpolicy.networking.k8s.io/argocd-redis-network-policy serverside-applied
networkpolicy.networking.k8s.io/argocd-repo-server-network-policy serverside-applied
networkpolicy.networking.k8s.io/argocd-server-network-policy serverside-applied
ana@laptop:~/setup$ kubectl -n argocd wait --for=condition=Available deployment --all --timeout=300s
deployment.apps/argocd-applicationset-controller condition met
deployment.apps/argocd-dex-server condition met
deployment.apps/argocd-notifications-controller condition met
deployment.apps/argocd-redis condition met
deployment.apps/argocd-repo-server condition met
deployment.apps/argocd-server condition met
ana@laptop:~/setup$ kubectl -n argocd get statefulsets
NAME                            READY   AGE
argocd-application-controller   1/1     46s
```

O `--server-side` é necessário e não uma questão de estilo: as definições de recurso do próprio Argo
CD são maiores do que a anotação que um apply do lado do cliente guarda, e são recusadas sem ele.
**Seis deployments e um statefulset**, cada um uma das partes da seção anterior, e o `wait` segurou o
terminal até todos os deployments ficarem disponíveis. O cluster agora usa mais memória do que antes:

```
ana@laptop:~/setup$ docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}" gitops-control-plane registry gitea
NAME                   MEM USAGE / LIMIT
gitops-control-plane   1.306GiB / 15.72GiB
registry               66.81MiB / 15.72GiB
gitea                  104.2MiB / 15.72GiB
```

## O comando

O comando `argocd` é mais um arquivo único, da mesma versão, conferido do mesmo jeito:

```
ana@laptop:~$ ARCH=$(dpkg --print-architecture)
ana@laptop:~$ curl -fsSLo argocd https://github.com/argoproj/argo-cd/releases/download/v3.5.4/argocd-linux-$ARCH
ana@laptop:~$ curl -fsSL https://github.com/argoproj/argo-cd/releases/download/v3.5.4/cli_checksums.txt | grep " argocd-linux-$ARCH$" | sed "s/argocd-linux-$ARCH/argocd/" | sha256sum --check
argocd: OK
ana@laptop:~$ sudo install -m 0755 argocd /usr/local/bin/ && rm argocd
ana@laptop:~$ argocd version --client --short
argocd: v3.5.4+d6d5b24
```

O `argocd` normalmente fala com o API server do Argo CD, o que pede um login, um port-forward ou um
ingress, e uma senha. **O modo `--core` pula tudo isso** e fala direto com a API do Kubernetes, com o
seu kubeconfig, lendo e escrevendo os objetos do Argo CD no namespace para onde o seu contexto
aponta. Para um laboratório em que você já tem as credenciais de administrador do cluster é o
caminho mais curto, e todo comando deste curso o usa:

```
ana@laptop:~$ kubectl config set-context --current --namespace=argocd
Context "kind-gitops" modified.
ana@laptop:~$ argocd login --core
Context 'kubernetes' updated
```

## A interface web

A interface web do Argo CD desenha cada Application como uma árvore dos objetos que ela possui, o que
vale ver uma vez. Ela não é necessária para nada neste curso, e estes comandos não foram executados
para ela:

```sh
argocd admin initial-password -n argocd
kubectl -n argocd port-forward svc/argocd-server 8443:443
```

O primeiro imprime a senha gerada do usuário `admin`; o segundo faz o API server responder em
`https://localhost:8443`, com um certificado autoassinado sobre o qual o navegador avisa, até você
apertar `Ctrl+C`.
