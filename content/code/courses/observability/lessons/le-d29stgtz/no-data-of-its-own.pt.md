---
title: Uma interface sem dados próprios
version: 1
---

A imagem comum do Grafana é *o sistema de monitoramento*. **Ele não guarda nenhum dos dados que
desenha.** Todo painel é uma consulta enviada, no momento em que o painel é desenhado, a uma **fonte
de dados** (data source): um backend que o Grafana sabe como consultar. O Prometheus guarda as
métricas, o Loki os logs, o Jaeger os rastros, e o Grafana guarda os painéis, os usuários e a lista
de onde perguntar. Perder o Grafana perde os desenhos, nem um único dado.

O Grafana do laboratório responde na porta 3000:

```
ana@obs:~/shop$ curl -s localhost:3000/api/health | jq -c .
{"database":"ok","version":"13.0.10","commit":"885f00ce25d95a9bedc723c89dfb2e4cb7c876eb"}
```

As fontes de dados dele não são montadas com cliques na interface; são **provisionadas** a partir de
um arquivo lido na partida, que mora em `~/shop` ao lado de todo o resto:

```
ana@obs:~/shop$ cat grafana/provisioning/datasources/shop.yaml
apiVersion: 1
datasources:
  - name: Prometheus
    uid: prometheus
    type: prometheus
    url: http://prometheus:9090
    isDefault: true
  - name: Loki
    uid: loki
    type: loki
    url: http://loki:3100
  - name: Jaeger
    uid: jaeger
    type: jaeger
    url: http://jaeger:16686
```

E o Grafana confirma que tem essas três, cada uma com o `uid` que o arquivo lhe deu:

```
ana@obs:~/shop$ curl -s -u admin:$(cat .grafana-password) localhost:3000/api/datasources | jq -r '.[] | [.name, .type, .uid, .url] | @tsv'
Jaeger	jaeger	jaeger	http://jaeger:16686
Loki	loki	loki	http://loki:3100
Prometheus	prometheus	prometheus	http://prometheus:9090
```

**O `uid` é aquilo a que todo o resto se refere**, e o arquivo o escolheu de propósito. Um painel
que nomeia a fonte de dados por um `uid` escrito no arquivo funciona igual em todo Grafana que
carregou o mesmo arquivo. Um que a nomeia por um id que o Grafana gerou só funciona no Grafana que o
gerou. A senha de administrador vem de um arquivo que o laboratório escreveu, `.grafana-password`,
lido por `$(cat ...)` para nunca aparecer na tela. A seção seguinte deixa de precisar dela.
