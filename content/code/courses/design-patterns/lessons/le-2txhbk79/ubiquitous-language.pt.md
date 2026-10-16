---
title: "Linguagem ubíqua: uma palavra, um significado, em todo lugar"
version: 1
---

**Uma linguagem ubíqua é o conjunto de palavras que as pessoas que tocam o negócio e as pessoas que
escrevem o código usam igualmente, com o mesmo significado, na conversa, nos documentos e no próprio
código.** Foi Evans quem deu o nome. A palavra *ubíqua* é a exigência. As palavras aparecem nos nomes
das classes, nos nomes dos métodos e nas mensagens de erro, e um glossário numa wiki que o código
ignora não conta: uma bibliotecária deveria conseguir ler um stack trace e reconhecer ali o próprio
trabalho.

O estado comum das coisas é duas línguas e um tradutor. O negócio diz *a reserva caducou*; o código
diz `r["st"] = 4`. Alguém na equipe sabe que status 4 quer dizer caducou, e toda conversa passa pela
cabeça dessa pessoa. A tradução é por onde o significado vaza: no dia em que alguém acrescenta o
status 5 para "cancelada pelo sócio" e esquece que o relatório conta 4 e 5 juntos como "não
retirada", o relatório está errado e ninguém consegue ver isso pelo código.

## Escrever o glossário

Comece com uma tabela, feita com as bibliotecárias, das palavras que elas de fato usam. Não as
palavras que os desenvolvedores gostariam que elas usassem. Quatro linhas do glossário da
biblioteca, com o termo em inglês que o código usa:

| palavra | o que as bibliotecárias querem dizer | o que não é |
|---|---|---|
| reserva (hold) | o lugar de um sócio na fila de um título | um empréstimo; nada foi entregue |
| pôr na estante (shelve) | colocar um exemplar devolvido na estante de reservas para o primeiro da fila | devolvê-lo ao acervo |
| prazo de retirada (pickup deadline) | o último dia em que o sócio pode retirar: 7 dias depois de ir para a estante | a data de devolução do empréstimo |
| caducar (lapse) | o que acontece com uma reserva quando o prazo passa sem retirada; o exemplar vai para o próximo sócio | um cancelamento, que é o sócio quem pede |

A terceira coluna é onde está o valor. Cada linha ali é uma confusão que alguém da equipe teve, e
que o código teria gravado.

## As palavras no código

Eis o código que antes dizia `r["st"] = 4`, escrito com as palavras do glossário. Crie primeiro o
diretório da lição:

```sh
mkdir -p ~/patterns/ddd-strategic
cd ~/patterns/ddd-strategic
```

```schooling-example
{"language": "python", "file": "holds.py", "parts": [
 {"code": "# holds.py\nfrom datetime import date, timedelta\n\nPICKUP_DAYS = 7", "note": "`PICKUP_DAYS` é a \"semana na estante de reservas\" das bibliotecárias, com a palavra que elas usam."},
 {"code": "\n\nclass Hold:\n    def __init__(self, member: str, title: str, placed_on: date):\n        self.member = member\n        self.title = title\n        self.placed_on = placed_on\n        self.shelved_on: date | None = None\n        self.collected = False", "note": "Uma reserva é feita por um sócio para um título. Ela ainda não foi para a estante e não foi retirada; são essas as duas coisas que vão acontecer com ela."},
 {"code": "\n    def shelve(self, on: date) -> None:\n        self.shelved_on = on\n\n    def pickup_deadline(self) -> date:\n        return self.shelved_on + timedelta(days=PICKUP_DAYS)\n\n    def has_lapsed(self, today: date) -> bool:\n        return (self.shelved_on is not None and not self.collected\n                and today > self.pickup_deadline())", "note": "Cada método é uma frase do balcão: o exemplar vai para a estante (*shelve*), o sócio precisa retirá-lo até o prazo (*pickup deadline*), e uma reserva não retirada até lá *caducou* (*lapsed*)."},
 {"code": "\n    def collect(self, on: date) -> None:\n        if self.shelved_on is None:\n            raise ValueError(f\"{self.title!r} is not on the hold shelf yet\")\n        if self.has_lapsed(on):\n            raise ValueError(f\"the hold on {self.title!r} was not collected by {self.pickup_deadline()}\")\n        self.collected = True", "note": "As duas recusas são as duas coisas que uma bibliotecária diria no balcão, e as mensagens as dizem com essas palavras."},
 {"code": "\n\nif __name__ == \"__main__\":\n    hold = Hold(\"Bia\", \"Vidas Secas\", placed_on=date(2026, 5, 4))\n    try:\n        hold.collect(date(2026, 5, 5))\n    except ValueError as err:\n        print(\"refused:\", err)\n    hold.shelve(date(2026, 5, 11))\n    print(\"collect by:\", hold.pickup_deadline())\n    print(\"lapsed on 18 May?\", hold.has_lapsed(date(2026, 5, 18)))\n    print(\"lapsed on 19 May?\", hold.has_lapsed(date(2026, 5, 19)))\n    try:\n        hold.collect(date(2026, 5, 19))\n    except ValueError as err:\n        print(\"refused:\", err)", "note": "Bia tenta retirar cedo demais, o exemplar vai para a estante em 11 de maio, e ela aparece no dia 19, um dia atrasada."}
]}
```

```
ana@laptop:~/patterns/ddd-strategic$ python3 holds.py
refused: 'Vidas Secas' is not on the hold shelf yet
collect by: 2026-05-18
lapsed on 18 May? False
lapsed on 19 May? True
refused: the hold on 'Vidas Secas' was not collected by 2026-05-18
```

A reserva não pode ser retirada antes de ir para a estante, e a mensagem diz isso com as palavras do
balcão. Posta na estante em 11 de maio, precisa ser retirada até o dia 18; no dia 18 não caducou, no
dia 19 caducou, e a retirada nesse dia é recusada com uma frase que uma bibliotecária diria. **Nada
neste arquivo precisa de tradução para quem decide as regras**, e esse é o teste de uma linguagem
ubíqua: leia os nomes dos métodos em voz alta para uma bibliotecária e veja se ela corrige você.

## Quando a linguagem muda, o código muda

A linguagem não fica fixa no começo. Seis meses depois, as bibliotecárias decidem que uma reserva
caducada ganha mais um dia antes de o exemplar seguir adiante, e na reunião alguém chama isso de
*segunda chance*. O movimento da linguagem ubíqua é renomear e remodelar o código na mesma semana: um
método `second_chance`, um teste com esse nome, e a palavra no glossário. A alternativa, uma flag
chamada `retry_lapsed` que só os desenvolvedores entendem, é como as duas línguas voltam a se
afastar, um nome conveniente de cada vez.

Dois avisos da prática. Uma linguagem ubíqua não é uma língua só para a organização inteira: as duas
próximas seções encontram a mesma palavra querendo dizer coisas diferentes em partes diferentes da
biblioteca, e isso é normal. E código em inglês com palavras do negócio em português tem lugar: as
classes daqui poderiam se chamar `Reserva` e `prateleira_de_reservas` se é isso o que a equipe e as
bibliotecárias dizem. O que importa é uma palavra por significado, usada pelos dois lados.
