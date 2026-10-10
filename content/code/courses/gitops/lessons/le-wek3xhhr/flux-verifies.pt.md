---
title: O Flux recusa o que ninguém assinou
version: 1
---

**O Flux verifica os artefatos que ele mesmo puxa.** Um `OCIRepository` aceita um campo `verify` que
nomeia o provedor, `cosign`, e um Secret com as chaves públicas; o source controller então confere a
assinatura de cada revisão antes que qualquer coisa adiante a veja. O chart da preview é um artefato
desses desde a aula 7, então é ele que se protege. Ele é assinado exatamente como a imagem, pelo
digest:

```
ana@laptop:~/signing$ CHART=$(curl -sI -H "Accept: application/vnd.oci.image.manifest.v1+json" localhost:5001/v2/charts/bulletin/manifests/0.1.0 | tr -d "\r" | awk "tolower(\$1) == \"docker-content-digest:\" { print \$2 }"); echo $CHART
sha256:98ccc0c8f616bc465570547bcc817f20ef82781b806664bc68b5f5aa048bc21d
ana@laptop:~/signing$ cosign sign --key cosign.key --signing-config offline.json -y localhost:5001/charts/bulletin@$CHART
WARNING: Could not fetch trusted_root.json from the TUF repository. Continuing with individual targets. Error from TUF: error getting live trusted root: failed to create TUF client failed to load metadata: tuf refresh failed: Get "https://tuf-repo-cdn.sigstore.dev/15.root.json": Forbidden
Signing artifact...
Pushing signature to: localhost:5001/charts/bulletin
```

A chave pública entra no cluster do jeito GitOps, pelo repositório. Ela não é segredo, então pode
ficar no Git como arquivo, e o Kustomize faz o Secret a partir dela. Este é o
`apps/bulletin/preview/kustomization.yaml` depois da mudança:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- namespace.yaml
- release.yaml
secretGenerator:
- name: cosign-pub
  namespace: preview
  files:
  - cosign.pub
generatorOptions:
  disableNameSuffixHash: true
```

O `disableNameSuffixHash` mantém o nome fixo, porque o `OCIRepository` o referencia e não é um dos
objetos que o Kustomize sabe reescrever. E este é o `OCIRepository` em
`apps/bulletin/preview/release.yaml`, com o HelmRelease abaixo dele sem mudança:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: bulletin-chart
  namespace: preview
spec:
  interval: 10m
  url: oci://registry:5000/charts/bulletin
  insecure: true
  ref:
    tag: 0.1.0
  verify:
    provider: cosign
    secretRef:
      name: cosign-pub
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: bulletin
  namespace: preview
spec:
  interval: 10m
  chartRef:
    kind: OCIRepository
    name: bulletin-chart
  values:
    message: A preview, installed by Helm.
```

```
ana@laptop:~/fleet$ git switch --quiet -c preview-verify
ana@laptop:~/fleet$ cp ~/signing/cosign.pub apps/bulletin/preview/
ana@laptop:~/fleet$ git diff | grep '^[-+] '
+  namespace: preview
+  files:
+  - cosign.pub
+  disableNameSuffixHash: true
+  verify:
+    provider: cosign
+    secretRef:
+      name: cosign-pub
ana@laptop:~/fleet$ git add apps && git commit --quiet -m "preview: only a signed chart"
ana@laptop:~/fleet$ flux get sources oci -n preview
NAME          	REVISION             	SUSPENDED	READY	MESSAGE                                            
bulletin-chart	0.1.0@sha256:98ccc0c8	False    	True 	stored artifact for digest '0.1.0@sha256:98ccc0c8'	
ana@laptop:~/fleet$ kubectl -n preview get ocirepository bulletin-chart -o jsonpath='{.status.conditions[?(@.type=="SourceVerified")].message}'; echo
verified signature of revision 0.1.0@sha256:98ccc0c8f616bc465570547bcc817f20ef82781b806664bc68b5f5aa048bc21d
```

O `SourceVerified` diz em palavras: o Flux baixou o chart, achou uma assinatura ao lado do digest e
a conferiu com a chave em `cosign-pub` antes de entregar o chart ao controlador do Helm.

## Um chart que ninguém assinou

Alguém publica a `0.1.1` do chart e a propõe para a preview, num pull request como toda mudança. O
chart está bom; só nunca foi assinado.

```
ana@laptop:~/fleet$ git switch --quiet -c preview-0.1.1
ana@laptop:~/fleet$ git diff | grep '^[-+] '
-    tag: 0.1.0
+    tag: 0.1.1
ana@laptop:~/fleet$ git commit --quiet -am "preview: chart 0.1.1"
ana@laptop:~/fleet$ flux get sources oci -n preview
NAME          	REVISION             	SUSPENDED	READY	MESSAGE                                                                                                                                       
bulletin-chart	0.1.0@sha256:98ccc0c8	False    	False	failed to verify the signature using provider 'cosign': no matching signatures were found for 'registry:5000/charts/bulletin@sha256:1bb62840'	
ana@laptop:~/fleet$ helm list -n preview
NAME    	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART                      	APP VERSION
bulletin	preview  	2       	2026-10-10 19:42:55.090250565 +0000 UTC	deployed	bulletin-0.1.0+98ccc0c8f616	1.1        
```

Leia a linha com cuidado. `READY` é `False`, e a mensagem nomeia o digest da 0.1.1 e diz que nenhuma
assinatura bateu. A coluna `REVISION` ainda diz 0.1.0, porque essa é a última revisão que a fonte
aceitou, e o `helm list` concorda: **a preview continua rodando o chart assinado** enquanto o não
assinado é recusado.

**Esta é a propriedade que a aula procura**: o pull request passou pela revisão e pelo CI, o merge
aconteceu, e o cluster recusou mesmo assim, porque a garantia não depende de alguém perceber. A saída
é assinar a `0.1.1` ou voltar para a `0.1.0`, e as duas são decisões com um nome nelas.
