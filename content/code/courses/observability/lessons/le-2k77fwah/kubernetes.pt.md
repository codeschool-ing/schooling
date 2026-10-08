---
title: Readiness e liveness no Kubernetes
version: 2
---

O Kubernetes é onde as três perguntas ganham consequências, e esta aula precisa de um cluster
próprio. O **kind** roda um dentro do Docker, um Kubernetes inteiro num contêiner, que é tudo de que
uma sonda precisa. Estas linhas instalam o kind e o `kubectl` pelos releases oficiais, nas versões com
que esta aula foi gravada, e criam o cluster. A última copia a imagem da loja para dentro dele: os
manifestos abaixo rodam essa imagem, e o cluster não consegue construí-la:

```sh
ARCH=$(dpkg --print-architecture)
curl -Lo kind https://github.com/kubernetes-sigs/kind/releases/download/v0.33.0/kind-linux-$ARCH
curl -Lo kubectl https://dl.k8s.io/release/v1.37.0/bin/linux/$ARCH/kubectl
sudo install kind kubectl /usr/local/bin/
rm kind kubectl
kind create cluster --name lab
kind load docker-image shop:1.4.0 --name lab
mkdir -p ~/shop/k8s
```

O cluster é mais um contêiner na mesma máquina, e um comando o apaga no fim da aula. A máquina em
que este curso foi gravado é um computador aninhado dentro de outro, e o cluster dela precisou de duas
configurações que uma máquina Linux comum não precisa; na sua, estas linhas são tudo.

O cluster roda duas cópias de um pequeno servidor web cujas sondas podem ser quebradas de propósito.
Salve o arquivo como `~/shop/k8s/probe-demo.yaml`, com o botão de copiar:

```schooling-example
{
  "language": "yaml",
  "file": "k8s/probe-demo.yaml",
  "parts": [
    {
      "code": "# Two copies of a small web server whose probes a test can break on purpose:\n# /ready fails while /tmp/unready exists, /live while /tmp/stuck does.\napiVersion: v1\nkind: ConfigMap\nmetadata: {name: web}\ndata:\n  web.py: |\n    import os\n    from http.server import BaseHTTPRequestHandler, HTTPServer\n\n    FAILS_IF = {\"/live\": \"/tmp/stuck\", \"/ready\": \"/tmp/unready\"}\n\n    class Handler(BaseHTTPRequestHandler):\n        def do_GET(self):\n            marker = FAILS_IF.get(self.path)\n            ok = not (marker and os.path.exists(marker))\n            self.send_response(200 if ok else 503)\n            self.end_headers()\n            self.wfile.write(os.environ[\"HOSTNAME\"].encode() + b\"\\n\")\n\n        def log_message(self, *args):\n            pass\n\n    HTTPServer((\"\", 8000), Handler).serve_forever()\n---\n",
      "note": "O programa, num ConfigMap para a imagem do laboratório poder rodá-lo. O `/live` falha enquanto existe `/tmp/stuck` e o `/ready` enquanto existe `/tmp/unready`, então um teste quebra qualquer das sondas com um `touch`."
    },
    {
      "code": "apiVersion: apps/v1\nkind: Deployment\nmetadata: {name: web}\nspec:\n  replicas: 2\n  selector: {matchLabels: {app: web}}\n  template:\n    metadata: {labels: {app: web}}\n    spec:\n      containers:\n        - name: web\n          image: shop:1.4.0\n          imagePullPolicy: Never\n          command: [python, /web/web.py]\n          volumeMounts: [{name: code, mountPath: /web}]\n"
    },
    {
      "code": "          readinessProbe:\n            httpGet: {path: /ready, port: 8000}\n            periodSeconds: 2\n            failureThreshold: 2\n",
      "note": "**Readiness**, a cada dois segundos; duas falhas seguidas tiram o pod do Service."
    },
    {
      "code": "          livenessProbe:\n            httpGet: {path: /live, port: 8000}\n            periodSeconds: 3\n            failureThreshold: 3\n",
      "note": "**Liveness**, a cada três segundos; três falhas seguidas e o contêiner é morto e iniciado de novo."
    },
    {
      "code": "      volumes: [{name: code, configMap: {name: web}}]\n---\napiVersion: v1\nkind: Service\nmetadata: {name: web}\nspec:\n  selector: {app: web}\n  ports: [{port: 80, targetPort: 8000}]\n",
      "note": "Duas cópias atrás de um Service, para que tirar uma deixe algum lugar para onde o tráfego ir."
    }
  ]
}
```

