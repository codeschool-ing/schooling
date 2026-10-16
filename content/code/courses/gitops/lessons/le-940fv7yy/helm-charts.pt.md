---
title: Um chart do Helm
version: 1
---

**Um chart do Helm é uma pasta de templates e um arquivo de valores padrão**, e instalá-lo é preencher
os templates com valores e aplicar o resultado. A maior parte do software que você não escreveu chega
assim, um banco de dados, um ingress controller, uma pilha de monitoramento, porque um chart deixa o
autor oferecer algumas centenas de opções sem ninguém editar o YAML dele.

## O comando

O `helm` é mais um arquivo único. As versões dele ficam em `get.helm.sh`, com um checksum ao lado de
cada uma:

```sh
curl -fsSLO https://get.helm.sh/helm-v4.3.0-linux-$ARCH.tar.gz
curl -fsSL https://get.helm.sh/helm-v4.3.0-linux-$ARCH.tar.gz.sha256sum | sha256sum --check
tar -xzf helm-v4.3.0-linux-$ARCH.tar.gz linux-$ARCH/helm && sudo install -m 0755 linux-$ARCH/helm /usr/local/bin/
```

**Esses três comandos não foram executados para este curso**: a máquina de gravação não alcança o
`get.helm.sh`, e o `helm` dela foi construído a partir do código-fonte da mesma versão.

```
ana@laptop:~/fleet$ helm version --short
v4.3.0
```

## O bulletin, como chart

No `fleet`, `charts/bulletin/` guarda quatro arquivos. Salve isto como `charts/bulletin/Chart.yaml`:

```yaml
apiVersion: v2
name: bulletin
description: A notice board that says which version it is
version: 0.1.0
appVersion: "1.1"
```

isto como `charts/bulletin/values.yaml`:

```yaml
replicas: 1
image:
  repository: localhost:5001/bulletin
  tag: "1.1"
message: Installed by Helm.
```

isto como `charts/bulletin/templates/deployment.yaml`:

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

e isto como `charts/bulletin/templates/service.yaml`:

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

`{{ … }}` é a linguagem de templates do Go. `.Values` é o `values.yaml` mesclado com o que a
instalação sobrescrever, `.Release.Name` é o nome que a instalação recebeu, e o `required` para a
geração com uma mensagem quando falta um valor. **Os templates não são YAML válido até serem gerados**,
que é o preço de um chart e o motivo de o `kubeconform` não conseguir lê-los diretamente. O
`helm template` os gera, com os valores que você der, sem tocar no cluster:

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

**Repare na mensagem: `Rendered`, e nada depois.** O `--set` lê uma vírgula como o começo da próxima
chave, então o resto da frase foi descartado sem aviso. Um valor com vírgula precisa dela escapada como
`\,`, ou vai num arquivo de valores passado com `--values`.

O `helm lint` confere a estrutura do chart, também sem cluster, e é a checagem para pôr no CI do pull
request de um chart.
