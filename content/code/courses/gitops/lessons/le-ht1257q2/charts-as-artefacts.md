---
title: Charts are artefacts too
version: 1
---

**Lesson 6's chart is read straight from `fleet`, as files.** That works, and it means the chart in
production is whatever the chart directory says at the revision Flux applied, built on the fly. A
published chart is the alternative: packaged once, with a version, pushed to a registry, and pulled
by digest like an image. Helm speaks OCI, so the course's registry holds charts as well:

```
ana@laptop:~/fleet$ helm package charts/bulletin
Successfully packaged chart and saved it to: /home/ana/fleet/bulletin-0.1.0.tgz
ana@laptop:~/fleet$ helm push bulletin-0.1.0.tgz oci://localhost:5001/charts --plain-http
Pushed: localhost:5001/charts/bulletin:0.1.0
Digest: sha256:6fcc8b2304d203065ad70cd24737552e697e4a45fe54555d5356e1b1e92f1aa3
```

`--plain-http` because this registry has no TLS, which is acceptable on `localhost` and nowhere else.
The chart is now `localhost:5001/charts/bulletin:0.1.0`, with a digest like any image.

Flux reads it with an `OCIRepository`, and the HelmRelease points at that instead of a path in Git.
The two go in one file, and this is the whole of `apps/bulletin/preview/release.yaml` now:

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

The address is `registry:5000` from inside the cluster, for the reason lesson 1 gave about
`localhost`, and `insecure: true` for the same reason as `--plain-http`. `validate.sh` meets one more
kind whose schema is Flux's, so it skips that one too:

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

The release went from revision 1 to revision 2 when its source changed from the Git path to the
published chart, with the same values. **From now on, changing the preview's chart is publishing a
new chart version and changing one tag in Git**, the same shape as an image release, and lesson 8
adds the step that makes Flux refuse a chart nobody signed.
