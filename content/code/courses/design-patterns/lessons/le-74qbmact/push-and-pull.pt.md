---
title: "Push e pull: quem decide quando o próximo valor anda"
version: 1
---

**Programação reativa costuma ser descrita como "assíncrona" ou "rápida", e nenhuma das duas
palavras é a ideia.** A ideia é sobre direção. Na maior parte do código que você já escreveu, quem
consome pede o próximo valor quando está pronto para ele: isso é *pull*. Em código reativo, quem
produz entrega um valor quando tem um, e quem consome precisa lidar com ele naquela hora: isso é
*push*. Threads, laços de eventos e velocidade costumam andar junto com o push. Nenhum deles é o que
torna um código reativo.

Você viu as duas formas na lição 6 como dois padrões separados. O iterator é pull: o laço chama
`next()` e a coleção responde. O observer é push: o sujeito chama cada ouvinte quando algo acontece.
Erik Meijer, que projetou as Reactive Extensions da Microsoft por volta de 2009, construiu tudo sobre
a observação de que os dois são o mesmo padrão virado do avesso. O iterator devolve valores para
quem o chamou; o observer recebe valores de alguém que ele nunca chamou.

O balcão de devoluções da biblioteca mostra as duas coisas. Crie `~/patterns/reactive` e trabalhe
lá:

```sh
mkdir -p ~/patterns/reactive
cd ~/patterns/reactive
```

```schooling-example
{"language": "python", "file": "pull_push.py", "parts": [
 {"code": "# pull_push.py\nfrom itertools import islice\n\nRETURNS = [\"Dom Casmurro\", \"Vidas Secas\", \"Iracema\"]", "note": "Três livros voltam hoje. A lista é fixa para a saída ser a mesma em toda execução."},
 {"code": "\n\ndef returned_books():\n    for title in RETURNS:\n        print(f\"  desk: {title} is back\")\n        yield title", "note": "Um gerador é uma fonte pull: o corpo dele só roda até o próximo `yield`, e só quando alguém pede um valor."},
 {"code": "\n\ndef pull() -> None:\n    print(\"pull: the shelver asks for two books\")\n    for title in islice(returned_books(), 2):\n        print(f\"  shelver: shelving {title}\")", "note": "O repositor pede dois livros e para. O `islice` deixa de pedir depois do segundo, então o gerador nunca roda uma terceira vez."},
 {"code": "\n\nclass Desk:\n    def __init__(self):\n        self._listeners = []\n\n    def subscribe(self, listener) -> None:\n        self._listeners.append(listener)\n\n    def book_returned(self, title: str) -> None:\n        print(f\"  desk: {title} is back\")\n        for listener in self._listeners:\n            listener(title)", "note": "O balcão é uma fonte push. Ele guarda uma lista de ouvintes e, quando um livro volta, chama cada um deles."},
 {"code": "\n\ndef push() -> None:\n    print(\"push: the desk tells whoever subscribed\")\n    desk = Desk()\n    desk.subscribe(lambda title: print(f\"  shelver: shelving {title}\"))\n    desk.subscribe(lambda title: print(f\"  catalogue: {title} available\"))\n    for title in RETURNS:\n        desk.book_returned(title)", "note": "Dois ouvintes, e é o balcão que decide quando eles rodam. Nenhum dos dois pode dizer *ainda não*."},
 {"code": "\n\nif __name__ == \"__main__\":\n    pull()\n    push()"}
]}
```

```
ana@laptop:~/patterns/reactive$ python3 pull_push.py
pull: the shelver asks for two books
  desk: Dom Casmurro is back
  shelver: shelving Dom Casmurro
  desk: Vidas Secas is back
  shelver: shelving Vidas Secas
push: the desk tells whoever subscribed
  desk: Dom Casmurro is back
  shelver: shelving Dom Casmurro
  catalogue: Dom Casmurro available
  desk: Vidas Secas is back
  shelver: shelving Vidas Secas
  catalogue: Vidas Secas available
  desk: Iracema is back
  shelver: shelving Iracema
  catalogue: Iracema available
```

Leia primeiro a metade pull. O balcão imprime *Dom Casmurro is back*, o repositor guarda o livro, e só
então o balcão procura o próximo. Depois de dois, o repositor para de pedir, e a linha *Iracema is
back* nunca aparece: **num projeto pull quem consome dita o ritmo, inclusive o ritmo zero.** O
gerador não produziu um terceiro valor que ninguém queria, porque ninguém pediu.

A metade push imprime os três livros, cada um seguido dos dois ouvintes. O repositor e o catálogo
rodam dentro de `book_returned`, no horário do balcão. Se o repositor fosse lento, o balcão esperaria
por ele aqui, porque a chamada é direta; no observer da lição 6 a história acabava aí. A seção 06
desta lição trata do que acontece quando o balcão não pode esperar.

## Quatro tipos de resposta

As duas formas cabem numa tabela que o trabalho de Meijer popularizou, e ela é o mapa mais rápido de
onde a programação reativa fica entre coisas que você já usa:

| | um valor | muitos valores |
|---|---|---|
| **pull**: você pede e espera | uma chamada de função devolve | um iterator ou um gerador |
| **push**: chega quando estiver pronto | um future, uma promise | um observable |

Uma promise em JavaScript, um `Future` em Java e uma task do `asyncio` em Python são a versão push de
uma chamada de função: um valor, algum tempo depois. Um observable é a versão push de um iterator:
qualquer número de valores, cada um algum tempo depois, e então um sinal de que não vem mais nada. A
seção 03 constrói um.

## Que forma uma fonte pede

Algumas fontes podem ser puxadas. Um arquivo, uma lista na memória e um cursor de banco de dados
esperam com paciência o próximo pedido, e puxá-los é mais simples: um laço comum, uma exceção comum,
e quem consome nunca tem mais do que pediu.

Outras fontes não podem ser consultadas. Um membro chega ao balcão quando decide, um leitor de
código de barras dispara quando um livro passa por baixo dele, e um usuário clica quando clica. Dá
para transformar uma fonte dessas em fonte pull pondo uma fila na frente, e essa fila é justamente
onde começa o problema das seções 06 e 07. **Programação reativa é o conjunto de ferramentas para
fontes que empurram**: um jeito de descrever o que deve acontecer com cada valor quando ele chega, e o
que deve acontecer quando eles chegam mais depressa do que você dá conta.

Um aviso sobre o nome. O *Reactive Manifesto*, publicado em 2013, descreve sistemas que continuam
respondendo sob carga e sob falha, e divide com esta lição uma palavra e muito pouco além dela. O
assunto dele é arquitetura entre serviços, que as lições 11 e 12 de `architecture` cobriram. Esta
lição fica dentro de um programa só.
