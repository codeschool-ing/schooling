---
title: "Tell e ask: recebendo uma resposta"
version: 1
---

**Há dois jeitos de falar com um ator: tell, que manda uma mensagem e segue em frente, e ask, que
manda uma mensagem com um endereço de resposta e espera a resposta chegar lá.** Tell é o natural; o
modelo de atores não traz mais nada embutido. Ask é construído a partir do tell, e é de onde vem a
maior parte das surpresas em código com atores.

O primeiro instinto de quem está acostumado a objetos é acrescentar um método que devolve a contagem:
`shelf.available("Iracema")`. Ele rodaria na thread de quem chama e leria `_copies` enquanto a thread
do próprio ator poderia estar mudando o dicionário, que é a corrida da seção 02 de novo. A resposta
tem de vir da thread do ator, então tem de voltar como mensagem.

A biblioteca padrão do Python já tem um recipiente para um valor que vai chegar depois:
`concurrent.futures.Future`. Uma thread espera em `result()`; outra chama `set_result()` e quem
esperava acorda com o valor. É uma caixa de correio de uma só entrega, e é tudo de que o ask precisa.

```schooling-example
{"language": "python", "file": "ask.py", "parts": [
 {"code": "# ask.py\nfrom concurrent.futures import Future\nfrom dataclasses import dataclass\n\nfrom actor import Actor, Lend, Shelf", "note": "O `actor.py` da seção anterior é importado, então a estante, as mensagens e a caixa de correio são as que você já rodou."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Available:\n    title: str\n    reply: Future\n\n\ndef ask(actor: Actor, make_message, timeout: float = 1.0):\n    reply: Future = Future()\n    actor.tell(make_message(reply))\n    return reply.result(timeout=timeout)", "note": "Uma pergunta carrega o próprio endereço de resposta, um `Future`. `ask` cria o future, manda ao ator uma mensagem montada em volta dele, e espera a resposta por no máximo `timeout` segundos."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Recount:\n    title: str\n\n\nclass CountingShelf(Shelf):\n    def receive(self, message) -> None:\n        match message:\n            case Available(title=title, reply=reply):\n                reply.set_result(self._copies.get(title, 0))\n            case Recount(title=title):\n                try:\n                    n = ask(self, lambda r: Available(title, r), timeout=0.5)\n                    print(f\"recount: {n}\")\n                except TimeoutError:\n                    print(\"recount: the shelf asked itself and gave up after 0.5 s\")\n            case _:\n                super().receive(message)", "note": "`Available` é respondida definindo o resultado do future, na thread do ator, a partir de um estado que só essa thread toca. `Recount` é um erro proposital: enquanto trata dela, a estante faz uma pergunta a si mesma. Todo o resto vai para a classe mãe."},
 {"code": "\n\nif __name__ == \"__main__\":\n    shelf = CountingShelf({\"Iracema\": 1})\n    print(\"asked:\", ask(shelf, lambda r: Available(\"Iracema\", r)))\n    shelf.tell(Lend(\"Iracema\", \"north desk\"))\n    print(\"asked:\", ask(shelf, lambda r: Available(\"Iracema\", r)))\n    shelf.tell(Recount(\"Iracema\"))\n    shelf.stop()", "note": "A thread principal pergunta, empresta, pergunta de novo, e por fim manda a recontagem."}
]}
```

```
ana@laptop:~/patterns/actors$ python3 ask.py
asked: 1
Iracema: lent, 0 left
asked: 0
recount: the shelf asked itself and gave up after 0.5 s
```

A primeira resposta é 1. Depois o empréstimo é tratado e a segunda resposta é 0, e essa ordem é
garantida: o *Available* da thread principal entrou na caixa de correio depois do *Lend* dela, e a
caixa é a primeira a entrar, a primeira a sair. **Um ask fica na fila depois de tudo o que o mesmo
remetente mandou antes dele**, que é o que torna seguro o padrão "tell, depois ask".

## O ator que esperou por si mesmo

A última linha é a armadilha. Enquanto tratava *Recount*, a estante mandou *Available* para si mesma
e esperou a resposta. Só que a resposta só pode ser escrita pela thread da estante, e essa thread era
justamente a que esperava. Nada responderia nunca. Sem o timeout, a estante ficaria em `result()` para
sempre e toda mensagem atrás de *Recount* esperaria junto: a pergunta de um balcão teria parado a
biblioteca inteira.

O mesmo deadlock acontece com dois atores que perguntam um ao outro, A esperando B enquanto B espera
A, e é o motivo mais forte para as bibliotecas desencorajarem o ask. O `ask` do Akka devolve um future
em vez de bloquear, e a documentação dele trata bloquear dentro de um ator como bug. O
`gen_server:call` do Erlang recebe um timeout, cinco segundos por padrão, e derruba quem chamou quando
ele expira. **Um timeout não conserta o projeto; ele transforma um travamento num erro que alguém
vê.** Repare também que a pergunta da estante não sumiu quando a espera desistiu. Ela continuava na
caixa de correio e foi respondida depois que *Recount* retornou, para um future que ninguém mais
segurava.

## Prefira o tell

A maioria dos projetos que recorrem ao ask pode ser virada do avesso. Em vez de o balcão perguntar à
estante se há um exemplar livre e depois mandar emprestar, o balcão diz à estante *empreste Iracema à
Bia, e me conte como foi*, passando o próprio endereço. A estante decide num passo só, sem brecha entre
verificar e agir, e manda *Lent* ou *Refused* de volta. O balcão trata a resposta quando ela chega,
como mais uma mensagem, sem bloquear ninguém no meio.

| | tell | ask |
|---|---|---|
| quem envia | segue em frente na hora | espera, até um timeout |
| a resposta | nenhuma, ou uma mensagem posterior para quem enviou | um valor vindo de um future |
| dentro de um ator | sempre seguro | pode travar, e bloqueia toda mensagem na fila atrás dele |
| serve para | comandos, eventos, respostas | a borda do sistema, onde código que não é ator precisa de um valor |

A última linha é onde o ask cabe: um handler web ou um teste que não é ator e precisa de um valor
agora. Entre atores, tell com endereço de resposta deixa todo ator livre para tratar a próxima
mensagem.

## Na sua linguagem

Uma `Promise` de JavaScript, um `CompletableFuture` de Java e um canal de Go de tamanho um são cada um
um endereço de resposta no sentido usado aqui. Quem programa em Go escreve o ask como "mande um pedido
que carrega um `chan` para a resposta, depois receba dele", que é exatamente o `ask` acima com um canal
no lugar do future. O deadlock é o mesmo em todos: uma goroutine que manda um pedido a si mesma e
espera no canal de resposta bloqueia para sempre, e o runtime do Go só informa "all goroutines are
asleep" quando todas as goroutines estão presas.
