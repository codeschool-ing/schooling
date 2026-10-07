---
title: A chart is templates plus values
version: 1
---

Helm is one more program on your machine beside `kubectl`, and it talks to the cluster through the
same kubeconfig. It installs the way lesson 1 installed `kind`, from the project's own release, checked
against the checksum published beside it, and this lesson starts with `./up.sh` and then this:

```sh
ARCH=$(dpkg --print-architecture)
curl -fsSLO https://get.helm.sh/helm-v4.3.0-linux-$ARCH.tar.gz
curl -fsSL https://get.helm.sh/helm-v4.3.0-linux-$ARCH.tar.gz.sha256sum | sha256sum --check
tar xzf helm-v4.3.0-linux-$ARCH.tar.gz linux-$ARCH/helm
sudo install -m 0755 linux-$ARCH/helm /usr/local/bin/ && rm -r helm-v4.3.0-linux-$ARCH.tar.gz linux-$ARCH
```

**Those commands were not run for this course**: the machine it was recorded on could not reach
`get.helm.sh`, so its `helm` was built from the same release's source, v4.3.0, and reports that version.
`helm version` should print `v4.3.0` on yours too.

**A chart is a directory with a fixed shape**: `Chart.yaml` names it and gives it a version,
`values.yaml` holds the defaults, and `templates/` holds manifests with gaps in them. The shop's chart,
written from nothing:

```
ana@laptop:~/shop$ find shop-chart -type f | sort
shop-chart/Chart.yaml
shop-chart/templates/deployment.yaml
shop-chart/templates/service.yaml
shop-chart/values.yaml
```

```yaml
apiVersion: v2
name: shop
description: The shop, as a chart
version: 0.1.0
appVersion: "1.0"
```

`version` is the chart's own version, which changes whenever the chart does; `appVersion` is the
version of the application it deploys, and is only a label.

```yaml
replicas: 2
image:
  repository: shop
  tag: "1.0"
greeting: ""
service:
  port: 80
```

Every key here is a value a user may override without touching a template. Choosing those keys is the
real design work of a chart: too few and people fork it, too many and nobody can read it.

The Deployment template, part by part:

```schooling-example
{"language": "yaml", "file": "templates/deployment.yaml", "parts": [{"code": "apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: {{ .Release.Name }}\n  labels:\n    app.kubernetes.io/name: shop\n    app.kubernetes.io/instance: {{ .Release.Name }}\n", "note": "**The release's name becomes the object's name.** Install the chart twice under two names and you get two Deployments that do not collide."}, {"code": "spec:\n  replicas: {{ .Values.replicas }}\n  selector:\n    matchLabels:\n      app.kubernetes.io/instance: {{ .Release.Name }}\n  template:\n    metadata:\n      labels:\n        app.kubernetes.io/name: shop\n        app.kubernetes.io/instance: {{ .Release.Name }}\n    spec:\n      containers:\n      - name: shop\n", "note": "**`.Values.replicas` comes from `values.yaml`**, unless the install overrides it. The selector uses the release name too, so two releases never select each other's pods."}, {"code": "        image: \"{{ .Values.image.repository }}:{{ .Values.image.tag }}\"\n", "note": "The image is assembled from two values, so an upgrade can change the tag alone."}, {"code": "        {{- with .Values.greeting }}\n        env:\n        - name: GREETING\n          value: {{ . | quote }}\n        {{- end }}\n", "note": "**`with` renders its block only when the value is not empty**, and `quote` makes it a YAML string. The `-` in `{{-` eats the line break before it, so no blank line is left behind."}, {"code": "        ports:\n        - containerPort: 8080\n"}]}
```

The Service template is shorter and has a flaw that the next section exposes:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}
spec:
  selector:
    app.kubernetes.io/instance: {{ .Release.Name }}
  ports:
  - port: {{ .Values.service.port }}
    targetPort: 8080
```

```
ana@laptop:~/shop$ helm lint shop-chart
==> Linting shop-chart
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
```

`helm lint` checks that the chart renders and follows the conventions. Its one note, a missing icon,
matters only for charts published to a repository.

## Rendering without installing

`helm template` runs the templates and prints the result, touching no cluster:

```
ana@laptop:~/shop$ helm template shop shop-chart --set greeting=Bom-dia | grep -A 4 "env:"
        env:
        - name: GREETING
          value: "Bom-dia"
        ports:
        - containerPort: 8080
```

With `greeting` set, the `env` block appears, quoted; without it, the block is absent. **Reading what
a chart renders before installing it** is the habit that catches most mistakes, in your own charts
and in other people's.
