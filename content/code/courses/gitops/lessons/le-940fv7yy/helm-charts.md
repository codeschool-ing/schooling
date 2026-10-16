---
title: A Helm chart
version: 1
---

**A Helm chart is a directory of templates and a file of default values**, and installing it is
filling the templates with values and applying the result. Most software you did not write arrives
this way, a database, an ingress controller, a monitoring stack, because a chart lets its author
offer a few hundred settings without anybody editing their YAML.

## The command

`helm` is one more single file. Its releases live on `get.helm.sh`, with a checksum beside each:

```sh
curl -fsSLO https://get.helm.sh/helm-v4.3.0-linux-$ARCH.tar.gz
curl -fsSL https://get.helm.sh/helm-v4.3.0-linux-$ARCH.tar.gz.sha256sum | sha256sum --check
tar -xzf helm-v4.3.0-linux-$ARCH.tar.gz linux-$ARCH/helm && sudo install -m 0755 linux-$ARCH/helm /usr/local/bin/
```

**Those three commands were not run for this course**: the recording machine cannot reach
`get.helm.sh`, and its `helm` was built from the source of the same release.

```
ana@laptop:~/fleet$ helm version --short
v4.3.0
```

## bulletin, as a chart

In `fleet`, `charts/bulletin/` holds four files. Save this as `charts/bulletin/Chart.yaml`:

```yaml
apiVersion: v2
name: bulletin
description: A notice board that says which version it is
version: 0.1.0
appVersion: "1.1"
```

this as `charts/bulletin/values.yaml`:

```yaml
replicas: 1
image:
  repository: localhost:5001/bulletin
  tag: "1.1"
message: Installed by Helm.
```

this as `charts/bulletin/templates/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicas }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      containers:
      - name: bulletin
        image: "{{ .Values.image.repository }}:{{ required "image.tag is required" .Values.image.tag }}"
        env:
        - name: MESSAGE
          value: {{ .Values.message | quote }}
        ports:
        - containerPort: 8080
```

and this as `charts/bulletin/templates/service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}
spec:
  selector:
    app: {{ .Release.Name }}
  ports:
  - port: 80
    targetPort: 8080
```

`{{ … }}` is Go's template language. `.Values` is `values.yaml` merged with whatever the
installation overrides, `.Release.Name` is the name the installation was given, and `required`
stops the rendering with a message when a value is missing. **The templates are not valid YAML
until they are rendered**, which is the price of a chart and the reason `kubeconform` cannot read
them directly. `helm template` renders them, with the values you give it, without touching the
cluster:

```
ana@laptop:~/fleet$ git switch --quiet -c chart
ana@laptop:~/fleet$ helm lint charts/bulletin
==> Linting charts/bulletin
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
ana@laptop:~/fleet$ helm template preview charts/bulletin --set message="Rendered, not installed."
---
# Source: bulletin/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: preview
spec:
  selector:
    app: preview
  ports:
  - port: 80
    targetPort: 8080

---
# Source: bulletin/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: preview
spec:
  replicas: 1
  selector:
    matchLabels:
      app: preview
  template:
    metadata:
      labels:
        app: preview
    spec:
      containers:
      - name: bulletin
        image: "localhost:5001/bulletin:1.1"
        env:
        - name: MESSAGE
          value: "Rendered"
        ports:
        - containerPort: 8080
```

**Look at the message: `Rendered`, and nothing after it.** `--set` reads a comma as the start of the
next key, so the rest of the sentence was dropped without a word. A value that contains a comma needs
it escaped as `\,`, or goes in a values file passed with `--values`.

`helm lint` checks the chart's structure, also without a cluster, and is the check to put in the pull
request's CI for a chart.
