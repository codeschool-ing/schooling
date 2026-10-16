---
title: "Strategy e observer: comportamento que se troca, eventos que se acompanham"
version: 1
---

**Strategy põe uma decisão que varia atrás de uma interface, para o objeto que precisa dela poder
receber outra; observer deixa um objeto anunciar que algo aconteceu a qualquer número de ouvintes
dos quais ele não sabe nada.** São os dois padrões comportamentais com mais chance de estar no
código em que você trabalha hoje, muitas vezes sem o nome.

## Strategy: uma decisão, vários jeitos de tomá-la

Um livro concorrido tem lista de espera. Quem o recebe em seguida? Quem chegou primeiro é a regra
óbvia. A comissão da biblioteca quer experimentar dar prioridade a quem tem menos empréstimos. No
próximo semestre pode ser outra coisa. A própria lista de espera não deveria mudar toda vez que a
comissão muda.

```schooling-example
{"language": "python", "file": "strategy.py", "parts": [
 {"code": "# strategy.py\nfrom dataclasses import dataclass\nfrom datetime import date\nfrom typing import Protocol\n\n\n@dataclass(frozen=True)\nclass Request:\n    member: str\n    placed: date\n    loans_held: int", "note": "Um pedido registra quando foi feito e quantos empréstimos o membro tem, que é tudo de que as duas regras precisam."},
 {"code": "\n\nclass Ordering(Protocol):\n    def order(self, requests: list[Request]) -> list[Request]: ...\n\n\nclass FirstCome:\n    def order(self, requests: list[Request]) -> list[Request]:\n        return sorted(requests, key=lambda r: r.placed)\n\n\nclass FewestLoansFirst:\n    def order(self, requests: list[Request]) -> list[Request]:\n        return sorted(requests, key=lambda r: (r.loans_held, r.placed))", "note": "A interface da strategy e duas strategies. Cada uma é uma regra inteira, e cada uma pode ser testada numa lista de pedidos sem lista de espera à vista."},
 {"code": "\n\nclass WaitingList:\n    def __init__(self, title: str, ordering: Ordering):\n        self.title, self.ordering = title, ordering\n        self._requests: list[Request] = []\n\n    def add(self, request: Request) -> None:\n        self._requests.append(request)\n\n    def queue(self) -> list[str]:\n        return [r.member for r in self.ordering.order(self._requests)]", "note": "O contexto, na palavra do livro. Ele guarda os pedidos e delega a única decisão que não é dele. `ordering` é um campo público, então a regra pode mudar enquanto a lista existe."},
 {"code": "\n\nif __name__ == \"__main__\":\n    waiting = WaitingList(\"Torto Arado\", FirstCome())\n    waiting.add(Request(\"Bia\", date(2026, 5, 1), loans_held=4))\n    waiting.add(Request(\"Caio\", date(2026, 5, 2), loans_held=0))\n    waiting.add(Request(\"Duda\", date(2026, 5, 3), loans_held=1))\n    print(\"first come:  \", waiting.queue())\n    waiting.ordering = FewestLoansFirst()\n    print(\"fewest loans:\", waiting.queue())", "note": "Os mesmos três pedidos, ordenados por cada regra."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 strategy.py
first come:   ['Bia', 'Caio', 'Duda']
fewest loans: ['Caio', 'Duda', 'Bia']
```

Bia pediu primeiro e tem quatro empréstimos, então lidera uma fila e fecha a outra. A próxima ideia
da comissão é uma classe nova com um método, e `WaitingList` fica como está: o princípio aberto/fechado
da lição 3, encontrado como padrão. Os canais da lição 1 já eram strategies para entregar um aviso,
antes de esta lição lhes dar o nome.

**Uma strategy com um método é uma função vestida de classe.** Em Python, `sorted(requests, key=...)`
já recebe a regra como argumento, e `FirstCome` poderia ser `lambda rs: sorted(rs, key=...)`. A classe
compensa quando a strategy guarda configurações ou tem mais de um método; a última seção de leitura
desta lição leva o caminho das funções adiante.

