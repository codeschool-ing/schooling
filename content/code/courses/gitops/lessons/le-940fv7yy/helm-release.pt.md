---
title: Um chart instalado pelo Flux
version: 1
---

**O Flux instala um chart com o código do próprio Helm, como um release do Helm de verdade**, então
tudo o que o Helm sabe de um release, o histórico, os valores e o rollback, está ali para quem tiver o
comando `helm`. O chart vem de uma fonte como tudo o mais; aqui é a pasta `charts/bulletin` do
`fleet`, lida pelo mesmo `GitRepository` que o Flux já tem.

Um terceiro ambiente o usa, uma prévia que ninguém alcança de fora. Salve isto como
`apps/bulletin/preview/release.yaml`:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: bulletin
  namespace: preview
spec:
  interval: 10m
  chart:
    spec:
      chart: ./charts/bulletin
      sourceRef:
        kind: GitRepository
        name: flux-system
        namespace: flux-system
  values:
    message: A preview, installed by Helm.
```

isto como `apps/bulletin/preview/namespace.yaml`, as mesmas três linhas do staging com `preview` no
lugar de `staging`, e isto como `apps/bulletin/preview/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- namespace.yaml
- release.yaml
```

e um terceiro arquivo em `clusters/lab/`, o `clusters/lab/preview.yaml`, que é o `staging.yaml` com
`preview` no lugar de `staging` no nome e no caminho. O HelmRelease sobrescreve um valor, a mensagem,
e pega o resto do `values.yaml`.

```
ana@laptop:~/fleet$ git add charts apps/bulletin/preview clusters/lab/preview.yaml
ana@laptop:~/fleet$ cat clusters/lab/preview.yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: preview
  namespace: flux-system
spec:
  interval: 10m
  path: ./apps/bulletin/preview
  prune: true
  wait: true
  timeout: 2m
  sourceRef:
    kind: GitRepository
    name: flux-system
ana@laptop:~/fleet$ git commit --quiet -m "bulletin: a chart, and a preview installed from it"
ana@laptop:~/fleet$ flux get helmreleases -n preview
NAME    	REVISION	SUSPENDED	READY	MESSAGE                                                                          
bulletin	0.1.0   	False    	True 	Helm install succeeded for release preview/bulletin.v1 with chart bulletin@0.1.0	
ana@laptop:~/fleet$ helm list -n preview
NAME    	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART         	APP VERSION
bulletin	preview  	1       	2026-10-10 06:25:09.524456214 +0000 UTC	deployed	bulletin-0.1.0	1.1        
ana@laptop:~/fleet$ helm history bulletin -n preview
REVISION	UPDATED                 	STATUS  	CHART         	APP VERSION	DESCRIPTION     
1       	Sat Oct 10 06:25:09 2026	deployed	bulletin-0.1.0	1.1        	Install complete
ana@laptop:~/fleet$ kubectl -n preview exec deploy/bulletin -- wget -qO- localhost:8080
bulletin 1.1
message: A preview, installed by Helm.
pod: bulletin-94d74b59f-jmsvg
token: none
```

O helm controller gerou o chart com esses valores e o instalou. **O `helm list` e o `helm history`
enxergam o release que o Flux fez**, porque é um release comum do Helm, guardado onde o Helm os
guarda, num Secret no namespace do release. A página responde de dentro do pod, já que nada liga uma
porta da sua máquina à prévia.

O Argo CD trata o mesmo chart de outro jeito, como a comparação da aula 4 disse: ele gera os templates
com os mesmos valores e aplica os manifestos, e o `helm list` não mostra nada. Os dois são razoáveis;
o que importa é saber qual você roda antes de recorrer ao `helm rollback` durante um incidente.
