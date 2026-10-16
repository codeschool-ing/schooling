---
title: Usuários virtuais, tempo de pensamento e rampa
version: 1
---

Um usuário virtual é um laço com uma pausa dentro. **Ele envia uma requisição, espera a resposta,
pensa um pouco e começa de novo**, e um teste de modelo fechado não é nada além de muitos desses
laços rodando ao mesmo tempo. Esta seção constrói um, pequeno o bastante para ler, em `~/loadtest`,
ao lado do `hammer.py` da aula 2. Abra-o com `nano users.py` e cole o arquivo com o botão de copiar:

```schooling-example
{"language": "python", "file": "loadtest/users.py", "parts": [{"code": "# loadtest/users.py\n# A closed workload: USERS virtual users, each sending a request, waiting for\n# the answer, thinking for THINK seconds and starting again. They start one by\n# one over RAMP seconds, and only the SECONDS after the ramp are measured.\n# Usage: python3 users.py URL USERS THINK RAMP SECONDS\nimport sys, threading, time, urllib.request\n\nurl, users = sys.argv[1], int(sys.argv[2])\nthink, ramp, seconds = (float(a) for a in sys.argv[3:6])\ndone = []                        # one (time it finished, seconds it took, ok) per request\ninside = [0]                     # requests sent and not yet answered, right now\ncounts = []                      # inside[0], read ten times a second\nlock = threading.Lock()\nt0 = time.perf_counter()\n", "note": "Cinco argumentos, todos eles o modelo: quantos usuários virtuais, quanto tempo cada um pensa entre requisições, quanto tempo a rampa leva e por quanto tempo medir depois dela. `inside` é o número de requisições a caminho neste instante, e `counts` guarda uma leitura dele a cada décimo de segundo."}, {"code": "def user(n):\n    time.sleep(n * ramp / users)\n    while time.perf_counter() < t0 + ramp + seconds:\n        start = time.perf_counter()\n        with lock:\n            inside[0] += 1\n        try:\n            with urllib.request.urlopen(url, timeout=10) as answer:\n                answer.read()\n            ok = True\n        except Exception:\n            ok = False\n        with lock:\n            inside[0] -= 1\n            done.append((time.perf_counter() - t0, time.perf_counter() - start, ok))\n        time.sleep(think)\n", "note": "Um usuário virtual. Ele espera o seu lugar na rampa e depois repete: envia, **espera a resposta**, pensa, envia de novo. Essa espera é toda a diferença em relação ao `hammer.py` da aula 2. Um usuário não consegue enviar a próxima requisição enquanto a última não foi respondida, então o número de requisições em voo nunca passa do número de usuários."}, {"code": "def count():\n    time.sleep(ramp)\n    while time.perf_counter() < t0 + ramp + seconds:\n        counts.append(inside[0])\n        time.sleep(0.1)\n\nthreads = [threading.Thread(target=user, args=(n,)) for n in range(users)]\nthreads.append(threading.Thread(target=count))\nfor thread in threads:\n    thread.start()\nfor thread in threads:\n    thread.join()\n", "note": "Um segundo tipo de thread, que não faz nada além de contar quantas requisições estão em voo, dez vezes por segundo, depois que a rampa terminou. Essa contagem é medida diretamente, então dá para compará-la com o que a lei de Little prevê a partir dos outros números."}, {"code": "measured = [d for d in done if ramp <= d[0] < ramp + seconds]\nx = len(measured) / seconds                       # throughput, requests a second\nr = sum(d[1] for d in measured) / len(measured)   # mean response time, seconds\nprint(f\"{users} users, think {think} s, ramp {ramp} s, measured for {seconds} s\")\nprint(f\"requests {len(measured)}, errors {sum(1 for d in measured if not d[2])}\")\nprint(f\"throughput X        {x:7.1f} requests/s\")\nprint(f\"response time R     {r * 1000:7.1f} ms (mean)\")\nprint(f\"in flight, counted  {sum(counts) / len(counts):7.1f} requests at a time\")\nprint(f\"X × R               {x * r:7.1f} requests at a time\")\nprint(f\"X × (R + think)     {x * (r + think):7.1f} users\")", "note": "Só contam as requisições que terminaram depois da rampa, para a partida não diluir o resultado. `X` é a vazão e `R` o tempo médio de resposta. As três últimas linhas são a conferência de \"A lei de Little\": a contagem de requisições em voo ao lado de `X × R`, e o número de usuários ao lado de `X × (R + think)`."}]}
```

