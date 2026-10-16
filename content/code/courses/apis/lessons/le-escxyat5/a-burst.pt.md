---
title: Uma rajada contra ele
version: 1
---

**Só se acredita num limitador depois que ele recusa alguma coisa, então esta seção envia mais do que o
limite e lê cada resposta.** Um laço de curl no shell serviria, mas o tempo dele é o que o shell
conseguir, e aqui é o tempo que está sendo medido. Este cliente pequeno envia um número de requisições com um
intervalo fixo entre elas e imprime, para cada uma, quando foi enviada, o status, o que o cabeçalho
`RateLimit` disse que sobrava, e o `Retry-After` quando havia um. Salve como `~/shelf/burst.py`:

```python
# shelf/burst.py
"""Send N requests to limits.py, GAP seconds apart, and print what each one got.

    python3 burst.py KEY PATH N [GAP]
    python3 burst.py --edge KEY PATH N [GAP]    start 1 s before a 10 s window ends
"""
import re
import sys
import time
import urllib.error
import urllib.request

args = sys.argv[1:]
edge = args[0] == "--edge"
if edge:
    args = args[1:]
key, path, n = args[0], args[1], int(args[2])
gap = float(args[3]) if len(args) > 3 else 0

if edge:
    time.sleep((9 - time.time() % 10) % 10)

start = time.time()
for _ in range(n):
    sent = time.time()
    request = urllib.request.Request("http://127.0.0.1:8000" + path, headers={"X-API-Key": key})
    try:
        with urllib.request.urlopen(request) as answer:
            status, headers = answer.status, answer.headers
    except urllib.error.HTTPError as refused:
        status, headers = refused.code, refused.headers
    left = re.findall(r'"(\w+)";r=(\d+)', headers.get("RateLimit", ""))
    line = f"{sent - start:6.2f}s  {status}  " + "  ".join(f"{p} r={r}" for p, r in left)
    if headers.get("Retry-After"):
        line += f"  Retry-After: {headers['Retry-After']}"
    print(line, flush=True)
    time.sleep(max(0, sent + gap - time.time()))
```

O `--edge` é para a janela fixa. Ele espera até um segundo antes do próximo múltiplo de dez segundos no
relógio, que é onde o `limits.py window` começa uma janela nova.

## Quinze de uma vez

Com o `limits.py` rodando no segundo terminal, a chave free, quinze requisições sem intervalo:

```
ana@api:~/shelf$ python3 burst.py demo-bia /books 15
  0.00s  200  burst r=9  daily r=4999
  0.05s  200  burst r=8  daily r=4998
  0.05s  200  burst r=7  daily r=4997
  0.06s  200  burst r=6  daily r=4996
  0.06s  200  burst r=5  daily r=4995
  0.06s  200  burst r=4  daily r=4994
  0.06s  200  burst r=3  daily r=4993
  0.07s  200  burst r=2  daily r=4992
  0.07s  200  burst r=1  daily r=4991
  0.07s  200  burst r=0  daily r=4990
  0.07s  429  burst r=0  daily r=4990  Retry-After: 1
  0.08s  429  burst r=0  daily r=4990  Retry-After: 1
  0.08s  429  burst r=0  daily r=4990  Retry-After: 1
  0.08s  429  burst r=0  daily r=4990  Retry-After: 1
  0.08s  429  burst r=0  daily r=4990  Retry-After: 1
```

Dez aceitas, a capacidade do balde, e o resto recusado, cada uma com `Retry-After: 1`. A contagem
`daily` só desceu nas requisições atendidas: uma recusa não custa nada da cota do cliente. A recusa
inteira:

```
ana@api:~/shelf$ curl -si -H 'X-API-Key: demo-bia' localhost:8000/books/1
HTTP/1.1 429 Too Many Requests
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:48:44 GMT
Content-Type: application/json
Content-Length: 45
RateLimit-Policy: "burst";q=10;w=10, "daily";q=5000;w=86400
RateLimit: "burst";r=0;t=1, "daily";r=4990;t=69076
Retry-After: 1

{"error": "too many requests: retry in 1 s"}
```

