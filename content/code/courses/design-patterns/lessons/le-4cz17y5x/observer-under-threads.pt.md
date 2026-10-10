---
title: "O observer com threads: uma lista que muda enquanto você a percorre"
version: 1
---

**O sujeito de um observer percorre sua lista de ouvintes, e a lição 6 supôs que a lista ficaria
parada enquanto isso.** Com threads, outra thread pode inscrever ou desinscrever alguém no meio de
uma notificação. Às vezes o Python percebe e lança um erro; com uma lista comum ele não percebe
nada, e um ouvinte simplesmente perde o evento.

A biblioteca publica um evento quando um livro volta. Três ouvintes se interessam: o balcão de
multas, um e-mail para o membro e as estatísticas. Enquanto o ouvinte do e-mail conversa com o
servidor de correio, outra thread fecha o balcão de multas por hoje e o desinscreve.

```schooling-example
{"language": "python", "file": "observers.py", "parts": [
 {"code": "# observers.py\nimport threading\nimport time\nfrom typing import Callable\n\nListener = Callable[[str], None]\n\n\nclass LoanEvents:\n    def __init__(self):\n        self._listeners: list[Listener] = []\n\n    def subscribe(self, listener: Listener) -> None:\n        self._listeners.append(listener)\n\n    def unsubscribe(self, listener: Listener) -> None:\n        self._listeners.remove(listener)\n\n    def publish(self, event: str) -> None:\n        for listener in self._listeners:\n            listener(event)", "note": "Um sujeito no formato que a lição 6 deu a ele: uma lista de chamáveis, e `publish` a percorre."},
 {"code": "\nreceived: dict[str, list[str]] = {\"fines\": [], \"e-mail\": [], \"stats\": []}\nemailing = threading.Event()\n\n\ndef fines(event: str) -> None:\n    received[\"fines\"].append(event)\n\n\ndef email(event: str) -> None:\n    received[\"e-mail\"].append(event)\n    emailing.set()\n    time.sleep(0.1)  # talking to the mail server\n\n\ndef stats(event: str) -> None:\n    received[\"stats\"].append(event)", "note": "Três ouvintes que anotam o que ouviram. `emailing` é um evento que o ouvinte do e-mail aciona, para a outra thread agir num momento conhecido em vez de num momento de sorte."},
 {"code": "\nif __name__ == \"__main__\":\n    events = LoanEvents()\n    for listener in (fines, email, stats):\n        events.subscribe(listener)\n\n    def closing_the_fines_desk() -> None:\n        emailing.wait()\n        events.unsubscribe(fines)\n\n    other = threading.Thread(target=closing_the_fines_desk)\n    other.start()\n    events.publish(\"Dom Casmurro returned\")\n    other.join()\n    for name, got in received.items():\n        print(f\"{name:<7} {got}\")", "note": "A segunda thread espera até o e-mail estar sendo enviado e então desinscreve o balcão de multas. A thread principal publica um evento."}
]}
```

```
ana@laptop:~/patterns/concurrency$ python3 observers.py
fines   ['Dom Casmurro returned']
e-mail  ['Dom Casmurro returned']
stats   []
```

As estatísticas nunca ficaram sabendo da devolução, e nada avisou. O laço em `publish` guarda uma
posição, não uma lista de quem falta. Ele já tinha tratado a posição 0 e estava dentro da posição 1
quando o balcão de multas foi removido da posição 0, então o ouvinte do e-mail escorregou para 0 e
as estatísticas para 1. O laço pediu a posição 2, encontrou o fim da lista e parou. **Um ouvinte
pulado, nenhuma exceção, e um relatório mensal silenciosamente incompleto.**

Se os ouvintes estivessem num dicionário ou num conjunto, o Python teria lançado `RuntimeError` com
as palavras *changed size during iteration*. Essa é a falha melhor. Uma lista comum não dá esse
aviso, e um append no meio do percurso é igualmente silencioso no outro sentido: um ouvinte
acrescentado durante uma publicação pode receber um evento que aconteceu antes de ele se
inscrever.

