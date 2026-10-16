---
title: A organização, por aplicação e ambiente
version: 1
---

**O `fleet` cresceu por acréscimo**: `staging/` na raiz desde a aula 1, `clusters/lab/` desde a aula
4. Esta seção dá a ele a forma que o resto do curso mantém:

```
fleet/
  apps/bulletin/staging/       what bulletin is in staging
  apps/bulletin/production/    what bulletin is in production (the next section)
  clusters/lab/                what this cluster runs: Flux itself, and one file per environment
```

`apps/` responde "do que esta aplicação precisa, por ambiente". `clusters/` responde "o que este
cluster roda", e cada arquivo ali aponta para uma pasta em `apps/`. Uma segunda aplicação é uma
segunda pasta em `apps/`; um segundo cluster é uma segunda pasta em `clusters/`.

## Mudando o staging de lugar

A mudança são duas alterações num pull request: `git mv` da pasta, e apontar a Kustomization do
staging para o caminho novo. Uma coisa fora do `fleet` também conhece o caminho antigo: o
`validate.sh` da aula 2 confere `$work/staging`, que está para deixar de existir. Aponte-o para
`apps/` antes, para ele conferir toda aplicação e todo ambiente daqui em diante:

```sh
sed -i 's#"$work/staging"#"$work/apps"#' ~/setup/validate.sh
```

```
ana@laptop:~/fleet$ git switch --quiet -c layout
ana@laptop:~/fleet$ mkdir -p apps/bulletin
ana@laptop:~/fleet$ git mv staging apps/bulletin/staging
ana@laptop:~/fleet$ git diff | grep '^[-+] '
-  path: ./staging
+  path: ./apps/bulletin/staging
ana@laptop:~/fleet$ git status --short
R  staging/bulletin.yaml -> apps/bulletin/staging/bulletin.yaml
 M clusters/lab/staging.yaml
ana@laptop:~/fleet$ kubectl -n staging get pods
NAME                        READY   STATUS    RESTARTS   AGE
bulletin-6b88476dc4-7pscf   1/1     Running   0          35s
bulletin-6b88476dc4-q9km6   1/1     Running   0          46s
bulletin-6b88476dc4-tjrjf   1/1     Running   0          34s
ana@laptop:~/fleet$ git commit --quiet -am "fleet: apps/bulletin/staging"
```

Depois do merge, o Flux aplicou os mesmos objetos a partir do caminho novo:

```
ana@laptop:~/fleet$ flux get kustomizations staging
NAME   	REVISION          	SUSPENDED	READY	MESSAGE                              
staging	main@sha1:ee8f6633	False    	True 	Applied revision: main@sha1:ee8f6633	
ana@laptop:~/fleet$ kubectl -n staging get pods
NAME                        READY   STATUS    RESTARTS   AGE
bulletin-6b88476dc4-7pscf   1/1     Running   0          50s
bulletin-6b88476dc4-q9km6   1/1     Running   0          61s
bulletin-6b88476dc4-tjrjf   1/1     Running   0          49s
```

Os pods têm os mesmos nomes da listagem feita antes do commit: **nada foi
recriado.** Os objetos são os mesmos
objetos, da mesma Kustomization, lidos de outra pasta. Uma mudança de lugar no Git não é uma remoção no
cluster, desde que a mesma Kustomization continue dona do que mudou. Se a mudança tivesse ido para uma
pasta que *outra* Kustomization lê, a primeira teria podado os objetos e a segunda os criaria de novo,
o que para um Deployment quer dizer pods novos e para um PersistentVolumeClaim pode querer dizer um
disco vazio.