```
ana@obs:~/shop$ kubectl apply -f k8s/probe-demo.yaml
configmap/web created
deployment.apps/web created
service/web created
ana@obs:~/shop$ kubectl get pods
NAME                  READY   STATUS    RESTARTS   AGE
web-b874f8dc4-nwb5g   1/1     Running   0          3s
web-b874f8dc4-ssql6   1/1     Running   0          3s
```

As duas cópias estão `1/1` prontas. **Primeiro a readiness**: uma cópia recebe a ordem de falhar nela.

```
ana@obs:~/shop$ kubectl exec web-b874f8dc4-nwb5g -- touch /tmp/unready
ana@obs:~/shop$ kubectl get pods
NAME                  READY   STATUS    RESTARTS   AGE
web-b874f8dc4-nwb5g   0/1     Running   0          12s
web-b874f8dc4-ssql6   1/1     Running   0          12s
```

O pod está `0/1`: rodando, não reiniciado, e não pronto. O que isso muda está no endpoint slice do
Service, a lista para a qual um Service manda tráfego:

```
ana@obs:~/shop$ kubectl get endpointslice -l kubernetes.io/service-name=web -o json | jq -r '.items[].endpoints[] | [.targetRef.name, .conditions.ready] | @tsv'
web-b874f8dc4-nwb5g	false
web-b874f8dc4-ssql6	true
```

**O Service agora manda tudo para a outra cópia.** Nada foi morto, e quando o arquivo é removido o pod
volta sem ninguém fazer nada. Essa é a resposta certa para *não consigo atender agora*: um pod que
perdeu o banco, está aquecendo um cache ou está esvaziando antes de desligar.

**Depois a liveness**, na outra cópia:

```
ana@obs:~/shop$ kubectl exec web-b874f8dc4-ssql6 -- touch /tmp/stuck
ana@obs:~/shop$ kubectl get pods
NAME                  READY   STATUS    RESTARTS     AGE
web-b874f8dc4-nwb5g   1/1     Running   0            53s
web-b874f8dc4-ssql6   1/1     Running   1 (2s ago)   53s
```

Um reinício, há poucos segundos. Os eventos dizem por quê, nas palavras do próprio Kubernetes:

```
ana@obs:~/shop$ kubectl get events --field-selector involvedObject.name=web-b874f8dc4-ssql6 --sort-by=.lastTimestamp -o custom-columns=REASON:.reason,MESSAGE:.message | grep -E 'REASON|Liveness|Killing'
REASON      MESSAGE
Unhealthy   Liveness probe failed: HTTP probe failed with statuscode: 503
Killing     Container web failed liveness probe, will be restarted
```

A sonda recebeu um 503, o código que o programa devolve enquanto existe `/tmp/stuck`, três vezes
seguidas, e o kubelet matou o contêiner. O reinício curou porque a falha morava dentro do contêiner: um contêiner novo começa com
um sistema de arquivos novo, sem o `/tmp/stuck`. Esse é o único tipo de falha que um reinício cura, e a
próxima seção é sobre o outro tipo.

Duas configurações decidem quanto tudo isso leva. `periodSeconds` vezes `failureThreshold` é a
demora entre uma falha e a ação, nove segundos para esta sonda de liveness. Uma terceira sonda, a
`startupProbe`, segura as outras duas enquanto um serviço lento inicia, para a liveness não matar um
processo que ainda está carregando.