Os argumentos são o modelo: `URL USERS THINK RAMP SECONDS`. Com a bilheteria rodando no primeiro
terminal, como na aula 2, comece com dez usuários que pensam meio segundo cada, faça a rampa deles em
dois segundos e meça durante dez:

```
ana@nft:~/loadtest$ python3 users.py http://127.0.0.1:8000/shows/990 10 0.5 2 10
10 users, think 0.5 s, ramp 2.0 s, measured for 10.0 s
requests 194, errors 0
throughput X           19.4 requests/s
response time R        14.0 ms (mean)
in flight, counted      0.2 requests at a time
X × R                   0.3 requests at a time
X × (R + think)        10.0 users
```

Dez usuários, cada um dando voltas num laço de 14,0 ms de espera em média e 500 ms de pensamento,
enviaram 19,4 requisições por segundo entre eles. **A vazão foi decidida pelos usuários, e não pelo
servidor**: ele respondeu cada requisição em poucos milissegundos e depois ficou parado até alguém
pedir de novo. Em média, só 0,2 requisição estava em voo a cada momento.

## Tempo de pensamento

O tempo de pensamento é a pausa entre uma resposta e a próxima requisição do usuário, os segundos
que uma pessoa de verdade passa lendo a página, escolhendo um assento, digitando um nome. É o número
mais importante de um modelo fechado, e o mais fácil de errar. **Zere-o e todo usuário virtual vira
um programa clicando tão rápido quanto o servidor responde**, coisa que nenhuma pessoa faz:

```
ana@nft:~/loadtest$ python3 users.py http://127.0.0.1:8000/shows/990 100 0 5 30
100 users, think 0.0 s, ramp 5.0 s, measured for 30.0 s
requests 4200, errors 22
throughput X          140.0 requests/s
response time R       704.7 ms (mean)
in flight, counted     99.9 requests at a time
X × R                  98.7 requests at a time
X × (R + think)        98.7 users
```

Cem usuários sem tempo de pensamento mantiveram o servidor permanentemente cheio. Em média, 99,9
deles estavam esperando uma resposta a cada contagem, o tempo médio de resposta subiu para 704,7 ms,
22 requisições falharam, e a vazão foi de 140,0 requisições por segundo, porque é isso o que o
servidor conseguia terminar. Cem pessoas de verdade pensando quatro segundos cada teriam pedido umas
25 requisições por segundo. Os dois testes têm o mesmo número de usuários e descrevem cargas
completamente diferentes.

De onde vem um tempo de pensamento realista? Do mesmo lugar que o requisito da aula 1: logs de
produção, que mostram o intervalo entre uma requisição e a seguinte da mesma sessão, ou analytics,
que mostram quanto tempo as pessoas ficam em cada página. Sem nenhum dos dois, alguns segundos por
página é um palpite defensável, escrito como palpite. Um tempo de pensamento fixo também faz todos os
usuários baterem no mesmo compasso, então as ferramentas deixam ele variar ao acaso em torno da
média; os timers do JMeter na aula 4 fazem exatamente isso.

## Cadência

