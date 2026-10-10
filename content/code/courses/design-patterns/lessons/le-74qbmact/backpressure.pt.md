---
title: "Backpressure: quando o produtor é mais rápido que o consumidor"
version: 1
---

**Backpressure é o jeito de o consumidor dizer a um produtor que vá mais devagar.** Quando o
produtor não pode ir mais devagar, é a regra para o que acontece com os valores que não cabem. O pull
nunca precisou disso, porque um consumidor que puxa só pega o que dá conta. O push precisa, porque o
produtor decide quando um valor anda, e nada em `on_next` diz *agora não*.

A primeira resposta de costume é uma fila entre os dois. Uma fila absorve uma rajada: o leitor lê dez
livros em um minuto, a atualização do catálogo os trata nos cinco seguintes, e ninguém percebe. **Uma
fila não absorve uma taxa.** Se os valores chegam mais depressa do que saem, em média, por tempo
suficiente, a fila cresce enquanto isso durar, e o tempo que cada valor espera cresce junto.

Aqui está o balcão numa manhã cheia, simulado segundo a segundo para os números serem os mesmos em
toda execução. As leituras chegam a cinco por segundo e o catálogo acompanha duas:

```python
# flood.py
from collections import deque

PRODUCED_PER_SECOND = 5   # barcode scans arriving at the returns desk
HANDLED_PER_SECOND = 2    # what the catalogue update can keep up with

backlog: deque[int] = deque()
scanned = handled = 0
for second in range(1, 11):
    for _ in range(PRODUCED_PER_SECOND):
        scanned += 1
        backlog.append(scanned)
    for _ in range(HANDLED_PER_SECOND):
        backlog.popleft()
        handled += 1
    if second % 2 == 0:
        print(f"second {second:2}: scanned {scanned:2}, handled {handled:2}, waiting {len(backlog):2}")
print(f"the oldest waiting scan is #{backlog[0]}, from second {(backlog[0] - 1) // PRODUCED_PER_SECOND + 1}")
```

```
ana@laptop:~/patterns/reactive$ python3 flood.py
second  2: scanned 10, handled  4, waiting  6
second  4: scanned 20, handled  8, waiting 12
second  6: scanned 30, handled 12, waiting 18
second  8: scanned 40, handled 16, waiting 24
second 10: scanned 50, handled 20, waiting 30
the oldest waiting scan is #21, from second 5
```

O acúmulo cresce três a cada segundo, que é cinco entrando menos dois saindo, e depois de dez
segundos há trinta leituras esperando. A mais antiga é a leitura 21, feita no segundo 5, então um
membro que devolveu um livro naquele instante ainda o veria emprestado cinco segundos depois, e o
atraso cresce a cada segundo em que a taxa se mantém. Deixado rodando por uma hora, o acúmulo passa de
dez mil leituras e cada uma espera cerca de uma hora e meia. Uma fila sem limite transforma um
problema de velocidade num problema de memória e num problema de dado velho, e faz isso em silêncio:
nada falha até o processo ficar sem memória.

A lição 12 de `architecture` encontrou o mesmo problema entre serviços, e a lição 9 de `scale` o
encontrou na porta de entrada de um sistema. Esta seção é a versão dentro de um programa só, em que o
produtor e o consumidor são dois pedaços do seu próprio código.

## Um limite, e um produtor que espera

O backpressure mais simples é uma fila com limite e um produtor que espera quando ela está cheia. A
`queue.Queue` do Python faz as duas coisas: `put` bloqueia enquanto a fila tem `maxsize` itens. Aqui
duas threads de verdade, um leitor rápido e um catálogo lento, dividem uma fila de três:

```schooling-example
{"language": "python", "file": "blocking.py", "parts": [
 {"code": "# blocking.py\nimport queue\nimport threading\nimport time\n\ndesk: queue.Queue[int | None] = queue.Queue(maxsize=3)\nlargest = 0", "note": "A fila guarda no máximo três leituras. `largest` registra o maior acúmulo que o leitor chegou a ver."},
 {"code": "\n\ndef scanner() -> None:\n    global largest\n    for scan in range(1, 13):\n        desk.put(scan)            # waits here while the queue is full\n        largest = max(largest, desk.qsize())\n    desk.put(None)                # nothing more is coming", "note": "O leitor faz doze leituras o mais depressa que consegue. Quando a fila está cheia, `put` só retorna depois que o catálogo tirou uma, e essa espera é o backpressure. O `None` no fim é o sinal de que não vem mais nada, o mesmo papel do `on_complete` num observable."},
 {"code": "\n\ndef catalogue(seen: list[int]) -> None:\n    while (scan := desk.get()) is not None:\n        time.sleep(0.02)          # the slow part\n        seen.append(scan)", "note": "O catálogo pega uma leitura, gasta 20 milissegundos nela e a registra. O operador morsa `:=` lê a próxima leitura e a testa numa linha só."},
 {"code": "\n\nseen: list[int] = []\nthreads = [threading.Thread(target=scanner), threading.Thread(target=catalogue, args=(seen,))]\nfor t in threads:\n    t.start()\nfor t in threads:\n    t.join()\nprint(\"handled:\", seen)\nprint(\"largest backlog:\", largest)\nprint(\"lost:\", 12 - len(seen))", "note": "Duas threads, iniciadas juntas e esperadas. A lição 18 trata do que threads custam; aqui elas só fazem os dois lados rodarem cada um no seu ritmo."}
]}
```

```
ana@laptop:~/patterns/reactive$ python3 blocking.py
handled: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
largest backlog: 3
lost: 0
```

As doze leituras chegaram, em ordem, nenhuma se perdeu, e o acúmulo nunca passou de três. O programa
não imprime tempos porque eles variam de uma execução para outra; estas três linhas não variam,
porque o limite e a ordem são garantidos pela fila, faça o escalonador o que fizer. O que o limite
custou foi o tempo do leitor: ele passou a maior parte da execução esperando dentro de `put`, no
ritmo do catálogo em vez do seu.

## Demanda: pull para a permissão, push para os dados

Bloquear uma thread é um jeito de dizer ao produtor que espere. A especificação Reactive Streams, que
o Java adotou na versão 9 como `java.util.concurrent.Flow`, usa outro. Quem se inscreve não só recebe
valores; ele chama `request(n)` na sua inscrição para dizer quantos mais está pronto para receber, e o
publicador não pode mandar mais do que o total pedido. Um inscrito que trata uma leitura de cada vez
pede uma, trata, e pede a próxima.

São as duas metades da seção 02 juntas. Os dados são empurrados, então o inscrito nunca fica
perguntando, e a permissão é puxada, então o produtor nunca o afoga. Nenhuma thread precisa
bloquear: um publicador sem demanda pendente simplesmente segura o próximo valor até chegar um
pedido.

**A demanda só funciona quando o produtor consegue de fato se segurar.** Um leitor de arquivo pode parar
de ler e um cursor de banco de dados pode parar de buscar. O leitor de código de barras do balcão não
pode: o livro já passou por baixo dele e o membro já foi embora. Quando o produtor não pode esperar,
outra coisa tem de ceder, e a próxima seção conta as quatro escolhas de costume.