## Copie dentro da trava, chame fora dela

A correção tem duas metades, e as duas importam.

```schooling-example
{"language": "python", "file": "observers.py", "parts": [
 {"code": "# observers.py\nimport threading\nimport time\nfrom typing import Callable\n\nListener = Callable[[str], None]\n\n\nclass LoanEvents:\n    def __init__(self):\n        self._listeners: list[Listener] = []\n        self._lock = threading.Lock()\n\n    def subscribe(self, listener: Listener) -> None:\n        with self._lock:\n            self._listeners.append(listener)\n\n    def unsubscribe(self, listener: Listener) -> None:\n        with self._lock:\n            self._listeners.remove(listener)", "note": "Uma trava protege a lista. Inscrever e desinscrever pegam a trava, então a lista nunca fica mudada pela metade."},
 {"code": "\n    def publish(self, event: str) -> None:\n        with self._lock:\n            listeners = list(self._listeners)\n        for listener in listeners:\n            listener(event)", "note": "`publish` copia a lista segurando a trava, solta, e só então chama os ouvintes. O percurso é sobre um retrato que ninguém mais consegue mudar."},
 {"code": "\nreceived: dict[str, list[str]] = {\"fines\": [], \"e-mail\": [], \"stats\": []}\nemailing = threading.Event()\n\n\ndef fines(event: str) -> None:\n    received[\"fines\"].append(event)\n\n\ndef email(event: str) -> None:\n    received[\"e-mail\"].append(event)\n    emailing.set()\n    time.sleep(0.1)  # talking to the mail server\n\n\ndef stats(event: str) -> None:\n    received[\"stats\"].append(event)\n\n\nif __name__ == \"__main__\":\n    events = LoanEvents()\n    for listener in (fines, email, stats):\n        events.subscribe(listener)\n\n    def closing_the_fines_desk() -> None:\n        emailing.wait()\n        events.unsubscribe(fines)\n\n    other = threading.Thread(target=closing_the_fines_desk)\n    other.start()\n    events.publish(\"Dom Casmurro returned\")\n    other.join()\n    for name, got in received.items():\n        print(f\"{name:<7} {got}\")", "note": "Tudo daqui para baixo é o mesmo programa de antes."}
]}
```

```
ana@laptop:~/patterns/concurrency$ python3 observers.py
fines   ['Dom Casmurro returned']
e-mail  ['Dom Casmurro returned']
stats   ['Dom Casmurro returned']
```

Os três ouviram. Por que não simplesmente segurar a trava durante o `publish` inteiro? Porque os
ouvintes são código que o sujeito não controla. Um que leva 0,1 segundo para mandar um e-mail
seguraria toda inscrição e desinscrição por esse tempo. Pior, um que inscreve outro ouvinte de
dentro do próprio callback pediria uma trava que a própria thread já segura, e com uma `Lock` comum
essa thread entra em deadlock consigo mesma. **Segure uma trava em volta dos seus dados, nunca em
volta de uma chamada para o código de outra pessoa.**

O retrato tem um custo que vale dizer: um ouvinte desinscrito durante uma publicação ainda pode
receber aquele evento, porque estava na cópia. Para os avisos de uma biblioteca isso não faz mal.
Onde fizer, o ouvinte precisa conferir se ainda quer eventos, e o sujeito não pode fazer isso por
ele.

## O que o padrão não dizia

O observer da lição 6 também roda todos os ouvintes na thread de quem publica, um depois do outro. O
0,1 segundo do e-mail foi 0,1 segundo que o balcão da devolução passou esperando. O
`CopyOnWriteArrayList` do Java existe exatamente para esse formato de retratar-e-percorrer. Os
fluxos reativos da lição 16 e os atores da lição 17 são, entre outras coisas, duas respostas
diferentes para *em que thread o ouvinte roda?*, que é a pergunta que este padrão nunca precisou
fazer.
