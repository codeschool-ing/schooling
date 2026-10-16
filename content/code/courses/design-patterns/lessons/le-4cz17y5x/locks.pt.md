---
title: Travas, e o deadlock que elas tornam possível
version: 1
---

**Uma trava torna um grupo de passos atômico ao deixar só uma thread lá dentro por vez.** Toda
outra thread que chega à porta espera até a de dentro sair. É a correção mais antiga para uma
corrida, e a certa mais vezes do que a fama dela sugere. Ela também traz uma falha que um programa
sem travas não pode ter: duas threads, cada uma esperando a outra, para sempre.

## O contador, corrigido

A única mudança em relação a `race.py` é uma trava criada junto com o contador e um `with` em
volta dos três passos:

```python
# locks.py
import threading
import time


class LoanCounter:
    def __init__(self):
        self.issued = 0
        self._lock = threading.Lock()

    def record(self) -> None:
        with self._lock:
            seen = self.issued
            time.sleep(0)
            self.issued = seen + 1


def desk(counter: LoanCounter, loans: int) -> None:
    for _ in range(loans):
        counter.record()


if __name__ == "__main__":
    counter = LoanCounter()
    desks = [threading.Thread(target=desk, args=(counter, 1000)) for _ in range(4)]
    for d in desks:
        d.start()
    for d in desks:
        d.join()
    print("loans recorded: 4000")
    print("counter says:  ", counter.issued)
```

```
ana@laptop:~/patterns/concurrency$ python3 locks.py
loans recorded: 4000
counter says:   4000
```

O `sleep(0)` continua lá, e outra thread continua podendo rodar durante ele. Essa thread chega a
`with self._lock`, encontra a trava ocupada e espera, então ninguém lê a contagem enquanto ela está
entre uma leitura e uma escrita. A trava mora dentro de `LoanCounter`, ao lado do estado que ela
protege, e esse é o encapsulamento da lição 1 fazendo um trabalho novo: **quem chama não tem como
esquecer uma trava que nunca vê.**

## Duas travas, duas ordens

O problema começa quando uma operação precisa de duas travas. Bia quer passar a reserva dela de
*Vidas Secas* para Caio e, no mesmo momento, em outro balcão, Caio passa uma das dele para Bia.
Cada troca trava quem cede, confere as reservas de quem cede e então trava quem recebe.

```schooling-example
{"language": "python", "file": "deadlock.py", "parts": [
 {"code": "# deadlock.py\nimport threading\nimport time\n\n\nclass Member:\n    def __init__(self, number: int, name: str):\n        self.number = number\n        self.name = name\n        self.lock = threading.Lock()", "note": "Cada membro carrega uma trava própria, então uma troca envolvendo Bia bloqueia qualquer outra mudança em Bia enquanto roda."},
 {"code": "\ndef swap_reservation(giver: Member, taker: Member, log: list[str]) -> None:\n    with giver.lock:\n        time.sleep(0.1)  # checking the giver's reservations\n        if taker.lock.acquire(timeout=1):\n            log.append(f\"{giver.name} -> {taker.name}: swapped\")\n            taker.lock.release()\n        else:\n            log.append(f\"{giver.name} -> {taker.name}: gave up waiting for {taker.name}\")", "note": "Primeiro quem cede, depois quem recebe. O `acquire(timeout=1)` está ali para o programa relatar uma troca travada em vez de prender o seu terminal."},
 {"code": "\nif __name__ == \"__main__\":\n    bia, caio = Member(17, \"Bia\"), Member(42, \"Caio\")\n    log: list[str] = []\n    desks = [threading.Thread(target=swap_reservation, args=(bia, caio, log)),\n             threading.Thread(target=swap_reservation, args=(caio, bia, log))]\n    for d in desks:\n        d.start()\n    for d in desks:\n        d.join()\n    print(\"\\n\".join(sorted(log)))", "note": "Dois balcões, duas trocas em sentidos opostos, iniciadas juntas. O log é ordenado para as linhas saírem na mesma ordem não importa qual thread escreveu primeiro."}
]}
```

```
ana@laptop:~/patterns/concurrency$ python3 deadlock.py
Bia -> Caio: gave up waiting for Caio
Caio -> Bia: swapped
```

