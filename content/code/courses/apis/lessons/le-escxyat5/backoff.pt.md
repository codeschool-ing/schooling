---
title: Um cliente que se comporta
version: 1
---

**Um limite só funciona se os clientes reagirem a ele, e a reação que funciona é esperar, mais a cada
vez, por um tempo em parte aleatório.** O servidor pode recusar; não pode obrigar um cliente a parar de
pedir. Um cliente que responde a um `429` tentando de novo na hora recebe outro `429`, gasta o tempo do
servidor com recusas e, se houver muitos clientes assim, eles mantêm uns aos outros recusados.

Duas regras, e cada uma conserta uma falha diferente:

- **Espere o quanto o servidor disse.** Quando a resposta traz `Retry-After`, esse é o número. Esperar
  menos é recusa garantida de novo; o servidor conhece o próprio balde.
- **Quando o servidor não disse nada, recue exponencialmente, com jitter.** Nenhuma resposta, conexão
  recusada, ou um `503` sem `Retry-After`: espere até meio segundo, depois até um, depois até dois,
  dobrando até um teto, e sorteie a espera de fato entre zero e esse limite. Desista depois de algumas
  tentativas.

O dobro serve para que um servidor fora do ar, ou sobrecarregado, seja procurado cada vez menos, em vez
de no mesmo ritmo constante por todo cliente que percebeu. O sorteio é para a falha que o dobro sozinho
piora:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 290\" role=\"img\" aria-label=\"Cinco clientes falham no mesmo instante e tentam de novo depois de até 0,5, 1 e 2 segundos. Sem jitter, os cinco tentam em 0,5, 1,5 e 3,5 segundos, cinco requisições em cada instante. Com full jitter, cada espera é um ponto aleatório abaixo do teto, e as novas tentativas se espalham pelos quatro segundos.\"><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sem jitter</text><rect x=\"146\" y=\"35\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"208.5\" y=\"35\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"333.5\" y=\"35\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"583.5\" y=\"35\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"146\" y=\"50\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"208.5\" y=\"50\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"333.5\" y=\"50\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"583.5\" y=\"50\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"146\" y=\"65\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"208.5\" y=\"65\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"333.5\" y=\"65\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"583.5\" y=\"65\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"146\" y=\"80\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"208.5\" y=\"80\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"333.5\" y=\"80\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"583.5\" y=\"80\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"146\" y=\"95\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"208.5\" y=\"95\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"333.5\" y=\"95\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"583.5\" y=\"95\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">full jitter</text><rect x=\"146\" y=\"155\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"175.7\" y=\"155\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"257.8\" y=\"155\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"424.4\" y=\"155\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"146\" y=\"170\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"154.9\" y=\"170\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"156.3\" y=\"170\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"250.0\" y=\"170\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"146\" y=\"185\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"163.1\" y=\"185\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"264.4\" y=\"185\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"437.1\" y=\"185\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"146\" y=\"200\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"183.6\" y=\"200\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"253.4\" y=\"200\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"418.7\" y=\"200\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"146\" y=\"215\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"155.1\" y=\"215\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"210.1\" y=\"215\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"250.7\" y=\"215\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"212.5\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">5</text><text x=\"337.5\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">5</text><text x=\"587.5\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">5</text><line x1=\"140\" y1=\"245\" x2=\"650\" y2=\"245\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"150\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 s</text><text x=\"275\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1 s</text><text x=\"400\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2 s</text><text x=\"525\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3 s</text><text x=\"650\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4 s</text><rect x=\"150\" y=\"272\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"164\" y=\"277\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a falha</text><rect x=\"260\" y=\"272\" width=\"8\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"274\" y=\"277\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma nova tentativa</text></svg>", "caption": "Dobrar sozinho só muda o pico de lugar; o jitter o espalha.", "same": ["full jitter"]}
```

Sem jitter, clientes que falharam juntos tentam de novo juntos, em 0,5 segundo, depois 1,5, depois
3,5, e cada nova tentativa é um pico tão alto quanto o que causou a falha. Sorteando cada espera entre
zero e o teto, o esquema normalmente chamado de **full jitter**, esses picos viram um fluxo pequeno que
o servidor consegue atender.

## polite.py

Ele pede `/books` um certo número de vezes, uma depois da outra, e segue as duas regras. Salve como
`~/shelf/polite.py`:

```python
# shelf/polite.py
"""Ask limits.py for the list of books N times, waiting instead of failing when told to.

    python3 polite.py KEY N
"""
import random
import sys
import time
import urllib.error
import urllib.request

BASE, CAP, TRIES = 0.5, 8, 5


