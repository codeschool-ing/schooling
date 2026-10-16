---
title: Um gerador de carga que dá para ler
version: 1
---

Toda ferramenta de teste de carga deste curso faz as mesmas três coisas por baixo do seu próprio
vocabulário: envia requisições segundo um cronograma, cronometra cada uma e resume o que voltou.
**Antes de qualquer uma delas, você escreve uma pequena o bastante para ler em um minuto**, para
que, quando o JMeter na aula 4 ou o k6 na aula 5 relatar um número, você já saiba que tipo de
máquina o produziu.

São 47 linhas de Python, só biblioteca padrão, e ele recebe a forma da carga como argumentos: uma
lista de estágios, cada um uma taxa e uma duração. Crie um diretório para ele ao lado da
bilheteria:

```sh
mkdir -p ~/loadtest && cd ~/loadtest
```

Depois `nano hammer.py`, e cole o arquivo abaixo com o botão de copiar, que leva o programa sem as
notas:

```schooling-example
{"language": "python", "file": "loadtest/hammer.py", "parts": [{"code": "# loadtest/hammer.py\n# A tiny load generator. Each stage sends RATE requests a second for SECONDS\n# seconds, every request in a thread of its own, whether or not the earlier\n# ones have come back. Usage: python3 hammer.py URL RATE:SECONDS ...\nimport sys, threading, time, urllib.request\nfrom statistics import median\n\nurl = sys.argv[1]\nstages = [tuple(int(n) for n in s.split(\":\")) for s in sys.argv[2:]]\nresults = []                     # one (second sent, second done, ms, ok) per request\nlock = threading.Lock()\nt0 = time.perf_counter()\n", "note": "Só a biblioteca padrão, como a bilheteria. Os estágios chegam como pares `RATE:SECONDS`, então `10:3 200:2` quer dizer dez requisições por segundo durante três segundos, depois duzentas por segundo durante dois. `t0` é o momento em que a execução começa, e todo tempo abaixo é medido a partir dele."}, {"code": "def one(second):\n    start = time.perf_counter()\n    try:\n        with urllib.request.urlopen(url, timeout=10) as answer:\n            answer.read()\n        ok = True\n    except Exception:            # an error status, a refused connection, a timeout\n        ok = False\n    end = time.perf_counter()\n    with lock:\n        results.append((second, int(end - t0), (end - start) * 1000, ok))\n", "note": "Uma requisição, cronometrada do momento em que sai até o momento em que o corpo inteiro chegou. Qualquer coisa que dê errado conta como erro: um status 4xx ou 5xx (que o `urlopen` levanta como exceção), uma conexão que o servidor recusou, ou dez segundos sem resposta. A trava impede que duas threads acrescentem à lista no mesmo instante."}, {"code": "threads, second = [], 0\nfor rate, seconds in stages:\n    for _ in range(seconds):\n        for i in range(rate):\n            time.sleep(max(0, t0 + second + i / rate - time.perf_counter()))\n            thread = threading.Thread(target=one, args=(second,))\n            thread.start()\n            threads.append(thread)\n        second += 1\nfor thread in threads:\n    thread.join()\n", "note": "O cronograma. A requisição `i` de um segundo está marcada para `i / rate` dentro dele, e o laço dorme até lá e inicia uma thread para ela. **Ele não espera a resposta**, então um servidor lento não atrasa as chegadas: a próxima requisição sai na hora, aconteça o que tiver acontecido com a anterior. É assim que as pessoas chegam a uma bilheteria, e a aula 3 dá um nome a isso."}, {"code": "print(\"second  sent  done  errors  median ms  max ms\")\nfor s in range(second):\n    sent = [r for r in results if r[0] == s]\n    done = sum(1 for r in results if r[1] == s)\n    errors = sum(1 for r in sent if not r[3])\n    times = [r[2] for r in sent]\n    print(f\"{s:6}  {len(sent):4}  {done:4}  {errors:6}  {median(times):9.0f}  {max(times):6.0f}\")\nlate = sum(1 for r in results if r[1] >= second)\nprint(f\"{late} answers came back after second {second - 1};\"\n      f\" the last at {time.perf_counter() - t0:.1f} s\")", "note": "Uma linha para cada segundo do cronograma. `sent` e os dois tempos descrevem as requisições enviadas naquele segundo; `done` conta as respostas que chegaram nele, que é a vazão que o servidor conseguiu. A última linha diz quantas respostas ainda estavam chegando depois que o cronograma tinha terminado."}]}
```

Duas coisas nele importam mais do que o seu tamanho.

**Ele envia segundo um cronograma e nunca espera uma resposta.** Dez requisições por segundo
quer dizer uma a cada décimo de segundo, cada uma numa thread própria, tenha a anterior voltado ou
não. Um gerador que enviasse a próxima requisição só depois da última resposta ficaria mais lento
exatamente quando o servidor ficasse, e relataria um número agradável sobre um sistema que estava
se afogando. A aula 3 trata dessa escolha e das suas consequências.

**Ele roda na mesma máquina que a aplicação que mede.** Cada thread que ele inicia custa tempo de
processador que o servidor poderia ter usado. Nas taxas desta aula esse custo é pequeno, e
"Acrescentando processadores", no fim desta aula, coloca os dois em processadores diferentes para
mantê-los separados. Num teste de verdade o gerador roda numa máquina própria, e a aula 4 mostra
como uma ferramenta o espalha por várias.
