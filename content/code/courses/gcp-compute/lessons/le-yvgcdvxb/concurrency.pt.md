---
title: Concorrência, e quanto uma instância aguenta
version: 1
---

Muitas plataformas de funções ensinaram uma geração que uma instância atende uma requisição. **O
Cloud Run não: uma instância atende até 80 requisições ao mesmo tempo por padrão, e até 1.000 se
você permitir.** Essa configuração única, `max_instance_request_concurrency`, decide quantas
instâncias uma rajada precisa, e portanto a maior parte da conta e a maior parte das partidas a
frio.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Vinte requisições chegam no mesmo instante. Com concorrência 1, o Cloud Run precisa de vinte instâncias, desenhadas como vinte caixinhas, cada uma com uma requisição. Com concorrência 80, uma instância segura as vinte, e ainda cabem mais sessenta.\"><defs><marker id=\"l11-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">concorrência 1: vinte instâncias</text><rect x=\"30\" y=\"50\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"55\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"92\" y=\"50\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"117\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"154\" y=\"50\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"179\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"216\" y=\"50\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"241\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"278\" y=\"50\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"303\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"30\" y=\"106\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"55\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"92\" y=\"106\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"117\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"154\" y=\"106\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"179\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"216\" y=\"106\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"241\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"278\" y=\"106\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"303\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"30\" y=\"162\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"55\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"92\" y=\"162\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"117\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"154\" y=\"162\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"179\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"216\" y=\"162\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"241\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"278\" y=\"162\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"303\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"30\" y=\"218\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"55\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"92\" y=\"218\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"117\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"154\" y=\"218\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"179\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"216\" y=\"218\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"241\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"278\" y=\"218\" width=\"50\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"303\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><path d=\"M360 30 L360 280\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"540\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">concorrência 80: uma instância</text><rect x=\"420\" y=\"50\" width=\"240\" height=\"212\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"440\" y=\"66\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"482\" y=\"66\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"524\" y=\"66\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"566\" y=\"66\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"608\" y=\"66\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"440\" y=\"96\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"482\" y=\"96\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"524\" y=\"96\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"566\" y=\"96\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"608\" y=\"96\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"440\" y=\"126\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"482\" y=\"126\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"524\" y=\"126\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"566\" y=\"126\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"608\" y=\"126\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"440\" y=\"156\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"482\" y=\"156\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"524\" y=\"156\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"566\" y=\"156\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"608\" y=\"156\" width=\"30\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">20 requisições numa instância</text><text x=\"540\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cabem mais 60</text></svg>", "caption": "As mesmas vinte requisições. Cheio é medido em requisições, então a concorrência decide quantas instâncias sobem, quantas sobem a frio e quantas são cobradas."}
```

## Medindo em casa

O serviço de pedidos da lição 8 atende cada requisição numa thread própria, e o `ORDERS_DELAY_MS`
faz o `/orders` esperar como se fosse um banco. Este programa manda requisições e as cronometra.
Salve como `~/gcp/load.py`:

```python
# load.py
"""Send N requests to URL, at most C at a time, and report how long they took."""
import sys
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor

url, n, c = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])


def one(_):
    started = time.perf_counter()
    urllib.request.urlopen(url).read()
    return time.perf_counter() - started


started = time.perf_counter()
with ThreadPoolExecutor(max_workers=c) as pool:
    times = sorted(pool.map(one, range(n)))
total = time.perf_counter() - started
print(f'{n} requests, {c} at a time: {total:.2f} s in all, '
      f'median {times[n // 2]:.3f} s, slowest {times[-1]:.3f} s')
```

Inicie o serviço com uma espera de 200 milissegundos por requisição e mande vinte requisições de
três jeitos: uma de cada vez, vinte de uma vez, e duzentas, oitenta de cada vez:

```
ana@laptop:~/gcp$ docker run -d --name orders-slow -p 8080:8080 -e ORDERS_DELAY_MS=200 orders:1
866eca200a31325a6a0783e688c1e4e0a2a8c5bde59fe20cec787e064407833e
ana@laptop:~/gcp$ python3 load.py http://localhost:8080/orders 20 1
20 requests, 1 at a time: 4.07 s in all, median 0.202 s, slowest 0.223 s
ana@laptop:~/gcp$ python3 load.py http://localhost:8080/orders 20 20
20 requests, 20 at a time: 0.61 s in all, median 0.526 s, slowest 0.581 s
ana@laptop:~/gcp$ python3 load.py http://localhost:8080/orders 200 80
200 requests, 80 at a time: 2.21 s in all, median 0.209 s, slowest 2.062 s
```

Neste laptop, **vinte requisições uma de cada vez levaram uns quatro segundos, e vinte de uma vez
uns seis décimos de segundo**: as esperas se sobrepuseram em vez de se somar, porque as requisições
estavam esperando e não calculando, e esperar é a única coisa que threads dividem de graça. Uma
instância carregou tudo.

Os outros dois números são os mais úteis. Vinte de uma vez não levaram 200 milissegundos cada, e
sim cerca de meio segundo, e na rodada de duzentas, oitenta de cada vez, a mediana continuou perto
de 200 milissegundos enquanto **a mais lenta levou dois segundos**. A espera deixou de ser o limite;
o programa virou o limite. O `http.server` do Python é um servidor de ensino: ele mantém uma fila
curta de conexões esperando para serem aceitas, cinco por padrão, e uma rajada maior que isso é
recusada e tentada de novo pelo cliente, que é a cara de uma requisição de dois segundos numa
rodada de requisições de 200 milissegundos. Um servidor de produção como o gunicorn, o da lição 19,
aguentaria mais. **A concorrência no Cloud Run é um teto; quanto uma instância realmente aguenta é
uma propriedade do seu programa**, e esta medição é como você descobre.

## O que isso quer dizer para o número de instâncias

O Cloud Run sobe uma instância nova quando as que estão rodando estão cheias, e **cheio é medido em
requisições, não em CPU**. Com concorrência 1, as vinte requisições simultâneas acima precisariam de
vinte instâncias, cada uma subindo a frio, cada uma cobrada. Com o padrão de 80, uma instância pega
todas e as outras dezenove nunca existem.

Então o padrão está certo para o caso comum, um serviço que passa a maior parte de cada requisição
esperando um banco ou outra API. Está errado em dois casos, e os dois têm sintoma:

- **a requisição calcula**: redimensionar uma imagem, gerar um PDF. Oitenta delas numa vCPU levam
  oitenta vezes mais cada uma, e a latência sobe enquanto o número de instâncias fica em um. Baixe
  a concorrência até cada requisição ter a CPU de que precisa; o Cloud Run então sobe mais
  instâncias.
- **o programa não aguenta requisições simultâneas**: um servidor de uma thread só, ou código com
  estado global que não é seguro entre threads. Ponha a concorrência em 1 e aceite as instâncias
  que isso custa, ou conserte o programa.

**Meça antes de escolher**: rode o serviço em casa sob o `load.py` com a concorrência que você
pretende permitir, e veja o que acontece com a mediana e com a requisição mais lenta. Quando a mais
lenta se afasta da mediana, como aconteceu acima com oitenta, a configuração está acima do que o
programa aguenta, e o Cloud Run faria melhor subindo uma segunda instância.
