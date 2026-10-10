---
title: "Condições de corrida: duas threads, um número, uma atualização perdida"
version: 1
---

**Uma condição de corrida é um resultado que depende de como duas threads calham de se
intercalar.** Costuma ser imaginada como rara e exótica, um defeito para quem escreve sistema
operacional. É o defeito mais comum do código concorrente, e não precisa de nada além de duas
threads que leem um valor compartilhado, mudam e escrevem de volta.

A biblioteca conta os empréstimos que faz. Quatro balcões registram empréstimos ao mesmo tempo,
mil cada um, num único contador. Cada `record` tem três passos: ler a contagem, somar um,
escrever. O programa alarga o vão entre ler e escrever com `time.sleep(0)`, que não espera nada e
só avisa o interpretador de que outra thread pode rodar agora. Em código de verdade esse vão é uma
chamada ao banco, uma linha de log ou simplesmente azar.

```schooling-example
{"language": "python", "file": "race.py", "parts": [
 {"code": "# race.py\nimport threading\nimport time\n\n\nclass LoanCounter:\n    def __init__(self):\n        self.issued = 0", "note": "O contador é um objeto comum com um inteiro dentro, como cem classes das lições 2 a 15."},
 {"code": "\n    def record(self) -> None:\n        seen = self.issued      # read\n        time.sleep(0)           # let another thread run here\n        self.issued = seen + 1  # write", "note": "Ler, pausar, escrever. Entre a primeira linha e a terceira, qualquer outro balcão pode ler o mesmo valor antigo."},
 {"code": "\ndef desk(counter: LoanCounter, loans: int) -> None:\n    for _ in range(loans):\n        counter.record()", "note": "Um balcão registra seus empréstimos um depois do outro. Dentro de uma única thread não há nada de errado neste código."},
 {"code": "\nif __name__ == \"__main__\":\n    counter = LoanCounter()\n    desks = [threading.Thread(target=desk, args=(counter, 1000)) for _ in range(4)]\n    for d in desks:\n        d.start()\n    for d in desks:\n        d.join()\n    print(\"loans recorded: 4000\")\n    print(\"counter says:  \", counter.issued)", "note": "Quatro threads, mil empréstimos cada. O `join` espera cada thread terminar antes de a contagem ser impressa."}
]}
```

Rode duas vezes:

```
ana@laptop:~/patterns/concurrency$ python3 race.py
loans recorded: 4000
counter says:   1006
ana@laptop:~/patterns/concurrency$ python3 race.py
loans recorded: 4000
counter says:   1004
```

