---
title: "Concorrência e paralelismo: duas palavras para duas coisas"
version: 1
---

**A imagem comum é que concorrência quer dizer fazer várias coisas no mesmo instante. Isso é
paralelismo, e é a mais estreita das duas palavras.** Concorrência é um jeito de estruturar um
programa para que várias tarefas estejam em andamento ao mesmo tempo: uma espera o disco enquanto
outra formata um recibo. Paralelismo é um jeito de executar um programa para que duas instruções
rodem no mesmo momento, em dois núcleos. Um programa pode ser concorrente num único núcleo, e só
pode ser paralelo se o trabalho e o ambiente de execução permitirem.

Todo padrão das lições 2 a 15 foi escrito como se uma única linha de execução percorresse o código.
Um empréstimo conferia as próprias regras, um sujeito avisava seus observadores, um repositório
devolvia um agregado, e nada mais rodava no meio. Esta lição tira essa premissa e olha o que
sobrevive.

Crie `~/patterns/concurrency` e trabalhe lá:

```sh
mkdir -p ~/patterns/concurrency
cd ~/patterns/concurrency
```

## Dois tipos de lentidão

O software da biblioteca é lento de dois jeitos diferentes. Procurar um livro num catálogo remoto
é lento porque **espera**: o programa manda um pedido e não faz nada até a resposta chegar. Montar
o relatório de atrasos é lento porque **calcula**: o processador fica ocupado o tempo todo. Este
programa faz quatro de cada, de três maneiras.

```schooling-example
{"language": "python", "file": "models.py", "parts": [
 {"code": "# models.py\nimport asyncio\nimport time\nfrom concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor\n\nISBNS = [\"978-85-01\", \"978-85-02\", \"978-85-03\", \"978-85-04\"]\n\n\ndef lookup(isbn: str) -> str:\n    time.sleep(0.25)  # waiting on a remote catalogue\n    return isbn", "note": "`lookup` faz o papel de uma chamada ao catálogo de outra biblioteca pela rede. `time.sleep` é espera, e ler um socket também: a thread fica estacionada e o processador fica livre."},
 {"code": "\nasync def lookup_async(isbn: str) -> str:\n    await asyncio.sleep(0.25)\n    return isbn", "note": "A mesma consulta para o `asyncio`. O `await` marca o único lugar em que esta função deixa outra coisa rodar, e é isso que torna o `asyncio` cooperativo."},
 {"code": "\ndef overdue_report(n: int) -> int:\n    total = 0\n    for day in range(n):\n        total += (day * 50) % 7\n    return total", "note": "O outro tipo de lentidão: aritmética pura, três milhões de passos, sem nada para esperar."},
 {"code": "\ndef timed(label: str, job) -> None:\n    start = time.perf_counter()\n    job()\n    print(f\"{label:<28} {time.perf_counter() - start:.2f} s\")\n\n\nasync def all_lookups() -> None:\n    await asyncio.gather(*(lookup_async(i) for i in ISBNS))", "note": "`timed` imprime quanto tempo um trabalho levou. `perf_counter` é o relógio feito para medir intervalos."},
 {"code": "\nif __name__ == \"__main__\":\n    print(\"-- waiting: 4 lookups of 0.25 s\")\n    timed(\"one after another\", lambda: [lookup(i) for i in ISBNS])\n    with ThreadPoolExecutor(4) as pool:\n        timed(\"4 threads\", lambda: list(pool.map(lookup, ISBNS)))\n    timed(\"asyncio, 1 thread\", lambda: asyncio.run(all_lookups()))", "note": "Esperar, de três maneiras: em sequência, em quatro threads e como quatro corrotinas numa thread só."},
 {"code": "\n    print(\"-- computing: 4 reports\")\n    WORK = [3_000_000] * 4\n    timed(\"one after another\", lambda: [overdue_report(n) for n in WORK])\n    with ThreadPoolExecutor(4) as pool:\n        timed(\"4 threads\", lambda: list(pool.map(overdue_report, WORK)))\n    with ProcessPoolExecutor(4) as pool:\n        timed(\"4 processes\", lambda: list(pool.map(overdue_report, WORK)))", "note": "Calcular, de três maneiras. O pool de processos inicia quatro interpretadores Python separados, e o tempo inclui iniciá-los."}
]}
```

```
ana@laptop:~/patterns/concurrency$ python3 models.py
-- waiting: 4 lookups of 0.25 s
one after another            1.00 s
4 threads                    0.25 s
asyncio, 1 thread            0.25 s
-- computing: 4 reports
one after another            0.61 s
4 threads                    0.61 s
4 processes                  0.17 s
```

Os seus tempos vão ser diferentes destes, e mudam um pouco a cada execução; o formato não muda.
Esperar passa de um segundo para um quarto de segundo com threads, e para o mesmo quarto com
`asyncio` numa thread só, porque quatro esperas se sobrepõem não importa quem faça a sobreposição.
Calcular é outra história. **Quatro threads não calcularam mais rápido que uma, e quatro processos
levaram cerca de um terço do tempo** neste notebook de quatro núcleos.

## A trava dentro do interpretador

O motivo é a **trava global do interpretador**, a GIL (*global interpreter lock*). O interpretador
CPython comum deixa só uma thread por vez executar bytecode Python num processo. Uma thread solta a
trava quando espera, no `sleep`, num socket ou lendo um arquivo, e por isso as quatro consultas se
sobrepuseram. Uma thread fazendo conta segura a trava e a passa adiante a cada poucos
milissegundos, então quatro delas se revezam num núcleo e ainda somam o custo da troca. Processos
separados têm cada um seu interpretador e sua GIL, e rodam de fato em paralelo; o preço é que não
compartilham memória, e tudo o que passa de um para outro é copiado.

O Python 3.13 trouxe uma **versão free-threaded** opcional, normalmente instalada como
`python3.13t`, sem GIL nenhuma, e o 3.14 a manteve como opção suportada. Com ela, as quatro threads
acima usariam quatro núcleos. Este curso roda a versão comum, e as próximas seções mostram por que
isso muda menos do que parece: a GIL nunca protegeu os *seus* dados, só os do próprio interpretador.

## Três modelos, e o que cada um compartilha

| modelo em Python | roda no mesmo instante? | compartilha memória? | onde uma troca pode acontecer |
|---|---|---|---|
| `asyncio` | não, uma thread | sim | só num `await` |
| `threading` | não para código Python na versão comum | sim | entre quase quaisquer dois bytecodes |
| `multiprocessing` | sim | não, as mensagens são copiadas | não se aplica: nada é compartilhado |

A última coluna é o assunto desta lição. No `asyncio` você pode ler um valor, calcular e escrevê-lo
de volta sem risco, porque nada mais roda até você escrever `await`. Com threads, o sistema
operacional pode pausar você entre a leitura e a escrita. Esse vão é onde as lições 2 a 15
supuseram, sem dizer, que ninguém estaria parado, e a próxima seção coloca alguém lá.
