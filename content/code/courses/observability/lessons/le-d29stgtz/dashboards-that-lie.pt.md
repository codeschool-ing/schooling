---
title: Painéis que mentem
version: 1
---

Todo número num painel é verdadeiro, e um painel ainda assim pode enganar. Os jeitos mais comuns são
poucos, e cada um tem conserto.

**A janela esconde o que aconteceu.** Uma em cada dez cobranças foi forçada a falhar por setenta
segundos, e trinta segundos depois de isso parar a mesma fração de erros foi pedida em duas janelas:

```
ana@obs:~/shop$ curl -sG localhost:9090/api/v1/query --data-urlencode 'query=sum(rate(http_server_requests_total{job="payments",code=~"5.."}[1m])) / sum(rate(http_server_requests_total{job="payments"}[1m]))' | jq -r '.data.result[0].value[1]'
0.059113300492610835
ana@obs:~/shop$ curl -sG localhost:9090/api/v1/query --data-urlencode 'query=sum(rate(http_server_requests_total{job="payments",code=~"5.."}[10m])) / sum(rate(http_server_requests_total{job="payments"}[10m]))' | jq -r '.data.result[0].value[1]'
0.01731959787210252
```

**5,9 por cento no último minuto, 1,7 por cento nos últimos dez**, para as mesmas falhas. Um painel
com janela de dez minutos teria mostrado um calombo suave durante uma queda em que uma cobrança em
dez falhava. Uma janela de um minuto a mostra como foi, e é mais ruidosa o resto do tempo. Nenhuma
das duas está errada. Um painel deve dizer que janela usa, no título ou na legenda, e um alerta, na
aula 16, usa duas ao mesmo tempo.

**Uma média esconde os lentos.** A média de mil checkouts rápidos e dez que levaram oito segundos
ainda é rápida. É por isso que o painel da loja desenha percentis de um histograma e nunca a média, e
por isso que a aula 6 gastou uma seção com o que um percentil de buckets consegue e não consegue
dizer.

**Uma série ausente parece um zero.** Se o payments para de responder às coletas, a fração de erros
dele não é zero, é desconhecida. Um painel que desenha *sem dados* como uma linha reta em zero diz
o contrário da verdade. Mostre lacunas como lacunas, e mantenha o `up` no mesmo painel.

**O eixo exagera.** Um eixo y que começa em 0,98 transforma uma mudança de 0,995 para 0,991 num
penhasco. Os painéis da loja declaram `"min": 0`.

**Um painel que ninguém projetou mostra tudo.** Quarenta painéis com cada métrica que um serviço
exporta não respondem pergunta nenhuma. A estrutura comum para um serviço são três painéis, os que a
loja tem: **taxa, erros, duração**, conhecida como método RED, com as versões das mesmas três para as
dependências logo abaixo. Para um recurso como um disco ou uma fila o equivalente é utilização,
saturação e erros, o método USE. Cada painel deve responder a uma pergunta que alguém faz durante um
incidente, e um painel para o qual ninguém sabe dizer a pergunta deve sair.
