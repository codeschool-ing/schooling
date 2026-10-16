---
title: "CAP: o que um link quebrado obriga"
version: 1
---

**Quando a rede entre duas cópias dos seus dados quebra, cada lado precisa escolher: responder e
arriscar discordar do outro lado, ou recusar até ter certeza.** Esse é o teorema CAP, proposto como
conjectura por Eric Brewer em 2000 e provado por Seth Gilbert e Nancy Lynch em 2002, e a lição 8 de
`architecture` o desmonta direito. Esta seção é sobre a cara da escolha no código que você escreve,
porque ela está lá, num `if`, e alguém tem de decidir o que ele diz.

A leitura errada mais comum é "escolha dois de três", como se um sistema pudesse ficar com
consistência e disponibilidade e simplesmente dispensar as partições. Partição não é algo que você
escolhe. Cabos são cortados, um roteador reinicia, um data center perde o link de saída. **A escolha
que o CAP descreve só existe enquanto a rede está quebrada, e você a faz de antemão, em código,
para o dia em que acontecer.**

A biblioteca abre uma segunda filial na Vila Madalena. Cada filial guarda uma cópia do estoque para
o balcão trabalhar rápido, e a cópia de Centro é a que a biblioteca trata como verdade. Resta um
exemplar de um livro, o link entre as filiais cai, e um sócio entra em cada filial:

```schooling-example
{"language": "python", "file": "branches.py", "parts": [
 {"code": "# branches.py\nclass Refused(Exception):\n    pass\n\n\nclass Branch:\n    def __init__(self, name: str, primary: bool):\n        self.name = name\n        self.primary = primary\n        self.copies = 1\n        self.loans: list[str] = []\n        self.peer: \"Branch | None\" = None\n        self.link_up = True", "note": "Uma filial guarda a própria cópia da contagem e dos empréstimos. Centro é a primária: a cópia dela é a que a biblioteca trata como verdade."},
 {"code": "\n    def lend(self, member: str, mode: str) -> None:\n        if mode == \"CP\" and not self.primary and not self.link_up:\n            raise Refused(f\"cannot reach {self.peer.name}, try again later\")\n        if self.copies == 0:\n            raise Refused(\"no copy left\")\n        self.copies -= 1\n        self.loans.append(member)\n        if self.link_up:\n            self.peer.copies, self.peer.loans = self.copies, list(self.loans)", "note": "O CAP inteiro está no primeiro `if`. No modo `CP`, uma filial que não alcança a primária recusa; no modo `AP`, empresta a partir da cópia que tem. Com o link no ar, toda mudança vai na hora para a outra filial."},
 {"code": "\n\ndef pair() -> tuple[Branch, Branch]:\n    centro, vila = Branch(\"Centro\", primary=True), Branch(\"Vila Madalena\", primary=False)\n    centro.peer, vila.peer = vila, centro\n    return centro, vila"},
 {"code": "\n\nif __name__ == \"__main__\":\n    for mode in (\"CP\", \"AP\"):\n        print(mode)\n        centro, vila = pair()\n        centro.link_up = vila.link_up = False\n        for branch, member in ((centro, \"Bia\"), (vila, \"Caio\")):\n            try:\n                branch.lend(member, mode)\n                print(f\"  {branch.name} lends the copy to {member}\")\n            except Refused as err:\n                print(f\"  {branch.name} refuses {member}: {err}\")\n        loans = sorted(set(centro.loans) | set(vila.loans))\n        print(f\"  link back up: loans {loans} against 1 copy\")", "note": "O link é cortado antes de alguém chegar. Bia pede em Centro, Caio em Vila Madalena, o único exemplar que as duas filiais acreditam ter."}
]}
```

```
ana@laptop:~/patterns/acid-cap$ python3 branches.py
CP
  Centro lends the copy to Bia
  Vila Madalena refuses Caio: cannot reach Centro, try again later
  link back up: loans ['Bia'] against 1 copy
AP
  Centro lends the copy to Bia
  Vila Madalena lends the copy to Caio
  link back up: loans ['Bia', 'Caio'] against 1 copy
```

No modo `CP`, Centro continua emprestando. É a primária, então a resposta dela é a verdade, pense o
que pensar a outra filial. A Vila Madalena não tem como saber se o exemplar ainda existe, então
recusa Caio, e quando o link volta há um empréstimo para um exemplar. **A consistência foi mantida
deixando um dos lados indisponível, e o outro lado seguiu trabalhando.**

No modo `AP`, as duas filiais emprestam. Cada uma atendeu o seu sócio na hora, e quando o link volta
a biblioteca tem dois empréstimos para um exemplar. Nada no programa está quebrado. Esse resultado é
o preço da disponibilidade, e agora alguém precisa ligar para o Caio.

## O que cada resposta custa em código

Uma recusa é uma exceção, e uma exceção precisa ser tratada por alguém. No modo `CP`, a tela do
balcão precisa de uma frase para "não foi possível falar com Centro, tente mais tarde", de um sócio
que volta para casa sem o livro, e de uma nova tentativa. Esse código existe só por causa da
escolha.

Aceitar custa outro tipo de código, e ele roda depois. Alguém precisa achar o conflito quando o link
volta, decidir quem fica com o exemplar e avisar o outro sócio. As projeções da lição 9 viram uma
forma mais branda da mesma coisa, um modelo de leitura que atrasa; aqui duas escritas discordam, e
nenhuma espera as reconcilia sozinha.

## Os dois Cs são palavras diferentes

O C do CAP e o C do ACID dividem uma letra e quase mais nada, e confundi-los faz os dois teoremas
parecerem errados.

| | o C do ACID | o C do CAP |
|---|---|---|
| significa | uma transação deixa os dados válidos: restrições e regras valem | toda leitura vê a escrita mais recente, como se houvesse uma cópia só |
| é sobre | um banco, e as regras sobre os dados dele | várias cópias dos dados, e se elas concordam |
| nesta lição | a chave estrangeira recusando `m-009` em `reserve.py` | a Vila Madalena recusando Caio em vez de responder com uma contagem velha |

O C do CAP é o que a literatura chama de *linearizabilidade*. Um sistema pode ter todas as
propriedades ACID em cada nó e mesmo assim falhar no C do CAP entre os nós, que é exatamente o que a
execução `AP` mostra: os dados de cada filial são válidos, e as duas discordam.
