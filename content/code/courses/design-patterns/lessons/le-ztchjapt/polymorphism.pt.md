---
title: "Polimorfismo: uma chamada, muitos comportamentos"
version: 1
---

**O polimorfismo é a razão de os objetos valerem o trabalho.** Ele deixa um trecho de código chamar
um método sem saber que classe vai responder, então o código que decide *o que acontece* e o código
que decide *quando acontece* podem ser escritos, testados e mudados separadamente. O encapsulamento
mantém honesto o estado de um objeto; o polimorfismo é o que deixa trocar um objeto por outro.

A biblioteca manda um lembrete dois dias antes do vencimento de um empréstimo. Alguns membros querem
e-mail, alguns uma mensagem de texto, e uns poucos ainda pedem um aviso impresso no balcão. Escrito
sem polimorfismo, o código do lembrete pergunta toda vez que tipo de membro tem nas mãos:

```python
if member.channel == "email":
    send_email(member.address, text)
elif member.channel == "sms":
    send_sms(member.phone, text)
elif member.channel == "print":
    print_slip(member.name, text)
```

Esse `if` precisa ser repetido em todo lugar onde a biblioteca fala com um membro, e no dia em que
chegar um quarto canal, todas as cópias terão de ser encontradas. Com polimorfismo, cada canal é um
objeto que sabe entregar, e o código do lembrete só diz *entregue*:

```schooling-example
{"language": "python", "file": "notices.py", "parts": [
 {"code": "# notices.py\nfrom typing import Protocol\n\n\nclass Channel(Protocol):\n    def deliver(self, text: str) -> str: ...", "note": "Um `Protocol` dá nome ao método que um canal precisa ter. É um tipo para quem lê e para verificadores; em tempo de execução nada herda dele."},
 {"code": "\n\nclass Email:\n    def __init__(self, address: str):\n        self.address = address\n\n    def deliver(self, text: str) -> str:\n        return f\"e-mail to {self.address}, subject \\\"Library\\\": {text}\"\n\n\nclass Sms:\n    def __init__(self, phone: str):\n        self.phone = phone\n\n    def deliver(self, text: str) -> str:\n        return f\"SMS to {self.phone}: {text}\"\n\n\nclass PrintedSlip:\n    def deliver(self, text: str) -> str:\n        return f\"slip for the desk: {text.upper()}\"", "note": "Três classes sem nada em comum, a não ser um método chamado `deliver` que recebe o mesmo argumento. Nenhuma delas menciona `Channel`."},
 {"code": "\n\ndef remind(channels: list[Channel], title: str) -> None:\n    text = f\"'{title}' is due in two days\"\n    for channel in channels:\n        print(channel.deliver(text))", "note": "Esta função nunca vai mudar quando um canal for acrescentado. Ela não sabe que classes existem; sabe o único método que elas compartilham."},
 {"code": "\n\nif __name__ == \"__main__\":\n    remind([Email(\"bia@example.org\"), Sms(\"+55 11 5550-0142\"), PrintedSlip()],\n           \"A Hora da Estrela\")"}
]}
```

```
ana@laptop:~/patterns/oo$ python3 notices.py
e-mail to bia@example.org, subject "Library": 'A Hora da Estrela' is due in two days
SMS to +55 11 5550-0142: 'A Hora da Estrela' is due in two days
slip for the desk: 'A HORA DA ESTRELA' IS DUE IN TWO DAYS
```

Uma chamada, `channel.deliver(text)`, três comportamentos. O e-mail ganha um assunto e o aviso sai
em maiúsculas, e `remind` não sabe de nenhum dos dois.

## Três jeitos de as linguagens dizerem "tem este método"

O Python acha o método em tempo de execução e não pergunta nada antes. Isso é **duck typing**: se
tem `deliver`, é um canal. O `Protocol` acima acrescenta uma descrição contra a qual um verificador
de tipos como o mypy pode conferir o código, sem mudar o que roda. Cada uma das quatro linguagens da
trilha `backend` diz a mesma coisa de um jeito:

| linguagem | como `Channel` é escrito | `Email` precisa citá-lo? |
|---|---|---|
| Python | `class Channel(Protocol)`, ou nada | não |
| Go | `type Channel interface { Deliver(text string) string }` | não: qualquer tipo com o método o satisfaz |
| Java | `interface Channel { String deliver(String text); }` | sim: `class Email implements Channel` |
| TypeScript | `interface Channel { deliver(text: string): string }` | não: confere-se a forma, não o nome |

Go e TypeScript conferem a **forma**, como o protocolo do Python, mas na compilação. Java confere o
**nome**: uma classe com o método certo que não declarou `implements Channel` é recusada. Os dois
são polimorfismo, e as discussões de projeto do resto do curso valem para as quatro.

A herança também dá polimorfismo: uma lista de `Item` da seção anterior pode guardar filmes e livros
e chamar `describe` em cada um. O que este exemplo mostra é que não é preciso um pai comum para
consegui-lo. Essa observação é a maior parte da lição 2.