`r=0` e `t=1` no `RateLimit` concordam com o `Retry-After: 1`: nada sobrando agora, e uma ficha de
volta em até um segundo. O corpo diz o mesmo em palavras, para uma pessoa lendo um log. **Toda recusa
diz quando voltar**, e é isso que separa um limite de uma queda do serviço.

O limite é por chave. A chave pro, consultada no mesmo segundo, não é afetada por nada que a chave free
fez:

```
ana@api:~/shelf$ curl -s -o /dev/null -w '%{http_code}\n' -H 'X-API-Key: demo-caio' localhost:8000/books
200
```

E depois de três segundos de silêncio, a chave free tem três fichas de novo, e a quarta requisição da
rajada seguinte é recusada:

```
ana@api:~/shelf$ sleep 3; python3 burst.py demo-bia /books 5
  0.00s  200  burst r=2  daily r=4989
  0.03s  200  burst r=1  daily r=4988
  0.03s  200  burst r=0  daily r=4987
  0.04s  429  burst r=0  daily r=4987  Retry-After: 1
  0.04s  429  burst r=0  daily r=4987  Retry-After: 1
```

O segundo terminal imprimiu uma linha por requisição, e as recusas aparecem nele como `429`:

```
127.0.0.1 - - [10/Oct/2026 01:48:44] "GET /books HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:48:44] "GET /books HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:48:44] "GET /books HTTP/1.1" 429 -
127.0.0.1 - - [10/Oct/2026 01:48:44] "GET /books HTTP/1.1" 429 -
127.0.0.1 - - [10/Oct/2026 01:48:44] "GET /books HTTP/1.1" 429 -
```

**Os `429` desse log são dados.** Uma chave recusada o dia inteiro precisa de uma conversa ou de um
plano maior, e uma alta repentina de recusas em todas as chaves costuma ser o primeiro sinal de uma
versão de cliente com um bug de retentativa.

## Um ritmo constante

Quatro requisições por segundo, contra um balde que é reabastecido a uma por segundo. São os números
desenhados na seção sobre o balde de fichas:

```
ana@api:~/shelf$ python3 burst.py demo-bia /books 24 0.25
  0.00s  200  burst r=9  daily r=4999
  0.25s  200  burst r=8  daily r=4998
  0.50s  200  burst r=7  daily r=4997
  0.75s  200  burst r=6  daily r=4996
  1.00s  200  burst r=5  daily r=4995
  1.25s  200  burst r=5  daily r=4994
  1.50s  200  burst r=4  daily r=4993
  1.75s  200  burst r=3  daily r=4992
  2.00s  200  burst r=2  daily r=4991
  2.25s  200  burst r=2  daily r=4990
  2.50s  200  burst r=1  daily r=4989
  2.75s  200  burst r=0  daily r=4988
  3.00s  429  burst r=0  daily r=4988  Retry-After: 1
  3.25s  200  burst r=0  daily r=4987
  3.50s  429  burst r=0  daily r=4987  Retry-After: 1
  3.75s  429  burst r=0  daily r=4987  Retry-After: 1
  4.00s  429  burst r=0  daily r=4987  Retry-After: 1
  4.25s  200  burst r=0  daily r=4986
  4.50s  429  burst r=0  daily r=4986  Retry-After: 1
  4.75s  429  burst r=0  daily r=4986  Retry-After: 1
  5.00s  429  burst r=0  daily r=4986  Retry-After: 1
  5.26s  200  burst r=0  daily r=4985
  5.51s  429  burst r=0  daily r=4985  Retry-After: 1
  5.76s  429  burst r=0  daily r=4985  Retry-After: 1
```

## A fronteira, medida

A execução por trás da figura da seção sobre a janela fixa. Primeiro com o `limits.py window` rodando,
depois, após `Ctrl+C`, com o `limits.py` simples. Trinta requisições a um décimo de segundo uma da
outra, começando um segundo antes do fim de uma janela:

