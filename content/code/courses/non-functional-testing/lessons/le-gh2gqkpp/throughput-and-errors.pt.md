---
title: Vazão, e o que conta como erro
version: 1
---

O tempo de resposta é um dos três números com que um relatório de teste de carga começa. Os
outros dois são a **vazão**, as requisições que o sistema completou por segundo, e a **taxa de
erro**, a fração delas que falhou. Cada um sozinho pode ser feito parecer bom; lidos juntos, eles
dizem se o sistema deu conta.

## A vazão para de subir

A vazão é o número de requisições completadas dividido pelo tempo decorrido, que o `measure.py`
imprime na primeira linha. Para ver como ela se comporta, rode o gerador com cada vez mais
workers, só consultas a um espetáculo, cinco segundos cada. O `sed` guarda duas linhas de cada
relatório, a primeira e a linha `all`:

```
ana@nft:~/boxoffice$ for w in 1 2 4 8 16 32; do python3 measure.py $w 5 | sed -n "1p;4p"; done
1 workers, 5.0 s: 232 requests, 46.3 per second
all           232    21.6    19.6    29.5    31.1    36.1    38.7
2 workers, 5.0 s: 332 requests, 66.1 per second
all           332    30.2    28.2    43.7    51.4    61.8    68.2
4 workers, 5.0 s: 404 requests, 80.3 per second
all           404    49.7    48.3    71.5    78.6    84.0   116.4
8 workers, 5.1 s: 492 requests, 97.1 per second
all           492    81.8    78.8   119.4   133.0   155.5   197.6
16 workers, 5.1 s: 527 requests, 102.4 per second
all           527   153.6   129.7   204.0   226.7  1172.1  1255.3
32 workers, 6.0 s: 584 requests, 96.6 per second
all           584   289.0   167.2  1060.1  1214.1  1459.0  2456.7
```

