---
title: Por que a média engana
version: 1
---

Um teste de carga não devolve um tempo de resposta. Devolve centenas ou milhares deles, um por
requisição, e todo relatório que você vai ler espreme esses tempos em poucos números. **Quais
números são esses decide o que o relatório consegue dizer**, e o primeiro que a maioria das
pessoas procura, a média, é o que diz menos sobre quanto os usuários esperaram.

Cada ferramenta das aulas 4 a 7 imprime o seu próprio resumo. Para ver de onde esses números vêm,
esta seção usa um gerador pequeno o bastante para ler de uma vez, escrito em Python só com a
biblioteca padrão. Ele manda requisições de várias threads ao mesmo tempo, registra cada tempo e
imprime as estatísticas que um relatório de teste de carga imprime, calculadas às claras.

Crie o arquivo em `~/boxoffice` com `nano measure.py`. O botão de copiar leva o arquivo inteiro,
sem as notas.

```schooling-example
{"language": "python", "file": "boxoffice/measure.py", "parts": [{"code": "# boxoffice/measure.py\n# A small load generator: WORKERS threads ask boxoffice for shows, and book\n# seats now and then, for SECONDS, then report what a load test reports.\n#   python3 measure.py WORKERS SECONDS [BOOKING_SHARE]\nimport http.client, json, math, random, sys, threading, time\n\nworkers, seconds = int(sys.argv[1]), float(sys.argv[2])\nshare = float(sys.argv[3]) if len(sys.argv) > 3 else 0.0\nresults, lock = [], threading.Lock()\n", "note": "Só a biblioteca padrão, como a bilheteria. Três argumentos: quantos workers enviam ao mesmo tempo, por quantos segundos, e que fração das requisições são reservas (0.2 é uma em cinco; sem o argumento, nenhuma)."}, {"code": "def worker(n):\n    rnd = random.Random(n)\n    stop = time.perf_counter() + seconds\n    while time.perf_counter() < stop:\n        show = rnd.randint(981, 1000)\n        if rnd.random() < share:\n            kind, method, path = \"book\", \"POST\", \"/bookings\"\n            body = json.dumps({\"show_id\": show, \"seat\": rnd.randint(1, 300), \"customer\": f\"w{n}\"})\n        else:\n            kind, method, path, body = \"show\", \"GET\", f\"/shows/{show}\", None\n        start = time.perf_counter()\n        conn = http.client.HTTPConnection(\"127.0.0.1\", 8000, timeout=30)\n        try:\n            conn.request(method, path, body)\n            answer = conn.getresponse()\n            answer.read()\n            status = answer.status\n        except OSError:\n            status = \"failed\"\n        conn.close()\n        with lock:\n            results.append((kind, status, (time.perf_counter() - start) * 1000))\n", "note": "Cada worker repete até o tempo acabar. Escolhe um espetáculo à venda, reserva um assento ao acaso ou consulta o espetáculo, e mede a requisição de logo antes de conectar até logo depois do último byte da resposta. **Ele abre uma conexão nova para cada requisição**, como o `curl` faz; a aula 9 mostra o que muda quando uma conexão é mantida. Uma requisição que não consegue conectar é registrada como `failed` em vez de descartada, porque uma falha que o relatório nunca vê é uma falha que não aconteceu."}, {"code": "def rank(ordered, p):\n    \"\"\"The nearest-rank percentile: the value at position ceil(p/100 * n).\"\"\"\n    return ordered[max(1, math.ceil(p / 100 * len(ordered))) - 1]\n", "note": "O percentil, pelo método da posição mais próxima: ordene os tempos, e o percentil p é o valor na posição p/100 × n, arredondada para cima. \"Percentis à mão\" faz a conta com lápis."}, {"code": "threads = [threading.Thread(target=worker, args=(n,)) for n in range(workers)]\nbegan = time.perf_counter()\nfor t in threads:\n    t.start()\nfor t in threads:\n    t.join()\nelapsed = time.perf_counter() - began\n", "note": "Inicia todos os workers, espera por todos, e guarda o tempo decorrido de verdade, um pouco maior que o pedido, porque as últimas requisições terminam depois dele."}, {"code": "print(f\"{workers} workers, {elapsed:.1f} s: {len(results)} requests, \"\n      f\"{len(results) / elapsed:.1f} per second\")\nstatuses = sorted({str(s) for _, s, _ in results})\nprint(\"status: \" + \", \".join(f\"{s} x{sum(str(r[1]) == s for r in results)}\" for s in statuses))\nprint(f\"{'ms':10} {'count':>6} {'mean':>7} {'median':>7} {'p90':>7} {'p95':>7} {'p99':>7} {'max':>7}\")\nfor label, kind in ((\"all\", None), (\"GET show\", \"show\"), (\"POST book\", \"book\")):\n    ms = sorted(t for k, _, t in results if kind in (None, k))\n    if ms:\n        cells = [sum(ms) / len(ms)] + [rank(ms, p) for p in (50, 90, 95, 99, 100)]\n        print(f\"{label:10} {len(ms):6} \" + \" \".join(f\"{c:7.1f}\" for c in cells))\n", "note": "O relatório: vazão, a contagem de cada código de status, depois uma linha para todas as requisições e uma por operação, cada uma com média, mediana, p90, p95, p99 e máximo."}, {"code": "ms = sorted(t for _, _, t in results)\nmean = sum(ms) / len(ms)\nnear = sum(abs(t - mean) <= 0.1 * mean for t in ms)\nprint(f\"within 10% of the mean: {near} of {len(ms)} requests\")\nprint(\"histogram, 20 ms bins\")\nfor low in range(0, 220, 20):\n    count = sum(low <= t < low + 20 for t in ms) if low < 200 else sum(t >= 200 for t in ms)\n    label = f\"{low:3}-{low + 20:3} ms\" if low < 200 else \"200 ms and up\"\n    print(f\"  {label}  {count:5} {'#' * math.ceil(50 * count / len(ms))}\".rstrip())", "note": "Duas coisas que um relatório raramente imprime. Quantas requisições levaram um tempo perto da média, a até 10% dela para cima ou para baixo. E um histograma em faixas de 20 ms, com tudo de 200 ms para cima numa faixa só, para que a forma apareça no terminal."}]}
```

