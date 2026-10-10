---
title: "Separação entre comando e consulta: mudar ou responder, nunca os dois"
version: 1
---

**Um método deve ou mudar o estado do objeto ou devolver uma resposta sobre ele, e nunca fazer as
duas coisas.** Bertrand Meyer enunciou a regra em *Object-Oriented Software Construction*, em 1988,
e chamou os dois tipos de *comandos* e *consultas*. Uma consulta pode ser chamada quantas vezes for,
em qualquer ordem, de uma linha de log, de um depurador ou de um teste, e nada muda. Um comando é
chamado quando você quer a mudança. A regra é sobre assinaturas de métodos, e o CQRS, duas seções
adiante, é a mesma regra aplicada a modelos inteiros.

A crença a deixar de lado é que um método que devolve algo útil é inofensivo. Ele é inofensivo
quando é uma consulta. Quando é também um comando, todo lugar que só queria a resposta provoca a
mudança junto.

```schooling-example
{"language": "python", "file": "cqs.py", "parts": [
 {"code": "# cqs.py\nclass Shelf:\n    def __init__(self, copies: list[str]):\n        self._copies = list(copies)\n\n    def take(self) -> str:\n        return self._copies.pop(0)\n\n    def count(self) -> int:\n        return len(self._copies)", "note": "`take` responde a uma pergunta, qual exemplar vem a seguir, e muda a estante na mesma chamada. `list.pop` faz a mesma coisa, e é daí que vem o hábito."},
 {"code": "\n\nclass SeparatedShelf:\n    def __init__(self, copies: list[str]):\n        self._copies = list(copies)\n\n    def next_copy(self) -> str:\n        return self._copies[0]\n\n    def remove(self, copy_id: str) -> None:\n        self._copies.remove(copy_id)\n\n    def count(self) -> int:\n        return len(self._copies)", "note": "A mesma estante com as duas tarefas separadas. `next_copy` responde e não muda nada; `remove` muda e não responde nada."},
 {"code": "\n\nif __name__ == \"__main__\":\n    shelf = Shelf([\"C1\", \"C2\", \"C3\"])\n    print(\"debugging, which copy is next?\", shelf.take())\n    lent = shelf.take()\n    print(\"lent\", lent, \"| left on the shelf:\", shelf.count())\n\n    shelf = SeparatedShelf([\"C1\", \"C2\", \"C3\"])\n    print(\"debugging, which copy is next?\", shelf.next_copy())\n    lent = shelf.next_copy()\n    shelf.remove(lent)\n    print(\"lent\", lent, \"| left on the shelf:\", shelf.count())", "note": "Cada metade do programa faz a mesma pergunta uma vez enquanto depura, e depois empresta um exemplar. Só a chamada com cara de inofensiva é diferente."}
]}
```

```
ana@laptop:~/patterns/cqrs$ python3 cqs.py
debugging, which copy is next? C1
lent C2 | left on the shelf: 1
debugging, which copy is next? C1
lent C1 | left on the shelf: 2
```

A primeira metade emprestou o **C2**, não o C1, e deixou um exemplar onde deviam estar dois. A linha
de depuração perguntou qual exemplar vinha a seguir, e perguntar o levou embora. Ninguém que lê
`print("…", shelf.take())` numa revisão enxerga um empréstimo; parece uma pergunta. A segunda
metade fez a mesma pergunta duas vezes e emprestou o C1, com dois exemplares sobrando, porque
`next_copy` é uma consulta e perguntar não custa nada.

## O que a regra compra

**Uma consulta é segura de chamar de qualquer lugar.** Você pode pô-la numa linha de log, numa
asserção, na janela de observação de um depurador ou na preparação de um teste, e ela quer dizer a
mesma coisa toda vez. O argumento de Meyer era exatamente esse: um programa cujas perguntas não têm
efeito colateral pode ser compreendido fazendo-lhe perguntas.

**O nome de um comando diz que algo muda.** `remove(copy_id)` se lê como uma mudança e devolve
`None`, então ninguém o chama para descobrir alguma coisa. Em Python, um método que devolve `None`
deixa a intenção visível em toda chamada; o mesmo vale para um método `void` em Java ou uma função
Go que devolve só um `error`.

**Os dois se testam separadamente.** Uma consulta se testa montando um estado e perguntando. Um
comando se testa chamando-o e depois perguntando a uma consulta se o estado mudou, o que mantém as
asserções num vocabulário só.

## Onde a regra se dobra

A regra de Meyer tem exceções conhecidas, e fingir que não tem ensina as pessoas a desconfiar dela.

| exceção | por que devolve e muda | na biblioteca padrão |
|---|---|---|
| tirar de uma pilha ou de uma fila | quem chama precisa do item removido, e perguntar antes e remover depois são dois passos | `list.pop`, `queue.Queue.get`, `deque.popleft` |
| um iterador | avançar e entregar o próximo elemento é um ato só | `next(it)` |
| uma operação atômica sob concorrência | separar "está livre?" de "pegue" deixa outra thread pegar no meio | `dict.setdefault`, um `INSERT … RETURNING id` no banco |

A última linha é a que mais importa. Com duas threads ou duas requisições, `if shelf.next_copy() ==
"C1": shelf.remove("C1")` pode ser intercalado de modo que as duas vejam o C1 livre e as duas o
removam. Quando a resposta e a mudança precisam acontecer juntas, um método que faz as duas é o
correto, e a lição 18 mostra corridas exatamente desse tipo.

Um caso mais brando é um comando que devolve o identificador que criou, como o id de um empréstimo
novo. É uma dobra comum e razoável: quem chama não tem outro jeito de saber o id sem uma segunda
consulta que poderia entrar em corrida. O que a regra continua proibindo é um comando que devolve
uma visão do mundo, o registro inteiro do membro ou as próximas linhas da tela, porque aí todo
mundo que quer a visão executa o comando.

## Na sua linguagem

A regra é a mesma em todo lugar; o que muda é o quanto a assinatura a anuncia. Java e TypeScript
marcam um comando com `void`, e Go com uma função que devolve só `error`. Em Python, um método
anotado com `-> None` diz o mesmo, e um verificador de tipos como o mypy aponta quem tenta usar o
resultado dele. O `sync.Map` do Go é um bom lugar para ver a exceção da concorrência nomeada com
honestidade: `LoadOrStore` devolve o valor e se ele já estava lá, porque perguntar e guardar em duas
chamadas entraria em corrida.