De um worker até oito, a vazão sobe, de 46.3 para 97.1 requisições por segundo. De oito até
trinta e dois ela fica onde está: 102.4 com dezesseis workers, 96.6 com trinta e dois. **Quatro
vezes mais workers não compraram nenhuma resposta a mais por segundo**, e os tempos de resposta
pagaram por eles: a mediana foi de 78.8 ms com oito workers para 167.2 ms com trinta e dois, e o
p95 de 133.0 para 1214.1 ms.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l08-load\" aria-label=\"Dois gráficos das mesmas seis execuções, com 1, 2, 4, 8, 16 e 32 workers embaixo de cada um. À esquerda, a vazão em requisições por segundo sobe de 46.3 com um worker para 97.1 com oito, e então fica plana: 102.4 com dezesseis e 96.6 com trinta e dois. À direita, o tempo de resposta: a mediana sobe de 19.6 para 167.2 ms, e o percentil 95 de 31.1 ms para 1214.1 ms, a maior parte dessa subida depois que a vazão parou de crescer.\"><text x=\"205.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">vazão, requisições por segundo</text><path d=\"M70.0 240.0 L340.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M70.0 240.0 L70.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M70.0 240.0 L340.0 240.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"64.0\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M70.0 180.0 L340.0 180.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"64.0\" y=\"180.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">40</text><path d=\"M70.0 120.0 L340.0 120.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"64.0\" y=\"120.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">80</text><path d=\"M70.0 60.0 L340.0 60.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"64.0\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">120</text><text x=\"90.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><text x=\"136.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><text x=\"182.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><text x=\"228.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><text x=\"274.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16</text><text x=\"320.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">32</text><text x=\"205.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">workers</text><path d=\"M90.0 170.6 L136.0 140.9 L182.0 119.5 L228.0 94.4 L274.0 86.4 L320.0 95.1\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><circle cx=\"90.0\" cy=\"170.6\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"136.0\" cy=\"140.9\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"182.0\" cy=\"119.5\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"228.0\" cy=\"94.4\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"274.0\" cy=\"86.4\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"320.0\" cy=\"95.1\" r=\"3\" fill=\"var(--phosphor)\"></circle><text x=\"222.0\" y=\"82.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">plana a partir de 8</text><text x=\"555.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">tempo de resposta, ms</text><path d=\"M420.0 240.0 L690.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M420.0 240.0 L420.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M420.0 240.0 L690.0 240.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"414.0\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M420.0 182.4 L690.0 182.4\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"414.0\" y=\"182.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">400</text><path d=\"M420.0 124.8 L690.0 124.8\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"414.0\" y=\"124.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">800</text><path d=\"M420.0 67.2 L690.0 67.2\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"414.0\" y=\"67.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1200</text><text x=\"440.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><text x=\"486.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><text x=\"532.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><text x=\"578.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><text x=\"624.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16</text><text x=\"670.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">32</text><text x=\"555.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">workers</text><path d=\"M440.0 237.2 L486.0 235.9 L532.0 233.0 L578.0 228.7 L624.0 221.3 L670.0 215.9\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><circle cx=\"440.0\" cy=\"237.2\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"486.0\" cy=\"235.9\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"532.0\" cy=\"233.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"578.0\" cy=\"228.7\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"624.0\" cy=\"221.3\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"670.0\" cy=\"215.9\" r=\"3\" fill=\"var(--phosphor)\"></circle><text x=\"664.0\" y=\"203.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">mediana</text><path d=\"M440.0 235.5 L486.0 232.6 L532.0 228.7 L578.0 220.8 L624.0 207.4 L670.0 65.2\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><circle cx=\"440.0\" cy=\"235.5\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"486.0\" cy=\"232.6\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"532.0\" cy=\"228.7\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"578.0\" cy=\"220.8\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"624.0\" cy=\"207.4\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"670.0\" cy=\"65.2\" r=\"3\" fill=\"var(--amber)\"></circle><text x=\"664.0\" y=\"53.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">p95</text></svg>", "caption": "Depois de oito workers a bilheteria não responde mais requisições por segundo. Cada worker a mais só espera mais.", "same": ["p95", "workers"]}
```

Essa forma é a mais comum em teste de desempenho, e tem um motivo simples. Um worker aqui manda
uma requisição, espera a resposta e manda a próxima, então a cada momento o número de requisições
dentro do sistema é o número de workers. Se o sistema completa X requisições por segundo e cada
uma passa R segundos dentro dele, então

> requisições dentro do sistema = X × R

que é a **lei de Little**, e ela vale para qualquer sistema que não esteja enchendo nem
esvaziando. Confira na linha com oito workers: 97.1 requisições por segundo × 0.0818 s de tempo
de resposta médio dá cerca de 7.9 requisições dentro, para oito workers. Com dezesseis, 102.4 ×
0.1536 dá cerca de 15.7.

Quando X não consegue crescer, porque alguma coisa na bilheteria está totalmente ocupada, cada
worker a mais aumenta R: ele entra numa fila. É por isso que a latência contra a carga é plana e
depois íngreme, e por isso o ponto onde ela vira, aqui por volta de oito workers, é o número mais
útil que um teste pode encontrar. **Um requisito de 50 requisições por segundo é folgado nesta
máquina; um de 150 não se cumpre adicionando workers**, só achando o que está ocupado, que é o
assunto da aula 9.

O gerador também faz parte dessa frase. O `measure.py` roda nos mesmos quatro processadores que a
bilheteria, e cada thread que ele inicia tira tempo do servidor. A aula 9 mostra como distinguir
um servidor ocupado de um gerador ocupado.

## O que conta como erro

Uma taxa de erro é uma contagem dividida por outra, e tudo depende do que vai em cima. O k6, da
aula 5, conta uma resposta como falha quando o status dela é 400 ou mais, ou quando nenhuma
resposta chegou. Aqui está a mesma carga misturada do `measure.py`, escrita para o k6:

```javascript
// boxoffice/mix.js
// Eight virtual users for ten seconds: one request in five books a seat,
// the rest look at a show. A fresh connection for every request.
import http from 'k6/http';

export const options = { vus: 8, duration: '10s', noConnectionReuse: true };