Entraram quatro mil empréstimos e saiu cerca de mil. O número exato pode variar um pouco de uma
execução para outra, então o seu pode ser diferente destes. Nenhuma exceção foi lançada e nenhuma
linha de `record` está errada sozinha. **Três quartos das atualizações se perderam, e o programa
terminou como se nada tivesse acontecido.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 300\" role=\"img\" data-fig=\"l18-lost-update\" aria-label=\"Uma linha do tempo de uma atualização perdida, lida de cima para baixo. O balcão A fica à esquerda, o contador compartilhado no meio e o balcão B à direita. Primeiro o balcão A lê o contador, 7. Depois o balcão B lê, também 7. O balcão A escreve 7 mais 1, e o contador vira 8. O balcão B também escreve 7 mais 1, e o contador é 8 de novo. Dois empréstimos foram registrados e o contador andou um.\"><defs><marker id=\"l18-lost-update-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l18-lost-update-dp-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"55.0\" y=\"16.0\" width=\"150.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">balcão A</text><rect x=\"255.0\" y=\"16.0\" width=\"130.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">issued</text><rect x=\"435.0\" y=\"16.0\" width=\"150.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">balcão B</text><path d=\"M130.0 44.0 L130.0 65.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M130.0 91.0 L130.0 153.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M130.0 179.0 L130.0 238.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M320.0 44.0 L320.0 65.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M320.0 91.0 L320.0 109.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M320.0 135.0 L320.0 153.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M320.0 179.0 L320.0 197.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M320.0 223.0 L320.0 238.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M510.0 44.0 L510.0 109.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M510.0 135.0 L510.0 197.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M510.0 223.0 L510.0 238.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M28.0 60.0 L28.0 236.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l18-lost-update-dp-ah-paper-dim)\"></path><text x=\"40.0\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">tempo</text><rect x=\"55.0\" y=\"65.0\" width=\"150.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">lê: seen = 7</text><rect x=\"297.0\" y=\"65.0\" width=\"46.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7</text><path d=\"M297.0 78.0 L205.0 78.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-lost-update-dp-ah-paper-dim)\"></path><rect x=\"435.0\" y=\"109.0\" width=\"150.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">lê: seen = 7</text><rect x=\"297.0\" y=\"109.0\" width=\"46.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7</text><path d=\"M343.0 122.0 L435.0 122.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-lost-update-dp-ah-paper-dim)\"></path><rect x=\"55.0\" y=\"153.0\" width=\"150.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">escreve: 7 + 1</text><rect x=\"297.0\" y=\"153.0\" width=\"46.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">8</text><path d=\"M205.0 166.0 L297.0 166.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-lost-update-dp-ah-phosphor)\"></path><rect x=\"435.0\" y=\"197.0\" width=\"150.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">escreve: 7 + 1</text><rect x=\"297.0\" y=\"197.0\" width=\"46.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">8</text><path d=\"M435.0 210.0 L343.0 210.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-lost-update-dp-ah-phosphor)\"></path><text x=\"320.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">dois empréstimos registrados, o contador andou um</text><text x=\"320.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">B escreveu por cima de A: a atualização de A se perdeu</text></svg>", "caption": "Uma atualização perdida. Os dois balcões leem antes de qualquer um escrever, e a segunda escrita apaga a primeira."}
```

A figura é o mecanismo inteiro. O balcão A lê 7. Antes de ele escrever, o balcão B também lê 7. A
escreve 8, e então B escreve 8 por cima. Dois empréstimos foram feitos e o contador andou um. Com
quatro balcões e o vão forçado a ficar aberto, quase toda escrita cai em cima de outra, e por isso
a contagem termina perto de mil: sobrevive mais ou menos o equivalente às atualizações de um
balcão.

## Por que a linha óbvia parece funcionar

Tire a pausa e escreva a atualização do jeito que qualquer pessoa escreveria:

```python
# plus_equals.py
import threading


class LoanCounter:
    issued = 0


counter = LoanCounter()


def desk() -> None:
    for _ in range(1_000_000):
        counter.issued += 1


desks = [threading.Thread(target=desk) for _ in range(4)]
for d in desks:
    d.start()
for d in desks:
    d.join()
print("expected 4000000, got", counter.issued)
```

```
ana@laptop:~/patterns/concurrency$ python3 plus_equals.py
expected 4000000, got 4000000
```

Quatro milhões de incrementos e nenhum perdido. Essa é a armadilha. `counter.issued += 1` continua
sendo uma leitura, uma soma e uma escrita, e no Python 3.12 o interpretador calha de nunca trocar
de thread no meio desses poucos bytecodes. **Nada na linguagem promete isso.** O Python 3.9 e os
anteriores trocavam ali, a versão free-threaded roda as threads de fato ao mesmo tempo, e no
momento em que a linha ganha uma chamada de função entre a leitura e a escrita, o vão volta. Um
teste que passa mil vezes só prova que o vão não foi atingido nessas mil execuções.

## O formato a procurar

Uma corrida precisa de três coisas juntas: **estado compartilhado** entre threads, **pelo menos um
escritor** e uma operação que não é atômica, ou seja, que pode ser interrompida no meio. Os
formatos comuns são ler-modificar-escrever, como aqui, e verificar-depois-agir: *se há um exemplar
na estante, empreste*, em que dois balcões podem ver o último exemplar. O singleton da seção 05 e o
observer da seção 06 são os dois verificar-depois-agir disfarçados.

Em Java o mesmo contador perde atualizações com threads comuns, e a linguagem oferece
`AtomicInteger` ou `synchronized`. O Go traz um detector exatamente para isso, `go test -race`, que
relata as duas goroutines e as linhas em que elas correram. JavaScript no navegador ou no Node tem
uma thread por event loop, então este programa não pode ser escrito lá sem workers. Com um `await`
no meio, porém, o mesmo defeito de ler-pausar-escrever aparece numa thread só, porque um `await` é
um lugar onde outra coisa roda.

Tire qualquer uma das três e a corrida some. As próximas três seções tiram a terceira com uma
trava; a seção 07 tira a primeira e a segunda.