Inicie a bilheteria num terminal, como na aula 1, com `python3 app.py` em `~/boxoffice`. No
segundo terminal, rode oito workers por dez segundos, com uma requisição em cada cinco sendo uma
reserva:

```
ana@nft:~/boxoffice$ python3 measure.py 8 10 0.2
8 workers, 10.4 s: 653 requests, 63.1 per second
status: 200 x520, 201 x105, 409 x28
ms          count    mean  median     p90     p95     p99     max
all           653   124.5    32.0   456.4   523.9   866.6  1071.0
GET show      520    36.0    27.4    56.5    71.0   105.2  1043.7
POST book     133   470.4   455.5   614.2   845.6  1020.0  1071.0
within 10% of the mean: 2 of 653 requests
histogram, 20 ms bins
    0- 20 ms     91 #######
   20- 40 ms    311 ########################
   40- 60 ms     75 ######
   60- 80 ms     26 ##
   80-100 ms     12 #
  100-120 ms      3 #
  120-140 ms      1 #
  140-160 ms      1 #
  160-180 ms      1 #
  180-200 ms      0
  200 ms and up    132 ###########
```

Leia a tabela de cima para baixo. Os dez segundos produziram 653 requisições. Delas, 520 foram
consultas a um espetáculo, 105 foram reservas bem-sucedidas e 28 foram reservas de um assento que
alguém já tinha. A linha `all` diz que o tempo de resposta médio foi 124.5 ms e a mediana 32.0 ms.