export default function () {
  const show = 981 + Math.floor(Math.random() * 20);
  if (Math.random() < 0.2) {
    http.post('http://127.0.0.1:8000/bookings', JSON.stringify({
      show_id: show, seat: 1 + Math.floor(Math.random() * 300), customer: `vu${__VU}`,
    }));
  } else {
    http.get(`http://127.0.0.1:8000/shows/${show}`);
  }
}
```

`noConnectionReuse` faz o k6 abrir uma conexão nova para cada requisição, como o `measure.py`
faz, para que os dois meçam a mesma coisa; a aula 9 mostra o que muda neste servidor quando uma
conexão é mantida. O k6 imprime um resumo comprido, e o `grep` guarda as linhas de HTTP:

```
ana@nft:~/boxoffice$ k6 run mix.js 2>&1 | grep -E "http_req_(duration|failed)|expected_resp|http_reqs"
    http_req_duration..............: avg=104.68ms min=16.12ms med=31.3ms  max=1.18s p(90)=409.95ms p(95)=479.66ms
      { expected_response:true }...: avg=95.05ms  min=16.12ms med=30.53ms max=1.18s p(90)=401.95ms p(95)=475.68ms
    http_req_failed................: 3.28%  25 out of 761
    http_reqs......................: 761    74.113918/s
```

`http_req_failed` diz 3.28%, 25 de 761 requisições. **Nenhuma delas é defeito.** O único status
de 400 para cima que este script consegue receber é um 409: um assento sorteado que alguém já tem.
A bilheteria recusar vender um assento duas vezes é exatamente o comportamento que um teste de
reserva existe para ver, e contar isso como falha faria uma versão estourar o orçamento de erros
por funcionar direito.

A correção é dizer ao k6 quais respostas este teste espera. `http.expectedStatuses` aceita uma
faixa e códigos avulsos:

```javascript
// boxoffice/mix-expected.js
// Eight virtual users for ten seconds: one request in five books a seat,
// the rest look at a show. A 409, a seat somebody already has, is an
// answer this test expects, so it is not counted as a failure.
import http from 'k6/http';

http.setResponseCallback(http.expectedStatuses({ min: 200, max: 299 }, 409));

export const options = { vus: 8, duration: '10s', noConnectionReuse: true };

export default function () {
  const show = 981 + Math.floor(Math.random() * 20);
  if (Math.random() < 0.2) {
    http.post('http://127.0.0.1:8000/bookings', JSON.stringify({
      show_id: show, seat: 1 + Math.floor(Math.random() * 300), customer: `vu${__VU}`,
    }));
  } else {
    http.get(`http://127.0.0.1:8000/shows/${show}`);
  }
}
```

```
ana@nft:~/boxoffice$ k6 run mix-expected.js 2>&1 | grep -E "http_req_(duration|failed)|expected_resp|http_reqs"
    http_req_duration..............: avg=115.02ms min=16.15ms med=32.64ms max=720.76ms p(90)=439.33ms p(95)=522.86ms
      { expected_response:true }...: avg=115.02ms min=16.15ms med=32.64ms max=720.76ms p(90)=439.33ms p(95)=522.86ms
    http_req_failed................: 0.00%  0 out of 704
    http_reqs......................: 704    67.995409/s
```

Agora `http_req_failed` é 0.00%, 0 de 704. As duas execuções diferem nos tempos, como quaisquer
duas execuções; a linha que mudou por causa do script é a contagem de falhas. A segunda linha de
cada resumo, `{ expected_response:true }`, é o tempo de resposta só das respostas esperadas. Na
primeira execução ela deixou os 409 de fora; na segunda ela cobre tudo, então é igual à linha de
cima.

Vale ler essa mesma linha de resumo uma vez com esta aula em mente. `avg`, `min`, `med`, `max`,
`p(90)` e `p(95)` são as estatísticas padrão do k6, então **a média vem primeiro e não há p99**.
`--summary-trend-stats "med,p(95),p(99),max"` na linha de comando, ou `summaryTrendStats` nas
opções, escolhe outras.

Três regras valem para qualquer taxa de erro que você escrever num requisito:

- **Decida o que é esperado antes da execução.** Um 409 num teste que reserva assentos sorteados
  é uma resposta correta. O mesmo 409 num teste que só reserva assentos que sabe estarem livres é
  um defeito.
- **Conte as requisições que não tiveram resposta.** Um timeout, uma conexão recusada ou
  derrubada nunca produz um código de status. O `measure.py` as registra como `failed`, e o k6 as
  conta como falha; um script caseiro que só conta códigos de status perde justamente as falhas
  que mais importam.
- **Leia a latência das respostas bem-sucedidas separada das que falharam.** Um servidor que
  responde 503 em um milissegundo enquanto está caindo faz os próprios percentis parecerem
  melhores; uma taxa de erro subindo enquanto os tempos de resposta caem é um aviso, não uma boa
  notícia.
