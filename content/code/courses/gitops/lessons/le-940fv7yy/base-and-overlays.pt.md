---
title: Uma base e dois overlays
version: 1
---

**A base é o que todo ambiente tem em comum, e ela não diz nada sobre nenhum deles.** Nem namespace,
nem um número de réplicas que valha guardar, nem tag de imagem, nem mensagem. No `fleet`, num branch
novo, a base são três arquivos em `apps/bulletin/base/`. Salve isto como
`apps/bulletin/base/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bulletin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bulletin
  template:
    metadata:
      labels:
        app: bulletin
    spec:
      containers:
      - name: bulletin
        image: localhost:5001/bulletin
        envFrom:
        - configMapRef:
            name: bulletin
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /
            port: 8080
```

isto como `apps/bulletin/base/service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: bulletin
spec:
  type: NodePort
  selector:
    app: bulletin
  ports:
  - port: 80
    targetPort: 8080
```

e isto como `apps/bulletin/base/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yaml
- service.yaml
```

A mensagem não fica mais no Deployment: ela vem de um ConfigMap chamado `bulletin`, por `envFrom`, e
cada ambiente gera o seu. A próxima seção diz por que isso é melhor que um valor no Deployment.

## O staging, como overlay

Um overlay lista a base como recurso e depois diz o que é diferente. Salve isto como
`apps/bulletin/staging/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: staging
resources:
- namespace.yaml
- ../base
replicas:
- name: bulletin
  count: 3
images:
- name: localhost:5001/bulletin
  newTag: "1.1"
configMapGenerator:
- name: bulletin
  literals:
  - MESSAGE=Staging is updated by a webhook.
patches:
- target:
    kind: Service
    name: bulletin
  patch: |-
    - op: add
      path: /spec/ports/0/nodePort
      value: 30080
```

e o namespace dele como `apps/bulletin/staging/namespace.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: staging
```

Cada linha do overlay é algo que o staging decide: o namespace, as réplicas, o release, a mensagem e a
porta. **Ler o overlay é ler o que faz do staging o staging**, que é o que o diff de dois arquivos
inteiros tentou e não conseguiu mostrar. O overlay da produção tem a mesma forma, com as respostas da
produção, mais uma coisa que o staging não tem e que a próxima seção acrescenta. O antigo
`bulletin.yaml` de cada pasta é apagado.

## Conferindo o resultado antes de alguém fazer o merge

O `kubectl kustomize` monta um overlay em manifestos simples, exatamente o que o Flux vai aplicar, e o
`kubectl diff` os compara com os objetos vivos. Duas flags tornam a comparação honesta: o `--server-side`
pede ao servidor da API um ensaio do apply, e o `--field-manager=kustomize-controller` faz o ensaio
aplicar como o Flux aplica, como dono dos campos que o Flux definiu. Sem elas o diff mostra o que o
*seu* `kubectl apply` mudaria, que para um campo de que o Flux é dono e você não, como o `env` antigo,
é nada:

```
ana@laptop:~/fleet$ git switch --quiet -c kustomize
ana@laptop:~/fleet$ find apps -type f | sort
apps/bulletin/base/deployment.yaml
apps/bulletin/base/kustomization.yaml
apps/bulletin/base/service.yaml
apps/bulletin/production/kustomization.yaml
apps/bulletin/production/namespace.yaml
apps/bulletin/staging/kustomization.yaml
apps/bulletin/staging/namespace.yaml
ana@laptop:~/fleet$ kubectl kustomize apps/bulletin/staging | grep -A4 '^kind: ConfigMap'
kind: ConfigMap
metadata:
  name: bulletin-t55m2kmd94
  namespace: staging
---
ana@laptop:~/fleet$ kubectl diff --server-side --field-manager=kustomize-controller -k apps/bulletin/staging | grep '^[-+] '
-  generation: 5
-  labels:
-    kustomize.toolkit.fluxcd.io/name: staging
-    kustomize.toolkit.fluxcd.io/namespace: flux-system
+  generation: 6
-      - env:
-        - name: MESSAGE
-          value: Staging is updated by a webhook.
+      - envFrom:
+        - configMapRef:
+            name: bulletin-t55m2kmd94
+  MESSAGE: Staging is updated by a webhook.
+  creationTimestamp: "2026-10-10T06:24:30Z"
+  name: bulletin-t55m2kmd94
+  namespace: staging
+  uid: ce10691e-4d23-4b3e-9577-cb0a176e4420
-    kustomize.toolkit.fluxcd.io/name: staging
-    kustomize.toolkit.fluxcd.io/namespace: flux-system
-  labels:
-    kustomize.toolkit.fluxcd.io/name: staging
-    kustomize.toolkit.fluxcd.io/namespace: flux-system
```