**Esses dois números descrevem requisições diferentes, e nenhum deles descreve as reservas.** A
mediana é o tempo abaixo do qual ficou metade das requisições: 32.0 ms, que é uma consulta a um
espetáculo numa máquina ocupada. A média é puxada para cima pelas 132 requisições que levaram 200
ms ou mais, quase todas reservas, e cai em 124.5 ms, onde quase nada aconteceu. A linha embaixo da
tabela conta quantas requisições levaram um tempo a até 10% da média, entre cerca de 112 e 137 ms:
**2 de 653**. O histograma mostra a mesma coisa como forma. A barra mais alta é a de 20 a 40 ms, a
barra comprida no fim é a de 200 ms para cima, e a faixa de 120 a 140 ms, onde a média cai, tem
uma requisição.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" data-fig=\"l08-distribution\" aria-label=\"Um histograma de 653 tempos de resposta de um teste de carga, em faixas de 20 milissegundos. A maioria das requisições está à esquerda: 91 abaixo de 20 ms, 311 entre 20 e 40, 75 entre 40 e 60, depois uma cauda que vai rareando, e 132 requisições com 200 ms ou mais, desenhadas como uma barra só, na ponta direita. A mediana, 32.0 ms, fica dentro da barra mais alta. A média, 124.5 ms, é uma linha tracejada sobre a faixa de 120 a 140 ms, que tem uma requisição. O percentil 95, 523.9 ms, está dentro da barra de 200 ms para cima.\"><path d=\"M60.0 250.0 L580.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"63.0\" y=\"197.3\" width=\"46.0\" height=\"52.7\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"86.0\" y=\"188.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">91</text><rect x=\"115.0\" y=\"70.0\" width=\"46.0\" height=\"180.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"138.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">311</text><rect x=\"167.0\" y=\"206.6\" width=\"46.0\" height=\"43.4\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"190.0\" y=\"197.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">75</text><rect x=\"219.0\" y=\"235.0\" width=\"46.0\" height=\"15.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"242.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">26</text><rect x=\"271.0\" y=\"243.1\" width=\"46.0\" height=\"6.9\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"294.0\" y=\"234.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">12</text><rect x=\"323.0\" y=\"248.3\" width=\"46.0\" height=\"1.7\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"346.0\" y=\"239.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">3</text><rect x=\"375.0\" y=\"249.4\" width=\"46.0\" height=\"0.6\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"398.0\" y=\"240.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1</text><rect x=\"427.0\" y=\"249.4\" width=\"46.0\" height=\"0.6\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"450.0\" y=\"240.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1</text><rect x=\"479.0\" y=\"249.4\" width=\"46.0\" height=\"0.6\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"502.0\" y=\"240.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1</text><text x=\"554.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><text x=\"60.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"164.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40</text><text x=\"268.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">80</text><text x=\"372.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">120</text><text x=\"476.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">160</text><text x=\"580.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200</text><text x=\"576.0\" y=\"282.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tempo de resposta, ms</text><path d=\"M610.0 250.0 L696.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"618.0\" y=\"173.6\" width=\"70.0\" height=\"76.4\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"653.0\" y=\"164.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">132</text><text x=\"653.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200+</text><text x=\"653.0\" y=\"205.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">p95</text><text x=\"653.0\" y=\"218.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">523.9</text><path d=\"M143.2 52.0 L143.2 44.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"149.2\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">mediana 32.0 ms</text><path d=\"M383.7 250.0 L383.7 106.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"389.7\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">média 124.5 ms</text><text x=\"389.7\" y=\"116.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">uma requisição mora aqui</text></svg>", "caption": "Onde 653 requisições caíram de fato. A média é o único lugar onde quase nenhuma caiu."}
```

A média é a estatística certa para uma quantidade que se soma, como o tempo total que uma máquina
passou ocupada. Tempos de resposta não são assim. Eles chegam em grupos, aqui dois: as leituras
rápidas e as reservas lentas. **A média de dois grupos é um ponto entre eles**, e um requisito
escrito sobre ela pode ser cumprido deixando as requisições rápidas mais rápidas enquanto as
lentas pioram.

## Os percentis dizem quem esperou quanto

As outras colunas são percentis. O p95 de `all` é 523.9 ms: 95 de cada 100 requisições levaram
isso ou menos, e 5 levaram mais. O p99 é 866.6 ms, o tempo que uma requisição em cada cem
ultrapassou. O máximo, 1071.0 ms, é uma requisição só, a mais lenta da execução, e ele varia
muito de uma execução para outra.

**Cada percentil é uma afirmação sobre pessoas**, e é por isso que a aula 1 escreveu o requisito
com um. Uma visita à página de reserva são várias requisições, não uma. Se ela faz oito, e cada
uma tem 5% de chance de ser mais lenta que o p95, a chance de as oito ficarem abaixo dele é 0.95
elevado à oitava potência, cerca de 66%: **uma visita em cada três encontra pelo menos uma
resposta da cauda.** A cauda é o que um usuário frequente encontra, não um acidente raro.

## Uma linha por operação

As duas linhas abaixo de `all` separam as mesmas requisições pelo que elas fizeram:

| | contagem | média | mediana | p95 |
|---|---|---|---|---|
| `GET show` | 520 | 36.0 | 27.4 | 71.0 |
| `POST book` | 133 | 470.4 | 455.5 | 845.6 |

São dois serviços diferentes dividindo um endereço. Consultar um espetáculo é rápido, e reservar
é mais de dez vezes mais lento, porque as reservas esperam umas pelas outras; a aula 9 descobre
onde. A linha `all` tira a média de uma operação rápida com uma lenta, na proporção que este teste
calhou de mandar, quatro para uma. **Mude a mistura e a linha `all` se mexe, embora nada no
sistema tenha mudado**, e é por isso que a aula 1 nomeou uma operação por requisito.