def get(url, key):
    """The status and Retry-After of one GET; the status is None when nothing answered."""
    request = urllib.request.Request(url, headers={"X-API-Key": key})
    try:
        with urllib.request.urlopen(request) as answer:
            return answer.status, None
    except urllib.error.HTTPError as refused:
        return refused.code, refused.headers.get("Retry-After")
    except OSError:
        return None, None


def fetch(url, key):
    """GET url, retrying a 429, a 5xx or silence up to TRIES times; the last status."""
    for attempt in range(TRIES):
        status, after = get(url, key)
        if status is not None and status != 429 and status < 500:
            return status
        if attempt == TRIES - 1:
            break
        if after is not None:
            pause = int(after) + random.uniform(0, 0.5)
            why = f"Retry-After: {after}"
        else:
            ceiling = min(CAP, BASE * 2 ** attempt)
            pause = random.uniform(0, ceiling)
            why = f"backing off, up to {ceiling}s"
        print(f"         {status or 'no answer'}, {why}, waiting {pause:.2f}s", flush=True)
        time.sleep(pause)
    return status


start = time.time()
key, n = sys.argv[1], int(sys.argv[2])
for i in range(1, n + 1):
    status = fetch("http://127.0.0.1:8000/books", key)
    print(f"{time.time() - start:6.2f}s  request {i}: {status or 'no answer'}", flush=True)
    if status is None or status == 429 or status >= 500:
        print(f"giving up after {TRIES} tries", flush=True)
        break
```

`get` transforma todo desfecho num status e num `Retry-After`, com `None` para um servidor que não
respondeu. `fetch` só tenta de novo o que vale a pena: um `429`, um `5xx` ou o silêncio. Um `404` ou um
`401` volta na hora, porque mandar a mesma requisição errada de novo não a torna certa. E a última
linha do laço desiste da execução inteira, não de uma requisição, quando uma requisição esgota as
tentativas: um servidor que não respondeu cinco vezes não vai responder à próxima requisição também.

Catorze requisições, contra um balde de dez:

```
ana@api:~/shelf$ python3 polite.py demo-bia 14
  0.03s  request 1: 200
  0.03s  request 2: 200
  0.04s  request 3: 200
  0.04s  request 4: 200
  0.04s  request 5: 200
  0.04s  request 6: 200
  0.04s  request 7: 200
  0.05s  request 8: 200
  0.05s  request 9: 200
  0.05s  request 10: 200
         429, Retry-After: 1, waiting 1.05s
  1.11s  request 11: 200
         429, Retry-After: 1, waiting 1.29s
  2.41s  request 12: 200
         429, Retry-After: 1, waiting 1.04s
  3.45s  request 13: 200
         429, Retry-After: 1, waiting 1.39s
  4.85s  request 14: 200
```

Catorze respostas e catorze `200`. Dez foram de uma vez, saindo do balde; cada uma das outras quatro foi
recusada uma vez, esperou o segundo que o servidor pediu mais uma fração, e passou. **Nenhuma requisição
falhou**, e o servidor gastou quatro recusas com este cliente, onde as quinze de uma vez do `burst.py`
renderam cinco e não resolveram nada.

Agora com o servidor parado, `Ctrl+C` no segundo terminal, de modo que nada responde e nada diz quanto
esperar:

```
ana@api:~/shelf$ python3 polite.py demo-bia 3
         no answer, backing off, up to 0.5s, waiting 0.10s
         no answer, backing off, up to 1.0s, waiting 0.85s
         no answer, backing off, up to 2.0s, waiting 0.85s
         no answer, backing off, up to 4.0s, waiting 0.39s
  2.23s  request 1: no answer
giving up after 5 tries
```

O teto dobrou a cada vez, `0.5s`, `1.0s`, `2.0s`, `4.0s`, enquanto cada espera de fato foi um ponto aleatório
abaixo dele. Depois de cinco tentativas, parou. Um cliente que tentasse para sempre, num ritmo fixo,
estaria batendo no servidor a toda velocidade no instante em que ele voltasse, junto com todo outro
cliente fazendo o mesmo.

## Onde um cliente pode fazer melhor

O `polite.py` espera até ser recusado. O cabeçalho `RateLimit` deixa um cliente desacelerar antes
disso: com `r=1` sobrando e `t=1` segundo, ele pode esperar um segundo antes da próxima requisição e
nunca ver um `429`. É um refinamento que um cliente pode fazer; o próprio rascunho diz que um cliente
não deve tratar o `r` como promessa de que as próximas requisições serão atendidas. **O `Retry-After` e
o `429` continuam sendo os sinais que um cliente tem de respeitar.**