Leia em três grupos. Os rótulos `kustomize.toolkit.fluxcd.io` são do próprio Flux: ele os põe em
tudo o que aplica, então aparecem como removidos aqui e voltam depois do merge. `generation`,
`creationTimestamp` e `uid` são a contabilidade do API server para um objeto que muda ou é criado. O
que sobra é a mudança em si: a mensagem chega por um ConfigMap cujo nome termina num hash, em vez de
uma entrada `env`, e isso muda o template do pod, então os pods vão ser trocados uma vez. **Nada mais
muda**: nenhum namespace, número de réplicas, imagem ou porta aparece no diff. Essa é a conferência
que vale fazer antes do merge de uma reorganização como esta, porque o diff do próprio pull request
só mostra arquivos apagados e arquivos criados.

## A checagem cresce com a organização

O `validate.sh` da aula 2 entregava ao `kubeconform` uma pasta de manifestos. Uma pasta de overlays não
é isso: o `kustomization.yaml` não é um objeto do Kubernetes, e os objetos só existem depois que o
overlay é montado. Então a checagem monta cada pasta em `apps/` que tenha um `kustomization.yaml` e
valida o que sai. Este é o `~/setup/validate.sh`, reescrito:

```sh
#!/bin/sh
# The course's CI: build and check every overlay of one commit of fleet, and
# report the result to Gitea.
# Usage: sh validate.sh COMMIT
sha=$1 api=http://localhost:3000/api/v1/repos/ana/fleet
work=$(mktemp -d)
git clone --quiet http://localhost:3000/ana/fleet.git "$work/fleet"
git -C "$work/fleet" checkout --quiet "$sha"
state=success text="every overlay builds and validates"
for dir in "$work"/fleet/apps/*/*; do
  [ -f "$dir/kustomization.yaml" ] || continue
  name=$(basename "$(dirname "$dir")")/$(basename "$dir")
  if ! kubectl kustomize "$dir" > "$work/out.yaml"; then
    state=failure text="$name does not build"
  elif ! kubeconform -strict -summary -skip HelmRelease -kubernetes-version 1.37.0 "$work/out.yaml"; then
    state=failure text="$name does not validate"
  fi
done
curl -s -o /dev/null -H "Authorization: token $(cat ~/ci.token)" \
  -H 'Content-Type: application/json' \
  -d "{\"state\": \"$state\", \"context\": \"validate\", \"description\": \"$text\"}" \
  "$api/statuses/$sha"
echo "validate: $state"
rm -rf "$work"
```

A montagem vai para um arquivo e não para um pipe, para que um overlay que não monta faça a checagem
falhar em vez de entregar nada ao `kubeconform`. O `-skip HelmRelease` é o único tipo que ele não
consegue validar, porque o schema dele é do Flux e não do Kubernetes, e esse tipo chega no fim desta
aula. Rodado contra a ponta do pull request, ele monta a base e os dois overlays:

```
ana@laptop:~/fleet$ git commit --quiet -m "bulletin: a base and two overlays"
ana@laptop:~/fleet$ git push --quiet -u origin kustomize 2>/dev/null
ana@laptop:~/fleet$ sh ~/setup/validate.sh $(git rev-parse HEAD)
Summary: 2 resources found in 1 file - Valid: 2, Invalid: 0, Errors: 0, Skipped: 0
Summary: 4 resources found in 1 file - Valid: 4, Invalid: 0, Errors: 0, Skipped: 0
Summary: 4 resources found in 1 file - Valid: 4, Invalid: 0, Errors: 0, Skipped: 0
validate: success
```
