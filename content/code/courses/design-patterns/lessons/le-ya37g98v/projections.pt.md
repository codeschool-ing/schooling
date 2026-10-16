---
title: "Projeções: modelos de leitura a partir de todo o histórico"
version: 1
---

**Uma projeção num sistema com event sourcing é o modelo de leitura da lição 8, alimentado pelo
event store em vez de um ouvinte ao vivo, e a diferença é que ela pode começar pelo primeiro evento
já escrito.** Ela guarda um checkpoint, a posição do último evento aplicado, e para se atualizar lê
tudo o que vem depois. Uma projeção criada hoje lê a partir da posição 0 e sabe tudo o que aconteceu
antes de ela existir.

Essa última propriedade é a que muda o jeito de as equipes trabalharem, e a crença que ela substitui
é que um relatório só pode mostrar dados que alguém decidiu coletar de antemão. Com os eventos
guardados, uma pergunta que ninguém fez no ano passado pode ser respondida sobre o ano passado.

```schooling-example
{"language": "python", "file": "projections.py", "parts": [
 {"code": "# projections.py\nfrom collections import Counter\nfrom store import EventStore", "note": "Duas projeções sobre o mesmo store. Nenhuma importa nada do lado da escrita além do store que lê."},
 {"code": "\n\nclass FinesOwed:\n    def __init__(self):\n        self.owed: dict[str, int] = {}\n        self.position = 0\n\n    def apply(self, position: int, event: dict) -> None:\n        member = event[\"stream\"].removeprefix(\"member-\")\n        if event[\"type\"] == \"CopyReturned\":\n            self.owed[member] = self.owed.get(member, 0) + event[\"fine\"]\n        elif event[\"type\"] == \"FinePaid\":\n            self.owed[member] = self.owed.get(member, 0) - event[\"amount\"]\n        self.position = position", "note": "Um modelo de leitura do que cada membro deve. Ele lembra a posição do último evento aplicado: o seu checkpoint, que diz até onde no histórico ele já leu."},
 {"code": "\n\nclass MostBorrowed:\n    def __init__(self):\n        self.count: Counter = Counter()\n        self.position = 0\n\n    def apply(self, position: int, event: dict) -> None:\n        if event[\"type\"] == \"CopyLent\":\n            self.count[event[\"title\"]] += 1\n        self.position = position", "note": "Um segundo modelo de leitura, contando empréstimos por título. Ele ignora todo evento que não é empréstimo, e mesmo assim avança o checkpoint por cima deles."},
 {"code": "\n\ndef catch_up(store: EventStore, projection) -> None:\n    for position, event in store.read_all(after=projection.position):\n        projection.apply(position, event)", "note": "Uma função serve às duas, e a qualquer projeção futura: ler todo evento depois do checkpoint, em ordem, e aplicá-lo. Rodando a partir da posição 0, ela constrói uma projeção com o histórico inteiro."},
 {"code": "\n\nif __name__ == \"__main__\":\n    store = EventStore(\":memory:\")\n    lent = lambda copy, title: {\"type\": \"CopyLent\", \"copy\": copy, \"title\": title}\n    returned = lambda copy, fine: {\"type\": \"CopyReturned\", \"copy\": copy, \"fine\": fine}\n    store.append(\"member-bia\", 0, [lent(\"C1\", \"Dom Casmurro\"), returned(\"C1\", 150),\n                                   {\"type\": \"FinePaid\", \"amount\": 150}, lent(\"C3\", \"Vidas Secas\")])\n    store.append(\"member-caio\", 0, [lent(\"C2\", \"Dom Casmurro\"), returned(\"C2\", 0)])\n    store.append(\"member-dani\", 0, [lent(\"C1\", \"Dom Casmurro\"), returned(\"C1\", 100)])\n\n    fines = FinesOwed()\n    catch_up(store, fines)\n    print(\"fines owed:\", fines.owed, \"at position\", fines.position)\n\n    store.append(\"member-caio\", 2, [lent(\"C4\", \"A Hora da Estrela\")])\n    popular = MostBorrowed()\n    catch_up(store, popular)\n    print(\"most borrowed:\", popular.count.most_common(2), \"at position\", popular.position)\n    catch_up(store, fines)\n    print(\"fines owed:\", fines.owed, \"at position\", fines.position)", "note": "O histórico de três membros, a projeção de multas construída e impressa, mais um empréstimo, e então uma projeção que não existia quando nenhum desses empréstimos aconteceu, construída a partir de todos eles. Por fim a projeção de multas se atualiza a partir de onde parou."}
]}
```

```
ana@laptop:~/patterns/events$ python3 projections.py
fines owed: {'bia': 0, 'caio': 0, 'dani': 100} at position 8
most borrowed: [('Dom Casmurro', 3), ('Vidas Secas', 1)] at position 9
fines owed: {'bia': 0, 'caio': 0, 'dani': 100} at position 9
```

Os 150 centavos da Bia foram pagos, o Caio devolveu no prazo, e a Dani deve 100, na posição 8, o
último evento do store. Então o Caio pega *A Hora da Estrela*, posição 9. `MostBorrowed` só é criado
agora, e mesmo assim informa que *Dom Casmurro* foi emprestado três vezes, a três membros, tudo antes
de ele existir. A projeção de multas se atualiza de 8 para 9 e seus números não mudam, porque um
empréstimo não gera dívida.

## O checkpoint é assunto da projeção

**Cada projeção guarda a própria posição, e nenhuma delas é "o" estado.** Elas podem estar em pontos
diferentes do histórico, e num sistema rodando normalmente estão, porque cada uma lê no seu ritmo.
Uma projeção que cai retoma do seu checkpoint; uma projeção que se revela errada é apagada e
reconstruída a partir do 0, com a correção no código. Nenhuma das duas coisas toca nos eventos.

É por isso que o lado da leitura da lição 8 podia ser chamado de dado derivado sem exagero. Aqui a
afirmação é literal: `FinesOwed()` com a posição de volta a 0 e `catch_up` chamado de novo produz
exatamente o mesmo dicionário, a partir exatamente dos mesmos eventos, toda vez.

## O que uma projeção pode e não pode fazer

Uma projeção lê eventos e escreve no seu próprio armazenamento. Ela não pode acrescentar eventos,
porque aí ler o histórico mudaria o histórico, e duas reconstruções poderiam diferir. Não pode chamar
o lado da escrita para pedir mais, pelo motivo que a lição 8 deu: se ela precisa de um fato, o evento
deveria carregá-lo.

Ela também precisa ser **determinística nos eventos**: nada de `date.today()`, nada de números
aleatórios, nada de consultas a uma tabela que pode ter mudado desde então. Uma projeção que calcula
"dias de atraso" a partir do relógio dá uma resposta diferente a cada reconstrução. A data de que ela
precisa pertence ao evento, do jeito que `CopyReturned` aqui carrega a sua multa em vez de deixar a
projeção calculá-la a partir da data de hoje.

## Modelos de leitura que sobrevivem às telas

Como projeções são baratas de jogar fora, uma equipe pode experimentar uma para uma única tela, mudar
a forma dela duas vezes num mês, e apagá-la quando a tela sair. Nada no lado da escrita se mexe. O
custo é tempo: reconstruir a partir do 0 sobre milhões de eventos leva minutos ou horas, e enquanto
uma projeção nova está se atualizando a tela dela mostra um histórico parcial. Sistemas de verdade
reconstroem ao lado da projeção antiga e trocam quando a nova chega à ponta do store.