O primeiro balcão pegou a trava de Bia e o segundo pegou a de Caio. Cada um então pediu a do
outro, e nenhum conseguiu, porque nenhum soltava a que segurava. Isso é um **deadlock**, e a figura
o desenha como o que ele é: um ciclo de espera.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l18-deadlock\" aria-label=\"Dois grafos de espera lado a lado. À esquerda, cada balcão trava primeiro quem cede: o balcão 1 segura a trava de Bia e espera a de Caio, enquanto o balcão 2 segura a trava de Caio e espera a de Bia. As setas formam um ciclo fechado, e nenhum balcão consegue andar. À direita, os dois balcões pegam primeiro a trava de número menor: o balcão 1 segura a trava de Bia, número 17, e em seguida pega a de Caio, número 42, enquanto o balcão 2 espera a trava 17. Não há ciclo, então o balcão 1 termina e depois o balcão 2 roda.\"><defs><marker id=\"l18-deadlock-dp-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18-deadlock-dp-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"170.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">cada balcão trava primeiro quem cede</text><rect x=\"105.0\" y=\"51.0\" width=\"130.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">trava de Bia, 17</text><rect x=\"105.0\" y=\"221.0\" width=\"130.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">trava de Caio, 42</text><rect x=\"10.0\" y=\"136.0\" width=\"90.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"55.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">balcão 1</text><rect x=\"240.0\" y=\"136.0\" width=\"90.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">balcão 2</text><path d=\"M105.0 74.0 L55.0 136.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l18-deadlock-dp-ah-phosphor)\"></path><path d=\"M55.0 166.0 L105.0 228.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l18-deadlock-dp-ah-amber)\"></path><path d=\"M235.0 228.0 L285.0 166.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l18-deadlock-dp-ah-phosphor)\"></path><path d=\"M285.0 136.0 L235.0 74.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l18-deadlock-dp-ah-amber)\"></path><text x=\"170.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">um ciclo: ninguém anda</text><path d=\"M360.0 10.0 L360.0 262.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"530.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">os dois travam primeiro o número menor</text><rect x=\"465.0\" y=\"51.0\" width=\"130.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"530.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">trava de Bia, 17</text><rect x=\"465.0\" y=\"221.0\" width=\"130.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"530.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">trava de Caio, 42</text><rect x=\"370.0\" y=\"136.0\" width=\"90.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"415.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">balcão 1</text><rect x=\"600.0\" y=\"136.0\" width=\"90.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"645.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">balcão 2</text><path d=\"M465.0 74.0 L415.0 136.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l18-deadlock-dp-ah-phosphor)\"></path><path d=\"M465.0 228.0 L415.0 166.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l18-deadlock-dp-ah-phosphor)\"></path><path d=\"M645.0 136.0 L595.0 74.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l18-deadlock-dp-ah-amber)\"></path><text x=\"530.0\" y=\"144.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sem ciclo: o balcão 2 espera,</text><text x=\"530.0\" y=\"157.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o balcão 1 termina</text><path d=\"M190.0 284.0 L230.0 284.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"238.0\" y=\"284.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">segura</text><path d=\"M420.0 284.0 L460.0 284.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"468.0\" y=\"284.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">espera</text></svg>", "caption": "Um deadlock é um ciclo de espera. Uma ordem combinada para pegar as travas torna o ciclo impossível."}
```

O timeout é o único motivo de o programa ter terminado. Um balcão desistiu depois de um segundo e
soltou a trava que segurava, o que deixou o outro terminar. Sem `timeout=1` as duas threads
esperariam para sempre, sem usar processador e sem imprimir nada, e o programa pareceria
exatamente um programa pensando. Qual balcão desiste primeiro depende de qual thread começou uma
fração antes, então na sua máquina os nomes na saída podem aparecer invertidos.

## A correção é uma ordem

Um deadlock precisa de um ciclo, e um ciclo precisa de duas threads pegando as mesmas travas em
ordens diferentes. **Combine uma única ordem para todas as travas e o ciclo não tem como se
formar.** Membros têm números, então pegue primeiro o número menor, não importa quem cede:

```python
# deadlock.py
import threading
import time


class Member:
    def __init__(self, number: int, name: str):
        self.number = number
        self.name = name
        self.lock = threading.Lock()


def swap_reservation(giver: Member, taker: Member, log: list[str]) -> None:
    first, second = sorted((giver, taker), key=lambda m: m.number)
    with first.lock:
        time.sleep(0.1)  # checking the giver's reservations
        if second.lock.acquire(timeout=1):
            log.append(f"{giver.name} -> {taker.name}: swapped")
            second.lock.release()
        else:
            log.append(f"{giver.name} -> {taker.name}: gave up waiting for {second.name}")


if __name__ == "__main__":
    bia, caio = Member(17, "Bia"), Member(42, "Caio")
    log: list[str] = []
    desks = [threading.Thread(target=swap_reservation, args=(bia, caio, log)),
             threading.Thread(target=swap_reservation, args=(caio, bia, log))]
    for d in desks:
        d.start()
    for d in desks:
        d.join()
    print("\n".join(sorted(log)))
```

```
ana@laptop:~/patterns/concurrency$ python3 deadlock.py
Bia -> Caio: swapped
Caio -> Bia: swapped
```

As duas trocas agora passam. O segundo balcão espera na trava de Bia, número 17, até o primeiro
terminar com as duas, e então pega a vez dele.

## Quatro regras para conviver com travas

- Mantenha curto o trabalho dentro de uma trava, e nunca espere a rede ou uma pessoa segurando uma.
- Pegue várias travas numa ordem combinada, e escreva essa ordem ao lado das travas.
- Nunca chame código que você não controla segurando uma trava; a seção 06 mostra o que esse código
  pode fazer.
- Prefira um timeout a uma espera sem limite onde quer que uma thread presa fosse ficar invisível.

Toda linguagem tem a mesma ferramenta com outro nome. Java tem blocos `synchronized` e
`ReentrantLock`, cujo `tryLock(1, SECONDS)` é o timeout acima. Go tem `sync.Mutex`, sem timeout, e
o runtime dele para o programa com *all goroutines are asleep - deadlock!* quando todas as
goroutines estão bloqueadas. O `threading.RLock` do Python é uma trava que a mesma thread pode pegar
duas vezes, o que evita o deadlock consigo mesma e esconde a pergunta de por que você precisou
disso.