O tempo de pensamento é medido do fim de uma requisição ao início da próxima. **A cadência é medida
do início de uma iteração ao início da seguinte**: cada usuário virtual começa uma passada nova a
cada N segundos, por mais que a anterior tenha demorado, e dorme só o que sobrar. Com cadência, um
servidor mais lento não reduz a taxa com que cada usuário começa, até uma passada levar mais que N e
não sobrar nada para dormir. É um jeito de manter um modelo fechado mais perto de uma taxa, e o
`users.py` não o implementa; a aula 4 mostra um timer do JMeter que implementa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l03-timeline\" aria-label=\"Um usuário virtual ao longo do tempo, desenhado duas vezes. Em cima, com tempo de pensamento: cada requisição é seguida do seu tempo de resposta e depois de um tempo de pensamento fixo, medido a partir do fim da resposta, então uma resposta lenta, desenhada como a segunda, mais longa, empurra todas as requisições seguintes para trás. Embaixo, com cadência: uma nova iteração começa em intervalos fixos medidos de início a início, e a pausa encolhe para preencher o que a resposta deixou, então a resposta lenta não move o próximo início.\"><defs><marker id=\"l03-timeline-nf-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20.0\" y=\"75.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pensamento</text><rect x=\"120.0\" y=\"66.0\" width=\"40.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><path d=\"M160.0 75.0 L260.0 75.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 3\"></path><rect x=\"260.0\" y=\"66.0\" width=\"110.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><path d=\"M370.0 75.0 L470.0 75.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 3\"></path><rect x=\"470.0\" y=\"66.0\" width=\"40.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><path d=\"M510.0 75.0 L610.0 75.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 3\"></path><rect x=\"610.0\" y=\"66.0\" width=\"40.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"140.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">R</text><text x=\"210.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">Z</text><text x=\"315.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma resposta lenta empurra tudo o que vem depois</text><text x=\"20.0\" y=\"165.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">cadência</text><rect x=\"120.0\" y=\"156.0\" width=\"40.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><path d=\"M160.0 165.0 L252.0 165.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 3\"></path><path d=\"M120.0 181.0 L120.0 189.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"260.0\" y=\"156.0\" width=\"110.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><path d=\"M370.0 165.0 L392.0 165.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 3\"></path><path d=\"M260.0 181.0 L260.0 189.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"400.0\" y=\"156.0\" width=\"40.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><path d=\"M440.0 165.0 L532.0 165.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 3\"></path><path d=\"M400.0 181.0 L400.0 189.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"540.0\" y=\"156.0\" width=\"40.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><path d=\"M580.0 165.0 L672.0 165.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 3\"></path><path d=\"M540.0 181.0 L540.0 189.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M680.0 181.0 L680.0 189.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M122.0 199.0 L258.0 199.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l03-timeline-nf-ah-paper-dim)\" marker-start=\"url(#l03-timeline-nf-ah-paper-dim)\"></path><text x=\"190.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">de início a início, fixo</text><text x=\"370.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">quem encolhe é a pausa</text></svg>", "caption": "O tempo de pensamento conta a partir do fim de uma resposta; a cadência, do início de uma iteração. Só a cadência mantém a taxa de um usuário quando o servidor fica lento."}
```

## Rampa

O quarto argumento espalha a partida dos usuários por um número de segundos. **Uma rampa existe
para o teste não abrir com um pico que ninguém pediu**: duzentos usuários começando no mesmo instante
enviam duzentas requisições no mesmo instante, e os primeiros segundos do resultado descrevem essa
rajada em vez da carga sendo testada. Uma rampa também deixa caches, pools de conexão e o
interpretador esquentarem, e mostra o ponto em que os tempos de resposta começam a subir conforme os
usuários são acrescentados.

A medição começa quando a rampa termina. O `users.py` conta só as requisições que terminaram depois,
e toda ferramenta deste curso tem um jeito de separar a rampa da parte estável, porque a média das
duas produz um número que não descreve nenhuma delas.

Quanto tempo de rampa? O bastante para os usuários chegarem a uma taxa que o sistema encontra na vida
real. Para um sistema que vê o tráfego crescer ao longo de uma manhã, uma rampa de vários minutos é
cautelosa e honesta. Na venda das 10:00 a chegada é justamente o ponto, e esse teste é um pico da
aula 2, e não um teste de carga com uma rampa curta.
