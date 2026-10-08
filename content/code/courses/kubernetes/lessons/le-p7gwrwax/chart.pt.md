---
title: Um chart é templates mais valores
version: 1
---

O Helm é mais um programa na sua máquina, ao lado do `kubectl`, e fala com o cluster pelo mesmo
kubeconfig. Ele se instala do jeito que a aula 1 instalou o `kind`, a partir da release do próprio
projeto, conferido contra o checksum publicado ao lado dela, e esta aula começa com `./up.sh` e depois
isto:

```sh
ARCH=$(dpkg --print-architecture)
curl -fsSLO https://get.helm.sh/helm-v4.3.0-linux-$ARCH.tar.gz
curl -fsSL https://get.helm.sh/helm-v4.3.0-linux-$ARCH.tar.gz.sha256sum | sha256sum --check
tar xzf helm-v4.3.0-linux-$ARCH.tar.gz linux-$ARCH/helm
sudo install -m 0755 linux-$ARCH/helm /usr/local/bin/ && rm -r helm-v4.3.0-linux-$ARCH.tar.gz linux-$ARCH
```

**Esses comandos não foram rodados para este curso**: a máquina em que ele foi gravado não alcançava o
`get.helm.sh`, então o `helm` dela foi compilado do código-fonte da mesma release, a v4.3.0, e informa
essa versão. O `helm version` deve imprimir `v4.3.0` na sua também.

**Um chart é um diretório com uma forma fixa**: `Chart.yaml` lhe dá nome e versão, `values.yaml` guarda
os padrões, e `templates/` guarda manifestos com lacunas. O chart da loja, escrito do zero:

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

`version` é a versão do próprio chart, que muda sempre que o chart muda; `appVersion` é a versão da
aplicação que ele publica, e é só um rótulo.

```yaml
replicas: 2
image:
  repository: shop
  tag: "1.0"
greeting: ""
service:
  port: 80
```

Cada chave aqui é um valor que quem usa pode sobrescrever sem tocar num template. Escolher essas chaves é
o trabalho de desenho de verdade de um chart: poucas demais e as pessoas fazem um fork, muitas demais e
ninguém consegue ler.

O template do Deployment, parte por parte:

```schooling-example
{"language": "yaml", "file": "templates/deployment.yaml", "parts": [{"code": "apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: {{ .Release.Name }}\n  labels:\n    app.kubernetes.io/name: shop\n    app.kubernetes.io/instance: {{ .Release.Name }}\n", "note": "**O nome da release vira o nome do objeto.** Instale o chart duas vezes com dois nomes e você tem dois Deployments que não colidem."}, {"code": "spec:\n  replicas: {{ .Values.replicas }}\n  selector:\n    matchLabels:\n      app.kubernetes.io/instance: {{ .Release.Name }}\n  template:\n    metadata:\n      labels:\n        app.kubernetes.io/name: shop\n        app.kubernetes.io/instance: {{ .Release.Name }}\n    spec:\n      containers:\n      - name: shop\n", "note": "**`.Values.replicas` vem de `values.yaml`**, a não ser que a instalação o sobrescreva. O seletor também usa o nome da release, então duas releases nunca selecionam os pods uma da outra."}, {"code": "        image: \"{{ .Values.image.repository }}:{{ .Values.image.tag }}\"\n", "note": "A imagem é montada a partir de dois valores, então um upgrade pode mudar só a tag."}, {"code": "        {{- with .Values.greeting }}\n        env:\n        - name: GREETING\n          value: {{ . | quote }}\n        {{- end }}\n", "note": "**`with` só renderiza o bloco quando o valor não está vazio**, e `quote` o transforma numa string YAML. O `-` em `{{-` come a quebra de linha antes dele, então não sobra linha em branco."}, {"code": "        ports:\n        - containerPort: 8080\n"}]}
```

O template do Service é mais curto e tem uma falha que a próxima seção expõe:

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

`helm lint` confere que o chart renderiza e segue as convenções. A única observação dele, um ícone
faltando, só importa para charts publicados num repositório.

## Renderizando sem instalar

`helm template` roda os templates e imprime o resultado, sem tocar em cluster nenhum:

```
ana@laptop:~/shop$ helm template shop shop-chart --set greeting=Bom-dia | grep -A 4 "env:"
        env:
        - name: GREETING
          value: "Bom-dia"
        ports:
        - containerPort: 8080
```

Com `greeting` definido, o bloco `env` aparece, entre aspas; sem ele, o bloco não existe. **Ler o que um
chart renderiza antes de instalá-lo** é o hábito que pega a maioria dos erros, nos seus charts e nos dos
outros.