```
ana@api:~/shelf$ python3 burst.py --edge demo-bia /books 30 0.1
  0.00s  200  burst r=9  daily r=4999
  0.10s  200  burst r=8  daily r=4998
  0.20s  200  burst r=7  daily r=4997
  0.30s  200  burst r=6  daily r=4996
  0.40s  200  burst r=5  daily r=4995
  0.50s  200  burst r=4  daily r=4994
  0.60s  200  burst r=3  daily r=4993
  0.70s  200  burst r=2  daily r=4992
  0.80s  200  burst r=1  daily r=4991
  0.90s  200  burst r=0  daily r=4990
  1.00s  200  burst r=9  daily r=4989
  1.10s  200  burst r=8  daily r=4988
  1.20s  200  burst r=7  daily r=4987
  1.30s  200  burst r=6  daily r=4986
  1.40s  200  burst r=5  daily r=4985
  1.50s  200  burst r=4  daily r=4984
  1.61s  200  burst r=3  daily r=4983
  1.71s  200  burst r=2  daily r=4982
  1.81s  200  burst r=1  daily r=4981
  1.91s  200  burst r=0  daily r=4980
  2.01s  429  burst r=0  daily r=4980  Retry-After: 9
  2.11s  429  burst r=0  daily r=4980  Retry-After: 9
  2.21s  429  burst r=0  daily r=4980  Retry-After: 9
  2.31s  429  burst r=0  daily r=4980  Retry-After: 9
  2.41s  429  burst r=0  daily r=4980  Retry-After: 9
  2.51s  429  burst r=0  daily r=4980  Retry-After: 9
  2.61s  429  burst r=0  daily r=4980  Retry-After: 9
  2.71s  429  burst r=0  daily r=4980  Retry-After: 9
  2.81s  429  burst r=0  daily r=4980  Retry-After: 9
  2.91s  429  burst r=0  daily r=4980  Retry-After: 9
```

Vinte aceitas em menos de dois segundos, com um limite de dez a cada dez segundos: as dez primeiras no
último segundo de uma janela, as dez seguintes no primeiro segundo da próxima. Aí o contador está
cheio, e o `Retry-After: 9` manda o cliente para o início da janela seguinte. As mesmas trinta contra o
balde:

```
ana@api:~/shelf$ python3 burst.py --edge demo-bia /books 30 0.1
  0.00s  200  burst r=9  daily r=4999
  0.10s  200  burst r=8  daily r=4998
  0.20s  200  burst r=7  daily r=4997
  0.30s  200  burst r=6  daily r=4996
  0.40s  200  burst r=5  daily r=4995
  0.50s  200  burst r=4  daily r=4994
  0.60s  200  burst r=3  daily r=4993
  0.70s  200  burst r=2  daily r=4992
  0.80s  200  burst r=1  daily r=4991
  0.90s  200  burst r=0  daily r=4990
  1.00s  429  burst r=0  daily r=4990  Retry-After: 1
  1.11s  200  burst r=0  daily r=4989
  1.21s  429  burst r=0  daily r=4989  Retry-After: 1
  1.31s  429  burst r=0  daily r=4989  Retry-After: 1
  1.41s  429  burst r=0  daily r=4989  Retry-After: 1
  1.51s  429  burst r=0  daily r=4989  Retry-After: 1
  1.61s  429  burst r=0  daily r=4989  Retry-After: 1
  1.71s  429  burst r=0  daily r=4989  Retry-After: 1
  1.81s  429  burst r=0  daily r=4989  Retry-After: 1
  1.91s  429  burst r=0  daily r=4989  Retry-After: 1
  2.01s  429  burst r=0  daily r=4989  Retry-After: 1
  2.11s  200  burst r=0  daily r=4988
  2.21s  429  burst r=0  daily r=4988  Retry-After: 1
  2.31s  429  burst r=0  daily r=4988  Retry-After: 1
  2.41s  429  burst r=0  daily r=4988  Retry-After: 1
  2.51s  429  burst r=0  daily r=4988  Retry-After: 1
  2.61s  429  burst r=0  daily r=4988  Retry-After: 1
  2.71s  429  burst r=0  daily r=4988  Retry-After: 1
  2.81s  429  burst r=0  daily r=4988  Retry-After: 1
  2.91s  429  burst r=0  daily r=4988  Retry-After: 1
```

Doze aceitas: as dez guardadas, depois uma por segundo. O balde não tem fronteira porque não tem
janelas; uma ficha gasta some até a reposição trazê-la de volta, diga o relógio o que disser.
