---
title: Charts também são artefatos
version: 1
---

**O chart da aula 6 é lido direto do `fleet`, como arquivos.** Isso funciona, e quer dizer que o chart
na produção é o que a pasta do chart disser na revisão que o Flux aplicou, montado na hora. Um chart
publicado é a alternativa: empacotado uma vez, com uma versão, enviado a um registry e baixado pelo
digest como uma imagem. O Helm fala OCI, então o registry do curso guarda charts também:

```
ana@laptop:~/fleet$ helm package charts/bulletin
Successfully packaged chart and saved it to: /home/ana/fleet/bulletin-0.1.0.tgz
ana@laptop:~/fleet$ helm push bulletin-0.1.0.tgz oci://localhost:5001/charts --plain-http
Pushed: localhost:5001/charts/bulletin:0.1.0
Digest: sha256:6fcc8b2304d203065ad70cd24737552e697e4a45fe54555d5356e1b1e92f1aa3
```

`--plain-http` porque este registry não tem TLS, o que é aceitável em `localhost` e em nenhum outro
lugar. O chart agora é `localhost:5001/charts/bulletin:0.1.0`, com um digest como qualquer imagem.

O Flux o lê com um `OCIRepository`, e o HelmRelease aponta para ele no lugar de um caminho no Git. Os dois
ficam num arquivo só, e este é o `apps/bulletin/preview/release.yaml` inteiro agora:

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

O endereço é `registry:5000` de dentro do cluster, pelo motivo que a aula 1 deu sobre `localhost`, e
`insecure: true` pelo mesmo motivo do `--plain-http`. O `validate.sh` encontra mais um tipo cujo
schema é do Flux, então pula esse também:

```sh
sed -i 's/-skip HelmRelease /-skip HelmRelease,OCIRepository /' ~/setup/validate.sh
```

```
ana@laptop:~/fleet$ git switch --quiet -c preview-oci
ana@laptop:~/fleet$ git commit --quiet -am "preview: the published chart"
ana@laptop:~/fleet$ flux get sources oci -n preview
NAME          	REVISION             	SUSPENDED	READY	MESSAGE                                            
bulletin-chart	0.1.0@sha256:6fcc8b23	False    	True 	stored artifact for digest '0.1.0@sha256:6fcc8b23'	
ana@laptop:~/fleet$ helm history bulletin -n preview
REVISION	UPDATED                 	STATUS    	CHART                      	APP VERSION	DESCRIPTION     
1       	Sat Oct 10 07:10:08 2026	superseded	bulletin-0.1.0             	1.1        	Install complete
2       	Sat Oct 10 07:12:24 2026	deployed  	bulletin-0.1.0+6fcc8b2304d2	1.1        	Upgrade complete
```

O release foi da revisão 1 para a 2 quando a fonte dele mudou do caminho no Git para o chart
publicado, com os mesmos valores. **Daqui em diante, mudar o chart da prévia é publicar uma versão nova
do chart e mudar uma tag no Git**, a mesma forma de um release de imagem, e a aula 8 acrescenta o passo
que faz o Flux recusar um chart que ninguém assinou.
