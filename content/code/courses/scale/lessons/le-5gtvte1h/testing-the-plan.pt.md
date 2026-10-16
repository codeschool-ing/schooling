---
title: Testando o plano
version: 1
---

O plano da aula 11, como um teste: 1.000 leituras e 100 vendas por segundo, o primeiro minuto da
abertura de vendas, por trinta segundos. Dois cenários rodam ao mesmo tempo, cada um marcando os seus
pedidos com um `kind`, e a nota de corte é escrita no teste como **limiares** (*thresholds*): o
percentil 95 das leituras abaixo de 100 ms, das vendas abaixo de 250 ms, e menos de 1% dos pedidos
falhando, em que o k6 conta qualquer status de 400 para cima como falha. Salve-o como `onsale.js`:

```javascript
// onsale.js
import http from "k6/http";

const READS = Number(__ENV.READS || 1000);
const SALES = Number(__ENV.SALES || 100);

export const options = {
  scenarios: {
    reads: {
      executor: "constant-arrival-rate", exec: "read",
      rate: READS, timeUnit: "1s", duration: "30s",
      preAllocatedVUs: 100, maxVUs: 1000,
    },
    sales: {
      executor: "constant-arrival-rate", exec: "sale",
      rate: SALES, timeUnit: "1s", duration: "30s",
      preAllocatedVUs: 50, maxVUs: 1000,
    },
  },
  thresholds: {
    "http_req_duration{kind:read}": ["p(95)<100"],
    "http_req_duration{kind:sale}": ["p(95)<250"],
    "http_req_failed": ["rate<0.01"],
  },
  summaryTrendStats: ["med", "p(95)", "p(99)", "max"],
};

const show = () => Math.floor(Math.random() * 50) + 1;

export function read() {
  http.get(`http://localhost:8080/events/${show()}`, { tags: { kind: "read" } });
}

export function sale() {
  http.post(`http://localhost:8080/events/${show()}/tickets`, null, {
    tags: { kind: "sale" },
    headers: { "X-Buyer": `buyer-${__VU}-${__ITER}` },
  });
}

export function handleSummary(data) {
  const lines = [];
  for (const [name, metric] of Object.entries(data.metrics)) {
    for (const [rule, result] of Object.entries(metric.thresholds || {})) {
      const v = metric.values;
      const seen = "p(95)" in v ? `${v["p(95)"].toFixed(1)} ms` : `${(v.rate * 100).toFixed(2)}%`;
      lines.push(`${result.ok ? "ok    " : "FAILED"}  ${name} ${rule}  (was ${seen})`);
    }
  }
  return { stdout: lines.sort().join("\n") + "\n" };
}
```

Este `handleSummary` imprime só os limiares, cada um com o valor pelo qual foi julgado. Quando
qualquer um deles é ultrapassado, o k6 sai com o código 99 em vez de 0, que é o que faz de um teste
uma barreira: uma esteira que o roda antes de uma versão para num limiar que falhou, sem ninguém
precisar ler nada.

Primeiro com uma cópia, depois com três:

```
ana@lab:~/tickets$ docker run --rm -i --network host grafana/k6:2.3.0 run -q --log-output=none - < onsale.js; echo "exit code $?"
FAILED  http_req_duration{kind:read} p(95)<100  (was 4453.4 ms)
FAILED  http_req_duration{kind:sale} p(95)<250  (was 5092.5 ms)
ok      http_req_failed rate<0.01  (was 0.31%)
exit code 99
ana@lab:~/tickets$ docker compose up -d --scale app=3
 Container tickets-prometheus-1 Running 
 Container tickets-lb-1 Running 
 Container tickets-payments-1 Running 
 Container tickets-app-1 Running 
 Container tickets-collector-1 Running 
 Container tickets-replica-1 Running 
 Container tickets-redis-1 Running 
 Container tickets-jaeger-1 Running 
 Container tickets-db-1 Running 
 Container tickets-app-3 Creating 
 Container tickets-app-2 Creating 
 Container tickets-app-3 Created 
 Container tickets-app-2 Created 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-db-1 Waiting 
 Container tickets-replica-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Healthy 
 Container tickets-app-3 Starting 
 Container tickets-app-3 Started 
 Container tickets-app-2 Starting 
 Container tickets-app-2 Started 
ana@lab:~/tickets$ docker compose restart lb
 Container tickets-lb-1 Restarting 
 Container tickets-lb-1 Started 
ana@lab:~/tickets$ docker run --rm -i --network host grafana/k6:2.3.0 run -q --log-output=none - < onsale.js; echo "exit code $?"
ok      http_req_duration{kind:read} p(95)<100  (was 16.5 ms)
ok      http_req_duration{kind:sale} p(95)<250  (was 84.5 ms)
ok      http_req_failed rate<0.01  (was 0.06%)
exit code 0
```

**Uma cópia reprova o plano**, e não por pouco: o percentil 95 das leituras foi 4,5 s e o das vendas
5,1 s, contra 100 e 250 ms. A taxa de erros passou, com 0,31%, que é a armadilha de um teste só com
limiar de erros: uma bilheteria que responde tudo em cinco segundos não está falhando, por essa
medida. **Três cópias passam**, com leituras em 16,5 ms e vendas em 84,5 ms no percentil 95, e código
de saída 0.

O plano dizia três cópias a 70% de ocupação, quatro com uma de reserva. O teste confirma a primeira
metade nesta máquina. A segunda metade, N + 1, é um teste à parte: rodar a mesma carga com três cópias
e parar uma no meio, `docker compose stop` num contêiner, e ver se os limiares aguentam. Isso é um
teste de pico e um teste de falha ao mesmo tempo, e é o tipo de teste que descobre se a cópia de
reserva é de fato uma reserva.