## Observer: anunciar sem saber quem escuta

Quando um livro volta, várias coisas devem acontecer: o primeiro da lista de espera é avisado, a
contagem de devoluções do dia sobe, e mais tarde talvez uma recomendação seja atualizada. O balcão
de devoluções não deveria ganhar uma linha para cada uma delas.

```schooling-example
{"language": "python", "file": "observer.py", "parts": [
 {"code": "# observer.py\nfrom typing import Protocol\n\n\nclass ReturnListener(Protocol):\n    def returned(self, title: str, member: str) -> None: ...", "note": "A interface do ouvinte. Qualquer coisa com um método `returned` pode ser avisada de uma devolução."},
 {"code": "\n\nclass ReturnsDesk:\n    def __init__(self):\n        self._listeners: list[ReturnListener] = []\n\n    def subscribe(self, listener: ReturnListener) -> None:\n        self._listeners.append(listener)\n\n    def unsubscribe(self, listener: ReturnListener) -> None:\n        self._listeners.remove(listener)\n\n    def give_back(self, title: str, member: str) -> None:\n        print(f\"desk: {member} returned {title}\")\n        for listener in list(self._listeners):\n            listener.returned(title, member)", "note": "O sujeito. Ele guarda uma lista de ouvintes e chama cada um depois de uma devolução. Ele percorre uma cópia, para um ouvinte poder cancelar a inscrição enquanto é avisado."},
 {"code": "\n\nclass ReservationAlert:\n    def __init__(self, waiting: dict[str, str]):\n        self._waiting = waiting\n\n    def returned(self, title: str, member: str) -> None:\n        if title in self._waiting:\n            print(f\"  alert: tell {self._waiting.pop(title)} that {title} is in\")\n\n\nclass ReturnCount:\n    def __init__(self):\n        self.today = 0\n\n    def returned(self, title: str, member: str) -> None:\n        self.today += 1\n        print(f\"  count: {self.today} returned today\")", "note": "Dois ouvintes que conhecem a interface do balcão e não um ao outro. Nenhum deles é citado em `ReturnsDesk`."},
 {"code": "\n\nif __name__ == \"__main__\":\n    desk = ReturnsDesk()\n    count = ReturnCount()\n    desk.subscribe(ReservationAlert({\"Vidas Secas\": \"Caio\"}))\n    desk.subscribe(count)\n    desk.give_back(\"Dom Casmurro\", \"Bia\")\n    desk.give_back(\"Vidas Secas\", \"Duda\")\n    desk.unsubscribe(count)\n    desk.give_back(\"Quincas Borba\", \"Bia\")", "note": "Três devoluções. A contagem cancela a inscrição antes da terceira, e o balcão não nota diferença."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 observer.py
desk: Bia returned Dom Casmurro
  count: 1 returned today
desk: Duda returned Vidas Secas
  alert: tell Caio that Vidas Secas is in
  count: 2 returned today
desk: Bia returned Quincas Borba
```

## O que o observer custa

O balcão não sabe mais o que acontece depois de uma devolução, e esse é o objetivo, e também o
preço. **Ler `give_back` não diz mais o que uma devolução faz**: a resposta está espalhada por quem se
inscreveu, e muda em tempo de execução. Três falhas decorrem disso.

Um ouvinte que levanta exceção interrompe o laço, e os ouvintes depois dele nunca são avisados.
Código de produção captura e registra o erro por ouvinte, e depois precisa decidir se um aviso que
falhou deve fazer a devolução falhar. Um ouvinte que nunca cancela a inscrição mantém o seu objeto
vivo enquanto o sujeito viver, o vazamento do "ouvinte esquecido". E a ordem dos avisos é a ordem das
inscrições, e é fácil passar a depender dela sem ninguém escrever isso em lugar nenhum.

Observer é a raiz de uma família grande. Tratadores de evento no navegador, os signals do Django e os
eventos de domínio da lição 12 são todos observer. A lição 16 o transforma num fluxo com operadores,
e a lição 18 mostra o que acontece quando a lista de ouvintes é alterada por uma thread enquanto
outra a percorre.
